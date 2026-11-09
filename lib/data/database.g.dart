// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RingsTable extends Rings with TableInfo<$RingsTable, RingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodDaysMeta = const VerificationMeta(
    'periodDays',
  );
  @override
  late final GeneratedColumn<int> periodDays = GeneratedColumn<int>(
    'period_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, periodDays];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rings';
  @override
  VerificationContext validateIntegrity(
    Insertable<RingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('period_days')) {
      context.handle(
        _periodDaysMeta,
        periodDays.isAcceptableOrUnknown(data['period_days']!, _periodDaysMeta),
      );
    } else if (isInserting) {
      context.missing(_periodDaysMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      periodDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period_days'],
      )!,
    );
  }

  @override
  $RingsTable createAlias(String alias) {
    return $RingsTable(attachedDatabase, alias);
  }
}

class RingRow extends DataClass implements Insertable<RingRow> {
  final int id;
  final String name;
  final int periodDays;
  const RingRow({
    required this.id,
    required this.name,
    required this.periodDays,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['period_days'] = Variable<int>(periodDays);
    return map;
  }

  RingsCompanion toCompanion(bool nullToAbsent) {
    return RingsCompanion(
      id: Value(id),
      name: Value(name),
      periodDays: Value(periodDays),
    );
  }

  factory RingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RingRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      periodDays: serializer.fromJson<int>(json['periodDays']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'periodDays': serializer.toJson<int>(periodDays),
    };
  }

  RingRow copyWith({int? id, String? name, int? periodDays}) => RingRow(
    id: id ?? this.id,
    name: name ?? this.name,
    periodDays: periodDays ?? this.periodDays,
  );
  RingRow copyWithCompanion(RingsCompanion data) {
    return RingRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      periodDays: data.periodDays.present
          ? data.periodDays.value
          : this.periodDays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RingRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('periodDays: $periodDays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, periodDays);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RingRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.periodDays == this.periodDays);
}

class RingsCompanion extends UpdateCompanion<RingRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> periodDays;
  const RingsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.periodDays = const Value.absent(),
  });
  RingsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int periodDays,
  }) : name = Value(name),
       periodDays = Value(periodDays);
  static Insertable<RingRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? periodDays,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (periodDays != null) 'period_days': periodDays,
    });
  }

  RingsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? periodDays,
  }) {
    return RingsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      periodDays: periodDays ?? this.periodDays,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (periodDays.present) {
      map['period_days'] = Variable<int>(periodDays.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RingsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('periodDays: $periodDays')
          ..write(')'))
        .toString();
  }
}

