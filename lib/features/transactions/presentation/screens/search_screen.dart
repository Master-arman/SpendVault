import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/theme_toggle_button.dart';
import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:finance_app/core/utils/debouncer.dart';
import 'package:finance_app/features/categories/data/models/category.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

/// Presentation model representing unified transaction search results.
class SearchResultItem {
  const SearchResultItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.timestamp,
    required this.isExpense,
    required this.categoryName,
    this.note,
    this.tags = const [],
  });

  final String id;
  final String title;
  final double amount;
  final DateTime timestamp;
  final bool isExpense;
  final String categoryName;
  final String? note;
  final List<String> tags;

  factory SearchResultItem.fromIsar(Transaction tx) {
    return SearchResultItem(
      id: tx.id.toString(),
      title: tx.note?.isNotEmpty == true ? tx.note! : (tx.category.value?.name ?? 'Transaction'),
      amount: tx.amount,
      timestamp: tx.timestamp,
      isExpense: tx.type == TransactionType.expense,
      categoryName: tx.category.value?.name ?? 'General',
      note: tx.note,
      tags: tx.tags,
    );
  }

  factory SearchResultItem.fromModel(TransactionModel model) {
    return SearchResultItem(
      id: model.id,
      title: model.title,
      amount: model.amount,
      timestamp: model.date,
      isExpense: model.isExpense,
      categoryName: model.category,
      note: model.note ?? model.title,
      tags: [if (model.isAutomated) '#auto', '#${model.category.toLowerCase().replaceAll(' ', '_')}'],
    );
  }
}

