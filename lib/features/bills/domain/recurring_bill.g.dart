// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_bill.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRecurringBillCollection on Isar {
  IsarCollection<RecurringBill> get recurringBills => this.collection();
}

const RecurringBillSchema = CollectionSchema(
  name: r'RecurringBill',
  id: 4191036981950318912,
  properties: {
    r'amount': PropertySchema(id: 0, name: r'amount', type: IsarType.double),
    r'category': PropertySchema(
      id: 1,
      name: r'category',
      type: IsarType.byte,
      enumMap: _RecurringBillcategoryEnumValueMap,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'daysUntilDue': PropertySchema(
      id: 3,
      name: r'daysUntilDue',
      type: IsarType.long,
    ),
    r'frequency': PropertySchema(
      id: 4,
      name: r'frequency',
      type: IsarType.byte,
      enumMap: _RecurringBillfrequencyEnumValueMap,
    ),
    r'isActive': PropertySchema(id: 5, name: r'isActive', type: IsarType.bool),
    r'isDueSoon': PropertySchema(
      id: 6,
      name: r'isDueSoon',
      type: IsarType.bool,
    ),
    r'isOverdue': PropertySchema(
      id: 7,
      name: r'isOverdue',
      type: IsarType.bool,
    ),
    r'lastPaidDate': PropertySchema(
      id: 8,
      name: r'lastPaidDate',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(id: 9, name: r'name', type: IsarType.string),
    r'nextDueDate': PropertySchema(
      id: 10,
      name: r'nextDueDate',
      type: IsarType.dateTime,
    ),
    r'paymentMethod': PropertySchema(
      id: 11,
      name: r'paymentMethod',
      type: IsarType.byte,
      enumMap: _RecurringBillpaymentMethodEnumValueMap,
    ),
    r'reminderDaysBefore': PropertySchema(
      id: 12,
      name: r'reminderDaysBefore',
      type: IsarType.long,
    ),
  },
  estimateSize: _recurringBillEstimateSize,
  serialize: _recurringBillSerialize,
  deserialize: _recurringBillDeserialize,
  deserializeProp: _recurringBillDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _recurringBillGetId,
  getLinks: _recurringBillGetLinks,
  attach: _recurringBillAttach,
  version: '3.1.0+1',
);

int _recurringBillEstimateSize(
  RecurringBill object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _recurringBillSerialize(
  RecurringBill object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amount);
  writer.writeByte(offsets[1], object.category.index);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeLong(offsets[3], object.daysUntilDue);
  writer.writeByte(offsets[4], object.frequency.index);
  writer.writeBool(offsets[5], object.isActive);
  writer.writeBool(offsets[6], object.isDueSoon);
  writer.writeBool(offsets[7], object.isOverdue);
  writer.writeDateTime(offsets[8], object.lastPaidDate);
  writer.writeString(offsets[9], object.name);
  writer.writeDateTime(offsets[10], object.nextDueDate);
  writer.writeByte(offsets[11], object.paymentMethod.index);
  writer.writeLong(offsets[12], object.reminderDaysBefore);
}

RecurringBill _recurringBillDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RecurringBill();
  object.amount = reader.readDouble(offsets[0]);
  object.category =
      _RecurringBillcategoryValueEnumMap[reader.readByteOrNull(offsets[1])] ??
      ExpenseCategory.foodAndDrink;
  object.createdAt = reader.readDateTimeOrNull(offsets[2]);
  object.frequency =
      _RecurringBillfrequencyValueEnumMap[reader.readByteOrNull(offsets[4])] ??
      BillFrequency.monthly;
  object.id = id;
  object.isActive = reader.readBool(offsets[5]);
  object.lastPaidDate = reader.readDateTimeOrNull(offsets[8]);
  object.name = reader.readString(offsets[9]);
  object.nextDueDate = reader.readDateTime(offsets[10]);
  object.paymentMethod =
      _RecurringBillpaymentMethodValueEnumMap[reader.readByteOrNull(
        offsets[11],
      )] ??
      PaymentMethod.cash;
  object.reminderDaysBefore = reader.readLong(offsets[12]);
  return object;
}

P _recurringBillDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (_RecurringBillcategoryValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              ExpenseCategory.foodAndDrink)
          as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (_RecurringBillfrequencyValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              BillFrequency.monthly)
          as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (_RecurringBillpaymentMethodValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              PaymentMethod.cash)
          as P;
    case 12:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _RecurringBillcategoryEnumValueMap = {
  'foodAndDrink': 0,
  'transport': 1,
  'shopping': 2,
  'bills': 3,
  'entertainment': 4,
  'income': 5,
  'other': 6,
};
const _RecurringBillcategoryValueEnumMap = {
  0: ExpenseCategory.foodAndDrink,
  1: ExpenseCategory.transport,
  2: ExpenseCategory.shopping,
  3: ExpenseCategory.bills,
  4: ExpenseCategory.entertainment,
  5: ExpenseCategory.income,
  6: ExpenseCategory.other,
};
const _RecurringBillfrequencyEnumValueMap = {
  'monthly': 0,
  'quarterly': 1,
  'annual': 2,
};
const _RecurringBillfrequencyValueEnumMap = {
  0: BillFrequency.monthly,
  1: BillFrequency.quarterly,
  2: BillFrequency.annual,
};
const _RecurringBillpaymentMethodEnumValueMap = {'cash': 0, 'bank': 1};
const _RecurringBillpaymentMethodValueEnumMap = {
  0: PaymentMethod.cash,
  1: PaymentMethod.bank,
};

Id _recurringBillGetId(RecurringBill object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _recurringBillGetLinks(RecurringBill object) {
  return [];
}

void _recurringBillAttach(
  IsarCollection<dynamic> col,
  Id id,
  RecurringBill object,
) {
  object.id = id;
}

extension RecurringBillQueryWhereSort
    on QueryBuilder<RecurringBill, RecurringBill, QWhere> {
  QueryBuilder<RecurringBill, RecurringBill, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RecurringBillQueryWhere
    on QueryBuilder<RecurringBill, RecurringBill, QWhereClause> {
  QueryBuilder<RecurringBill, RecurringBill, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<RecurringBill, RecurringBill, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension RecurringBillQueryFilter
    on QueryBuilder<RecurringBill, RecurringBill, QFilterCondition> {
  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  amountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'amount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'amount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'amount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'amount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  categoryEqualTo(ExpenseCategory value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: value),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  categoryGreaterThan(ExpenseCategory value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'category',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  categoryLessThan(ExpenseCategory value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'category',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  categoryBetween(
    ExpenseCategory lower,
    ExpenseCategory upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'category',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'createdAt'),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'createdAt'),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  createdAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  createdAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  createdAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  daysUntilDueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'daysUntilDue', value: value),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  daysUntilDueGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'daysUntilDue',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  daysUntilDueLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'daysUntilDue',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  daysUntilDueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'daysUntilDue',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  frequencyEqualTo(BillFrequency value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'frequency', value: value),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  frequencyGreaterThan(BillFrequency value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'frequency',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  frequencyLessThan(BillFrequency value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'frequency',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  frequencyBetween(
    BillFrequency lower,
    BillFrequency upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'frequency',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isActive', value: value),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  isDueSoonEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isDueSoon', value: value),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  isOverdueEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isOverdue', value: value),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  lastPaidDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastPaidDate'),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  lastPaidDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastPaidDate'),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  lastPaidDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastPaidDate', value: value),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  lastPaidDateGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastPaidDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  lastPaidDateLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastPaidDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  lastPaidDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastPaidDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  nameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  nameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition> nameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  nextDueDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nextDueDate', value: value),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  nextDueDateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nextDueDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  nextDueDateLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nextDueDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  nextDueDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nextDueDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  paymentMethodEqualTo(PaymentMethod value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'paymentMethod', value: value),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  paymentMethodGreaterThan(PaymentMethod value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'paymentMethod',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  paymentMethodLessThan(PaymentMethod value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'paymentMethod',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  paymentMethodBetween(
    PaymentMethod lower,
    PaymentMethod upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'paymentMethod',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  reminderDaysBeforeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'reminderDaysBefore', value: value),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  reminderDaysBeforeGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'reminderDaysBefore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  reminderDaysBeforeLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'reminderDaysBefore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterFilterCondition>
  reminderDaysBeforeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'reminderDaysBefore',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension RecurringBillQueryObject
    on QueryBuilder<RecurringBill, RecurringBill, QFilterCondition> {}

extension RecurringBillQueryLinks
    on QueryBuilder<RecurringBill, RecurringBill, QFilterCondition> {}

extension RecurringBillQuerySortBy
    on QueryBuilder<RecurringBill, RecurringBill, QSortBy> {
  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  sortByDaysUntilDue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilDue', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  sortByDaysUntilDueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilDue', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> sortByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  sortByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> sortByIsDueSoon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDueSoon', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  sortByIsDueSoonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDueSoon', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> sortByIsOverdue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOverdue', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  sortByIsOverdueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOverdue', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  sortByLastPaidDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPaidDate', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  sortByLastPaidDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPaidDate', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> sortByNextDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextDueDate', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  sortByNextDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextDueDate', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  sortByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  sortByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  sortByReminderDaysBefore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderDaysBefore', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  sortByReminderDaysBeforeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderDaysBefore', Sort.desc);
    });
  }
}

