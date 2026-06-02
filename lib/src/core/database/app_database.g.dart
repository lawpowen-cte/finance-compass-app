// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountTypeMeta =
      const VerificationMeta('accountType');
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
      'account_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reportGroupMeta =
      const VerificationMeta('reportGroup');
  @override
  late final GeneratedColumn<String> reportGroup = GeneratedColumn<String>(
      'report_group', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _initialBalanceMeta =
      const VerificationMeta('initialBalance');
  @override
  late final GeneratedColumn<double> initialBalance = GeneratedColumn<double>(
      'initial_balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentBalanceMeta =
      const VerificationMeta('currentBalance');
  @override
  late final GeneratedColumn<double> currentBalance = GeneratedColumn<double>(
      'current_balance', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _institutionMeta =
      const VerificationMeta('institution');
  @override
  late final GeneratedColumn<String> institution = GeneratedColumn<String>(
      'institution', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        accountType,
        reportGroup,
        currency,
        initialBalance,
        currentBalance,
        institution,
        note,
        isActive,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('account_type')) {
      context.handle(
          _accountTypeMeta,
          accountType.isAcceptableOrUnknown(
              data['account_type']!, _accountTypeMeta));
    } else if (isInserting) {
      context.missing(_accountTypeMeta);
    }
    if (data.containsKey('report_group')) {
      context.handle(
          _reportGroupMeta,
          reportGroup.isAcceptableOrUnknown(
              data['report_group']!, _reportGroupMeta));
    } else if (isInserting) {
      context.missing(_reportGroupMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('initial_balance')) {
      context.handle(
          _initialBalanceMeta,
          initialBalance.isAcceptableOrUnknown(
              data['initial_balance']!, _initialBalanceMeta));
    }
    if (data.containsKey('current_balance')) {
      context.handle(
          _currentBalanceMeta,
          currentBalance.isAcceptableOrUnknown(
              data['current_balance']!, _currentBalanceMeta));
    } else if (isInserting) {
      context.missing(_currentBalanceMeta);
    }
    if (data.containsKey('institution')) {
      context.handle(
          _institutionMeta,
          institution.isAcceptableOrUnknown(
              data['institution']!, _institutionMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      accountType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_type'])!,
      reportGroup: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}report_group'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      initialBalance: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}initial_balance'])!,
      currentBalance: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}current_balance'])!,
      institution: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}institution']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final String id;
  final String name;
  final String accountType;
  final String reportGroup;
  final String currency;
  final double initialBalance;
  final double currentBalance;
  final String? institution;
  final String? note;
  final bool isActive;
  final DateTime createdAt;
  const Account(
      {required this.id,
      required this.name,
      required this.accountType,
      required this.reportGroup,
      required this.currency,
      required this.initialBalance,
      required this.currentBalance,
      this.institution,
      this.note,
      required this.isActive,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['account_type'] = Variable<String>(accountType);
    map['report_group'] = Variable<String>(reportGroup);
    map['currency'] = Variable<String>(currency);
    map['initial_balance'] = Variable<double>(initialBalance);
    map['current_balance'] = Variable<double>(currentBalance);
    if (!nullToAbsent || institution != null) {
      map['institution'] = Variable<String>(institution);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      accountType: Value(accountType),
      reportGroup: Value(reportGroup),
      currency: Value(currency),
      initialBalance: Value(initialBalance),
      currentBalance: Value(currentBalance),
      institution: institution == null && nullToAbsent
          ? const Value.absent()
          : Value(institution),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      accountType: serializer.fromJson<String>(json['accountType']),
      reportGroup: serializer.fromJson<String>(json['reportGroup']),
      currency: serializer.fromJson<String>(json['currency']),
      initialBalance: serializer.fromJson<double>(json['initialBalance']),
      currentBalance: serializer.fromJson<double>(json['currentBalance']),
      institution: serializer.fromJson<String?>(json['institution']),
      note: serializer.fromJson<String?>(json['note']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'accountType': serializer.toJson<String>(accountType),
      'reportGroup': serializer.toJson<String>(reportGroup),
      'currency': serializer.toJson<String>(currency),
      'initialBalance': serializer.toJson<double>(initialBalance),
      'currentBalance': serializer.toJson<double>(currentBalance),
      'institution': serializer.toJson<String?>(institution),
      'note': serializer.toJson<String?>(note),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Account copyWith(
          {String? id,
          String? name,
          String? accountType,
          String? reportGroup,
          String? currency,
          double? initialBalance,
          double? currentBalance,
          Value<String?> institution = const Value.absent(),
          Value<String?> note = const Value.absent(),
          bool? isActive,
          DateTime? createdAt}) =>
      Account(
        id: id ?? this.id,
        name: name ?? this.name,
        accountType: accountType ?? this.accountType,
        reportGroup: reportGroup ?? this.reportGroup,
        currency: currency ?? this.currency,
        initialBalance: initialBalance ?? this.initialBalance,
        currentBalance: currentBalance ?? this.currentBalance,
        institution: institution.present ? institution.value : this.institution,
        note: note.present ? note.value : this.note,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      accountType:
          data.accountType.present ? data.accountType.value : this.accountType,
      reportGroup:
          data.reportGroup.present ? data.reportGroup.value : this.reportGroup,
      currency: data.currency.present ? data.currency.value : this.currency,
      initialBalance: data.initialBalance.present
          ? data.initialBalance.value
          : this.initialBalance,
      currentBalance: data.currentBalance.present
          ? data.currentBalance.value
          : this.currentBalance,
      institution:
          data.institution.present ? data.institution.value : this.institution,
      note: data.note.present ? data.note.value : this.note,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('accountType: $accountType, ')
          ..write('reportGroup: $reportGroup, ')
          ..write('currency: $currency, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('institution: $institution, ')
          ..write('note: $note, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, accountType, reportGroup, currency,
      initialBalance, currentBalance, institution, note, isActive, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.name == this.name &&
          other.accountType == this.accountType &&
          other.reportGroup == this.reportGroup &&
          other.currency == this.currency &&
          other.initialBalance == this.initialBalance &&
          other.currentBalance == this.currentBalance &&
          other.institution == this.institution &&
          other.note == this.note &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> accountType;
  final Value<String> reportGroup;
  final Value<String> currency;
  final Value<double> initialBalance;
  final Value<double> currentBalance;
  final Value<String?> institution;
  final Value<String?> note;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.accountType = const Value.absent(),
    this.reportGroup = const Value.absent(),
    this.currency = const Value.absent(),
    this.initialBalance = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.institution = const Value.absent(),
    this.note = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String name,
    required String accountType,
    required String reportGroup,
    required String currency,
    this.initialBalance = const Value.absent(),
    required double currentBalance,
    this.institution = const Value.absent(),
    this.note = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        accountType = Value(accountType),
        reportGroup = Value(reportGroup),
        currency = Value(currency),
        currentBalance = Value(currentBalance);
  static Insertable<Account> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? accountType,
    Expression<String>? reportGroup,
    Expression<String>? currency,
    Expression<double>? initialBalance,
    Expression<double>? currentBalance,
    Expression<String>? institution,
    Expression<String>? note,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (accountType != null) 'account_type': accountType,
      if (reportGroup != null) 'report_group': reportGroup,
      if (currency != null) 'currency': currency,
      if (initialBalance != null) 'initial_balance': initialBalance,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (institution != null) 'institution': institution,
      if (note != null) 'note': note,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? accountType,
      Value<String>? reportGroup,
      Value<String>? currency,
      Value<double>? initialBalance,
      Value<double>? currentBalance,
      Value<String?>? institution,
      Value<String?>? note,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      reportGroup: reportGroup ?? this.reportGroup,
      currency: currency ?? this.currency,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      institution: institution ?? this.institution,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
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
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (reportGroup.present) {
      map['report_group'] = Variable<String>(reportGroup.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (initialBalance.present) {
      map['initial_balance'] = Variable<double>(initialBalance.value);
    }
    if (currentBalance.present) {
      map['current_balance'] = Variable<double>(currentBalance.value);
    }
    if (institution.present) {
      map['institution'] = Variable<String>(institution.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('accountType: $accountType, ')
          ..write('reportGroup: $reportGroup, ')
          ..write('currency: $currency, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('institution: $institution, ')
          ..write('note: $note, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, name, type, parentId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String name;
  final String type;
  final String? parentId;
  final DateTime createdAt;
  const Category(
      {required this.id,
      required this.name,
      required this.type,
      this.parentId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      createdAt: Value(createdAt),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'parentId': serializer.toJson<String?>(parentId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Category copyWith(
          {String? id,
          String? name,
          String? type,
          Value<String?> parentId = const Value.absent(),
          DateTime? createdAt}) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        parentId: parentId.present ? parentId.value : this.parentId,
        createdAt: createdAt ?? this.createdAt,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('parentId: $parentId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, parentId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.parentId == this.parentId &&
          other.createdAt == this.createdAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> parentId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.parentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    required String type,
    this.parentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        type = Value(type);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? parentId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (parentId != null) 'parent_id': parentId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? type,
      Value<String?>? parentId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('parentId: $parentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _monthKeyMeta =
      const VerificationMeta('monthKey');
  @override
  late final GeneratedColumn<String> monthKey = GeneratedColumn<String>(
      'month_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('MYR'));
  static const VerificationMeta _alertThresholdMeta =
      const VerificationMeta('alertThreshold');
  @override
  late final GeneratedColumn<double> alertThreshold = GeneratedColumn<double>(
      'alert_threshold', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.8));
  static const VerificationMeta _rolloverEnabledMeta =
      const VerificationMeta('rolloverEnabled');
  @override
  late final GeneratedColumn<bool> rolloverEnabled = GeneratedColumn<bool>(
      'rollover_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("rollover_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        categoryId,
        monthKey,
        amount,
        currency,
        alertThreshold,
        rolloverEnabled,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(Insertable<Budget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('month_key')) {
      context.handle(_monthKeyMeta,
          monthKey.isAcceptableOrUnknown(data['month_key']!, _monthKeyMeta));
    } else if (isInserting) {
      context.missing(_monthKeyMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('alert_threshold')) {
      context.handle(
          _alertThresholdMeta,
          alertThreshold.isAcceptableOrUnknown(
              data['alert_threshold']!, _alertThresholdMeta));
    }
    if (data.containsKey('rollover_enabled')) {
      context.handle(
          _rolloverEnabledMeta,
          rolloverEnabled.isAcceptableOrUnknown(
              data['rollover_enabled']!, _rolloverEnabledMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      monthKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}month_key'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      alertThreshold: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}alert_threshold'])!,
      rolloverEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}rollover_enabled'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final String id;
  final String categoryId;
  final String monthKey;
  final double amount;
  final String currency;
  final double alertThreshold;
  final bool rolloverEnabled;
  final DateTime createdAt;
  const Budget(
      {required this.id,
      required this.categoryId,
      required this.monthKey,
      required this.amount,
      required this.currency,
      required this.alertThreshold,
      required this.rolloverEnabled,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(categoryId);
    map['month_key'] = Variable<String>(monthKey);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    map['alert_threshold'] = Variable<double>(alertThreshold);
    map['rollover_enabled'] = Variable<bool>(rolloverEnabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      monthKey: Value(monthKey),
      amount: Value(amount),
      currency: Value(currency),
      alertThreshold: Value(alertThreshold),
      rolloverEnabled: Value(rolloverEnabled),
      createdAt: Value(createdAt),
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      monthKey: serializer.fromJson<String>(json['monthKey']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      alertThreshold: serializer.fromJson<double>(json['alertThreshold']),
      rolloverEnabled: serializer.fromJson<bool>(json['rolloverEnabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'monthKey': serializer.toJson<String>(monthKey),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'alertThreshold': serializer.toJson<double>(alertThreshold),
      'rolloverEnabled': serializer.toJson<bool>(rolloverEnabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Budget copyWith(
          {String? id,
          String? categoryId,
          String? monthKey,
          double? amount,
          String? currency,
          double? alertThreshold,
          bool? rolloverEnabled,
          DateTime? createdAt}) =>
      Budget(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        monthKey: monthKey ?? this.monthKey,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        alertThreshold: alertThreshold ?? this.alertThreshold,
        rolloverEnabled: rolloverEnabled ?? this.rolloverEnabled,
        createdAt: createdAt ?? this.createdAt,
      );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      monthKey: data.monthKey.present ? data.monthKey.value : this.monthKey,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      alertThreshold: data.alertThreshold.present
          ? data.alertThreshold.value
          : this.alertThreshold,
      rolloverEnabled: data.rolloverEnabled.present
          ? data.rolloverEnabled.value
          : this.rolloverEnabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('monthKey: $monthKey, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('alertThreshold: $alertThreshold, ')
          ..write('rolloverEnabled: $rolloverEnabled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, categoryId, monthKey, amount, currency,
      alertThreshold, rolloverEnabled, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.monthKey == this.monthKey &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.alertThreshold == this.alertThreshold &&
          other.rolloverEnabled == this.rolloverEnabled &&
          other.createdAt == this.createdAt);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<String> monthKey;
  final Value<double> amount;
  final Value<String> currency;
  final Value<double> alertThreshold;
  final Value<bool> rolloverEnabled;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.monthKey = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.alertThreshold = const Value.absent(),
    this.rolloverEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String id,
    required String categoryId,
    required String monthKey,
    required double amount,
    this.currency = const Value.absent(),
    this.alertThreshold = const Value.absent(),
    this.rolloverEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        categoryId = Value(categoryId),
        monthKey = Value(monthKey),
        amount = Value(amount);
  static Insertable<Budget> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? monthKey,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<double>? alertThreshold,
    Expression<bool>? rolloverEnabled,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (monthKey != null) 'month_key': monthKey,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (alertThreshold != null) 'alert_threshold': alertThreshold,
      if (rolloverEnabled != null) 'rollover_enabled': rolloverEnabled,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? categoryId,
      Value<String>? monthKey,
      Value<double>? amount,
      Value<String>? currency,
      Value<double>? alertThreshold,
      Value<bool>? rolloverEnabled,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return BudgetsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      monthKey: monthKey ?? this.monthKey,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      rolloverEnabled: rolloverEnabled ?? this.rolloverEnabled,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (monthKey.present) {
      map['month_key'] = Variable<String>(monthKey.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (alertThreshold.present) {
      map['alert_threshold'] = Variable<double>(alertThreshold.value);
    }
    if (rolloverEnabled.present) {
      map['rollover_enabled'] = Variable<bool>(rolloverEnabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('monthKey: $monthKey, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('alertThreshold: $alertThreshold, ')
          ..write('rolloverEnabled: $rolloverEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _toAccountIdMeta =
      const VerificationMeta('toAccountId');
  @override
  late final GeneratedColumn<String> toAccountId = GeneratedColumn<String>(
      'to_account_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toAmountMeta =
      const VerificationMeta('toAmount');
  @override
  late final GeneratedColumn<double> toAmount = GeneratedColumn<double>(
      'to_amount', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _toCurrencyMeta =
      const VerificationMeta('toCurrency');
  @override
  late final GeneratedColumn<String> toCurrency = GeneratedColumn<String>(
      'to_currency', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recordDateMeta =
      const VerificationMeta('recordDate');
  @override
  late final GeneratedColumn<DateTime> recordDate = GeneratedColumn<DateTime>(
      'record_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _transactionDateMeta =
      const VerificationMeta('transactionDate');
  @override
  late final GeneratedColumn<DateTime> transactionDate =
      GeneratedColumn<DateTime>('transaction_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recurringRuleIdMeta =
      const VerificationMeta('recurringRuleId');
  @override
  late final GeneratedColumn<String> recurringRuleId = GeneratedColumn<String>(
      'recurring_rule_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _merchantMeta =
      const VerificationMeta('merchant');
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
      'merchant', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        type,
        accountId,
        toAccountId,
        categoryId,
        amount,
        currency,
        toAmount,
        toCurrency,
        recordDate,
        transactionDate,
        status,
        recurringRuleId,
        description,
        merchant,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Transaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
          _toAccountIdMeta,
          toAccountId.isAcceptableOrUnknown(
              data['to_account_id']!, _toAccountIdMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('to_amount')) {
      context.handle(_toAmountMeta,
          toAmount.isAcceptableOrUnknown(data['to_amount']!, _toAmountMeta));
    }
    if (data.containsKey('to_currency')) {
      context.handle(
          _toCurrencyMeta,
          toCurrency.isAcceptableOrUnknown(
              data['to_currency']!, _toCurrencyMeta));
    }
    if (data.containsKey('record_date')) {
      context.handle(
          _recordDateMeta,
          recordDate.isAcceptableOrUnknown(
              data['record_date']!, _recordDateMeta));
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
          _transactionDateMeta,
          transactionDate.isAcceptableOrUnknown(
              data['transaction_date']!, _transactionDateMeta));
    } else if (isInserting) {
      context.missing(_transactionDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('recurring_rule_id')) {
      context.handle(
          _recurringRuleIdMeta,
          recurringRuleId.isAcceptableOrUnknown(
              data['recurring_rule_id']!, _recurringRuleIdMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('merchant')) {
      context.handle(_merchantMeta,
          merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      toAccountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_account_id']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      toAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}to_amount']),
      toCurrency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_currency']),
      recordDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}record_date']),
      transactionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}transaction_date'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status']),
      recurringRuleId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}recurring_rule_id']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      merchant: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}merchant']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final String type;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;
  final double amount;
  final String currency;
  final double? toAmount;
  final String? toCurrency;
  final DateTime? recordDate;
  final DateTime transactionDate;
  final String? status;
  final String? recurringRuleId;
  final String? description;
  final String? merchant;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Transaction(
      {required this.id,
      required this.type,
      required this.accountId,
      this.toAccountId,
      this.categoryId,
      required this.amount,
      required this.currency,
      this.toAmount,
      this.toCurrency,
      this.recordDate,
      required this.transactionDate,
      this.status,
      this.recurringRuleId,
      this.description,
      this.merchant,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<String>(toAccountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || toAmount != null) {
      map['to_amount'] = Variable<double>(toAmount);
    }
    if (!nullToAbsent || toCurrency != null) {
      map['to_currency'] = Variable<String>(toCurrency);
    }
    if (!nullToAbsent || recordDate != null) {
      map['record_date'] = Variable<DateTime>(recordDate);
    }
    map['transaction_date'] = Variable<DateTime>(transactionDate);
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || recurringRuleId != null) {
      map['recurring_rule_id'] = Variable<String>(recurringRuleId);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || merchant != null) {
      map['merchant'] = Variable<String>(merchant);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      type: Value(type),
      accountId: Value(accountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      amount: Value(amount),
      currency: Value(currency),
      toAmount: toAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(toAmount),
      toCurrency: toCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(toCurrency),
      recordDate: recordDate == null && nullToAbsent
          ? const Value.absent()
          : Value(recordDate),
      transactionDate: Value(transactionDate),
      status:
          status == null && nullToAbsent ? const Value.absent() : Value(status),
      recurringRuleId: recurringRuleId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringRuleId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      merchant: merchant == null && nullToAbsent
          ? const Value.absent()
          : Value(merchant),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      accountId: serializer.fromJson<String>(json['accountId']),
      toAccountId: serializer.fromJson<String?>(json['toAccountId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      toAmount: serializer.fromJson<double?>(json['toAmount']),
      toCurrency: serializer.fromJson<String?>(json['toCurrency']),
      recordDate: serializer.fromJson<DateTime?>(json['recordDate']),
      transactionDate: serializer.fromJson<DateTime>(json['transactionDate']),
      status: serializer.fromJson<String?>(json['status']),
      recurringRuleId: serializer.fromJson<String?>(json['recurringRuleId']),
      description: serializer.fromJson<String?>(json['description']),
      merchant: serializer.fromJson<String?>(json['merchant']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'accountId': serializer.toJson<String>(accountId),
      'toAccountId': serializer.toJson<String?>(toAccountId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'toAmount': serializer.toJson<double?>(toAmount),
      'toCurrency': serializer.toJson<String?>(toCurrency),
      'recordDate': serializer.toJson<DateTime?>(recordDate),
      'transactionDate': serializer.toJson<DateTime>(transactionDate),
      'status': serializer.toJson<String?>(status),
      'recurringRuleId': serializer.toJson<String?>(recurringRuleId),
      'description': serializer.toJson<String?>(description),
      'merchant': serializer.toJson<String?>(merchant),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Transaction copyWith(
          {String? id,
          String? type,
          String? accountId,
          Value<String?> toAccountId = const Value.absent(),
          Value<String?> categoryId = const Value.absent(),
          double? amount,
          String? currency,
          Value<double?> toAmount = const Value.absent(),
          Value<String?> toCurrency = const Value.absent(),
          Value<DateTime?> recordDate = const Value.absent(),
          DateTime? transactionDate,
          Value<String?> status = const Value.absent(),
          Value<String?> recurringRuleId = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<String?> merchant = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Transaction(
        id: id ?? this.id,
        type: type ?? this.type,
        accountId: accountId ?? this.accountId,
        toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        toAmount: toAmount.present ? toAmount.value : this.toAmount,
        toCurrency: toCurrency.present ? toCurrency.value : this.toCurrency,
        recordDate: recordDate.present ? recordDate.value : this.recordDate,
        transactionDate: transactionDate ?? this.transactionDate,
        status: status.present ? status.value : this.status,
        recurringRuleId: recurringRuleId.present
            ? recurringRuleId.value
            : this.recurringRuleId,
        description: description.present ? description.value : this.description,
        merchant: merchant.present ? merchant.value : this.merchant,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      toAccountId:
          data.toAccountId.present ? data.toAccountId.value : this.toAccountId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      toAmount: data.toAmount.present ? data.toAmount.value : this.toAmount,
      toCurrency:
          data.toCurrency.present ? data.toCurrency.value : this.toCurrency,
      recordDate:
          data.recordDate.present ? data.recordDate.value : this.recordDate,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      status: data.status.present ? data.status.value : this.status,
      recurringRuleId: data.recurringRuleId.present
          ? data.recurringRuleId.value
          : this.recurringRuleId,
      description:
          data.description.present ? data.description.value : this.description,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('toAmount: $toAmount, ')
          ..write('toCurrency: $toCurrency, ')
          ..write('recordDate: $recordDate, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('status: $status, ')
          ..write('recurringRuleId: $recurringRuleId, ')
          ..write('description: $description, ')
          ..write('merchant: $merchant, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      type,
      accountId,
      toAccountId,
      categoryId,
      amount,
      currency,
      toAmount,
      toCurrency,
      recordDate,
      transactionDate,
      status,
      recurringRuleId,
      description,
      merchant,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.type == this.type &&
          other.accountId == this.accountId &&
          other.toAccountId == this.toAccountId &&
          other.categoryId == this.categoryId &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.toAmount == this.toAmount &&
          other.toCurrency == this.toCurrency &&
          other.recordDate == this.recordDate &&
          other.transactionDate == this.transactionDate &&
          other.status == this.status &&
          other.recurringRuleId == this.recurringRuleId &&
          other.description == this.description &&
          other.merchant == this.merchant &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> accountId;
  final Value<String?> toAccountId;
  final Value<String?> categoryId;
  final Value<double> amount;
  final Value<String> currency;
  final Value<double?> toAmount;
  final Value<String?> toCurrency;
  final Value<DateTime?> recordDate;
  final Value<DateTime> transactionDate;
  final Value<String?> status;
  final Value<String?> recurringRuleId;
  final Value<String?> description;
  final Value<String?> merchant;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.accountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.toAmount = const Value.absent(),
    this.toCurrency = const Value.absent(),
    this.recordDate = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.status = const Value.absent(),
    this.recurringRuleId = const Value.absent(),
    this.description = const Value.absent(),
    this.merchant = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String type,
    required String accountId,
    this.toAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    required double amount,
    required String currency,
    this.toAmount = const Value.absent(),
    this.toCurrency = const Value.absent(),
    this.recordDate = const Value.absent(),
    required DateTime transactionDate,
    this.status = const Value.absent(),
    this.recurringRuleId = const Value.absent(),
    this.description = const Value.absent(),
    this.merchant = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        type = Value(type),
        accountId = Value(accountId),
        amount = Value(amount),
        currency = Value(currency),
        transactionDate = Value(transactionDate);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? accountId,
    Expression<String>? toAccountId,
    Expression<String>? categoryId,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<double>? toAmount,
    Expression<String>? toCurrency,
    Expression<DateTime>? recordDate,
    Expression<DateTime>? transactionDate,
    Expression<String>? status,
    Expression<String>? recurringRuleId,
    Expression<String>? description,
    Expression<String>? merchant,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (accountId != null) 'account_id': accountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (categoryId != null) 'category_id': categoryId,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (toAmount != null) 'to_amount': toAmount,
      if (toCurrency != null) 'to_currency': toCurrency,
      if (recordDate != null) 'record_date': recordDate,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (status != null) 'status': status,
      if (recurringRuleId != null) 'recurring_rule_id': recurringRuleId,
      if (description != null) 'description': description,
      if (merchant != null) 'merchant': merchant,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? type,
      Value<String>? accountId,
      Value<String?>? toAccountId,
      Value<String?>? categoryId,
      Value<double>? amount,
      Value<String>? currency,
      Value<double?>? toAmount,
      Value<String?>? toCurrency,
      Value<DateTime?>? recordDate,
      Value<DateTime>? transactionDate,
      Value<String?>? status,
      Value<String?>? recurringRuleId,
      Value<String?>? description,
      Value<String?>? merchant,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return TransactionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      toAmount: toAmount ?? this.toAmount,
      toCurrency: toCurrency ?? this.toCurrency,
      recordDate: recordDate ?? this.recordDate,
      transactionDate: transactionDate ?? this.transactionDate,
      status: status ?? this.status,
      recurringRuleId: recurringRuleId ?? this.recurringRuleId,
      description: description ?? this.description,
      merchant: merchant ?? this.merchant,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<String>(toAccountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (toAmount.present) {
      map['to_amount'] = Variable<double>(toAmount.value);
    }
    if (toCurrency.present) {
      map['to_currency'] = Variable<String>(toCurrency.value);
    }
    if (recordDate.present) {
      map['record_date'] = Variable<DateTime>(recordDate.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (recurringRuleId.present) {
      map['recurring_rule_id'] = Variable<String>(recurringRuleId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
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
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('toAmount: $toAmount, ')
          ..write('toCurrency: $toCurrency, ')
          ..write('recordDate: $recordDate, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('status: $status, ')
          ..write('recurringRuleId: $recurringRuleId, ')
          ..write('description: $description, ')
          ..write('merchant: $merchant, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetSnapshotsTable extends AssetSnapshots
    with TableInfo<$AssetSnapshotsTable, AssetSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _snapshotDateMeta =
      const VerificationMeta('snapshotDate');
  @override
  late final GeneratedColumn<DateTime> snapshotDate = GeneratedColumn<DateTime>(
      'snapshot_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _marketValueMeta =
      const VerificationMeta('marketValue');
  @override
  late final GeneratedColumn<double> marketValue = GeneratedColumn<double>(
      'market_value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _costBasisMeta =
      const VerificationMeta('costBasis');
  @override
  late final GeneratedColumn<double> costBasis = GeneratedColumn<double>(
      'cost_basis', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _cashBalanceMeta =
      const VerificationMeta('cashBalance');
  @override
  late final GeneratedColumn<double> cashBalance = GeneratedColumn<double>(
      'cash_balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _unrealizedPnlMeta =
      const VerificationMeta('unrealizedPnl');
  @override
  late final GeneratedColumn<double> unrealizedPnl = GeneratedColumn<double>(
      'unrealized_pnl', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        accountId,
        snapshotDate,
        marketValue,
        costBasis,
        cashBalance,
        unrealizedPnl,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_snapshots';
  @override
  VerificationContext validateIntegrity(Insertable<AssetSnapshot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('snapshot_date')) {
      context.handle(
          _snapshotDateMeta,
          snapshotDate.isAcceptableOrUnknown(
              data['snapshot_date']!, _snapshotDateMeta));
    } else if (isInserting) {
      context.missing(_snapshotDateMeta);
    }
    if (data.containsKey('market_value')) {
      context.handle(
          _marketValueMeta,
          marketValue.isAcceptableOrUnknown(
              data['market_value']!, _marketValueMeta));
    } else if (isInserting) {
      context.missing(_marketValueMeta);
    }
    if (data.containsKey('cost_basis')) {
      context.handle(_costBasisMeta,
          costBasis.isAcceptableOrUnknown(data['cost_basis']!, _costBasisMeta));
    }
    if (data.containsKey('cash_balance')) {
      context.handle(
          _cashBalanceMeta,
          cashBalance.isAcceptableOrUnknown(
              data['cash_balance']!, _cashBalanceMeta));
    }
    if (data.containsKey('unrealized_pnl')) {
      context.handle(
          _unrealizedPnlMeta,
          unrealizedPnl.isAcceptableOrUnknown(
              data['unrealized_pnl']!, _unrealizedPnlMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetSnapshot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      snapshotDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}snapshot_date'])!,
      marketValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}market_value'])!,
      costBasis: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost_basis'])!,
      cashBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cash_balance'])!,
      unrealizedPnl: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}unrealized_pnl'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AssetSnapshotsTable createAlias(String alias) {
    return $AssetSnapshotsTable(attachedDatabase, alias);
  }
}

class AssetSnapshot extends DataClass implements Insertable<AssetSnapshot> {
  final String id;
  final String accountId;
  final DateTime snapshotDate;
  final double marketValue;
  final double costBasis;
  final double cashBalance;
  final double unrealizedPnl;
  final DateTime createdAt;
  const AssetSnapshot(
      {required this.id,
      required this.accountId,
      required this.snapshotDate,
      required this.marketValue,
      required this.costBasis,
      required this.cashBalance,
      required this.unrealizedPnl,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['snapshot_date'] = Variable<DateTime>(snapshotDate);
    map['market_value'] = Variable<double>(marketValue);
    map['cost_basis'] = Variable<double>(costBasis);
    map['cash_balance'] = Variable<double>(cashBalance);
    map['unrealized_pnl'] = Variable<double>(unrealizedPnl);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AssetSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return AssetSnapshotsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      snapshotDate: Value(snapshotDate),
      marketValue: Value(marketValue),
      costBasis: Value(costBasis),
      cashBalance: Value(cashBalance),
      unrealizedPnl: Value(unrealizedPnl),
      createdAt: Value(createdAt),
    );
  }

  factory AssetSnapshot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetSnapshot(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      snapshotDate: serializer.fromJson<DateTime>(json['snapshotDate']),
      marketValue: serializer.fromJson<double>(json['marketValue']),
      costBasis: serializer.fromJson<double>(json['costBasis']),
      cashBalance: serializer.fromJson<double>(json['cashBalance']),
      unrealizedPnl: serializer.fromJson<double>(json['unrealizedPnl']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'snapshotDate': serializer.toJson<DateTime>(snapshotDate),
      'marketValue': serializer.toJson<double>(marketValue),
      'costBasis': serializer.toJson<double>(costBasis),
      'cashBalance': serializer.toJson<double>(cashBalance),
      'unrealizedPnl': serializer.toJson<double>(unrealizedPnl),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AssetSnapshot copyWith(
          {String? id,
          String? accountId,
          DateTime? snapshotDate,
          double? marketValue,
          double? costBasis,
          double? cashBalance,
          double? unrealizedPnl,
          DateTime? createdAt}) =>
      AssetSnapshot(
        id: id ?? this.id,
        accountId: accountId ?? this.accountId,
        snapshotDate: snapshotDate ?? this.snapshotDate,
        marketValue: marketValue ?? this.marketValue,
        costBasis: costBasis ?? this.costBasis,
        cashBalance: cashBalance ?? this.cashBalance,
        unrealizedPnl: unrealizedPnl ?? this.unrealizedPnl,
        createdAt: createdAt ?? this.createdAt,
      );
  AssetSnapshot copyWithCompanion(AssetSnapshotsCompanion data) {
    return AssetSnapshot(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      snapshotDate: data.snapshotDate.present
          ? data.snapshotDate.value
          : this.snapshotDate,
      marketValue:
          data.marketValue.present ? data.marketValue.value : this.marketValue,
      costBasis: data.costBasis.present ? data.costBasis.value : this.costBasis,
      cashBalance:
          data.cashBalance.present ? data.cashBalance.value : this.cashBalance,
      unrealizedPnl: data.unrealizedPnl.present
          ? data.unrealizedPnl.value
          : this.unrealizedPnl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetSnapshot(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('snapshotDate: $snapshotDate, ')
          ..write('marketValue: $marketValue, ')
          ..write('costBasis: $costBasis, ')
          ..write('cashBalance: $cashBalance, ')
          ..write('unrealizedPnl: $unrealizedPnl, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, accountId, snapshotDate, marketValue,
      costBasis, cashBalance, unrealizedPnl, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetSnapshot &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.snapshotDate == this.snapshotDate &&
          other.marketValue == this.marketValue &&
          other.costBasis == this.costBasis &&
          other.cashBalance == this.cashBalance &&
          other.unrealizedPnl == this.unrealizedPnl &&
          other.createdAt == this.createdAt);
}

class AssetSnapshotsCompanion extends UpdateCompanion<AssetSnapshot> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<DateTime> snapshotDate;
  final Value<double> marketValue;
  final Value<double> costBasis;
  final Value<double> cashBalance;
  final Value<double> unrealizedPnl;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AssetSnapshotsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.snapshotDate = const Value.absent(),
    this.marketValue = const Value.absent(),
    this.costBasis = const Value.absent(),
    this.cashBalance = const Value.absent(),
    this.unrealizedPnl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetSnapshotsCompanion.insert({
    required String id,
    required String accountId,
    required DateTime snapshotDate,
    required double marketValue,
    this.costBasis = const Value.absent(),
    this.cashBalance = const Value.absent(),
    this.unrealizedPnl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        accountId = Value(accountId),
        snapshotDate = Value(snapshotDate),
        marketValue = Value(marketValue);
  static Insertable<AssetSnapshot> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<DateTime>? snapshotDate,
    Expression<double>? marketValue,
    Expression<double>? costBasis,
    Expression<double>? cashBalance,
    Expression<double>? unrealizedPnl,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (snapshotDate != null) 'snapshot_date': snapshotDate,
      if (marketValue != null) 'market_value': marketValue,
      if (costBasis != null) 'cost_basis': costBasis,
      if (cashBalance != null) 'cash_balance': cashBalance,
      if (unrealizedPnl != null) 'unrealized_pnl': unrealizedPnl,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetSnapshotsCompanion copyWith(
      {Value<String>? id,
      Value<String>? accountId,
      Value<DateTime>? snapshotDate,
      Value<double>? marketValue,
      Value<double>? costBasis,
      Value<double>? cashBalance,
      Value<double>? unrealizedPnl,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return AssetSnapshotsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      snapshotDate: snapshotDate ?? this.snapshotDate,
      marketValue: marketValue ?? this.marketValue,
      costBasis: costBasis ?? this.costBasis,
      cashBalance: cashBalance ?? this.cashBalance,
      unrealizedPnl: unrealizedPnl ?? this.unrealizedPnl,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (snapshotDate.present) {
      map['snapshot_date'] = Variable<DateTime>(snapshotDate.value);
    }
    if (marketValue.present) {
      map['market_value'] = Variable<double>(marketValue.value);
    }
    if (costBasis.present) {
      map['cost_basis'] = Variable<double>(costBasis.value);
    }
    if (cashBalance.present) {
      map['cash_balance'] = Variable<double>(cashBalance.value);
    }
    if (unrealizedPnl.present) {
      map['unrealized_pnl'] = Variable<double>(unrealizedPnl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('snapshotDate: $snapshotDate, ')
          ..write('marketValue: $marketValue, ')
          ..write('costBasis: $costBasis, ')
          ..write('cashBalance: $cashBalance, ')
          ..write('unrealizedPnl: $unrealizedPnl, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(Insertable<AppMetaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaData extends DataClass implements Insertable<AppMetaData> {
  final String key;
  final String value;
  const AppMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory AppMetaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppMetaData copyWith({String? key, String? value}) => AppMetaData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  AppMetaData copyWithCompanion(AppMetaCompanion data) {
    return AppMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<AppMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return AppMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $AssetSnapshotsTable assetSnapshots = $AssetSnapshotsTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [accounts, categories, budgets, transactions, assetSnapshots, appMeta];
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String id,
  required String name,
  required String accountType,
  required String reportGroup,
  required String currency,
  Value<double> initialBalance,
  required double currentBalance,
  Value<String?> institution,
  Value<String?> note,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> accountType,
  Value<String> reportGroup,
  Value<String> currency,
  Value<double> initialBalance,
  Value<double> currentBalance,
  Value<String?> institution,
  Value<String?> note,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AssetSnapshotsTable, List<AssetSnapshot>>
      _assetSnapshotsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.assetSnapshots,
              aliasName: $_aliasNameGenerator(
                  db.accounts.id, db.assetSnapshots.accountId));

  $$AssetSnapshotsTableProcessedTableManager get assetSnapshotsRefs {
    final manager = $$AssetSnapshotsTableTableManager($_db, $_db.assetSnapshots)
        .filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetSnapshotsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reportGroup => $composableBuilder(
      column: $table.reportGroup, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get initialBalance => $composableBuilder(
      column: $table.initialBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get currentBalance => $composableBuilder(
      column: $table.currentBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get institution => $composableBuilder(
      column: $table.institution, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> assetSnapshotsRefs(
      Expression<bool> Function($$AssetSnapshotsTableFilterComposer f) f) {
    final $$AssetSnapshotsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.assetSnapshots,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetSnapshotsTableFilterComposer(
              $db: $db,
              $table: $db.assetSnapshots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reportGroup => $composableBuilder(
      column: $table.reportGroup, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get initialBalance => $composableBuilder(
      column: $table.initialBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get currentBalance => $composableBuilder(
      column: $table.currentBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get institution => $composableBuilder(
      column: $table.institution, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
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

  GeneratedColumn<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => column);

  GeneratedColumn<String> get reportGroup => $composableBuilder(
      column: $table.reportGroup, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get initialBalance => $composableBuilder(
      column: $table.initialBalance, builder: (column) => column);

  GeneratedColumn<double> get currentBalance => $composableBuilder(
      column: $table.currentBalance, builder: (column) => column);

  GeneratedColumn<String> get institution => $composableBuilder(
      column: $table.institution, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> assetSnapshotsRefs<T extends Object>(
      Expression<T> Function($$AssetSnapshotsTableAnnotationComposer a) f) {
    final $$AssetSnapshotsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.assetSnapshots,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetSnapshotsTableAnnotationComposer(
              $db: $db,
              $table: $db.assetSnapshots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, $$AccountsTableReferences),
    Account,
    PrefetchHooks Function({bool assetSnapshotsRefs})> {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> accountType = const Value.absent(),
            Value<String> reportGroup = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<double> initialBalance = const Value.absent(),
            Value<double> currentBalance = const Value.absent(),
            Value<String?> institution = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion(
            id: id,
            name: name,
            accountType: accountType,
            reportGroup: reportGroup,
            currency: currency,
            initialBalance: initialBalance,
            currentBalance: currentBalance,
            institution: institution,
            note: note,
            isActive: isActive,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String accountType,
            required String reportGroup,
            required String currency,
            Value<double> initialBalance = const Value.absent(),
            required double currentBalance,
            Value<String?> institution = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion.insert(
            id: id,
            name: name,
            accountType: accountType,
            reportGroup: reportGroup,
            currency: currency,
            initialBalance: initialBalance,
            currentBalance: currentBalance,
            institution: institution,
            note: note,
            isActive: isActive,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$AccountsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({assetSnapshotsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (assetSnapshotsRefs) db.assetSnapshots
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (assetSnapshotsRefs)
                    await $_getPrefetchedData<Account, $AccountsTable,
                            AssetSnapshot>(
                        currentTable: table,
                        referencedTable: $$AccountsTableReferences
                            ._assetSnapshotsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .assetSnapshotsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, $$AccountsTableReferences),
    Account,
    PrefetchHooks Function({bool assetSnapshotsRefs})>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  required String type,
  Value<String?> parentId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> type,
  Value<String?> parentId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BudgetsTable, List<Budget>> _budgetsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.budgets,
          aliasName:
              $_aliasNameGenerator(db.categories.id, db.budgets.categoryId));

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager($_db, $_db.budgets)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: $_aliasNameGenerator(
                  db.categories.id, db.transactions.categoryId));

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> budgetsRefs(
      Expression<bool> Function($$BudgetsTableFilterComposer f) f) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.budgets,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BudgetsTableFilterComposer(
              $db: $db,
              $table: $db.budgets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> budgetsRefs<T extends Object>(
      Expression<T> Function($$BudgetsTableAnnotationComposer a) f) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.budgets,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BudgetsTableAnnotationComposer(
              $db: $db,
              $table: $db.budgets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function({bool budgetsRefs, bool transactionsRefs})> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            type: type,
            parentId: parentId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String type,
            Value<String?> parentId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            type: type,
            parentId: parentId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {budgetsRefs = false, transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (budgetsRefs) db.budgets,
                if (transactionsRefs) db.transactions
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (budgetsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable,
                            Budget>(
                        currentTable: table,
                        referencedTable:
                            $$CategoriesTableReferences._budgetsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .budgetsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (transactionsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable,
                            Transaction>(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function({bool budgetsRefs, bool transactionsRefs})>;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  required String id,
  required String categoryId,
  required String monthKey,
  required double amount,
  Value<String> currency,
  Value<double> alertThreshold,
  Value<bool> rolloverEnabled,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<String> id,
  Value<String> categoryId,
  Value<String> monthKey,
  Value<double> amount,
  Value<String> currency,
  Value<double> alertThreshold,
  Value<bool> rolloverEnabled,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$BudgetsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetsTable, Budget> {
  $$BudgetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
          $_aliasNameGenerator(db.budgets.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get monthKey => $composableBuilder(
      column: $table.monthKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get alertThreshold => $composableBuilder(
      column: $table.alertThreshold,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get rolloverEnabled => $composableBuilder(
      column: $table.rolloverEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get monthKey => $composableBuilder(
      column: $table.monthKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get alertThreshold => $composableBuilder(
      column: $table.alertThreshold,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get rolloverEnabled => $composableBuilder(
      column: $table.rolloverEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get monthKey =>
      $composableBuilder(column: $table.monthKey, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get alertThreshold => $composableBuilder(
      column: $table.alertThreshold, builder: (column) => column);

  GeneratedColumn<bool> get rolloverEnabled => $composableBuilder(
      column: $table.rolloverEnabled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableAnnotationComposer,
    $$BudgetsTableCreateCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder,
    (Budget, $$BudgetsTableReferences),
    Budget,
    PrefetchHooks Function({bool categoryId})> {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<String> monthKey = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<double> alertThreshold = const Value.absent(),
            Value<bool> rolloverEnabled = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion(
            id: id,
            categoryId: categoryId,
            monthKey: monthKey,
            amount: amount,
            currency: currency,
            alertThreshold: alertThreshold,
            rolloverEnabled: rolloverEnabled,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String categoryId,
            required String monthKey,
            required double amount,
            Value<String> currency = const Value.absent(),
            Value<double> alertThreshold = const Value.absent(),
            Value<bool> rolloverEnabled = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion.insert(
            id: id,
            categoryId: categoryId,
            monthKey: monthKey,
            amount: amount,
            currency: currency,
            alertThreshold: alertThreshold,
            rolloverEnabled: rolloverEnabled,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$BudgetsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$BudgetsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$BudgetsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BudgetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableAnnotationComposer,
    $$BudgetsTableCreateCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder,
    (Budget, $$BudgetsTableReferences),
    Budget,
    PrefetchHooks Function({bool categoryId})>;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  required String id,
  required String type,
  required String accountId,
  Value<String?> toAccountId,
  Value<String?> categoryId,
  required double amount,
  required String currency,
  Value<double?> toAmount,
  Value<String?> toCurrency,
  Value<DateTime?> recordDate,
  required DateTime transactionDate,
  Value<String?> status,
  Value<String?> recurringRuleId,
  Value<String?> description,
  Value<String?> merchant,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<String> id,
  Value<String> type,
  Value<String> accountId,
  Value<String?> toAccountId,
  Value<String?> categoryId,
  Value<double> amount,
  Value<String> currency,
  Value<double?> toAmount,
  Value<String?> toCurrency,
  Value<DateTime?> recordDate,
  Value<DateTime> transactionDate,
  Value<String?> status,
  Value<String?> recurringRuleId,
  Value<String?> description,
  Value<String?> merchant,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.transactions.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _toAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.transactions.toAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get toAccountId {
    final $_column = $_itemColumn<String>('to_account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
          $_aliasNameGenerator(db.transactions.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get toAmount => $composableBuilder(
      column: $table.toAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toCurrency => $composableBuilder(
      column: $table.toCurrency, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordDate => $composableBuilder(
      column: $table.recordDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
      column: $table.transactionDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurringRuleId => $composableBuilder(
      column: $table.recurringRuleId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get merchant => $composableBuilder(
      column: $table.merchant, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get toAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get toAmount => $composableBuilder(
      column: $table.toAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toCurrency => $composableBuilder(
      column: $table.toCurrency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordDate => $composableBuilder(
      column: $table.recordDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
      column: $table.transactionDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurringRuleId => $composableBuilder(
      column: $table.recurringRuleId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get merchant => $composableBuilder(
      column: $table.merchant, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get toAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get toAmount =>
      $composableBuilder(column: $table.toAmount, builder: (column) => column);

  GeneratedColumn<String> get toCurrency => $composableBuilder(
      column: $table.toCurrency, builder: (column) => column);

  GeneratedColumn<DateTime> get recordDate => $composableBuilder(
      column: $table.recordDate, builder: (column) => column);

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
      column: $table.transactionDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get recurringRuleId => $composableBuilder(
      column: $table.recurringRuleId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get toAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Transaction, $$TransactionsTableReferences),
    Transaction,
    PrefetchHooks Function(
        {bool accountId, bool toAccountId, bool categoryId})> {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<String?> toAccountId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<double?> toAmount = const Value.absent(),
            Value<String?> toCurrency = const Value.absent(),
            Value<DateTime?> recordDate = const Value.absent(),
            Value<DateTime> transactionDate = const Value.absent(),
            Value<String?> status = const Value.absent(),
            Value<String?> recurringRuleId = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> merchant = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion(
            id: id,
            type: type,
            accountId: accountId,
            toAccountId: toAccountId,
            categoryId: categoryId,
            amount: amount,
            currency: currency,
            toAmount: toAmount,
            toCurrency: toCurrency,
            recordDate: recordDate,
            transactionDate: transactionDate,
            status: status,
            recurringRuleId: recurringRuleId,
            description: description,
            merchant: merchant,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String type,
            required String accountId,
            Value<String?> toAccountId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            required double amount,
            required String currency,
            Value<double?> toAmount = const Value.absent(),
            Value<String?> toCurrency = const Value.absent(),
            Value<DateTime?> recordDate = const Value.absent(),
            required DateTime transactionDate,
            Value<String?> status = const Value.absent(),
            Value<String?> recurringRuleId = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> merchant = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            id: id,
            type: type,
            accountId: accountId,
            toAccountId: toAccountId,
            categoryId: categoryId,
            amount: amount,
            currency: currency,
            toAmount: toAmount,
            toCurrency: toCurrency,
            recordDate: recordDate,
            transactionDate: transactionDate,
            status: status,
            recurringRuleId: recurringRuleId,
            description: description,
            merchant: merchant,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {accountId = false, toAccountId = false, categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable:
                        $$TransactionsTableReferences._accountIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._accountIdTable(db).id,
                  ) as T;
                }
                if (toAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.toAccountId,
                    referencedTable:
                        $$TransactionsTableReferences._toAccountIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._toAccountIdTable(db).id,
                  ) as T;
                }
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$TransactionsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Transaction, $$TransactionsTableReferences),
    Transaction,
    PrefetchHooks Function(
        {bool accountId, bool toAccountId, bool categoryId})>;
typedef $$AssetSnapshotsTableCreateCompanionBuilder = AssetSnapshotsCompanion
    Function({
  required String id,
  required String accountId,
  required DateTime snapshotDate,
  required double marketValue,
  Value<double> costBasis,
  Value<double> cashBalance,
  Value<double> unrealizedPnl,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$AssetSnapshotsTableUpdateCompanionBuilder = AssetSnapshotsCompanion
    Function({
  Value<String> id,
  Value<String> accountId,
  Value<DateTime> snapshotDate,
  Value<double> marketValue,
  Value<double> costBasis,
  Value<double> cashBalance,
  Value<double> unrealizedPnl,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$AssetSnapshotsTableReferences
    extends BaseReferences<_$AppDatabase, $AssetSnapshotsTable, AssetSnapshot> {
  $$AssetSnapshotsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.assetSnapshots.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AssetSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $AssetSnapshotsTable> {
  $$AssetSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get snapshotDate => $composableBuilder(
      column: $table.snapshotDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get marketValue => $composableBuilder(
      column: $table.marketValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get costBasis => $composableBuilder(
      column: $table.costBasis, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cashBalance => $composableBuilder(
      column: $table.cashBalance, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get unrealizedPnl => $composableBuilder(
      column: $table.unrealizedPnl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AssetSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetSnapshotsTable> {
  $$AssetSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get snapshotDate => $composableBuilder(
      column: $table.snapshotDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get marketValue => $composableBuilder(
      column: $table.marketValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get costBasis => $composableBuilder(
      column: $table.costBasis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cashBalance => $composableBuilder(
      column: $table.cashBalance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get unrealizedPnl => $composableBuilder(
      column: $table.unrealizedPnl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AssetSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetSnapshotsTable> {
  $$AssetSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get snapshotDate => $composableBuilder(
      column: $table.snapshotDate, builder: (column) => column);

  GeneratedColumn<double> get marketValue => $composableBuilder(
      column: $table.marketValue, builder: (column) => column);

  GeneratedColumn<double> get costBasis =>
      $composableBuilder(column: $table.costBasis, builder: (column) => column);

  GeneratedColumn<double> get cashBalance => $composableBuilder(
      column: $table.cashBalance, builder: (column) => column);

  GeneratedColumn<double> get unrealizedPnl => $composableBuilder(
      column: $table.unrealizedPnl, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AssetSnapshotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AssetSnapshotsTable,
    AssetSnapshot,
    $$AssetSnapshotsTableFilterComposer,
    $$AssetSnapshotsTableOrderingComposer,
    $$AssetSnapshotsTableAnnotationComposer,
    $$AssetSnapshotsTableCreateCompanionBuilder,
    $$AssetSnapshotsTableUpdateCompanionBuilder,
    (AssetSnapshot, $$AssetSnapshotsTableReferences),
    AssetSnapshot,
    PrefetchHooks Function({bool accountId})> {
  $$AssetSnapshotsTableTableManager(
      _$AppDatabase db, $AssetSnapshotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<DateTime> snapshotDate = const Value.absent(),
            Value<double> marketValue = const Value.absent(),
            Value<double> costBasis = const Value.absent(),
            Value<double> cashBalance = const Value.absent(),
            Value<double> unrealizedPnl = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AssetSnapshotsCompanion(
            id: id,
            accountId: accountId,
            snapshotDate: snapshotDate,
            marketValue: marketValue,
            costBasis: costBasis,
            cashBalance: cashBalance,
            unrealizedPnl: unrealizedPnl,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String accountId,
            required DateTime snapshotDate,
            required double marketValue,
            Value<double> costBasis = const Value.absent(),
            Value<double> cashBalance = const Value.absent(),
            Value<double> unrealizedPnl = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AssetSnapshotsCompanion.insert(
            id: id,
            accountId: accountId,
            snapshotDate: snapshotDate,
            marketValue: marketValue,
            costBasis: costBasis,
            cashBalance: cashBalance,
            unrealizedPnl: unrealizedPnl,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AssetSnapshotsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable:
                        $$AssetSnapshotsTableReferences._accountIdTable(db),
                    referencedColumn:
                        $$AssetSnapshotsTableReferences._accountIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AssetSnapshotsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AssetSnapshotsTable,
    AssetSnapshot,
    $$AssetSnapshotsTableFilterComposer,
    $$AssetSnapshotsTableOrderingComposer,
    $$AssetSnapshotsTableAnnotationComposer,
    $$AssetSnapshotsTableCreateCompanionBuilder,
    $$AssetSnapshotsTableUpdateCompanionBuilder,
    (AssetSnapshot, $$AssetSnapshotsTableReferences),
    AssetSnapshot,
    PrefetchHooks Function({bool accountId})>;
typedef $$AppMetaTableCreateCompanionBuilder = AppMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppMetaTableUpdateCompanionBuilder = AppMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppMetaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppMetaTable,
    AppMetaData,
    $$AppMetaTableFilterComposer,
    $$AppMetaTableOrderingComposer,
    $$AppMetaTableAnnotationComposer,
    $$AppMetaTableCreateCompanionBuilder,
    $$AppMetaTableUpdateCompanionBuilder,
    (AppMetaData, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>),
    AppMetaData,
    PrefetchHooks Function()> {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppMetaCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppMetaCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppMetaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppMetaTable,
    AppMetaData,
    $$AppMetaTableFilterComposer,
    $$AppMetaTableOrderingComposer,
    $$AppMetaTableAnnotationComposer,
    $$AppMetaTableCreateCompanionBuilder,
    $$AppMetaTableUpdateCompanionBuilder,
    (AppMetaData, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>),
    AppMetaData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$AssetSnapshotsTableTableManager get assetSnapshots =>
      $$AssetSnapshotsTableTableManager(_db, _db.assetSnapshots);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
}