class $MembersTable extends Members with TableInfo<$MembersTable, MemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _contactKeyMeta = const VerificationMeta(
    'contactKey',
  );
  @override
  late final GeneratedColumn<String> contactKey = GeneratedColumn<String>(
    'contact_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _cachedNameMeta = const VerificationMeta(
    'cachedName',
  );
  @override
  late final GeneratedColumn<String> cachedName = GeneratedColumn<String>(
    'cached_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ringIdMeta = const VerificationMeta('ringId');
  @override
  late final GeneratedColumn<int> ringId = GeneratedColumn<int>(
    'ring_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rings (id) ON DELETE RESTRICT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CalendarDate, int> baselineDate =
      GeneratedColumn<int>(
        'baseline_date',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<CalendarDate>($MembersTable.$converterbaselineDate);
  @override
  late final GeneratedColumnWithTypeConverter<CalendarDate?, int>
  lastContacted = GeneratedColumn<int>(
    'last_contacted',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<CalendarDate?>($MembersTable.$converterlastContactedn);
  @override
  late final GeneratedColumnWithTypeConverter<CalendarDate?, int> snoozedUntil =
      GeneratedColumn<int>(
        'snoozed_until',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<CalendarDate?>($MembersTable.$convertersnoozedUntiln);
  @override
  late final GeneratedColumnWithTypeConverter<CalendarDate?, int> lastSurfaced =
      GeneratedColumn<int>(
        'last_surfaced',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<CalendarDate?>($MembersTable.$converterlastSurfacedn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contactKey,
    cachedName,
    ringId,
    baselineDate,
    lastContacted,
    snoozedUntil,
    lastSurfaced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('contact_key')) {
      context.handle(
        _contactKeyMeta,
        contactKey.isAcceptableOrUnknown(data['contact_key']!, _contactKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_contactKeyMeta);
    }
    if (data.containsKey('cached_name')) {
      context.handle(
        _cachedNameMeta,
        cachedName.isAcceptableOrUnknown(data['cached_name']!, _cachedNameMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedNameMeta);
    }
    if (data.containsKey('ring_id')) {
      context.handle(
        _ringIdMeta,
        ringId.isAcceptableOrUnknown(data['ring_id']!, _ringIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ringIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      contactKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_key'],
      )!,
      cachedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cached_name'],
      )!,
      ringId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ring_id'],
      )!,
      baselineDate: $MembersTable.$converterbaselineDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}baseline_date'],
        )!,
      ),
      lastContacted: $MembersTable.$converterlastContactedn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_contacted'],
        ),
      ),
      snoozedUntil: $MembersTable.$convertersnoozedUntiln.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}snoozed_until'],
        ),
      ),
      lastSurfaced: $MembersTable.$converterlastSurfacedn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_surfaced'],
        ),
      ),
    );
  }

  @override
  $MembersTable createAlias(String alias) {
    return $MembersTable(attachedDatabase, alias);
  }

  static TypeConverter<CalendarDate, int> $converterbaselineDate =
      const CalendarDateConverter();
  static TypeConverter<CalendarDate, int> $converterlastContacted =
      const CalendarDateConverter();
  static TypeConverter<CalendarDate?, int?> $converterlastContactedn =
      NullAwareTypeConverter.wrap($converterlastContacted);
  static TypeConverter<CalendarDate, int> $convertersnoozedUntil =
      const CalendarDateConverter();
  static TypeConverter<CalendarDate?, int?> $convertersnoozedUntiln =
      NullAwareTypeConverter.wrap($convertersnoozedUntil);
  static TypeConverter<CalendarDate, int> $converterlastSurfaced =
      const CalendarDateConverter();
  static TypeConverter<CalendarDate?, int?> $converterlastSurfacedn =
      NullAwareTypeConverter.wrap($converterlastSurfaced);
}

class MemberRow extends DataClass implements Insertable<MemberRow> {
  final int id;

  /// UNIQUE: enforces one ring per contact at the database level.
  final String contactKey;
  final String cachedName;