extension RecurringBillQuerySortThenBy
    on QueryBuilder<RecurringBill, RecurringBill, QSortThenBy> {
  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  thenByDaysUntilDue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilDue', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  thenByDaysUntilDueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUntilDue', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> thenByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  thenByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> thenByIsDueSoon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDueSoon', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  thenByIsDueSoonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDueSoon', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> thenByIsOverdue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOverdue', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  thenByIsOverdueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOverdue', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  thenByLastPaidDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPaidDate', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  thenByLastPaidDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPaidDate', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy> thenByNextDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextDueDate', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  thenByNextDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextDueDate', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  thenByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  thenByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  thenByReminderDaysBefore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderDaysBefore', Sort.asc);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QAfterSortBy>
  thenByReminderDaysBeforeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderDaysBefore', Sort.desc);
    });
  }
}

extension RecurringBillQueryWhereDistinct
    on QueryBuilder<RecurringBill, RecurringBill, QDistinct> {
  QueryBuilder<RecurringBill, RecurringBill, QDistinct> distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QDistinct> distinctByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category');
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QDistinct>
  distinctByDaysUntilDue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'daysUntilDue');
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QDistinct> distinctByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'frequency');
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QDistinct> distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QDistinct> distinctByIsDueSoon() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDueSoon');
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QDistinct> distinctByIsOverdue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isOverdue');
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QDistinct>
  distinctByLastPaidDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastPaidDate');
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QDistinct>
  distinctByNextDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextDueDate');
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QDistinct>
  distinctByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentMethod');
    });
  }

  QueryBuilder<RecurringBill, RecurringBill, QDistinct>
  distinctByReminderDaysBefore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reminderDaysBefore');
    });
  }
}