/// Phase 41: Multi-Parametric Search with 300ms Debounce.
///
/// Combines full-text search across notes, tags, and category titles:
/// ```dart
/// isar.transactions.filter()
///   .noteContains(query, caseSensitive: false)
///   .or()
///   .tagsElementContains(query, caseSensitive: false)
///   .sortByTimestampDesc()
///   .findAll();
/// ```
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    this.isar,
    this.initialTransactions,
    this.initialTransactionModels,
    this.repository,
    this.initialQuery = '',
    super.key,
  });

  final Isar? isar;
  final List<Transaction>? initialTransactions;
  final List<TransactionModel>? initialTransactionModels;
  final TransactionRepository? repository;
  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Debouncer _debouncer = Debouncer(milliseconds: 300);

  late final TransactionRepository _repository;
  List<SearchResultItem> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _currentQuery = '';

  final List<String> _popularTags = const [
    '#food',
    '#dining',
    '#shopping',
    '#tech',
    '#bills',
    '#subscription',
    '#auto',
  ];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? TransactionRepositoryImpl();
    if (widget.initialQuery.isNotEmpty) {
      _searchController.text = widget.initialQuery;
      _executeSearch(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    setState(() {
      _currentQuery = query;
      _isSearching = query.trim().isNotEmpty;
    });

    _debouncer.run(() {
      _executeSearch(query);
    });
  }

  Future<void> _executeSearch(String query) async {
    final String cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      if (mounted) {
        setState(() {
          _results = [];
          _isSearching = false;
          _hasSearched = false;
        });
      }
      return;
    }

    List<SearchResultItem> matchedResults = [];

    // Case 1: Direct Isar query execution using Multi-Parametric Filter API
    if (widget.isar != null) {
      final isar = widget.isar!;
      
      // Step 1: Query transactions directly by notes or tags
      final List<Transaction> isarDirectMatches = await isar.transactions
          .filter()
          .noteContains(cleanQuery, caseSensitive: false)
          .or()
          .tagsElementContains(cleanQuery, caseSensitive: false)
          .sortByTimestampDesc()
          .findAll();

      // Step 2: Query by category titles if category matches
      final List<Category> matchingCategories = await isar.categorys
          .filter()
          .nameContains(cleanQuery, caseSensitive: false)
          .findAll();

      final Set<int> seenIds = isarDirectMatches.map((t) => t.id).toSet();
      matchedResults.addAll(isarDirectMatches.map((t) => SearchResultItem.fromIsar(t)));

      if (matchingCategories.isNotEmpty) {
        final List<Transaction> allTransactions = await isar.transactions.where().findAll();
        for (final tx in allTransactions) {
          if (!seenIds.contains(tx.id)) {
            final String catName = tx.category.value?.name ?? '';
            if (catName.toLowerCase().contains(cleanQuery.toLowerCase())) {
              matchedResults.add(SearchResultItem.fromIsar(tx));
              seenIds.add(tx.id);
            }
          }
        }
      }
    } else if (widget.initialTransactions != null) {
      // Case 2: In-memory Isar Transaction list
      final qLower = cleanQuery.toLowerCase();
      final filtered = widget.initialTransactions!.where((tx) {
        final bool noteMatch = tx.note?.toLowerCase().contains(qLower) ?? false;
        final bool tagMatch = tx.tags.any((tag) => tag.toLowerCase().contains(qLower));
        final bool catMatch =
            (tx.category.value?.name ?? '').toLowerCase().contains(qLower);
        return noteMatch || tagMatch || catMatch;
      }).toList();

      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      matchedResults = filtered.map((t) => SearchResultItem.fromIsar(t)).toList();
    } else {
      // Case 3: Domain Transaction Repository / Models
      final List<TransactionModel> all = widget.initialTransactionModels ??
          await _repository.getTransactions(limit: 100);
      final qLower = cleanQuery.toLowerCase();

      final filtered = all.where((model) {
        final bool titleMatch = model.title.toLowerCase().contains(qLower);
        final bool noteMatch = model.note?.toLowerCase().contains(qLower) ?? false;
        final bool catMatch = model.category.toLowerCase().contains(qLower);
        final bool merchantMatch =
            model.merchant?.toLowerCase().contains(qLower) ?? false;
        final bool autoMatch =
            qLower == '#auto' || qLower == 'auto' ? model.isAutomated : false;
        return titleMatch || noteMatch || catMatch || merchantMatch || autoMatch;
      }).toList();

      filtered.sort((a, b) => b.date.compareTo(a.date));
      matchedResults = filtered.map((m) => SearchResultItem.fromModel(m)).toList();
    }

    if (mounted) {
      setState(() {
        _results = matchedResults;
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  void _clearSearch() {
    _debouncer.cancel();
    _searchController.clear();
    setState(() {
      _currentQuery = '';
      _results = [];
      _isSearching = false;
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Ledger'),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Box with 300ms Debounce and Clear Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? AppColors.accentIndigo
                      : AppColors.borderStroke,
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x11000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                key: const Key('search_input_field'),
                controller: _searchController,
                focusNode: _focusNode,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search notes, tags (#bills), or categories...',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.accentIndigo,
                    size: 22,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          key: const Key('search_clear_button'),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: _onQueryChanged,
                onSubmitted: (val) {
                  _debouncer.cancel();
                  _executeSearch(val);
                },
              ),
            ),
          ),

          // Debounce Active Loading Indicator
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                key: Key('search_loading_indicator'),
                backgroundColor: Colors.transparent,
                color: AppColors.accentIndigo,
                minHeight: 2,
              ),
            ),

          // Quick Filter Tag Chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _popularTags.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final String tag = _popularTags[index];
                final bool isSelected = _currentQuery.toLowerCase() == tag.toLowerCase();

                return ActionChip(
                  label: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.indigoLight,
                    ),
                  ),
                  backgroundColor: isSelected
                      ? AppColors.accentIndigo
                      : AppColors.surfaceCard,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.accentIndigo
                        : AppColors.borderStroke,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onPressed: () {
                    _searchController.text = tag;
                    _onQueryChanged(tag);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Search Results / States
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (!_hasSearched) {
      return Center(
        key: const Key('empty_search_state'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.accentIndigo.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.travel_explore_rounded,
                size: 40,
                color: AppColors.indigoLight,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Multi-Parametric Search',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Type to filter by transaction notes, #tags, or categories',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty && _hasSearched) {
      return Center(
        key: const Key('no_results_state'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 44,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No matches found for "$_currentQuery"',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try searching with a broader keyword or a tag',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    final DateFormat formatter = DateFormat('MMM d, yyyy');

    return ListView.separated(
      key: const Key('search_results_list'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final SearchResultItem item = _results[index];

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderStroke),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.isExpense
                      ? AppColors.expenseRedSoft
                      : AppColors.successGreenSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.isExpense
                      ? Icons.arrow_outward_rounded
                      : Icons.arrow_downward_rounded,
                  color: item.isExpense
                      ? AppColors.expenseRed
                      : AppColors.successGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          item.categoryName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.indigoLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatter.format(item.timestamp),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    if (item.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: item.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.borderStroke.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${item.isExpense ? '-' : '+'}${CurrencyFormatter.format(item.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: item.isExpense
                      ? AppColors.expenseRed
                      : AppColors.successGreen,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