  /// RESTRICT: a ring with members can't be deleted until they're moved.
  final int ringId;
  final CalendarDate baselineDate;
  final CalendarDate? lastContacted;
  final CalendarDate? snoozedUntil;
  final CalendarDate? lastSurfaced;
  const MemberRow({
    required this.id,
    required this.contactKey,
    required this.cachedName,
    required this.ringId,
    required this.baselineDate,
    this.lastContacted,
    this.snoozedUntil,
    this.lastSurfaced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['contact_key'] = Variable<String>(contactKey);
    map['cached_name'] = Variable<String>(cachedName);
    map['ring_id'] = Variable<int>(ringId);
    {
      map['baseline_date'] = Variable<int>(
        $MembersTable.$converterbaselineDate.toSql(baselineDate),
      );
    }
    if (!nullToAbsent || lastContacted != null) {
      map['last_contacted'] = Variable<int>(
        $MembersTable.$converterlastContactedn.toSql(lastContacted),
      );
    }
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<int>(
        $MembersTable.$convertersnoozedUntiln.toSql(snoozedUntil),
      );
    }
    if (!nullToAbsent || lastSurfaced != null) {
      map['last_surfaced'] = Variable<int>(
        $MembersTable.$converterlastSurfacedn.toSql(lastSurfaced),
      );
    }
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      id: Value(id),
      contactKey: Value(contactKey),
      cachedName: Value(cachedName),
      ringId: Value(ringId),
      baselineDate: Value(baselineDate),
      lastContacted: lastContacted == null && nullToAbsent
          ? const Value.absent()
          : Value(lastContacted),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
      lastSurfaced: lastSurfaced == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSurfaced),
    );
  }

  factory MemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberRow(
      id: serializer.fromJson<int>(json['id']),
      contactKey: serializer.fromJson<String>(json['contactKey']),
      cachedName: serializer.fromJson<String>(json['cachedName']),
      ringId: serializer.fromJson<int>(json['ringId']),
      baselineDate: serializer.fromJson<CalendarDate>(json['baselineDate']),
      lastContacted: serializer.fromJson<CalendarDate?>(json['lastContacted']),
      snoozedUntil: serializer.fromJson<CalendarDate?>(json['snoozedUntil']),
      lastSurfaced: serializer.fromJson<CalendarDate?>(json['lastSurfaced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'contactKey': serializer.toJson<String>(contactKey),
      'cachedName': serializer.toJson<String>(cachedName),
      'ringId': serializer.toJson<int>(ringId),
      'baselineDate': serializer.toJson<CalendarDate>(baselineDate),
      'lastContacted': serializer.toJson<CalendarDate?>(lastContacted),
      'snoozedUntil': serializer.toJson<CalendarDate?>(snoozedUntil),
      'lastSurfaced': serializer.toJson<CalendarDate?>(lastSurfaced),
    };
  }

  MemberRow copyWith({
    int? id,
    String? contactKey,
    String? cachedName,
    int? ringId,
    CalendarDate? baselineDate,
    Value<CalendarDate?> lastContacted = const Value.absent(),
    Value<CalendarDate?> snoozedUntil = const Value.absent(),
    Value<CalendarDate?> lastSurfaced = const Value.absent(),
  }) => MemberRow(
    id: id ?? this.id,
    contactKey: contactKey ?? this.contactKey,
    cachedName: cachedName ?? this.cachedName,
    ringId: ringId ?? this.ringId,
    baselineDate: baselineDate ?? this.baselineDate,
    lastContacted: lastContacted.present
        ? lastContacted.value
        : this.lastContacted,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
    lastSurfaced: lastSurfaced.present ? lastSurfaced.value : this.lastSurfaced,
  );
  MemberRow copyWithCompanion(MembersCompanion data) {
    return MemberRow(
      id: data.id.present ? data.id.value : this.id,
      contactKey: data.contactKey.present
          ? data.contactKey.value
          : this.contactKey,
      cachedName: data.cachedName.present
          ? data.cachedName.value
          : this.cachedName,
      ringId: data.ringId.present ? data.ringId.value : this.ringId,
      baselineDate: data.baselineDate.present
          ? data.baselineDate.value
          : this.baselineDate,
      lastContacted: data.lastContacted.present
          ? data.lastContacted.value
          : this.lastContacted,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
      lastSurfaced: data.lastSurfaced.present
          ? data.lastSurfaced.value
          : this.lastSurfaced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberRow(')
          ..write('id: $id, ')
          ..write('contactKey: $contactKey, ')
          ..write('cachedName: $cachedName, ')
          ..write('ringId: $ringId, ')
          ..write('baselineDate: $baselineDate, ')
          ..write('lastContacted: $lastContacted, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('lastSurfaced: $lastSurfaced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contactKey,
    cachedName,
    ringId,
    baselineDate,
    lastContacted,
    snoozedUntil,
    lastSurfaced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberRow &&
          other.id == this.id &&
          other.contactKey == this.contactKey &&
          other.cachedName == this.cachedName &&
          other.ringId == this.ringId &&
          other.baselineDate == this.baselineDate &&
          other.lastContacted == this.lastContacted &&
          other.snoozedUntil == this.snoozedUntil &&
          other.lastSurfaced == this.lastSurfaced);
}

class MembersCompanion extends UpdateCompanion<MemberRow> {
  final Value<int> id;
  final Value<String> contactKey;
  final Value<String> cachedName;
  final Value<int> ringId;
  final Value<CalendarDate> baselineDate;
  final Value<CalendarDate?> lastContacted;
  final Value<CalendarDate?> snoozedUntil;
  final Value<CalendarDate?> lastSurfaced;
  const MembersCompanion({
    this.id = const Value.absent(),
    this.contactKey = const Value.absent(),
    this.cachedName = const Value.absent(),
    this.ringId = const Value.absent(),
    this.baselineDate = const Value.absent(),
    this.lastContacted = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.lastSurfaced = const Value.absent(),
  });
  MembersCompanion.insert({
    this.id = const Value.absent(),
    required String contactKey,
    required String cachedName,
    required int ringId,
    required CalendarDate baselineDate,
    this.lastContacted = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.lastSurfaced = const Value.absent(),
  }) : contactKey = Value(contactKey),
       cachedName = Value(cachedName),
       ringId = Value(ringId),
       baselineDate = Value(baselineDate);
  static Insertable<MemberRow> custom({
    Expression<int>? id,
    Expression<String>? contactKey,
    Expression<String>? cachedName,
    Expression<int>? ringId,
    Expression<int>? baselineDate,
    Expression<int>? lastContacted,
    Expression<int>? snoozedUntil,
    Expression<int>? lastSurfaced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contactKey != null) 'contact_key': contactKey,
      if (cachedName != null) 'cached_name': cachedName,
      if (ringId != null) 'ring_id': ringId,
      if (baselineDate != null) 'baseline_date': baselineDate,
      if (lastContacted != null) 'last_contacted': lastContacted,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (lastSurfaced != null) 'last_surfaced': lastSurfaced,
    });
  }

  MembersCompanion copyWith({
    Value<int>? id,
    Value<String>? contactKey,
    Value<String>? cachedName,
    Value<int>? ringId,
    Value<CalendarDate>? baselineDate,
    Value<CalendarDate?>? lastContacted,
    Value<CalendarDate?>? snoozedUntil,
    Value<CalendarDate?>? lastSurfaced,
  }) {
    return MembersCompanion(
      id: id ?? this.id,
      contactKey: contactKey ?? this.contactKey,
      cachedName: cachedName ?? this.cachedName,
      ringId: ringId ?? this.ringId,
      baselineDate: baselineDate ?? this.baselineDate,
      lastContacted: lastContacted ?? this.lastContacted,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      lastSurfaced: lastSurfaced ?? this.lastSurfaced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (contactKey.present) {
      map['contact_key'] = Variable<String>(contactKey.value);
    }
    if (cachedName.present) {
      map['cached_name'] = Variable<String>(cachedName.value);
    }
    if (ringId.present) {
      map['ring_id'] = Variable<int>(ringId.value);
    }
    if (baselineDate.present) {
      map['baseline_date'] = Variable<int>(
        $MembersTable.$converterbaselineDate.toSql(baselineDate.value),
      );
    }
    if (lastContacted.present) {
      map['last_contacted'] = Variable<int>(
        $MembersTable.$converterlastContactedn.toSql(lastContacted.value),
      );
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<int>(
        $MembersTable.$convertersnoozedUntiln.toSql(snoozedUntil.value),
      );
    }
    if (lastSurfaced.present) {
      map['last_surfaced'] = Variable<int>(
        $MembersTable.$converterlastSurfacedn.toSql(lastSurfaced.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('id: $id, ')
          ..write('contactKey: $contactKey, ')
          ..write('cachedName: $cachedName, ')
          ..write('ringId: $ringId, ')
          ..write('baselineDate: $baselineDate, ')
          ..write('lastContacted: $lastContacted, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('lastSurfaced: $lastSurfaced')
          ..write(')'))
        .toString();
  }
}

class $DailyNudgesTable extends DailyNudges
    with TableInfo<$DailyNudgesTable, DailyNudgeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyNudgesTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<CalendarDate, int> date =
      GeneratedColumn<int>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<CalendarDate>($DailyNudgesTable.$converterdate);
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<int> memberId = GeneratedColumn<int>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<NudgeStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<NudgeStatus>($DailyNudgesTable.$converterstatus);
  @override
  List<GeneratedColumn> get $columns => [date, memberId, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_nudges';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyNudgeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date, memberId};
  @override
  DailyNudgeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyNudgeRow(
      date: $DailyNudgesTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}date'],
        )!,
      ),
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_id'],
      )!,
      status: $DailyNudgesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
    );
  }

  @override
  $DailyNudgesTable createAlias(String alias) {
    return $DailyNudgesTable(attachedDatabase, alias);
  }

  static TypeConverter<CalendarDate, int> $converterdate =
      const CalendarDateConverter();
  static JsonTypeConverter2<NudgeStatus, String, String> $converterstatus =
      const EnumNameConverter<NudgeStatus>(NudgeStatus.values);
}

