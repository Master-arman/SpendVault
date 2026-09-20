// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_audit_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSmsAuditLogCollection on Isar {
  IsarCollection<SmsAuditLog> get smsAuditLogs => this.collection();
}

const SmsAuditLogSchema = CollectionSchema(
  name: r'SmsAuditLog',
  id: -4751677749012678517,
  properties: {
    r'deduplicationHash': PropertySchema(
      id: 0,
      name: r'deduplicationHash',
      type: IsarType.string,
    ),
    r'detectedPayee': PropertySchema(
      id: 1,
      name: r'detectedPayee',
      type: IsarType.string,
    ),
    r'executionState': PropertySchema(
      id: 2,
      name: r'executionState',
      type: IsarType.string,
      enumMap: _SmsAuditLogexecutionStateEnumValueMap,
    ),
    r'inferredCategory': PropertySchema(
      id: 3,
      name: r'inferredCategory',
      type: IsarType.string,
    ),
    r'parsedAmount': PropertySchema(
      id: 4,
      name: r'parsedAmount',
      type: IsarType.double,
    ),
    r'rawPayload': PropertySchema(
      id: 5,
      name: r'rawPayload',
      type: IsarType.string,
    ),
    r'sourcePackageOrSender': PropertySchema(
      id: 6,
      name: r'sourcePackageOrSender',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 7,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _smsAuditLogEstimateSize,
  serialize: _smsAuditLogSerialize,
  deserialize: _smsAuditLogDeserialize,
  deserializeProp: _smsAuditLogDeserializeProp,
  idName: r'id',
  indexes: {
    r'deduplicationHash': IndexSchema(
      id: -6292943981559420207,
      name: r'deduplicationHash',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'deduplicationHash',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _smsAuditLogGetId,
  getLinks: _smsAuditLogGetLinks,
  attach: _smsAuditLogAttach,
  version: '3.1.0+1',
);

int _smsAuditLogEstimateSize(
  SmsAuditLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.deduplicationHash;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.detectedPayee;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.executionState.name.length * 3;
  {
    final value = object.inferredCategory;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.rawPayload.length * 3;
  {
    final value = object.sourcePackageOrSender;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _smsAuditLogSerialize(
  SmsAuditLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.deduplicationHash);
  writer.writeString(offsets[1], object.detectedPayee);
  writer.writeString(offsets[2], object.executionState.name);
  writer.writeString(offsets[3], object.inferredCategory);
  writer.writeDouble(offsets[4], object.parsedAmount);
  writer.writeString(offsets[5], object.rawPayload);
  writer.writeString(offsets[6], object.sourcePackageOrSender);
  writer.writeDateTime(offsets[7], object.timestamp);
}

SmsAuditLog _smsAuditLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SmsAuditLog();
  object.deduplicationHash = reader.readStringOrNull(offsets[0]);
  object.detectedPayee = reader.readStringOrNull(offsets[1]);
  object.executionState = _SmsAuditLogexecutionStateValueEnumMap[
          reader.readStringOrNull(offsets[2])] ??
      AuditExecutionState.parsed;
  object.id = id;
  object.inferredCategory = reader.readStringOrNull(offsets[3]);
  object.parsedAmount = reader.readDoubleOrNull(offsets[4]);
  object.rawPayload = reader.readString(offsets[5]);
  object.sourcePackageOrSender = reader.readStringOrNull(offsets[6]);
  object.timestamp = reader.readDateTime(offsets[7]);
  return object;
}

P _smsAuditLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (_SmsAuditLogexecutionStateValueEnumMap[
              reader.readStringOrNull(offset)] ??
          AuditExecutionState.parsed) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _SmsAuditLogexecutionStateEnumValueMap = {
  r'parsed': r'parsed',
  r'ignored': r'ignored',
  r'duplicate': r'duplicate',
};
const _SmsAuditLogexecutionStateValueEnumMap = {
  r'parsed': AuditExecutionState.parsed,
  r'ignored': AuditExecutionState.ignored,
  r'duplicate': AuditExecutionState.duplicate,
};

Id _smsAuditLogGetId(SmsAuditLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _smsAuditLogGetLinks(SmsAuditLog object) {
  return [];
}

void _smsAuditLogAttach(
    IsarCollection<dynamic> col, Id id, SmsAuditLog object) {
  object.id = id;
}

extension SmsAuditLogQueryWhereSort
    on QueryBuilder<SmsAuditLog, SmsAuditLog, QWhere> {
  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SmsAuditLogQueryWhere
    on QueryBuilder<SmsAuditLog, SmsAuditLog, QWhereClause> {
  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterWhereClause>
      deduplicationHashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'deduplicationHash',
        value: [null],
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterWhereClause>
      deduplicationHashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'deduplicationHash',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterWhereClause>
      deduplicationHashEqualTo(String? deduplicationHash) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'deduplicationHash',
        value: [deduplicationHash],
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterWhereClause>
      deduplicationHashNotEqualTo(String? deduplicationHash) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deduplicationHash',
              lower: [],
              upper: [deduplicationHash],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deduplicationHash',
              lower: [deduplicationHash],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deduplicationHash',
              lower: [deduplicationHash],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deduplicationHash',
              lower: [],
              upper: [deduplicationHash],
              includeUpper: false,
            ));
      }
    });
  }
}

extension SmsAuditLogQueryFilter
    on QueryBuilder<SmsAuditLog, SmsAuditLog, QFilterCondition> {
  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      deduplicationHashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deduplicationHash',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      deduplicationHashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deduplicationHash',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      deduplicationHashEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deduplicationHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      deduplicationHashGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deduplicationHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      deduplicationHashLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deduplicationHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      deduplicationHashBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deduplicationHash',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      deduplicationHashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deduplicationHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      deduplicationHashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deduplicationHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      deduplicationHashContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deduplicationHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      deduplicationHashMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deduplicationHash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      deduplicationHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deduplicationHash',
        value: '',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      deduplicationHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deduplicationHash',
        value: '',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      detectedPayeeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'detectedPayee',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      detectedPayeeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'detectedPayee',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      detectedPayeeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'detectedPayee',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      detectedPayeeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'detectedPayee',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      detectedPayeeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'detectedPayee',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      detectedPayeeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'detectedPayee',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      detectedPayeeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'detectedPayee',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      detectedPayeeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'detectedPayee',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      detectedPayeeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'detectedPayee',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      detectedPayeeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'detectedPayee',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      detectedPayeeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'detectedPayee',
        value: '',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      detectedPayeeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'detectedPayee',
        value: '',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      executionStateEqualTo(
    AuditExecutionState value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'executionState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      executionStateGreaterThan(
    AuditExecutionState value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'executionState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      executionStateLessThan(
    AuditExecutionState value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'executionState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      executionStateBetween(
    AuditExecutionState lower,
    AuditExecutionState upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'executionState',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      executionStateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'executionState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      executionStateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'executionState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      executionStateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'executionState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      executionStateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'executionState',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      executionStateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'executionState',
        value: '',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      executionStateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'executionState',
        value: '',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      inferredCategoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'inferredCategory',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      inferredCategoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'inferredCategory',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      inferredCategoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inferredCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      inferredCategoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'inferredCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      inferredCategoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'inferredCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      inferredCategoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'inferredCategory',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      inferredCategoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'inferredCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      inferredCategoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'inferredCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      inferredCategoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'inferredCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      inferredCategoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'inferredCategory',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      inferredCategoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inferredCategory',
        value: '',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      inferredCategoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'inferredCategory',
        value: '',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      parsedAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'parsedAmount',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      parsedAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'parsedAmount',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      parsedAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parsedAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      parsedAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'parsedAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      parsedAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'parsedAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      parsedAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'parsedAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      rawPayloadEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rawPayload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      rawPayloadGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rawPayload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      rawPayloadLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rawPayload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      rawPayloadBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rawPayload',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      rawPayloadStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rawPayload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      rawPayloadEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rawPayload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      rawPayloadContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rawPayload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      rawPayloadMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rawPayload',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      rawPayloadIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rawPayload',
        value: '',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      rawPayloadIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rawPayload',
        value: '',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      sourcePackageOrSenderIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sourcePackageOrSender',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      sourcePackageOrSenderIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sourcePackageOrSender',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      sourcePackageOrSenderEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourcePackageOrSender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      sourcePackageOrSenderGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourcePackageOrSender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      sourcePackageOrSenderLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourcePackageOrSender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      sourcePackageOrSenderBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourcePackageOrSender',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      sourcePackageOrSenderStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourcePackageOrSender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      sourcePackageOrSenderEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourcePackageOrSender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      sourcePackageOrSenderContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourcePackageOrSender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      sourcePackageOrSenderMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourcePackageOrSender',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      sourcePackageOrSenderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourcePackageOrSender',
        value: '',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      sourcePackageOrSenderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourcePackageOrSender',
        value: '',
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SmsAuditLogQueryObject
    on QueryBuilder<SmsAuditLog, SmsAuditLog, QFilterCondition> {}

extension SmsAuditLogQueryLinks
    on QueryBuilder<SmsAuditLog, SmsAuditLog, QFilterCondition> {}

extension SmsAuditLogQuerySortBy
    on QueryBuilder<SmsAuditLog, SmsAuditLog, QSortBy> {
  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      sortByDeduplicationHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deduplicationHash', Sort.asc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      sortByDeduplicationHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deduplicationHash', Sort.desc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy> sortByDetectedPayee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedPayee', Sort.asc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      sortByDetectedPayeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedPayee', Sort.desc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy> sortByExecutionState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executionState', Sort.asc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      sortByExecutionStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executionState', Sort.desc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      sortByInferredCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inferredCategory', Sort.asc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      sortByInferredCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inferredCategory', Sort.desc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy> sortByParsedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedAmount', Sort.asc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      sortByParsedAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedAmount', Sort.desc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy> sortByRawPayload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawPayload', Sort.asc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy> sortByRawPayloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawPayload', Sort.desc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      sortBySourcePackageOrSender() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourcePackageOrSender', Sort.asc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      sortBySourcePackageOrSenderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourcePackageOrSender', Sort.desc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy> sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension SmsAuditLogQuerySortThenBy
    on QueryBuilder<SmsAuditLog, SmsAuditLog, QSortThenBy> {
  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      thenByDeduplicationHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deduplicationHash', Sort.asc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      thenByDeduplicationHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deduplicationHash', Sort.desc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy> thenByDetectedPayee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedPayee', Sort.asc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      thenByDetectedPayeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedPayee', Sort.desc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy> thenByExecutionState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executionState', Sort.asc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      thenByExecutionStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executionState', Sort.desc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      thenByInferredCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inferredCategory', Sort.asc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      thenByInferredCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inferredCategory', Sort.desc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy> thenByParsedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedAmount', Sort.asc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      thenByParsedAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedAmount', Sort.desc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy> thenByRawPayload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawPayload', Sort.asc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy> thenByRawPayloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawPayload', Sort.desc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      thenBySourcePackageOrSender() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourcePackageOrSender', Sort.asc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy>
      thenBySourcePackageOrSenderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourcePackageOrSender', Sort.desc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QAfterSortBy> thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension SmsAuditLogQueryWhereDistinct
    on QueryBuilder<SmsAuditLog, SmsAuditLog, QDistinct> {
  QueryBuilder<SmsAuditLog, SmsAuditLog, QDistinct> distinctByDeduplicationHash(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deduplicationHash',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QDistinct> distinctByDetectedPayee(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'detectedPayee',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QDistinct> distinctByExecutionState(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'executionState',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QDistinct> distinctByInferredCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'inferredCategory',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QDistinct> distinctByParsedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parsedAmount');
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QDistinct> distinctByRawPayload(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rawPayload', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QDistinct>
      distinctBySourcePackageOrSender({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourcePackageOrSender',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SmsAuditLog, SmsAuditLog, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension SmsAuditLogQueryProperty
    on QueryBuilder<SmsAuditLog, SmsAuditLog, QQueryProperty> {
  QueryBuilder<SmsAuditLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SmsAuditLog, String?, QQueryOperations>
      deduplicationHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deduplicationHash');
    });
  }

  QueryBuilder<SmsAuditLog, String?, QQueryOperations> detectedPayeeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'detectedPayee');
    });
  }

  QueryBuilder<SmsAuditLog, AuditExecutionState, QQueryOperations>
      executionStateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'executionState');
    });
  }

  QueryBuilder<SmsAuditLog, String?, QQueryOperations>
      inferredCategoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inferredCategory');
    });
  }

  QueryBuilder<SmsAuditLog, double?, QQueryOperations> parsedAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parsedAmount');
    });
  }

  QueryBuilder<SmsAuditLog, String, QQueryOperations> rawPayloadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rawPayload');
    });
  }

  QueryBuilder<SmsAuditLog, String?, QQueryOperations>
      sourcePackageOrSenderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourcePackageOrSender');
    });
  }

  QueryBuilder<SmsAuditLog, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}