extension RecurringBillQueryProperty
    on QueryBuilder<RecurringBill, RecurringBill, QQueryProperty> {
  QueryBuilder<RecurringBill, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RecurringBill, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<RecurringBill, ExpenseCategory, QQueryOperations>
  categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<RecurringBill, DateTime?, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<RecurringBill, int, QQueryOperations> daysUntilDueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'daysUntilDue');
    });
  }

  QueryBuilder<RecurringBill, BillFrequency, QQueryOperations>
  frequencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'frequency');
    });
  }

  QueryBuilder<RecurringBill, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<RecurringBill, bool, QQueryOperations> isDueSoonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDueSoon');
    });
  }

  QueryBuilder<RecurringBill, bool, QQueryOperations> isOverdueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isOverdue');
    });
  }

  QueryBuilder<RecurringBill, DateTime?, QQueryOperations>
  lastPaidDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastPaidDate');
    });
  }

  QueryBuilder<RecurringBill, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<RecurringBill, DateTime, QQueryOperations>
  nextDueDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextDueDate');
    });
  }

  QueryBuilder<RecurringBill, PaymentMethod, QQueryOperations>
  paymentMethodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentMethod');
    });
  }

  QueryBuilder<RecurringBill, int, QQueryOperations>
  reminderDaysBeforeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reminderDaysBefore');
    });
  }
}
