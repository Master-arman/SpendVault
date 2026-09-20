import 'package:flutter/material.dart';

/// Configuration helper for staggered entrance animations.
class AnimationConfiguration {
  const AnimationConfiguration._();

  /// Wraps a list item at [position] with a staggered sliding and fade entrance delay.
  static Widget staggeredList({
    required int position,
    Duration duration = const Duration(milliseconds: 320),
    Duration delay = const Duration(milliseconds: 40),
    Curve curve = Curves.easeOutCubic,
    required Widget child,
  }) {
    return StaggeredItem(
      position: position,
      duration: duration,
      delay: delay,
      curve: curve,
      child: child,
    );
  }

  /// Automatically wraps an entire list of [children] with staggered animations.
  static List<Widget> toStaggeredList({
    required List<Widget> children,
    Duration duration = const Duration(milliseconds: 320),
    Duration delay = const Duration(milliseconds: 40),
    Curve curve = Curves.easeOutCubic,
  }) {
    return List.generate(children.length, (int index) {
      return staggeredList(
        position: index,
        duration: duration,
        delay: delay,
        curve: curve,
        child: children[index],
      );
    });
  }
}

/// An animated wrapper that applies a per-index sliding offset and opacity fade.
class StaggeredItem extends StatefulWidget {
  const StaggeredItem({
    super.key,
    required this.position,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
    this.delay = const Duration(milliseconds: 40),
    this.curve = Curves.easeOutCubic,
    this.slideOffset = const Offset(0.0, 0.15),
  });

  final int position;
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset slideOffset;

  @override
  State<StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final CurvedAnimation curved = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnim = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(curved);

    final int totalDelayMs = widget.position * widget.delay.inMilliseconds;
    if (totalDelayMs == 0) {
      _controller.forward();
    } else {
      Future<void>.delayed(Duration(milliseconds: totalDelayMs), () {
        if (mounted && !_disposed) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
}

/// Staggered List Wrapper widget to animate ListView items seamlessly.
class StaggeredListWrapper extends StatelessWidget {
  const StaggeredListWrapper({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.delay = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 320),
    this.padding = EdgeInsets.zero,
    this.separatorBuilder,
    this.physics,
    this.shrinkWrap = false,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Duration delay;
  final Duration duration;
  final EdgeInsetsGeometry padding;
  final IndexedWidgetBuilder? separatorBuilder;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    if (separatorBuilder != null) {
      return ListView.separated(
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemCount: itemCount,
        separatorBuilder: separatorBuilder!,
        itemBuilder: (BuildContext context, int index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            delay: delay,
            duration: duration,
            child: itemBuilder(context, index),
          );
        },
      );
    }

    return ListView.builder(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) {
        return AnimationConfiguration.staggeredList(
          position: index,
          delay: delay,
          duration: duration,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}
