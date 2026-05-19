// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserSettingsCollection on Isar {
  IsarCollection<UserSettings> get userSettings => this.collection();
}

const UserSettingsSchema = CollectionSchema(
  name: r'UserSettings',
  id: 4939698790990493221,
  properties: {
    r'initialBankBalance': PropertySchema(
      id: 0,
      name: r'initialBankBalance',
      type: IsarType.double,
    ),
    r'initialCashBalance': PropertySchema(
      id: 1,
      name: r'initialCashBalance',
      type: IsarType.double,
    ),
    r'isSetupCompleted': PropertySchema(
      id: 2,
      name: r'isSetupCompleted',
      type: IsarType.bool,
    ),
    r'trackedNotificationApps': PropertySchema(
      id: 3,
      name: r'trackedNotificationApps',
      type: IsarType.stringList,
    ),
    r'trackedNotificationPackages': PropertySchema(
      id: 4,
      name: r'trackedNotificationPackages',
      type: IsarType.stringList,
    ),
    r'updatedAt': PropertySchema(
      id: 5,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _userSettingsEstimateSize,
  serialize: _userSettingsSerialize,
  deserialize: _userSettingsDeserialize,
  deserializeProp: _userSettingsDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _userSettingsGetId,
  getLinks: _userSettingsGetLinks,
  attach: _userSettingsAttach,
  version: '3.1.0+1',
);

int _userSettingsEstimateSize(
  UserSettings object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.trackedNotificationApps.length * 3;
  {
    for (var i = 0; i < object.trackedNotificationApps.length; i++) {
      final value = object.trackedNotificationApps[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.trackedNotificationPackages.length * 3;
  {
    for (var i = 0; i < object.trackedNotificationPackages.length; i++) {
      final value = object.trackedNotificationPackages[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _userSettingsSerialize(
  UserSettings object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.initialBankBalance);
  writer.writeDouble(offsets[1], object.initialCashBalance);
  writer.writeBool(offsets[2], object.isSetupCompleted);
  writer.writeStringList(offsets[3], object.trackedNotificationApps);
  writer.writeStringList(offsets[4], object.trackedNotificationPackages);
  writer.writeDateTime(offsets[5], object.updatedAt);
}

UserSettings _userSettingsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserSettings();
  object.id = id;
  object.initialBankBalance = reader.readDouble(offsets[0]);
  object.initialCashBalance = reader.readDouble(offsets[1]);
  object.isSetupCompleted = reader.readBool(offsets[2]);
  object.trackedNotificationApps = reader.readStringList(offsets[3]) ?? [];
  object.trackedNotificationPackages = reader.readStringList(offsets[4]) ?? [];
  object.updatedAt = reader.readDateTimeOrNull(offsets[5]);
  return object;
}

P _userSettingsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readStringList(offset) ?? []) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _userSettingsGetId(UserSettings object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userSettingsGetLinks(UserSettings object) {
  return [];
}

void _userSettingsAttach(
    IsarCollection<dynamic> col, Id id, UserSettings object) {
  object.id = id;
}

extension UserSettingsQueryWhereSort
    on QueryBuilder<UserSettings, UserSettings, QWhere> {
  QueryBuilder<UserSettings, UserSettings, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserSettingsQueryWhere
    on QueryBuilder<UserSettings, UserSettings, QWhereClause> {
  QueryBuilder<UserSettings, UserSettings, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<UserSettings, UserSettings, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterWhereClause> idBetween(
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
}

extension UserSettingsQueryFilter
    on QueryBuilder<UserSettings, UserSettings, QFilterCondition> {
  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition> idBetween(
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

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      initialBankBalanceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'initialBankBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      initialBankBalanceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'initialBankBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      initialBankBalanceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'initialBankBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      initialBankBalanceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'initialBankBalance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      initialCashBalanceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'initialCashBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      initialCashBalanceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'initialCashBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      initialCashBalanceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'initialCashBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      initialCashBalanceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'initialCashBalance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      isSetupCompletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSetupCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationAppsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trackedNotificationApps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationAppsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'trackedNotificationApps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationAppsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'trackedNotificationApps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationAppsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'trackedNotificationApps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationAppsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'trackedNotificationApps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationAppsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'trackedNotificationApps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationAppsElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'trackedNotificationApps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationAppsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'trackedNotificationApps',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationAppsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trackedNotificationApps',
        value: '',
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationAppsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'trackedNotificationApps',
        value: '',
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationAppsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackedNotificationApps',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationAppsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackedNotificationApps',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationAppsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackedNotificationApps',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationAppsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackedNotificationApps',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationAppsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackedNotificationApps',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationAppsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackedNotificationApps',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationPackagesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trackedNotificationPackages',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationPackagesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'trackedNotificationPackages',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationPackagesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'trackedNotificationPackages',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationPackagesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'trackedNotificationPackages',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationPackagesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'trackedNotificationPackages',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationPackagesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'trackedNotificationPackages',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationPackagesElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'trackedNotificationPackages',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationPackagesElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'trackedNotificationPackages',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationPackagesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trackedNotificationPackages',
        value: '',
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationPackagesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'trackedNotificationPackages',
        value: '',
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationPackagesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackedNotificationPackages',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationPackagesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackedNotificationPackages',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationPackagesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackedNotificationPackages',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationPackagesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackedNotificationPackages',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationPackagesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackedNotificationPackages',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      trackedNotificationPackagesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackedNotificationPackages',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterFilterCondition>
      updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension UserSettingsQueryObject
    on QueryBuilder<UserSettings, UserSettings, QFilterCondition> {}

extension UserSettingsQueryLinks
    on QueryBuilder<UserSettings, UserSettings, QFilterCondition> {}

extension UserSettingsQuerySortBy
    on QueryBuilder<UserSettings, UserSettings, QSortBy> {
  QueryBuilder<UserSettings, UserSettings, QAfterSortBy>
      sortByInitialBankBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialBankBalance', Sort.asc);
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterSortBy>
      sortByInitialBankBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialBankBalance', Sort.desc);
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterSortBy>
      sortByInitialCashBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialCashBalance', Sort.asc);
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterSortBy>
      sortByInitialCashBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialCashBalance', Sort.desc);
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterSortBy>
      sortByIsSetupCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSetupCompleted', Sort.asc);
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterSortBy>
      sortByIsSetupCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSetupCompleted', Sort.desc);
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension UserSettingsQuerySortThenBy
    on QueryBuilder<UserSettings, UserSettings, QSortThenBy> {
  QueryBuilder<UserSettings, UserSettings, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterSortBy>
      thenByInitialBankBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialBankBalance', Sort.asc);
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterSortBy>
      thenByInitialBankBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialBankBalance', Sort.desc);
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterSortBy>
      thenByInitialCashBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialCashBalance', Sort.asc);
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterSortBy>
      thenByInitialCashBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialCashBalance', Sort.desc);
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterSortBy>
      thenByIsSetupCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSetupCompleted', Sort.asc);
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterSortBy>
      thenByIsSetupCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSetupCompleted', Sort.desc);
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<UserSettings, UserSettings, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension UserSettingsQueryWhereDistinct
    on QueryBuilder<UserSettings, UserSettings, QDistinct> {
  QueryBuilder<UserSettings, UserSettings, QDistinct>
      distinctByInitialBankBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'initialBankBalance');
    });
  }

  QueryBuilder<UserSettings, UserSettings, QDistinct>
      distinctByInitialCashBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'initialCashBalance');
    });
  }

  QueryBuilder<UserSettings, UserSettings, QDistinct>
      distinctByIsSetupCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSetupCompleted');
    });
  }

  QueryBuilder<UserSettings, UserSettings, QDistinct>
      distinctByTrackedNotificationApps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trackedNotificationApps');
    });
  }

  QueryBuilder<UserSettings, UserSettings, QDistinct>
      distinctByTrackedNotificationPackages() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trackedNotificationPackages');
    });
  }

  QueryBuilder<UserSettings, UserSettings, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension UserSettingsQueryProperty
    on QueryBuilder<UserSettings, UserSettings, QQueryProperty> {
  QueryBuilder<UserSettings, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserSettings, double, QQueryOperations>
      initialBankBalanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'initialBankBalance');
    });
  }

  QueryBuilder<UserSettings, double, QQueryOperations>
      initialCashBalanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'initialCashBalance');
    });
  }

  QueryBuilder<UserSettings, bool, QQueryOperations>
      isSetupCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSetupCompleted');
    });
  }

  QueryBuilder<UserSettings, List<String>, QQueryOperations>
      trackedNotificationAppsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trackedNotificationApps');
    });
  }

  QueryBuilder<UserSettings, List<String>, QQueryOperations>
      trackedNotificationPackagesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trackedNotificationPackages');
    });
  }

  QueryBuilder<UserSettings, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