class DailyNudgeRow extends DataClass implements Insertable<DailyNudgeRow> {
  final CalendarDate date;
  final int memberId;
  final NudgeStatus status;
  const DailyNudgeRow({
    required this.date,
    required this.memberId,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['date'] = Variable<int>($DailyNudgesTable.$converterdate.toSql(date));
    }
    map['member_id'] = Variable<int>(memberId);
    {
      map['status'] = Variable<String>(
        $DailyNudgesTable.$converterstatus.toSql(status),
      );
    }
    return map;
  }

  DailyNudgesCompanion toCompanion(bool nullToAbsent) {
    return DailyNudgesCompanion(
      date: Value(date),
      memberId: Value(memberId),
      status: Value(status),
    );
  }

  factory DailyNudgeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyNudgeRow(
      date: serializer.fromJson<CalendarDate>(json['date']),
      memberId: serializer.fromJson<int>(json['memberId']),
      status: $DailyNudgesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<CalendarDate>(date),
      'memberId': serializer.toJson<int>(memberId),
      'status': serializer.toJson<String>(
        $DailyNudgesTable.$converterstatus.toJson(status),
      ),
    };
  }

  DailyNudgeRow copyWith({
    CalendarDate? date,
    int? memberId,
    NudgeStatus? status,
  }) => DailyNudgeRow(
    date: date ?? this.date,
    memberId: memberId ?? this.memberId,
    status: status ?? this.status,
  );
  DailyNudgeRow copyWithCompanion(DailyNudgesCompanion data) {
    return DailyNudgeRow(
      date: data.date.present ? data.date.value : this.date,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyNudgeRow(')
          ..write('date: $date, ')
          ..write('memberId: $memberId, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, memberId, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyNudgeRow &&
          other.date == this.date &&
          other.memberId == this.memberId &&
          other.status == this.status);
}

class DailyNudgesCompanion extends UpdateCompanion<DailyNudgeRow> {
  final Value<CalendarDate> date;
  final Value<int> memberId;
  final Value<NudgeStatus> status;
  final Value<int> rowid;
  const DailyNudgesCompanion({
    this.date = const Value.absent(),
    this.memberId = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyNudgesCompanion.insert({
    required CalendarDate date,
    required int memberId,
    required NudgeStatus status,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       memberId = Value(memberId),
       status = Value(status);
  static Insertable<DailyNudgeRow> custom({
    Expression<int>? date,
    Expression<int>? memberId,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (memberId != null) 'member_id': memberId,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyNudgesCompanion copyWith({
    Value<CalendarDate>? date,
    Value<int>? memberId,
    Value<NudgeStatus>? status,
    Value<int>? rowid,
  }) {
    return DailyNudgesCompanion(
      date: date ?? this.date,
      memberId: memberId ?? this.memberId,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<int>(
        $DailyNudgesTable.$converterdate.toSql(date.value),
      );
    }
    if (memberId.present) {
      map['member_id'] = Variable<int>(memberId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $DailyNudgesTable.$converterstatus.toSql(status.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyNudgesCompanion(')
          ..write('date: $date, ')
          ..write('memberId: $memberId, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RingsTable rings = $RingsTable(this);
  late final $MembersTable members = $MembersTable(this);
  late final $DailyNudgesTable dailyNudges = $DailyNudgesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    rings,
    members,
    dailyNudges,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'members',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('daily_nudges', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$RingsTableCreateCompanionBuilder = RingsCompanion Function({
  Value<int> id,
  required String name,
  required int periodDays,
});
typedef $$RingsTableUpdateCompanionBuilder = RingsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> periodDays,
});

final class $$RingsTableReferences
    extends BaseReferences<_$AppDatabase, $RingsTable, RingRow> {
  $$RingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MembersTable, List<MemberRow>> _membersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.members,
    aliasName: 'rings__id__members__ring_id',
  );

  $$MembersTableProcessedTableManager get membersRefs {
    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.ringId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_membersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RingsTableFilterComposer extends Composer<_$AppDatabase, $RingsTable> {
  $$RingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get periodDays => $composableBuilder(
    column: $table.periodDays,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> membersRefs(
    Expression<bool> Function($$MembersTableFilterComposer f) f,
  ) {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.ringId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RingsTableOrderingComposer
    extends Composer<_$AppDatabase, $RingsTable> {
  $$RingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get periodDays => $composableBuilder(
    column: $table.periodDays,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RingsTable> {
  $$RingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get periodDays => $composableBuilder(
    column: $table.periodDays,
    builder: (column) => column,
  );

  Expression<T> membersRefs<T extends Object>(
    Expression<T> Function($$MembersTableAnnotationComposer a) f,
  ) {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.ringId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RingsTable,
          RingRow,
          $$RingsTableFilterComposer,
          $$RingsTableOrderingComposer,
          $$RingsTableAnnotationComposer,
          $$RingsTableCreateCompanionBuilder,
          $$RingsTableUpdateCompanionBuilder,
          (RingRow, $$RingsTableReferences),
          RingRow,
          PrefetchHooks Function({bool membersRefs})
        > {
  $$RingsTableTableManager(_$AppDatabase db, $RingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> periodDays = const Value.absent(),
          }) => RingsCompanion(id: id, name: name, periodDays: periodDays),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int periodDays,
              }) => RingsCompanion.insert(
                id: id,
                name: name,
                periodDays: periodDays,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RingsTable, RingRow>(table),
                  $$RingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({membersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (membersRefs) db.members],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (membersRefs)
                    await $_getPrefetchedDataByColumns<
                      RingRow,
                      $RingsTable,
                      MemberRow,
                      $MembersTable
                    >(
                      currentTable: table,
                      referencedTable: $$RingsTableReferences._membersRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$RingsTableReferences(db, table, p0).membersRefs,
                      currentColumn: 'id',
                      referencedColumn: 'ring_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RingsTable,
      RingRow,
      $$RingsTableFilterComposer,
      $$RingsTableOrderingComposer,
      $$RingsTableAnnotationComposer,
      $$RingsTableCreateCompanionBuilder,
      $$RingsTableUpdateCompanionBuilder,
      (RingRow, $$RingsTableReferences),
      RingRow,
      PrefetchHooks Function({bool membersRefs})
    >;
typedef $$MembersTableCreateCompanionBuilder = MembersCompanion Function({
  Value<int> id,
  required String contactKey,
  required String cachedName,
  required int ringId,
  required CalendarDate baselineDate,
  Value<CalendarDate?> lastContacted,
  Value<CalendarDate?> snoozedUntil,
  Value<CalendarDate?> lastSurfaced,
});
typedef $$MembersTableUpdateCompanionBuilder = MembersCompanion Function({
  Value<int> id,
  Value<String> contactKey,
  Value<String> cachedName,
  Value<int> ringId,
  Value<CalendarDate> baselineDate,
  Value<CalendarDate?> lastContacted,
  Value<CalendarDate?> snoozedUntil,
  Value<CalendarDate?> lastSurfaced,
});

final class $$MembersTableReferences
    extends BaseReferences<_$AppDatabase, $MembersTable, MemberRow> {
  $$MembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RingsTable _ringIdTable(_$AppDatabase db) =>
      db.rings.createAlias('members__ring_id__rings__id');

  $$RingsTableProcessedTableManager get ringId {
    final $_column = $_itemColumn<int>('ring_id')!;

    final manager = $$RingsTableTableManager(
      $_db,
      $_db.rings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ringIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DailyNudgesTable, List<DailyNudgeRow>>
  _dailyNudgesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dailyNudges,
    aliasName: 'members__id__daily_nudges__member_id',
  );

  $$DailyNudgesTableProcessedTableManager get dailyNudgesRefs {
    final manager = $$DailyNudgesTableTableManager(
      $_db,
      $_db.dailyNudges,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_dailyNudgesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MembersTableFilterComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactKey => $composableBuilder(
    column: $table.contactKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachedName => $composableBuilder(
    column: $table.cachedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarDate, CalendarDate, int>
  get baselineDate => $composableBuilder(
    column: $table.baselineDate,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarDate?, CalendarDate, int>
  get lastContacted => $composableBuilder(
    column: $table.lastContacted,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarDate?, CalendarDate, int>
  get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarDate?, CalendarDate, int>
  get lastSurfaced => $composableBuilder(
    column: $table.lastSurfaced,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$RingsTableFilterComposer get ringId {
    final $$RingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ringId,
      referencedTable: $db.rings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RingsTableFilterComposer(
            $db: $db,
            $table: $db.rings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> dailyNudgesRefs(
    Expression<bool> Function($$DailyNudgesTableFilterComposer f) f,
  ) {
    final $$DailyNudgesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dailyNudges,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyNudgesTableFilterComposer(
            $db: $db,
            $table: $db.dailyNudges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MembersTableOrderingComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactKey => $composableBuilder(
    column: $table.contactKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachedName => $composableBuilder(
    column: $table.cachedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baselineDate => $composableBuilder(
    column: $table.baselineDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastContacted => $composableBuilder(
    column: $table.lastContacted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSurfaced => $composableBuilder(
    column: $table.lastSurfaced,
    builder: (column) => ColumnOrderings(column),
  );

  $$RingsTableOrderingComposer get ringId {
    final $$RingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ringId,
      referencedTable: $db.rings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RingsTableOrderingComposer(
            $db: $db,
            $table: $db.rings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contactKey => $composableBuilder(
    column: $table.contactKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cachedName => $composableBuilder(
    column: $table.cachedName,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CalendarDate, int> get baselineDate =>
      $composableBuilder(
        column: $table.baselineDate,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<CalendarDate?, int> get lastContacted =>
      $composableBuilder(
        column: $table.lastContacted,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<CalendarDate?, int> get snoozedUntil =>
      $composableBuilder(
        column: $table.snoozedUntil,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<CalendarDate?, int> get lastSurfaced =>
      $composableBuilder(
        column: $table.lastSurfaced,
        builder: (column) => column,
      );

  $$RingsTableAnnotationComposer get ringId {
    final $$RingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ringId,
      referencedTable: $db.rings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RingsTableAnnotationComposer(
            $db: $db,
            $table: $db.rings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> dailyNudgesRefs<T extends Object>(
    Expression<T> Function($$DailyNudgesTableAnnotationComposer a) f,
  ) {
    final $$DailyNudgesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dailyNudges,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyNudgesTableAnnotationComposer(
            $db: $db,
            $table: $db.dailyNudges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MembersTable,
          MemberRow,
          $$MembersTableFilterComposer,
          $$MembersTableOrderingComposer,
          $$MembersTableAnnotationComposer,
          $$MembersTableCreateCompanionBuilder,
          $$MembersTableUpdateCompanionBuilder,
          (MemberRow, $$MembersTableReferences),
          MemberRow,
          PrefetchHooks Function({bool ringId, bool dailyNudgesRefs})
        > {
  $$MembersTableTableManager(_$AppDatabase db, $MembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> contactKey = const Value.absent(),
                Value<String> cachedName = const Value.absent(),
                Value<int> ringId = const Value.absent(),
                Value<CalendarDate> baselineDate = const Value.absent(),
                Value<CalendarDate?> lastContacted = const Value.absent(),
                Value<CalendarDate?> snoozedUntil = const Value.absent(),
                Value<CalendarDate?> lastSurfaced = const Value.absent(),
              }) => MembersCompanion(
                id: id,
                contactKey: contactKey,
                cachedName: cachedName,
                ringId: ringId,
                baselineDate: baselineDate,
                lastContacted: lastContacted,
                snoozedUntil: snoozedUntil,
                lastSurfaced: lastSurfaced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String contactKey,
                required String cachedName,
                required int ringId,
                required CalendarDate baselineDate,
                Value<CalendarDate?> lastContacted = const Value.absent(),
                Value<CalendarDate?> snoozedUntil = const Value.absent(),
                Value<CalendarDate?> lastSurfaced = const Value.absent(),
              }) => MembersCompanion.insert(
                id: id,
                contactKey: contactKey,
                cachedName: cachedName,
                ringId: ringId,
                baselineDate: baselineDate,
                lastContacted: lastContacted,
                snoozedUntil: snoozedUntil,
                lastSurfaced: lastSurfaced,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MembersTable, MemberRow>(table),
                  $$MembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ringId = false, dailyNudgesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (dailyNudgesRefs) db.dailyNudges],
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
                    if (ringId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.ringId,
                        referencedTable: $$MembersTableReferences._ringIdTable(
                          db,
                        ),
                        referencedColumn: $$MembersTableReferences
                            ._ringIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (dailyNudgesRefs)
                    await $_getPrefetchedDataByColumns<
                      MemberRow,
                      $MembersTable,
                      DailyNudgeRow,
                      $DailyNudgesTable
                    >(
                      currentTable: table,
                      referencedTable: $$MembersTableReferences
                          ._dailyNudgesRefsTable(db),
                      managerFromTypedResult: (p0) => $$MembersTableReferences(
                        db,
                        table,
                        p0,
                      ).dailyNudgesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'member_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MembersTable,
      MemberRow,
      $$MembersTableFilterComposer,
      $$MembersTableOrderingComposer,
      $$MembersTableAnnotationComposer,
      $$MembersTableCreateCompanionBuilder,
      $$MembersTableUpdateCompanionBuilder,
      (MemberRow, $$MembersTableReferences),
      MemberRow,
      PrefetchHooks Function({bool ringId, bool dailyNudgesRefs})
    >;
typedef $$DailyNudgesTableCreateCompanionBuilder =
    DailyNudgesCompanion Function({
      required CalendarDate date,
      required int memberId,
      required NudgeStatus status,
      Value<int> rowid,
    });
typedef $$DailyNudgesTableUpdateCompanionBuilder =
    DailyNudgesCompanion Function({
      Value<CalendarDate> date,
      Value<int> memberId,
      Value<NudgeStatus> status,
      Value<int> rowid,
    });

final class $$DailyNudgesTableReferences
    extends BaseReferences<_$AppDatabase, $DailyNudgesTable, DailyNudgeRow> {
  $$DailyNudgesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('daily_nudges__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<int>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DailyNudgesTableFilterComposer
    extends Composer<_$AppDatabase, $DailyNudgesTable> {
  $$DailyNudgesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<CalendarDate, CalendarDate, int> get date =>
      $composableBuilder(
        column: $table.date,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<NudgeStatus, NudgeStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyNudgesTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyNudgesTable> {
  $$DailyNudgesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyNudgesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyNudgesTable> {
  $$DailyNudgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<CalendarDate, int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<NudgeStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyNudgesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyNudgesTable,
          DailyNudgeRow,
          $$DailyNudgesTableFilterComposer,
          $$DailyNudgesTableOrderingComposer,
          $$DailyNudgesTableAnnotationComposer,
          $$DailyNudgesTableCreateCompanionBuilder,
          $$DailyNudgesTableUpdateCompanionBuilder,
          (DailyNudgeRow, $$DailyNudgesTableReferences),
          DailyNudgeRow,
          PrefetchHooks Function({bool memberId})
        > {
  $$DailyNudgesTableTableManager(_$AppDatabase db, $DailyNudgesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyNudgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyNudgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyNudgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<CalendarDate> date = const Value.absent(),
                Value<int> memberId = const Value.absent(),
                Value<NudgeStatus> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyNudgesCompanion(
                date: date,
                memberId: memberId,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required CalendarDate date,
                required int memberId,
                required NudgeStatus status,
                Value<int> rowid = const Value.absent(),
              }) => DailyNudgesCompanion.insert(
                date: date,
                memberId: memberId,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyNudgesTable, DailyNudgeRow>(table),
                  $$DailyNudgesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false}) {
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
                    if (memberId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.memberId,
                        referencedTable: $$DailyNudgesTableReferences
                            ._memberIdTable(db),
                        referencedColumn: $$DailyNudgesTableReferences
                            ._memberIdTable(db)
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

typedef $$DailyNudgesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyNudgesTable,
      DailyNudgeRow,
      $$DailyNudgesTableFilterComposer,
      $$DailyNudgesTableOrderingComposer,
      $$DailyNudgesTableAnnotationComposer,
      $$DailyNudgesTableCreateCompanionBuilder,
      $$DailyNudgesTableUpdateCompanionBuilder,
      (DailyNudgeRow, $$DailyNudgesTableReferences),
      DailyNudgeRow,
      PrefetchHooks Function({bool memberId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RingsTableTableManager get rings =>
      $$RingsTableTableManager(_db, _db.rings);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db, _db.members);
  $$DailyNudgesTableTableManager get dailyNudges =>
      $$DailyNudgesTableTableManager(_db, _db.dailyNudges);
}
