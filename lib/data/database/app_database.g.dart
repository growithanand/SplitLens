// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ParticipantsTable extends Participants
    with TableInfo<$ParticipantsTable, Participant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParticipantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'participants';
  @override
  VerificationContext validateIntegrity(
    Insertable<Participant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Participant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Participant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $ParticipantsTable createAlias(String alias) {
    return $ParticipantsTable(attachedDatabase, alias);
  }
}

class Participant extends DataClass implements Insertable<Participant> {
  final String id;
  final String name;
  const Participant({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  ParticipantsCompanion toCompanion(bool nullToAbsent) {
    return ParticipantsCompanion(id: Value(id), name: Value(name));
  }

  factory Participant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Participant(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Participant copyWith({String? id, String? name}) =>
      Participant(id: id ?? this.id, name: name ?? this.name);
  Participant copyWithCompanion(ParticipantsCompanion data) {
    return Participant(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Participant(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Participant && other.id == this.id && other.name == this.name);
}

class ParticipantsCompanion extends UpdateCompanion<Participant> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> rowid;
  const ParticipantsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParticipantsCompanion.insert({
    required String id,
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Participant> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParticipantsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return ParticipantsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParticipantsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expenseDateMeta = const VerificationMeta(
    'expenseDate',
  );
  @override
  late final GeneratedColumn<DateTime> expenseDate = GeneratedColumn<DateTime>(
    'expense_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalCentsMeta = const VerificationMeta(
    'totalCents',
  );
  @override
  late final GeneratedColumn<int> totalCents = GeneratedColumn<int>(
    'total_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidByParticipantIdMeta =
      const VerificationMeta('paidByParticipantId');
  @override
  late final GeneratedColumn<String> paidByParticipantId =
      GeneratedColumn<String>(
        'paid_by_participant_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES participants (id) ON DELETE RESTRICT',
        ),
      );
  static const VerificationMeta _receiptLocalPathMeta = const VerificationMeta(
    'receiptLocalPath',
  );
  @override
  late final GeneratedColumn<String> receiptLocalPath = GeneratedColumn<String>(
    'receipt_local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawOcrTextMeta = const VerificationMeta(
    'rawOcrText',
  );
  @override
  late final GeneratedColumn<String> rawOcrText = GeneratedColumn<String>(
    'raw_ocr_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    merchant,
    expenseDate,
    currency,
    totalCents,
    paidByParticipantId,
    receiptLocalPath,
    rawOcrText,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Expense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    } else if (isInserting) {
      context.missing(_merchantMeta);
    }
    if (data.containsKey('expense_date')) {
      context.handle(
        _expenseDateMeta,
        expenseDate.isAcceptableOrUnknown(
          data['expense_date']!,
          _expenseDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expenseDateMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('total_cents')) {
      context.handle(
        _totalCentsMeta,
        totalCents.isAcceptableOrUnknown(data['total_cents']!, _totalCentsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalCentsMeta);
    }
    if (data.containsKey('paid_by_participant_id')) {
      context.handle(
        _paidByParticipantIdMeta,
        paidByParticipantId.isAcceptableOrUnknown(
          data['paid_by_participant_id']!,
          _paidByParticipantIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paidByParticipantIdMeta);
    }
    if (data.containsKey('receipt_local_path')) {
      context.handle(
        _receiptLocalPathMeta,
        receiptLocalPath.isAcceptableOrUnknown(
          data['receipt_local_path']!,
          _receiptLocalPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receiptLocalPathMeta);
    }
    if (data.containsKey('raw_ocr_text')) {
      context.handle(
        _rawOcrTextMeta,
        rawOcrText.isAcceptableOrUnknown(
          data['raw_ocr_text']!,
          _rawOcrTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rawOcrTextMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      )!,
      expenseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expense_date'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      totalCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_cents'],
      )!,
      paidByParticipantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paid_by_participant_id'],
      )!,
      receiptLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_local_path'],
      )!,
      rawOcrText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_ocr_text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final String id;
  final String merchant;
  final DateTime expenseDate;
  final String currency;
  final int totalCents;
  final String paidByParticipantId;
  final String receiptLocalPath;
  final String rawOcrText;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Expense({
    required this.id,
    required this.merchant,
    required this.expenseDate,
    required this.currency,
    required this.totalCents,
    required this.paidByParticipantId,
    required this.receiptLocalPath,
    required this.rawOcrText,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['merchant'] = Variable<String>(merchant);
    map['expense_date'] = Variable<DateTime>(expenseDate);
    map['currency'] = Variable<String>(currency);
    map['total_cents'] = Variable<int>(totalCents);
    map['paid_by_participant_id'] = Variable<String>(paidByParticipantId);
    map['receipt_local_path'] = Variable<String>(receiptLocalPath);
    map['raw_ocr_text'] = Variable<String>(rawOcrText);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      merchant: Value(merchant),
      expenseDate: Value(expenseDate),
      currency: Value(currency),
      totalCents: Value(totalCents),
      paidByParticipantId: Value(paidByParticipantId),
      receiptLocalPath: Value(receiptLocalPath),
      rawOcrText: Value(rawOcrText),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Expense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<String>(json['id']),
      merchant: serializer.fromJson<String>(json['merchant']),
      expenseDate: serializer.fromJson<DateTime>(json['expenseDate']),
      currency: serializer.fromJson<String>(json['currency']),
      totalCents: serializer.fromJson<int>(json['totalCents']),
      paidByParticipantId: serializer.fromJson<String>(
        json['paidByParticipantId'],
      ),
      receiptLocalPath: serializer.fromJson<String>(json['receiptLocalPath']),
      rawOcrText: serializer.fromJson<String>(json['rawOcrText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'merchant': serializer.toJson<String>(merchant),
      'expenseDate': serializer.toJson<DateTime>(expenseDate),
      'currency': serializer.toJson<String>(currency),
      'totalCents': serializer.toJson<int>(totalCents),
      'paidByParticipantId': serializer.toJson<String>(paidByParticipantId),
      'receiptLocalPath': serializer.toJson<String>(receiptLocalPath),
      'rawOcrText': serializer.toJson<String>(rawOcrText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Expense copyWith({
    String? id,
    String? merchant,
    DateTime? expenseDate,
    String? currency,
    int? totalCents,
    String? paidByParticipantId,
    String? receiptLocalPath,
    String? rawOcrText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Expense(
    id: id ?? this.id,
    merchant: merchant ?? this.merchant,
    expenseDate: expenseDate ?? this.expenseDate,
    currency: currency ?? this.currency,
    totalCents: totalCents ?? this.totalCents,
    paidByParticipantId: paidByParticipantId ?? this.paidByParticipantId,
    receiptLocalPath: receiptLocalPath ?? this.receiptLocalPath,
    rawOcrText: rawOcrText ?? this.rawOcrText,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      expenseDate: data.expenseDate.present
          ? data.expenseDate.value
          : this.expenseDate,
      currency: data.currency.present ? data.currency.value : this.currency,
      totalCents: data.totalCents.present
          ? data.totalCents.value
          : this.totalCents,
      paidByParticipantId: data.paidByParticipantId.present
          ? data.paidByParticipantId.value
          : this.paidByParticipantId,
      receiptLocalPath: data.receiptLocalPath.present
          ? data.receiptLocalPath.value
          : this.receiptLocalPath,
      rawOcrText: data.rawOcrText.present
          ? data.rawOcrText.value
          : this.rawOcrText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('merchant: $merchant, ')
          ..write('expenseDate: $expenseDate, ')
          ..write('currency: $currency, ')
          ..write('totalCents: $totalCents, ')
          ..write('paidByParticipantId: $paidByParticipantId, ')
          ..write('receiptLocalPath: $receiptLocalPath, ')
          ..write('rawOcrText: $rawOcrText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    merchant,
    expenseDate,
    currency,
    totalCents,
    paidByParticipantId,
    receiptLocalPath,
    rawOcrText,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.merchant == this.merchant &&
          other.expenseDate == this.expenseDate &&
          other.currency == this.currency &&
          other.totalCents == this.totalCents &&
          other.paidByParticipantId == this.paidByParticipantId &&
          other.receiptLocalPath == this.receiptLocalPath &&
          other.rawOcrText == this.rawOcrText &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<String> id;
  final Value<String> merchant;
  final Value<DateTime> expenseDate;
  final Value<String> currency;
  final Value<int> totalCents;
  final Value<String> paidByParticipantId;
  final Value<String> receiptLocalPath;
  final Value<String> rawOcrText;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.merchant = const Value.absent(),
    this.expenseDate = const Value.absent(),
    this.currency = const Value.absent(),
    this.totalCents = const Value.absent(),
    this.paidByParticipantId = const Value.absent(),
    this.receiptLocalPath = const Value.absent(),
    this.rawOcrText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    required String merchant,
    required DateTime expenseDate,
    required String currency,
    required int totalCents,
    required String paidByParticipantId,
    required String receiptLocalPath,
    required String rawOcrText,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       merchant = Value(merchant),
       expenseDate = Value(expenseDate),
       currency = Value(currency),
       totalCents = Value(totalCents),
       paidByParticipantId = Value(paidByParticipantId),
       receiptLocalPath = Value(receiptLocalPath),
       rawOcrText = Value(rawOcrText),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Expense> custom({
    Expression<String>? id,
    Expression<String>? merchant,
    Expression<DateTime>? expenseDate,
    Expression<String>? currency,
    Expression<int>? totalCents,
    Expression<String>? paidByParticipantId,
    Expression<String>? receiptLocalPath,
    Expression<String>? rawOcrText,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (merchant != null) 'merchant': merchant,
      if (expenseDate != null) 'expense_date': expenseDate,
      if (currency != null) 'currency': currency,
      if (totalCents != null) 'total_cents': totalCents,
      if (paidByParticipantId != null)
        'paid_by_participant_id': paidByParticipantId,
      if (receiptLocalPath != null) 'receipt_local_path': receiptLocalPath,
      if (rawOcrText != null) 'raw_ocr_text': rawOcrText,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? merchant,
    Value<DateTime>? expenseDate,
    Value<String>? currency,
    Value<int>? totalCents,
    Value<String>? paidByParticipantId,
    Value<String>? receiptLocalPath,
    Value<String>? rawOcrText,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      expenseDate: expenseDate ?? this.expenseDate,
      currency: currency ?? this.currency,
      totalCents: totalCents ?? this.totalCents,
      paidByParticipantId: paidByParticipantId ?? this.paidByParticipantId,
      receiptLocalPath: receiptLocalPath ?? this.receiptLocalPath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (expenseDate.present) {
      map['expense_date'] = Variable<DateTime>(expenseDate.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (totalCents.present) {
      map['total_cents'] = Variable<int>(totalCents.value);
    }
    if (paidByParticipantId.present) {
      map['paid_by_participant_id'] = Variable<String>(
        paidByParticipantId.value,
      );
    }
    if (receiptLocalPath.present) {
      map['receipt_local_path'] = Variable<String>(receiptLocalPath.value);
    }
    if (rawOcrText.present) {
      map['raw_ocr_text'] = Variable<String>(rawOcrText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('merchant: $merchant, ')
          ..write('expenseDate: $expenseDate, ')
          ..write('currency: $currency, ')
          ..write('totalCents: $totalCents, ')
          ..write('paidByParticipantId: $paidByParticipantId, ')
          ..write('receiptLocalPath: $receiptLocalPath, ')
          ..write('rawOcrText: $rawOcrText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpenseAllocationsTable extends ExpenseAllocations
    with TableInfo<$ExpenseAllocationsTable, ExpenseAllocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpenseAllocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES expenses (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _participantIdMeta = const VerificationMeta(
    'participantId',
  );
  @override
  late final GeneratedColumn<String> participantId = GeneratedColumn<String>(
    'participant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES participants (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    expenseId,
    participantId,
    amountCents,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_allocations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseAllocation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('participant_id')) {
      context.handle(
        _participantIdMeta,
        participantId.isAcceptableOrUnknown(
          data['participant_id']!,
          _participantIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantIdMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {expenseId, participantId},
  ];
  @override
  ExpenseAllocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseAllocation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      )!,
      participantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_id'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
    );
  }

  @override
  $ExpenseAllocationsTable createAlias(String alias) {
    return $ExpenseAllocationsTable(attachedDatabase, alias);
  }
}

class ExpenseAllocation extends DataClass
    implements Insertable<ExpenseAllocation> {
  final String id;
  final String expenseId;
  final String participantId;
  final int amountCents;
  const ExpenseAllocation({
    required this.id,
    required this.expenseId,
    required this.participantId,
    required this.amountCents,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['expense_id'] = Variable<String>(expenseId);
    map['participant_id'] = Variable<String>(participantId);
    map['amount_cents'] = Variable<int>(amountCents);
    return map;
  }

  ExpenseAllocationsCompanion toCompanion(bool nullToAbsent) {
    return ExpenseAllocationsCompanion(
      id: Value(id),
      expenseId: Value(expenseId),
      participantId: Value(participantId),
      amountCents: Value(amountCents),
    );
  }

  factory ExpenseAllocation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseAllocation(
      id: serializer.fromJson<String>(json['id']),
      expenseId: serializer.fromJson<String>(json['expenseId']),
      participantId: serializer.fromJson<String>(json['participantId']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'expenseId': serializer.toJson<String>(expenseId),
      'participantId': serializer.toJson<String>(participantId),
      'amountCents': serializer.toJson<int>(amountCents),
    };
  }

  ExpenseAllocation copyWith({
    String? id,
    String? expenseId,
    String? participantId,
    int? amountCents,
  }) => ExpenseAllocation(
    id: id ?? this.id,
    expenseId: expenseId ?? this.expenseId,
    participantId: participantId ?? this.participantId,
    amountCents: amountCents ?? this.amountCents,
  );
  ExpenseAllocation copyWithCompanion(ExpenseAllocationsCompanion data) {
    return ExpenseAllocation(
      id: data.id.present ? data.id.value : this.id,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      participantId: data.participantId.present
          ? data.participantId.value
          : this.participantId,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseAllocation(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('participantId: $participantId, ')
          ..write('amountCents: $amountCents')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, expenseId, participantId, amountCents);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseAllocation &&
          other.id == this.id &&
          other.expenseId == this.expenseId &&
          other.participantId == this.participantId &&
          other.amountCents == this.amountCents);
}

class ExpenseAllocationsCompanion extends UpdateCompanion<ExpenseAllocation> {
  final Value<String> id;
  final Value<String> expenseId;
  final Value<String> participantId;
  final Value<int> amountCents;
  final Value<int> rowid;
  const ExpenseAllocationsCompanion({
    this.id = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.participantId = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpenseAllocationsCompanion.insert({
    required String id,
    required String expenseId,
    required String participantId,
    required int amountCents,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       expenseId = Value(expenseId),
       participantId = Value(participantId),
       amountCents = Value(amountCents);
  static Insertable<ExpenseAllocation> custom({
    Expression<String>? id,
    Expression<String>? expenseId,
    Expression<String>? participantId,
    Expression<int>? amountCents,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (expenseId != null) 'expense_id': expenseId,
      if (participantId != null) 'participant_id': participantId,
      if (amountCents != null) 'amount_cents': amountCents,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpenseAllocationsCompanion copyWith({
    Value<String>? id,
    Value<String>? expenseId,
    Value<String>? participantId,
    Value<int>? amountCents,
    Value<int>? rowid,
  }) {
    return ExpenseAllocationsCompanion(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      participantId: participantId ?? this.participantId,
      amountCents: amountCents ?? this.amountCents,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (participantId.present) {
      map['participant_id'] = Variable<String>(participantId.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseAllocationsCompanion(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('participantId: $participantId, ')
          ..write('amountCents: $amountCents, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ParticipantsTable participants = $ParticipantsTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $ExpenseAllocationsTable expenseAllocations =
      $ExpenseAllocationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    participants,
    expenses,
    expenseAllocations,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'expenses',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('expense_allocations', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ParticipantsTableCreateCompanionBuilder =
    ParticipantsCompanion Function({
      required String id,
      required String name,
      Value<int> rowid,
    });
typedef $$ParticipantsTableUpdateCompanionBuilder =
    ParticipantsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> rowid,
    });

final class $$ParticipantsTableReferences
    extends BaseReferences<_$AppDatabase, $ParticipantsTable, Participant> {
  $$ParticipantsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: 'participants__id__expenses__paid_by_participant_id',
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager($_db, $_db.expenses).filter(
      (f) => f.paidByParticipantId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpenseAllocationsTable, List<ExpenseAllocation>>
  _expenseAllocationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.expenseAllocations,
        aliasName: 'participants__id__expense_allocations__participant_id',
      );

  $$ExpenseAllocationsTableProcessedTableManager get expenseAllocationsRefs {
    final manager = $$ExpenseAllocationsTableTableManager(
      $_db,
      $_db.expenseAllocations,
    ).filter((f) => f.participantId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _expenseAllocationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ParticipantsTableFilterComposer
    extends Composer<_$AppDatabase, $ParticipantsTable> {
  $$ParticipantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.paidByParticipantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expenseAllocationsRefs(
    Expression<bool> Function($$ExpenseAllocationsTableFilterComposer f) f,
  ) {
    final $$ExpenseAllocationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseAllocations,
      getReferencedColumn: (t) => t.participantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseAllocationsTableFilterComposer(
            $db: $db,
            $table: $db.expenseAllocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ParticipantsTableOrderingComposer
    extends Composer<_$AppDatabase, $ParticipantsTable> {
  $$ParticipantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ParticipantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParticipantsTable> {
  $$ParticipantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.paidByParticipantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expenseAllocationsRefs<T extends Object>(
    Expression<T> Function($$ExpenseAllocationsTableAnnotationComposer a) f,
  ) {
    final $$ExpenseAllocationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.expenseAllocations,
          getReferencedColumn: (t) => t.participantId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExpenseAllocationsTableAnnotationComposer(
                $db: $db,
                $table: $db.expenseAllocations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ParticipantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ParticipantsTable,
          Participant,
          $$ParticipantsTableFilterComposer,
          $$ParticipantsTableOrderingComposer,
          $$ParticipantsTableAnnotationComposer,
          $$ParticipantsTableCreateCompanionBuilder,
          $$ParticipantsTableUpdateCompanionBuilder,
          (Participant, $$ParticipantsTableReferences),
          Participant,
          PrefetchHooks Function({
            bool expensesRefs,
            bool expenseAllocationsRefs,
          })
        > {
  $$ParticipantsTableTableManager(_$AppDatabase db, $ParticipantsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParticipantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParticipantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParticipantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => ParticipantsCompanion(id: id, name: name, rowid: rowid),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<int> rowid = const Value.absent(),
          }) => ParticipantsCompanion.insert(id: id, name: name, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ParticipantsTable, Participant>(table),
                  $$ParticipantsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({expensesRefs = false, expenseAllocationsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (expensesRefs) db.expenses,
                    if (expenseAllocationsRefs) db.expenseAllocations,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (expensesRefs)
                        await $_getPrefetchedData<
                          Participant,
                          $ParticipantsTable,
                          Expense
                        >(
                          currentTable: table,
                          referencedTable: $$ParticipantsTableReferences
                              ._expensesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ParticipantsTableReferences(
                                db,
                                table,
                                p0,
                              ).expensesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.paidByParticipantId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (expenseAllocationsRefs)
                        await $_getPrefetchedData<
                          Participant,
                          $ParticipantsTable,
                          ExpenseAllocation
                        >(
                          currentTable: table,
                          referencedTable: $$ParticipantsTableReferences
                              ._expenseAllocationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ParticipantsTableReferences(
                                db,
                                table,
                                p0,
                              ).expenseAllocationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.participantId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ParticipantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ParticipantsTable,
      Participant,
      $$ParticipantsTableFilterComposer,
      $$ParticipantsTableOrderingComposer,
      $$ParticipantsTableAnnotationComposer,
      $$ParticipantsTableCreateCompanionBuilder,
      $$ParticipantsTableUpdateCompanionBuilder,
      (Participant, $$ParticipantsTableReferences),
      Participant,
      PrefetchHooks Function({bool expensesRefs, bool expenseAllocationsRefs})
    >;
typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  required String id,
  required String merchant,
  required DateTime expenseDate,
  required String currency,
  required int totalCents,
  required String paidByParticipantId,
  required String receiptLocalPath,
  required String rawOcrText,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<String> id,
  Value<String> merchant,
  Value<DateTime> expenseDate,
  Value<String> currency,
  Value<int> totalCents,
  Value<String> paidByParticipantId,
  Value<String> receiptLocalPath,
  Value<String> rawOcrText,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ExpensesTableReferences
    extends BaseReferences<_$AppDatabase, $ExpensesTable, Expense> {
  $$ExpensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ParticipantsTable _paidByParticipantIdTable(_$AppDatabase db) => db
      .participants
      .createAlias('expenses__paid_by_participant_id__participants__id');

  $$ParticipantsTableProcessedTableManager get paidByParticipantId {
    final $_column = $_itemColumn<String>('paid_by_participant_id')!;

    final manager = $$ParticipantsTableTableManager(
      $_db,
      $_db.participants,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_paidByParticipantIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ExpenseAllocationsTable, List<ExpenseAllocation>>
  _expenseAllocationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.expenseAllocations,
        aliasName: 'expenses__id__expense_allocations__expense_id',
      );

  $$ExpenseAllocationsTableProcessedTableManager get expenseAllocationsRefs {
    final manager = $$ExpenseAllocationsTableTableManager(
      $_db,
      $_db.expenseAllocations,
    ).filter((f) => f.expenseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _expenseAllocationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expenseDate => $composableBuilder(
    column: $table.expenseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptLocalPath => $composableBuilder(
    column: $table.receiptLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawOcrText => $composableBuilder(
    column: $table.rawOcrText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ParticipantsTableFilterComposer get paidByParticipantId {
    final $$ParticipantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.paidByParticipantId,
      referencedTable: $db.participants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ParticipantsTableFilterComposer(
            $db: $db,
            $table: $db.participants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> expenseAllocationsRefs(
    Expression<bool> Function($$ExpenseAllocationsTableFilterComposer f) f,
  ) {
    final $$ExpenseAllocationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseAllocations,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseAllocationsTableFilterComposer(
            $db: $db,
            $table: $db.expenseAllocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expenseDate => $composableBuilder(
    column: $table.expenseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptLocalPath => $composableBuilder(
    column: $table.receiptLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawOcrText => $composableBuilder(
    column: $table.rawOcrText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ParticipantsTableOrderingComposer get paidByParticipantId {
    final $$ParticipantsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.paidByParticipantId,
      referencedTable: $db.participants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ParticipantsTableOrderingComposer(
            $db: $db,
            $table: $db.participants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<DateTime> get expenseDate => $composableBuilder(
    column: $table.expenseDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptLocalPath => $composableBuilder(
    column: $table.receiptLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawOcrText => $composableBuilder(
    column: $table.rawOcrText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ParticipantsTableAnnotationComposer get paidByParticipantId {
    final $$ParticipantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.paidByParticipantId,
      referencedTable: $db.participants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ParticipantsTableAnnotationComposer(
            $db: $db,
            $table: $db.participants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> expenseAllocationsRefs<T extends Object>(
    Expression<T> Function($$ExpenseAllocationsTableAnnotationComposer a) f,
  ) {
    final $$ExpenseAllocationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.expenseAllocations,
          getReferencedColumn: (t) => t.expenseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExpenseAllocationsTableAnnotationComposer(
                $db: $db,
                $table: $db.expenseAllocations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          Expense,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (Expense, $$ExpensesTableReferences),
          Expense,
          PrefetchHooks Function({
            bool paidByParticipantId,
            bool expenseAllocationsRefs,
          })
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> merchant = const Value.absent(),
                Value<DateTime> expenseDate = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int> totalCents = const Value.absent(),
                Value<String> paidByParticipantId = const Value.absent(),
                Value<String> receiptLocalPath = const Value.absent(),
                Value<String> rawOcrText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                merchant: merchant,
                expenseDate: expenseDate,
                currency: currency,
                totalCents: totalCents,
                paidByParticipantId: paidByParticipantId,
                receiptLocalPath: receiptLocalPath,
                rawOcrText: rawOcrText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String merchant,
                required DateTime expenseDate,
                required String currency,
                required int totalCents,
                required String paidByParticipantId,
                required String receiptLocalPath,
                required String rawOcrText,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                merchant: merchant,
                expenseDate: expenseDate,
                currency: currency,
                totalCents: totalCents,
                paidByParticipantId: paidByParticipantId,
                receiptLocalPath: receiptLocalPath,
                rawOcrText: rawOcrText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExpensesTable, Expense>(table),
                  $$ExpensesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({paidByParticipantId = false, expenseAllocationsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (expenseAllocationsRefs) db.expenseAllocations,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (paidByParticipantId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.paidByParticipantId,
                            referencedTable: $$ExpensesTableReferences
                                ._paidByParticipantIdTable(db),
                            referencedColumn: $$ExpensesTableReferences
                                ._paidByParticipantIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (expenseAllocationsRefs)
                        await $_getPrefetchedData<
                          Expense,
                          $ExpensesTable,
                          ExpenseAllocation
                        >(
                          currentTable: table,
                          referencedTable: $$ExpensesTableReferences
                              ._expenseAllocationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExpensesTableReferences(
                                db,
                                table,
                                p0,
                              ).expenseAllocationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.expenseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      Expense,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (Expense, $$ExpensesTableReferences),
      Expense,
      PrefetchHooks Function({
        bool paidByParticipantId,
        bool expenseAllocationsRefs,
      })
    >;
typedef $$ExpenseAllocationsTableCreateCompanionBuilder =
    ExpenseAllocationsCompanion Function({
      required String id,
      required String expenseId,
      required String participantId,
      required int amountCents,
      Value<int> rowid,
    });
typedef $$ExpenseAllocationsTableUpdateCompanionBuilder =
    ExpenseAllocationsCompanion Function({
      Value<String> id,
      Value<String> expenseId,
      Value<String> participantId,
      Value<int> amountCents,
      Value<int> rowid,
    });

final class $$ExpenseAllocationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ExpenseAllocationsTable,
          ExpenseAllocation
        > {
  $$ExpenseAllocationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExpensesTable _expenseIdTable(_$AppDatabase db) =>
      db.expenses.createAlias('expense_allocations__expense_id__expenses__id');

  $$ExpensesTableProcessedTableManager get expenseId {
    final $_column = $_itemColumn<String>('expense_id')!;

    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expenseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ParticipantsTable _participantIdTable(_$AppDatabase db) => db
      .participants
      .createAlias('expense_allocations__participant_id__participants__id');

  $$ParticipantsTableProcessedTableManager get participantId {
    final $_column = $_itemColumn<String>('participant_id')!;

    final manager = $$ParticipantsTableTableManager(
      $_db,
      $_db.participants,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_participantIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExpenseAllocationsTableFilterComposer
    extends Composer<_$AppDatabase, $ExpenseAllocationsTable> {
  $$ExpenseAllocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  $$ExpensesTableFilterComposer get expenseId {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ParticipantsTableFilterComposer get participantId {
    final $$ParticipantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.participantId,
      referencedTable: $db.participants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ParticipantsTableFilterComposer(
            $db: $db,
            $table: $db.participants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpenseAllocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpenseAllocationsTable> {
  $$ExpenseAllocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExpensesTableOrderingComposer get expenseId {
    final $$ExpensesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableOrderingComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ParticipantsTableOrderingComposer get participantId {
    final $$ParticipantsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.participantId,
      referencedTable: $db.participants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ParticipantsTableOrderingComposer(
            $db: $db,
            $table: $db.participants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpenseAllocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpenseAllocationsTable> {
  $$ExpenseAllocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  $$ExpensesTableAnnotationComposer get expenseId {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ParticipantsTableAnnotationComposer get participantId {
    final $$ParticipantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.participantId,
      referencedTable: $db.participants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ParticipantsTableAnnotationComposer(
            $db: $db,
            $table: $db.participants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpenseAllocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpenseAllocationsTable,
          ExpenseAllocation,
          $$ExpenseAllocationsTableFilterComposer,
          $$ExpenseAllocationsTableOrderingComposer,
          $$ExpenseAllocationsTableAnnotationComposer,
          $$ExpenseAllocationsTableCreateCompanionBuilder,
          $$ExpenseAllocationsTableUpdateCompanionBuilder,
          (ExpenseAllocation, $$ExpenseAllocationsTableReferences),
          ExpenseAllocation,
          PrefetchHooks Function({bool expenseId, bool participantId})
        > {
  $$ExpenseAllocationsTableTableManager(
    _$AppDatabase db,
    $ExpenseAllocationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpenseAllocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpenseAllocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpenseAllocationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> expenseId = const Value.absent(),
                Value<String> participantId = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpenseAllocationsCompanion(
                id: id,
                expenseId: expenseId,
                participantId: participantId,
                amountCents: amountCents,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String expenseId,
                required String participantId,
                required int amountCents,
                Value<int> rowid = const Value.absent(),
              }) => ExpenseAllocationsCompanion.insert(
                id: id,
                expenseId: expenseId,
                participantId: participantId,
                amountCents: amountCents,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExpenseAllocationsTable, ExpenseAllocation>(
                    table,
                  ),
                  $$ExpenseAllocationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({expenseId = false, participantId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (expenseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.expenseId,
                        referencedTable: $$ExpenseAllocationsTableReferences
                            ._expenseIdTable(db),
                        referencedColumn: $$ExpenseAllocationsTableReferences
                            ._expenseIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (participantId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.participantId,
                        referencedTable: $$ExpenseAllocationsTableReferences
                            ._participantIdTable(db),
                        referencedColumn: $$ExpenseAllocationsTableReferences
                            ._participantIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExpenseAllocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpenseAllocationsTable,
      ExpenseAllocation,
      $$ExpenseAllocationsTableFilterComposer,
      $$ExpenseAllocationsTableOrderingComposer,
      $$ExpenseAllocationsTableAnnotationComposer,
      $$ExpenseAllocationsTableCreateCompanionBuilder,
      $$ExpenseAllocationsTableUpdateCompanionBuilder,
      (ExpenseAllocation, $$ExpenseAllocationsTableReferences),
      ExpenseAllocation,
      PrefetchHooks Function({bool expenseId, bool participantId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ParticipantsTableTableManager get participants =>
      $$ParticipantsTableTableManager(_db, _db.participants);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$ExpenseAllocationsTableTableManager get expenseAllocations =>
      $$ExpenseAllocationsTableTableManager(_db, _db.expenseAllocations);
}
