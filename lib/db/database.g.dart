// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SitesTable extends Sites with TableInfo<$SitesTable, Site> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SitesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _associationIdMeta = const VerificationMeta(
    'associationId',
  );
  @override
  late final GeneratedColumn<String> associationId = GeneratedColumn<String>(
    'association_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enteredByMeta = const VerificationMeta(
    'enteredBy',
  );
  @override
  late final GeneratedColumn<String> enteredBy = GeneratedColumn<String>(
    'entered_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observedByMeta = const VerificationMeta(
    'observedBy',
  );
  @override
  late final GeneratedColumn<String> observedBy = GeneratedColumn<String>(
    'observed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtDeviceMeta = const VerificationMeta(
    'createdAtDevice',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtDevice =
      GeneratedColumn<DateTime>(
        'created_at_device',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        clientDefault: utcNow,
      );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverReceivedAtMeta = const VerificationMeta(
    'serverReceivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverReceivedAt =
      GeneratedColumn<DateTime>(
        'server_received_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.pending.name),
      ).withConverter<SyncState>($SitesTable.$convertersyncState);
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtDeviceMeta = const VerificationMeta(
    'updatedAtDevice',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtDevice =
      GeneratedColumn<DateTime>(
        'updated_at_device',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        clientDefault: utcNow,
      );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationNoteMeta = const VerificationMeta(
    'locationNote',
  );
  @override
  late final GeneratedColumn<String> locationNote = GeneratedColumn<String>(
    'location_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    associationId,
    enteredBy,
    observedBy,
    createdAtDevice,
    deviceId,
    serverReceivedAt,
    serverSeq,
    syncState,
    syncError,
    updatedAtDevice,
    name,
    locationNote,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Site> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('association_id')) {
      context.handle(
        _associationIdMeta,
        associationId.isAcceptableOrUnknown(
          data['association_id']!,
          _associationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_associationIdMeta);
    }
    if (data.containsKey('entered_by')) {
      context.handle(
        _enteredByMeta,
        enteredBy.isAcceptableOrUnknown(data['entered_by']!, _enteredByMeta),
      );
    } else if (isInserting) {
      context.missing(_enteredByMeta);
    }
    if (data.containsKey('observed_by')) {
      context.handle(
        _observedByMeta,
        observedBy.isAcceptableOrUnknown(data['observed_by']!, _observedByMeta),
      );
    }
    if (data.containsKey('created_at_device')) {
      context.handle(
        _createdAtDeviceMeta,
        createdAtDevice.isAcceptableOrUnknown(
          data['created_at_device']!,
          _createdAtDeviceMeta,
        ),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('server_received_at')) {
      context.handle(
        _serverReceivedAtMeta,
        serverReceivedAt.isAcceptableOrUnknown(
          data['server_received_at']!,
          _serverReceivedAtMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('updated_at_device')) {
      context.handle(
        _updatedAtDeviceMeta,
        updatedAtDevice.isAcceptableOrUnknown(
          data['updated_at_device']!,
          _updatedAtDeviceMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('location_note')) {
      context.handle(
        _locationNoteMeta,
        locationNote.isAcceptableOrUnknown(
          data['location_note']!,
          _locationNoteMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Site map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Site(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      associationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}association_id'],
      )!,
      enteredBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entered_by'],
      )!,
      observedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observed_by'],
      ),
      createdAtDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_device'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      serverReceivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_received_at'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      syncState: $SitesTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      updatedAtDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_device'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      locationNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_note'],
      ),
    );
  }

  @override
  $SitesTable createAlias(String alias) {
    return $SitesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class Site extends DataClass implements Insertable<Site> {
  final String id;
  final String associationId;
  final String enteredBy;
  final String? observedBy;
  final DateTime createdAtDevice;
  final String deviceId;
  final DateTime? serverReceivedAt;
  final int? serverSeq;
  final SyncState syncState;
  final String? syncError;
  final DateTime updatedAtDevice;
  final String name;
  final String? locationNote;
  const Site({
    required this.id,
    required this.associationId,
    required this.enteredBy,
    this.observedBy,
    required this.createdAtDevice,
    required this.deviceId,
    this.serverReceivedAt,
    this.serverSeq,
    required this.syncState,
    this.syncError,
    required this.updatedAtDevice,
    required this.name,
    this.locationNote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['association_id'] = Variable<String>(associationId);
    map['entered_by'] = Variable<String>(enteredBy);
    if (!nullToAbsent || observedBy != null) {
      map['observed_by'] = Variable<String>(observedBy);
    }
    map['created_at_device'] = Variable<DateTime>(createdAtDevice);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || serverReceivedAt != null) {
      map['server_received_at'] = Variable<DateTime>(serverReceivedAt);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    {
      map['sync_state'] = Variable<String>(
        $SitesTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['updated_at_device'] = Variable<DateTime>(updatedAtDevice);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || locationNote != null) {
      map['location_note'] = Variable<String>(locationNote);
    }
    return map;
  }

  SitesCompanion toCompanion(bool nullToAbsent) {
    return SitesCompanion(
      id: Value(id),
      associationId: Value(associationId),
      enteredBy: Value(enteredBy),
      observedBy: observedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(observedBy),
      createdAtDevice: Value(createdAtDevice),
      deviceId: Value(deviceId),
      serverReceivedAt: serverReceivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverReceivedAt),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      syncState: Value(syncState),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      updatedAtDevice: Value(updatedAtDevice),
      name: Value(name),
      locationNote: locationNote == null && nullToAbsent
          ? const Value.absent()
          : Value(locationNote),
    );
  }

  factory Site.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Site(
      id: serializer.fromJson<String>(json['id']),
      associationId: serializer.fromJson<String>(json['associationId']),
      enteredBy: serializer.fromJson<String>(json['enteredBy']),
      observedBy: serializer.fromJson<String?>(json['observedBy']),
      createdAtDevice: serializer.fromJson<DateTime>(json['createdAtDevice']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      serverReceivedAt: serializer.fromJson<DateTime?>(
        json['serverReceivedAt'],
      ),
      serverSeq: serializer.fromJson<int?>(json['serverSeq']),
      syncState: $SitesTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      syncError: serializer.fromJson<String?>(json['syncError']),
      updatedAtDevice: serializer.fromJson<DateTime>(json['updatedAtDevice']),
      name: serializer.fromJson<String>(json['name']),
      locationNote: serializer.fromJson<String?>(json['locationNote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'associationId': serializer.toJson<String>(associationId),
      'enteredBy': serializer.toJson<String>(enteredBy),
      'observedBy': serializer.toJson<String?>(observedBy),
      'createdAtDevice': serializer.toJson<DateTime>(createdAtDevice),
      'deviceId': serializer.toJson<String>(deviceId),
      'serverReceivedAt': serializer.toJson<DateTime?>(serverReceivedAt),
      'serverSeq': serializer.toJson<int?>(serverSeq),
      'syncState': serializer.toJson<String>(
        $SitesTable.$convertersyncState.toJson(syncState),
      ),
      'syncError': serializer.toJson<String?>(syncError),
      'updatedAtDevice': serializer.toJson<DateTime>(updatedAtDevice),
      'name': serializer.toJson<String>(name),
      'locationNote': serializer.toJson<String?>(locationNote),
    };
  }

  Site copyWith({
    String? id,
    String? associationId,
    String? enteredBy,
    Value<String?> observedBy = const Value.absent(),
    DateTime? createdAtDevice,
    String? deviceId,
    Value<DateTime?> serverReceivedAt = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    SyncState? syncState,
    Value<String?> syncError = const Value.absent(),
    DateTime? updatedAtDevice,
    String? name,
    Value<String?> locationNote = const Value.absent(),
  }) => Site(
    id: id ?? this.id,
    associationId: associationId ?? this.associationId,
    enteredBy: enteredBy ?? this.enteredBy,
    observedBy: observedBy.present ? observedBy.value : this.observedBy,
    createdAtDevice: createdAtDevice ?? this.createdAtDevice,
    deviceId: deviceId ?? this.deviceId,
    serverReceivedAt: serverReceivedAt.present
        ? serverReceivedAt.value
        : this.serverReceivedAt,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    syncState: syncState ?? this.syncState,
    syncError: syncError.present ? syncError.value : this.syncError,
    updatedAtDevice: updatedAtDevice ?? this.updatedAtDevice,
    name: name ?? this.name,
    locationNote: locationNote.present ? locationNote.value : this.locationNote,
  );
  Site copyWithCompanion(SitesCompanion data) {
    return Site(
      id: data.id.present ? data.id.value : this.id,
      associationId: data.associationId.present
          ? data.associationId.value
          : this.associationId,
      enteredBy: data.enteredBy.present ? data.enteredBy.value : this.enteredBy,
      observedBy: data.observedBy.present
          ? data.observedBy.value
          : this.observedBy,
      createdAtDevice: data.createdAtDevice.present
          ? data.createdAtDevice.value
          : this.createdAtDevice,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      serverReceivedAt: data.serverReceivedAt.present
          ? data.serverReceivedAt.value
          : this.serverReceivedAt,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      updatedAtDevice: data.updatedAtDevice.present
          ? data.updatedAtDevice.value
          : this.updatedAtDevice,
      name: data.name.present ? data.name.value : this.name,
      locationNote: data.locationNote.present
          ? data.locationNote.value
          : this.locationNote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Site(')
          ..write('id: $id, ')
          ..write('associationId: $associationId, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('observedBy: $observedBy, ')
          ..write('createdAtDevice: $createdAtDevice, ')
          ..write('deviceId: $deviceId, ')
          ..write('serverReceivedAt: $serverReceivedAt, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('updatedAtDevice: $updatedAtDevice, ')
          ..write('name: $name, ')
          ..write('locationNote: $locationNote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    associationId,
    enteredBy,
    observedBy,
    createdAtDevice,
    deviceId,
    serverReceivedAt,
    serverSeq,
    syncState,
    syncError,
    updatedAtDevice,
    name,
    locationNote,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Site &&
          other.id == this.id &&
          other.associationId == this.associationId &&
          other.enteredBy == this.enteredBy &&
          other.observedBy == this.observedBy &&
          other.createdAtDevice == this.createdAtDevice &&
          other.deviceId == this.deviceId &&
          other.serverReceivedAt == this.serverReceivedAt &&
          other.serverSeq == this.serverSeq &&
          other.syncState == this.syncState &&
          other.syncError == this.syncError &&
          other.updatedAtDevice == this.updatedAtDevice &&
          other.name == this.name &&
          other.locationNote == this.locationNote);
}

class SitesCompanion extends UpdateCompanion<Site> {
  final Value<String> id;
  final Value<String> associationId;
  final Value<String> enteredBy;
  final Value<String?> observedBy;
  final Value<DateTime> createdAtDevice;
  final Value<String> deviceId;
  final Value<DateTime?> serverReceivedAt;
  final Value<int?> serverSeq;
  final Value<SyncState> syncState;
  final Value<String?> syncError;
  final Value<DateTime> updatedAtDevice;
  final Value<String> name;
  final Value<String?> locationNote;
  final Value<int> rowid;
  const SitesCompanion({
    this.id = const Value.absent(),
    this.associationId = const Value.absent(),
    this.enteredBy = const Value.absent(),
    this.observedBy = const Value.absent(),
    this.createdAtDevice = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.serverReceivedAt = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncError = const Value.absent(),
    this.updatedAtDevice = const Value.absent(),
    this.name = const Value.absent(),
    this.locationNote = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SitesCompanion.insert({
    this.id = const Value.absent(),
    required String associationId,
    required String enteredBy,
    this.observedBy = const Value.absent(),
    this.createdAtDevice = const Value.absent(),
    required String deviceId,
    this.serverReceivedAt = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncError = const Value.absent(),
    this.updatedAtDevice = const Value.absent(),
    required String name,
    this.locationNote = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : associationId = Value(associationId),
       enteredBy = Value(enteredBy),
       deviceId = Value(deviceId),
       name = Value(name);
  static Insertable<Site> custom({
    Expression<String>? id,
    Expression<String>? associationId,
    Expression<String>? enteredBy,
    Expression<String>? observedBy,
    Expression<DateTime>? createdAtDevice,
    Expression<String>? deviceId,
    Expression<DateTime>? serverReceivedAt,
    Expression<int>? serverSeq,
    Expression<String>? syncState,
    Expression<String>? syncError,
    Expression<DateTime>? updatedAtDevice,
    Expression<String>? name,
    Expression<String>? locationNote,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (associationId != null) 'association_id': associationId,
      if (enteredBy != null) 'entered_by': enteredBy,
      if (observedBy != null) 'observed_by': observedBy,
      if (createdAtDevice != null) 'created_at_device': createdAtDevice,
      if (deviceId != null) 'device_id': deviceId,
      if (serverReceivedAt != null) 'server_received_at': serverReceivedAt,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (syncState != null) 'sync_state': syncState,
      if (syncError != null) 'sync_error': syncError,
      if (updatedAtDevice != null) 'updated_at_device': updatedAtDevice,
      if (name != null) 'name': name,
      if (locationNote != null) 'location_note': locationNote,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SitesCompanion copyWith({
    Value<String>? id,
    Value<String>? associationId,
    Value<String>? enteredBy,
    Value<String?>? observedBy,
    Value<DateTime>? createdAtDevice,
    Value<String>? deviceId,
    Value<DateTime?>? serverReceivedAt,
    Value<int?>? serverSeq,
    Value<SyncState>? syncState,
    Value<String?>? syncError,
    Value<DateTime>? updatedAtDevice,
    Value<String>? name,
    Value<String?>? locationNote,
    Value<int>? rowid,
  }) {
    return SitesCompanion(
      id: id ?? this.id,
      associationId: associationId ?? this.associationId,
      enteredBy: enteredBy ?? this.enteredBy,
      observedBy: observedBy ?? this.observedBy,
      createdAtDevice: createdAtDevice ?? this.createdAtDevice,
      deviceId: deviceId ?? this.deviceId,
      serverReceivedAt: serverReceivedAt ?? this.serverReceivedAt,
      serverSeq: serverSeq ?? this.serverSeq,
      syncState: syncState ?? this.syncState,
      syncError: syncError ?? this.syncError,
      updatedAtDevice: updatedAtDevice ?? this.updatedAtDevice,
      name: name ?? this.name,
      locationNote: locationNote ?? this.locationNote,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (associationId.present) {
      map['association_id'] = Variable<String>(associationId.value);
    }
    if (enteredBy.present) {
      map['entered_by'] = Variable<String>(enteredBy.value);
    }
    if (observedBy.present) {
      map['observed_by'] = Variable<String>(observedBy.value);
    }
    if (createdAtDevice.present) {
      map['created_at_device'] = Variable<DateTime>(createdAtDevice.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (serverReceivedAt.present) {
      map['server_received_at'] = Variable<DateTime>(serverReceivedAt.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $SitesTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (updatedAtDevice.present) {
      map['updated_at_device'] = Variable<DateTime>(updatedAtDevice.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (locationNote.present) {
      map['location_note'] = Variable<String>(locationNote.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SitesCompanion(')
          ..write('id: $id, ')
          ..write('associationId: $associationId, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('observedBy: $observedBy, ')
          ..write('createdAtDevice: $createdAtDevice, ')
          ..write('deviceId: $deviceId, ')
          ..write('serverReceivedAt: $serverReceivedAt, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('updatedAtDevice: $updatedAtDevice, ')
          ..write('name: $name, ')
          ..write('locationNote: $locationNote, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMetaTable extends LocalMeta
    with TableInfo<$LocalMetaTable, LocalMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMetaData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $LocalMetaTable createAlias(String alias) {
    return $LocalMetaTable(attachedDatabase, alias);
  }
}

class LocalMetaData extends DataClass implements Insertable<LocalMetaData> {
  final String key;
  final String value;
  const LocalMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalMetaCompanion toCompanion(bool nullToAbsent) {
    return LocalMetaCompanion(key: Value(key), value: Value(value));
  }

  factory LocalMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMetaData(
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

  LocalMetaData copyWith({String? key, String? value}) =>
      LocalMetaData(key: key ?? this.key, value: value ?? this.value);
  LocalMetaData copyWithCompanion(LocalMetaCompanion data) {
    return LocalMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMetaData(')
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
      (other is LocalMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class LocalMetaCompanion extends UpdateCompanion<LocalMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const LocalMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<LocalMetaData> custom({
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

  LocalMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return LocalMetaCompanion(
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
    return (StringBuffer('LocalMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeopleTable extends People with TableInfo<$PeopleTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _associationIdMeta = const VerificationMeta(
    'associationId',
  );
  @override
  late final GeneratedColumn<String> associationId = GeneratedColumn<String>(
    'association_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enteredByMeta = const VerificationMeta(
    'enteredBy',
  );
  @override
  late final GeneratedColumn<String> enteredBy = GeneratedColumn<String>(
    'entered_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observedByMeta = const VerificationMeta(
    'observedBy',
  );
  @override
  late final GeneratedColumn<String> observedBy = GeneratedColumn<String>(
    'observed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtDeviceMeta = const VerificationMeta(
    'createdAtDevice',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtDevice =
      GeneratedColumn<DateTime>(
        'created_at_device',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        clientDefault: utcNow,
      );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverReceivedAtMeta = const VerificationMeta(
    'serverReceivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverReceivedAt =
      GeneratedColumn<DateTime>(
        'server_received_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.pending.name),
      ).withConverter<SyncState>($PeopleTable.$convertersyncState);
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtDeviceMeta = const VerificationMeta(
    'updatedAtDevice',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtDevice =
      GeneratedColumn<DateTime>(
        'updated_at_device',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        clientDefault: utcNow,
      );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    associationId,
    enteredBy,
    observedBy,
    createdAtDevice,
    deviceId,
    serverReceivedAt,
    serverSeq,
    syncState,
    syncError,
    updatedAtDevice,
    name,
    phone,
    note,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people';
  @override
  VerificationContext validateIntegrity(
    Insertable<Person> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('association_id')) {
      context.handle(
        _associationIdMeta,
        associationId.isAcceptableOrUnknown(
          data['association_id']!,
          _associationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_associationIdMeta);
    }
    if (data.containsKey('entered_by')) {
      context.handle(
        _enteredByMeta,
        enteredBy.isAcceptableOrUnknown(data['entered_by']!, _enteredByMeta),
      );
    } else if (isInserting) {
      context.missing(_enteredByMeta);
    }
    if (data.containsKey('observed_by')) {
      context.handle(
        _observedByMeta,
        observedBy.isAcceptableOrUnknown(data['observed_by']!, _observedByMeta),
      );
    }
    if (data.containsKey('created_at_device')) {
      context.handle(
        _createdAtDeviceMeta,
        createdAtDevice.isAcceptableOrUnknown(
          data['created_at_device']!,
          _createdAtDeviceMeta,
        ),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('server_received_at')) {
      context.handle(
        _serverReceivedAtMeta,
        serverReceivedAt.isAcceptableOrUnknown(
          data['server_received_at']!,
          _serverReceivedAtMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('updated_at_device')) {
      context.handle(
        _updatedAtDeviceMeta,
        updatedAtDevice.isAcceptableOrUnknown(
          data['updated_at_device']!,
          _updatedAtDeviceMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      associationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}association_id'],
      )!,
      enteredBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entered_by'],
      )!,
      observedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observed_by'],
      ),
      createdAtDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_device'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      serverReceivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_received_at'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      syncState: $PeopleTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      updatedAtDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_device'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $PeopleTable createAlias(String alias) {
    return $PeopleTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class Person extends DataClass implements Insertable<Person> {
  final String id;
  final String associationId;
  final String enteredBy;
  final String? observedBy;
  final DateTime createdAtDevice;
  final String deviceId;
  final DateTime? serverReceivedAt;
  final int? serverSeq;
  final SyncState syncState;
  final String? syncError;
  final DateTime updatedAtDevice;
  final String name;
  final String? phone;
  final String? note;
  final bool active;
  const Person({
    required this.id,
    required this.associationId,
    required this.enteredBy,
    this.observedBy,
    required this.createdAtDevice,
    required this.deviceId,
    this.serverReceivedAt,
    this.serverSeq,
    required this.syncState,
    this.syncError,
    required this.updatedAtDevice,
    required this.name,
    this.phone,
    this.note,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['association_id'] = Variable<String>(associationId);
    map['entered_by'] = Variable<String>(enteredBy);
    if (!nullToAbsent || observedBy != null) {
      map['observed_by'] = Variable<String>(observedBy);
    }
    map['created_at_device'] = Variable<DateTime>(createdAtDevice);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || serverReceivedAt != null) {
      map['server_received_at'] = Variable<DateTime>(serverReceivedAt);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    {
      map['sync_state'] = Variable<String>(
        $PeopleTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['updated_at_device'] = Variable<DateTime>(updatedAtDevice);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['active'] = Variable<bool>(active);
    return map;
  }

  PeopleCompanion toCompanion(bool nullToAbsent) {
    return PeopleCompanion(
      id: Value(id),
      associationId: Value(associationId),
      enteredBy: Value(enteredBy),
      observedBy: observedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(observedBy),
      createdAtDevice: Value(createdAtDevice),
      deviceId: Value(deviceId),
      serverReceivedAt: serverReceivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverReceivedAt),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      syncState: Value(syncState),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      updatedAtDevice: Value(updatedAtDevice),
      name: Value(name),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      active: Value(active),
    );
  }

  factory Person.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      id: serializer.fromJson<String>(json['id']),
      associationId: serializer.fromJson<String>(json['associationId']),
      enteredBy: serializer.fromJson<String>(json['enteredBy']),
      observedBy: serializer.fromJson<String?>(json['observedBy']),
      createdAtDevice: serializer.fromJson<DateTime>(json['createdAtDevice']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      serverReceivedAt: serializer.fromJson<DateTime?>(
        json['serverReceivedAt'],
      ),
      serverSeq: serializer.fromJson<int?>(json['serverSeq']),
      syncState: $PeopleTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      syncError: serializer.fromJson<String?>(json['syncError']),
      updatedAtDevice: serializer.fromJson<DateTime>(json['updatedAtDevice']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      note: serializer.fromJson<String?>(json['note']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'associationId': serializer.toJson<String>(associationId),
      'enteredBy': serializer.toJson<String>(enteredBy),
      'observedBy': serializer.toJson<String?>(observedBy),
      'createdAtDevice': serializer.toJson<DateTime>(createdAtDevice),
      'deviceId': serializer.toJson<String>(deviceId),
      'serverReceivedAt': serializer.toJson<DateTime?>(serverReceivedAt),
      'serverSeq': serializer.toJson<int?>(serverSeq),
      'syncState': serializer.toJson<String>(
        $PeopleTable.$convertersyncState.toJson(syncState),
      ),
      'syncError': serializer.toJson<String?>(syncError),
      'updatedAtDevice': serializer.toJson<DateTime>(updatedAtDevice),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'note': serializer.toJson<String?>(note),
      'active': serializer.toJson<bool>(active),
    };
  }

  Person copyWith({
    String? id,
    String? associationId,
    String? enteredBy,
    Value<String?> observedBy = const Value.absent(),
    DateTime? createdAtDevice,
    String? deviceId,
    Value<DateTime?> serverReceivedAt = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    SyncState? syncState,
    Value<String?> syncError = const Value.absent(),
    DateTime? updatedAtDevice,
    String? name,
    Value<String?> phone = const Value.absent(),
    Value<String?> note = const Value.absent(),
    bool? active,
  }) => Person(
    id: id ?? this.id,
    associationId: associationId ?? this.associationId,
    enteredBy: enteredBy ?? this.enteredBy,
    observedBy: observedBy.present ? observedBy.value : this.observedBy,
    createdAtDevice: createdAtDevice ?? this.createdAtDevice,
    deviceId: deviceId ?? this.deviceId,
    serverReceivedAt: serverReceivedAt.present
        ? serverReceivedAt.value
        : this.serverReceivedAt,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    syncState: syncState ?? this.syncState,
    syncError: syncError.present ? syncError.value : this.syncError,
    updatedAtDevice: updatedAtDevice ?? this.updatedAtDevice,
    name: name ?? this.name,
    phone: phone.present ? phone.value : this.phone,
    note: note.present ? note.value : this.note,
    active: active ?? this.active,
  );
  Person copyWithCompanion(PeopleCompanion data) {
    return Person(
      id: data.id.present ? data.id.value : this.id,
      associationId: data.associationId.present
          ? data.associationId.value
          : this.associationId,
      enteredBy: data.enteredBy.present ? data.enteredBy.value : this.enteredBy,
      observedBy: data.observedBy.present
          ? data.observedBy.value
          : this.observedBy,
      createdAtDevice: data.createdAtDevice.present
          ? data.createdAtDevice.value
          : this.createdAtDevice,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      serverReceivedAt: data.serverReceivedAt.present
          ? data.serverReceivedAt.value
          : this.serverReceivedAt,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      updatedAtDevice: data.updatedAtDevice.present
          ? data.updatedAtDevice.value
          : this.updatedAtDevice,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      note: data.note.present ? data.note.value : this.note,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('id: $id, ')
          ..write('associationId: $associationId, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('observedBy: $observedBy, ')
          ..write('createdAtDevice: $createdAtDevice, ')
          ..write('deviceId: $deviceId, ')
          ..write('serverReceivedAt: $serverReceivedAt, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('updatedAtDevice: $updatedAtDevice, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('note: $note, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    associationId,
    enteredBy,
    observedBy,
    createdAtDevice,
    deviceId,
    serverReceivedAt,
    serverSeq,
    syncState,
    syncError,
    updatedAtDevice,
    name,
    phone,
    note,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.id == this.id &&
          other.associationId == this.associationId &&
          other.enteredBy == this.enteredBy &&
          other.observedBy == this.observedBy &&
          other.createdAtDevice == this.createdAtDevice &&
          other.deviceId == this.deviceId &&
          other.serverReceivedAt == this.serverReceivedAt &&
          other.serverSeq == this.serverSeq &&
          other.syncState == this.syncState &&
          other.syncError == this.syncError &&
          other.updatedAtDevice == this.updatedAtDevice &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.note == this.note &&
          other.active == this.active);
}

class PeopleCompanion extends UpdateCompanion<Person> {
  final Value<String> id;
  final Value<String> associationId;
  final Value<String> enteredBy;
  final Value<String?> observedBy;
  final Value<DateTime> createdAtDevice;
  final Value<String> deviceId;
  final Value<DateTime?> serverReceivedAt;
  final Value<int?> serverSeq;
  final Value<SyncState> syncState;
  final Value<String?> syncError;
  final Value<DateTime> updatedAtDevice;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String?> note;
  final Value<bool> active;
  final Value<int> rowid;
  const PeopleCompanion({
    this.id = const Value.absent(),
    this.associationId = const Value.absent(),
    this.enteredBy = const Value.absent(),
    this.observedBy = const Value.absent(),
    this.createdAtDevice = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.serverReceivedAt = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncError = const Value.absent(),
    this.updatedAtDevice = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.note = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeopleCompanion.insert({
    this.id = const Value.absent(),
    required String associationId,
    required String enteredBy,
    this.observedBy = const Value.absent(),
    this.createdAtDevice = const Value.absent(),
    required String deviceId,
    this.serverReceivedAt = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncError = const Value.absent(),
    this.updatedAtDevice = const Value.absent(),
    required String name,
    this.phone = const Value.absent(),
    this.note = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : associationId = Value(associationId),
       enteredBy = Value(enteredBy),
       deviceId = Value(deviceId),
       name = Value(name);
  static Insertable<Person> custom({
    Expression<String>? id,
    Expression<String>? associationId,
    Expression<String>? enteredBy,
    Expression<String>? observedBy,
    Expression<DateTime>? createdAtDevice,
    Expression<String>? deviceId,
    Expression<DateTime>? serverReceivedAt,
    Expression<int>? serverSeq,
    Expression<String>? syncState,
    Expression<String>? syncError,
    Expression<DateTime>? updatedAtDevice,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? note,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (associationId != null) 'association_id': associationId,
      if (enteredBy != null) 'entered_by': enteredBy,
      if (observedBy != null) 'observed_by': observedBy,
      if (createdAtDevice != null) 'created_at_device': createdAtDevice,
      if (deviceId != null) 'device_id': deviceId,
      if (serverReceivedAt != null) 'server_received_at': serverReceivedAt,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (syncState != null) 'sync_state': syncState,
      if (syncError != null) 'sync_error': syncError,
      if (updatedAtDevice != null) 'updated_at_device': updatedAtDevice,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (note != null) 'note': note,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeopleCompanion copyWith({
    Value<String>? id,
    Value<String>? associationId,
    Value<String>? enteredBy,
    Value<String?>? observedBy,
    Value<DateTime>? createdAtDevice,
    Value<String>? deviceId,
    Value<DateTime?>? serverReceivedAt,
    Value<int?>? serverSeq,
    Value<SyncState>? syncState,
    Value<String?>? syncError,
    Value<DateTime>? updatedAtDevice,
    Value<String>? name,
    Value<String?>? phone,
    Value<String?>? note,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return PeopleCompanion(
      id: id ?? this.id,
      associationId: associationId ?? this.associationId,
      enteredBy: enteredBy ?? this.enteredBy,
      observedBy: observedBy ?? this.observedBy,
      createdAtDevice: createdAtDevice ?? this.createdAtDevice,
      deviceId: deviceId ?? this.deviceId,
      serverReceivedAt: serverReceivedAt ?? this.serverReceivedAt,
      serverSeq: serverSeq ?? this.serverSeq,
      syncState: syncState ?? this.syncState,
      syncError: syncError ?? this.syncError,
      updatedAtDevice: updatedAtDevice ?? this.updatedAtDevice,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (associationId.present) {
      map['association_id'] = Variable<String>(associationId.value);
    }
    if (enteredBy.present) {
      map['entered_by'] = Variable<String>(enteredBy.value);
    }
    if (observedBy.present) {
      map['observed_by'] = Variable<String>(observedBy.value);
    }
    if (createdAtDevice.present) {
      map['created_at_device'] = Variable<DateTime>(createdAtDevice.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (serverReceivedAt.present) {
      map['server_received_at'] = Variable<DateTime>(serverReceivedAt.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $PeopleTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (updatedAtDevice.present) {
      map['updated_at_device'] = Variable<DateTime>(updatedAtDevice.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCompanion(')
          ..write('id: $id, ')
          ..write('associationId: $associationId, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('observedBy: $observedBy, ')
          ..write('createdAtDevice: $createdAtDevice, ')
          ..write('deviceId: $deviceId, ')
          ..write('serverReceivedAt: $serverReceivedAt, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('updatedAtDevice: $updatedAtDevice, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('note: $note, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PondsTable extends Ponds with TableInfo<$PondsTable, Pond> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PondsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _associationIdMeta = const VerificationMeta(
    'associationId',
  );
  @override
  late final GeneratedColumn<String> associationId = GeneratedColumn<String>(
    'association_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enteredByMeta = const VerificationMeta(
    'enteredBy',
  );
  @override
  late final GeneratedColumn<String> enteredBy = GeneratedColumn<String>(
    'entered_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observedByMeta = const VerificationMeta(
    'observedBy',
  );
  @override
  late final GeneratedColumn<String> observedBy = GeneratedColumn<String>(
    'observed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtDeviceMeta = const VerificationMeta(
    'createdAtDevice',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtDevice =
      GeneratedColumn<DateTime>(
        'created_at_device',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        clientDefault: utcNow,
      );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverReceivedAtMeta = const VerificationMeta(
    'serverReceivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverReceivedAt =
      GeneratedColumn<DateTime>(
        'server_received_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.pending.name),
      ).withConverter<SyncState>($PondsTable.$convertersyncState);
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtDeviceMeta = const VerificationMeta(
    'updatedAtDevice',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtDevice =
      GeneratedColumn<DateTime>(
        'updated_at_device',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        clientDefault: utcNow,
      );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<String> siteId = GeneratedColumn<String>(
    'site_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PondColour, String> colour =
      GeneratedColumn<String>(
        'colour',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PondColour>($PondsTable.$convertercolour);
  @override
  late final GeneratedColumnWithTypeConverter<StructureType, String> structure =
      GeneratedColumn<String>(
        'structure',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(StructureType.earth.name),
      ).withConverter<StructureType>($PondsTable.$converterstructure);
  @override
  late final GeneratedColumnWithTypeConverter<PondRole, String> role =
      GeneratedColumn<String>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PondRole>($PondsTable.$converterrole);
  @override
  late final GeneratedColumnWithTypeConverter<WaterSupply?, String>
  waterSupply = GeneratedColumn<String>(
    'water_supply',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<WaterSupply?>($PondsTable.$converterwaterSupplyn);
  static const VerificationMeta _lengthMMeta = const VerificationMeta(
    'lengthM',
  );
  @override
  late final GeneratedColumn<double> lengthM = GeneratedColumn<double>(
    'length_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _widthMMeta = const VerificationMeta('widthM');
  @override
  late final GeneratedColumn<double> widthM = GeneratedColumn<double>(
    'width_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _surfaceM2OverrideMeta = const VerificationMeta(
    'surfaceM2Override',
  );
  @override
  late final GeneratedColumn<double> surfaceM2Override =
      GeneratedColumn<double>(
        'surface_m2_override',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _depthInletMMeta = const VerificationMeta(
    'depthInletM',
  );
  @override
  late final GeneratedColumn<double> depthInletM = GeneratedColumn<double>(
    'depth_inlet_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _depthOutletMMeta = const VerificationMeta(
    'depthOutletM',
  );
  @override
  late final GeneratedColumn<double> depthOutletM = GeneratedColumn<double>(
    'depth_outlet_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PondStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(PondStatus.empty.name),
      ).withConverter<PondStatus>($PondsTable.$converterstatus);
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    associationId,
    enteredBy,
    observedBy,
    createdAtDevice,
    deviceId,
    serverReceivedAt,
    serverSeq,
    syncState,
    syncError,
    updatedAtDevice,
    siteId,
    code,
    colour,
    structure,
    role,
    waterSupply,
    lengthM,
    widthM,
    surfaceM2Override,
    depthInletM,
    depthOutletM,
    status,
    archived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ponds';
  @override
  VerificationContext validateIntegrity(
    Insertable<Pond> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('association_id')) {
      context.handle(
        _associationIdMeta,
        associationId.isAcceptableOrUnknown(
          data['association_id']!,
          _associationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_associationIdMeta);
    }
    if (data.containsKey('entered_by')) {
      context.handle(
        _enteredByMeta,
        enteredBy.isAcceptableOrUnknown(data['entered_by']!, _enteredByMeta),
      );
    } else if (isInserting) {
      context.missing(_enteredByMeta);
    }
    if (data.containsKey('observed_by')) {
      context.handle(
        _observedByMeta,
        observedBy.isAcceptableOrUnknown(data['observed_by']!, _observedByMeta),
      );
    }
    if (data.containsKey('created_at_device')) {
      context.handle(
        _createdAtDeviceMeta,
        createdAtDevice.isAcceptableOrUnknown(
          data['created_at_device']!,
          _createdAtDeviceMeta,
        ),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('server_received_at')) {
      context.handle(
        _serverReceivedAtMeta,
        serverReceivedAt.isAcceptableOrUnknown(
          data['server_received_at']!,
          _serverReceivedAtMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('updated_at_device')) {
      context.handle(
        _updatedAtDeviceMeta,
        updatedAtDevice.isAcceptableOrUnknown(
          data['updated_at_device']!,
          _updatedAtDeviceMeta,
        ),
      );
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('length_m')) {
      context.handle(
        _lengthMMeta,
        lengthM.isAcceptableOrUnknown(data['length_m']!, _lengthMMeta),
      );
    }
    if (data.containsKey('width_m')) {
      context.handle(
        _widthMMeta,
        widthM.isAcceptableOrUnknown(data['width_m']!, _widthMMeta),
      );
    }
    if (data.containsKey('surface_m2_override')) {
      context.handle(
        _surfaceM2OverrideMeta,
        surfaceM2Override.isAcceptableOrUnknown(
          data['surface_m2_override']!,
          _surfaceM2OverrideMeta,
        ),
      );
    }
    if (data.containsKey('depth_inlet_m')) {
      context.handle(
        _depthInletMMeta,
        depthInletM.isAcceptableOrUnknown(
          data['depth_inlet_m']!,
          _depthInletMMeta,
        ),
      );
    }
    if (data.containsKey('depth_outlet_m')) {
      context.handle(
        _depthOutletMMeta,
        depthOutletM.isAcceptableOrUnknown(
          data['depth_outlet_m']!,
          _depthOutletMMeta,
        ),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Pond map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pond(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      associationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}association_id'],
      )!,
      enteredBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entered_by'],
      )!,
      observedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observed_by'],
      ),
      createdAtDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_device'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      serverReceivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_received_at'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      syncState: $PondsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      updatedAtDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_device'],
      )!,
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      colour: $PondsTable.$convertercolour.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}colour'],
        )!,
      ),
      structure: $PondsTable.$converterstructure.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}structure'],
        )!,
      ),
      role: $PondsTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}role'],
        )!,
      ),
      waterSupply: $PondsTable.$converterwaterSupplyn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}water_supply'],
        ),
      ),
      lengthM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}length_m'],
      ),
      widthM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}width_m'],
      ),
      surfaceM2Override: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}surface_m2_override'],
      ),
      depthInletM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}depth_inlet_m'],
      ),
      depthOutletM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}depth_outlet_m'],
      ),
      status: $PondsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $PondsTable createAlias(String alias) {
    return $PondsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
  static JsonTypeConverter2<PondColour, String, String> $convertercolour =
      const EnumNameConverter<PondColour>(PondColour.values);
  static JsonTypeConverter2<StructureType, String, String> $converterstructure =
      const EnumNameConverter<StructureType>(StructureType.values);
  static JsonTypeConverter2<PondRole, String, String> $converterrole =
      const EnumNameConverter<PondRole>(PondRole.values);
  static JsonTypeConverter2<WaterSupply, String, String> $converterwaterSupply =
      const EnumNameConverter<WaterSupply>(WaterSupply.values);
  static JsonTypeConverter2<WaterSupply?, String?, String?>
  $converterwaterSupplyn = JsonTypeConverter2.asNullable($converterwaterSupply);
  static JsonTypeConverter2<PondStatus, String, String> $converterstatus =
      const EnumNameConverter<PondStatus>(PondStatus.values);
}

class Pond extends DataClass implements Insertable<Pond> {
  final String id;
  final String associationId;
  final String enteredBy;
  final String? observedBy;
  final DateTime createdAtDevice;
  final String deviceId;
  final DateTime? serverReceivedAt;
  final int? serverSeq;
  final SyncState syncState;
  final String? syncError;
  final DateTime updatedAtDevice;
  final String siteId;
  final String code;
  final PondColour colour;
  final StructureType structure;
  final PondRole role;
  final WaterSupply? waterSupply;
  final double? lengthM;
  final double? widthM;
  final double? surfaceM2Override;
  final double? depthInletM;
  final double? depthOutletM;
  final PondStatus status;
  final bool archived;
  const Pond({
    required this.id,
    required this.associationId,
    required this.enteredBy,
    this.observedBy,
    required this.createdAtDevice,
    required this.deviceId,
    this.serverReceivedAt,
    this.serverSeq,
    required this.syncState,
    this.syncError,
    required this.updatedAtDevice,
    required this.siteId,
    required this.code,
    required this.colour,
    required this.structure,
    required this.role,
    this.waterSupply,
    this.lengthM,
    this.widthM,
    this.surfaceM2Override,
    this.depthInletM,
    this.depthOutletM,
    required this.status,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['association_id'] = Variable<String>(associationId);
    map['entered_by'] = Variable<String>(enteredBy);
    if (!nullToAbsent || observedBy != null) {
      map['observed_by'] = Variable<String>(observedBy);
    }
    map['created_at_device'] = Variable<DateTime>(createdAtDevice);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || serverReceivedAt != null) {
      map['server_received_at'] = Variable<DateTime>(serverReceivedAt);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    {
      map['sync_state'] = Variable<String>(
        $PondsTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['updated_at_device'] = Variable<DateTime>(updatedAtDevice);
    map['site_id'] = Variable<String>(siteId);
    map['code'] = Variable<String>(code);
    {
      map['colour'] = Variable<String>(
        $PondsTable.$convertercolour.toSql(colour),
      );
    }
    {
      map['structure'] = Variable<String>(
        $PondsTable.$converterstructure.toSql(structure),
      );
    }
    {
      map['role'] = Variable<String>($PondsTable.$converterrole.toSql(role));
    }
    if (!nullToAbsent || waterSupply != null) {
      map['water_supply'] = Variable<String>(
        $PondsTable.$converterwaterSupplyn.toSql(waterSupply),
      );
    }
    if (!nullToAbsent || lengthM != null) {
      map['length_m'] = Variable<double>(lengthM);
    }
    if (!nullToAbsent || widthM != null) {
      map['width_m'] = Variable<double>(widthM);
    }
    if (!nullToAbsent || surfaceM2Override != null) {
      map['surface_m2_override'] = Variable<double>(surfaceM2Override);
    }
    if (!nullToAbsent || depthInletM != null) {
      map['depth_inlet_m'] = Variable<double>(depthInletM);
    }
    if (!nullToAbsent || depthOutletM != null) {
      map['depth_outlet_m'] = Variable<double>(depthOutletM);
    }
    {
      map['status'] = Variable<String>(
        $PondsTable.$converterstatus.toSql(status),
      );
    }
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  PondsCompanion toCompanion(bool nullToAbsent) {
    return PondsCompanion(
      id: Value(id),
      associationId: Value(associationId),
      enteredBy: Value(enteredBy),
      observedBy: observedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(observedBy),
      createdAtDevice: Value(createdAtDevice),
      deviceId: Value(deviceId),
      serverReceivedAt: serverReceivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverReceivedAt),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      syncState: Value(syncState),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      updatedAtDevice: Value(updatedAtDevice),
      siteId: Value(siteId),
      code: Value(code),
      colour: Value(colour),
      structure: Value(structure),
      role: Value(role),
      waterSupply: waterSupply == null && nullToAbsent
          ? const Value.absent()
          : Value(waterSupply),
      lengthM: lengthM == null && nullToAbsent
          ? const Value.absent()
          : Value(lengthM),
      widthM: widthM == null && nullToAbsent
          ? const Value.absent()
          : Value(widthM),
      surfaceM2Override: surfaceM2Override == null && nullToAbsent
          ? const Value.absent()
          : Value(surfaceM2Override),
      depthInletM: depthInletM == null && nullToAbsent
          ? const Value.absent()
          : Value(depthInletM),
      depthOutletM: depthOutletM == null && nullToAbsent
          ? const Value.absent()
          : Value(depthOutletM),
      status: Value(status),
      archived: Value(archived),
    );
  }

  factory Pond.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pond(
      id: serializer.fromJson<String>(json['id']),
      associationId: serializer.fromJson<String>(json['associationId']),
      enteredBy: serializer.fromJson<String>(json['enteredBy']),
      observedBy: serializer.fromJson<String?>(json['observedBy']),
      createdAtDevice: serializer.fromJson<DateTime>(json['createdAtDevice']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      serverReceivedAt: serializer.fromJson<DateTime?>(
        json['serverReceivedAt'],
      ),
      serverSeq: serializer.fromJson<int?>(json['serverSeq']),
      syncState: $PondsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      syncError: serializer.fromJson<String?>(json['syncError']),
      updatedAtDevice: serializer.fromJson<DateTime>(json['updatedAtDevice']),
      siteId: serializer.fromJson<String>(json['siteId']),
      code: serializer.fromJson<String>(json['code']),
      colour: $PondsTable.$convertercolour.fromJson(
        serializer.fromJson<String>(json['colour']),
      ),
      structure: $PondsTable.$converterstructure.fromJson(
        serializer.fromJson<String>(json['structure']),
      ),
      role: $PondsTable.$converterrole.fromJson(
        serializer.fromJson<String>(json['role']),
      ),
      waterSupply: $PondsTable.$converterwaterSupplyn.fromJson(
        serializer.fromJson<String?>(json['waterSupply']),
      ),
      lengthM: serializer.fromJson<double?>(json['lengthM']),
      widthM: serializer.fromJson<double?>(json['widthM']),
      surfaceM2Override: serializer.fromJson<double?>(
        json['surfaceM2Override'],
      ),
      depthInletM: serializer.fromJson<double?>(json['depthInletM']),
      depthOutletM: serializer.fromJson<double?>(json['depthOutletM']),
      status: $PondsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'associationId': serializer.toJson<String>(associationId),
      'enteredBy': serializer.toJson<String>(enteredBy),
      'observedBy': serializer.toJson<String?>(observedBy),
      'createdAtDevice': serializer.toJson<DateTime>(createdAtDevice),
      'deviceId': serializer.toJson<String>(deviceId),
      'serverReceivedAt': serializer.toJson<DateTime?>(serverReceivedAt),
      'serverSeq': serializer.toJson<int?>(serverSeq),
      'syncState': serializer.toJson<String>(
        $PondsTable.$convertersyncState.toJson(syncState),
      ),
      'syncError': serializer.toJson<String?>(syncError),
      'updatedAtDevice': serializer.toJson<DateTime>(updatedAtDevice),
      'siteId': serializer.toJson<String>(siteId),
      'code': serializer.toJson<String>(code),
      'colour': serializer.toJson<String>(
        $PondsTable.$convertercolour.toJson(colour),
      ),
      'structure': serializer.toJson<String>(
        $PondsTable.$converterstructure.toJson(structure),
      ),
      'role': serializer.toJson<String>(
        $PondsTable.$converterrole.toJson(role),
      ),
      'waterSupply': serializer.toJson<String?>(
        $PondsTable.$converterwaterSupplyn.toJson(waterSupply),
      ),
      'lengthM': serializer.toJson<double?>(lengthM),
      'widthM': serializer.toJson<double?>(widthM),
      'surfaceM2Override': serializer.toJson<double?>(surfaceM2Override),
      'depthInletM': serializer.toJson<double?>(depthInletM),
      'depthOutletM': serializer.toJson<double?>(depthOutletM),
      'status': serializer.toJson<String>(
        $PondsTable.$converterstatus.toJson(status),
      ),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  Pond copyWith({
    String? id,
    String? associationId,
    String? enteredBy,
    Value<String?> observedBy = const Value.absent(),
    DateTime? createdAtDevice,
    String? deviceId,
    Value<DateTime?> serverReceivedAt = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    SyncState? syncState,
    Value<String?> syncError = const Value.absent(),
    DateTime? updatedAtDevice,
    String? siteId,
    String? code,
    PondColour? colour,
    StructureType? structure,
    PondRole? role,
    Value<WaterSupply?> waterSupply = const Value.absent(),
    Value<double?> lengthM = const Value.absent(),
    Value<double?> widthM = const Value.absent(),
    Value<double?> surfaceM2Override = const Value.absent(),
    Value<double?> depthInletM = const Value.absent(),
    Value<double?> depthOutletM = const Value.absent(),
    PondStatus? status,
    bool? archived,
  }) => Pond(
    id: id ?? this.id,
    associationId: associationId ?? this.associationId,
    enteredBy: enteredBy ?? this.enteredBy,
    observedBy: observedBy.present ? observedBy.value : this.observedBy,
    createdAtDevice: createdAtDevice ?? this.createdAtDevice,
    deviceId: deviceId ?? this.deviceId,
    serverReceivedAt: serverReceivedAt.present
        ? serverReceivedAt.value
        : this.serverReceivedAt,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    syncState: syncState ?? this.syncState,
    syncError: syncError.present ? syncError.value : this.syncError,
    updatedAtDevice: updatedAtDevice ?? this.updatedAtDevice,
    siteId: siteId ?? this.siteId,
    code: code ?? this.code,
    colour: colour ?? this.colour,
    structure: structure ?? this.structure,
    role: role ?? this.role,
    waterSupply: waterSupply.present ? waterSupply.value : this.waterSupply,
    lengthM: lengthM.present ? lengthM.value : this.lengthM,
    widthM: widthM.present ? widthM.value : this.widthM,
    surfaceM2Override: surfaceM2Override.present
        ? surfaceM2Override.value
        : this.surfaceM2Override,
    depthInletM: depthInletM.present ? depthInletM.value : this.depthInletM,
    depthOutletM: depthOutletM.present ? depthOutletM.value : this.depthOutletM,
    status: status ?? this.status,
    archived: archived ?? this.archived,
  );
  Pond copyWithCompanion(PondsCompanion data) {
    return Pond(
      id: data.id.present ? data.id.value : this.id,
      associationId: data.associationId.present
          ? data.associationId.value
          : this.associationId,
      enteredBy: data.enteredBy.present ? data.enteredBy.value : this.enteredBy,
      observedBy: data.observedBy.present
          ? data.observedBy.value
          : this.observedBy,
      createdAtDevice: data.createdAtDevice.present
          ? data.createdAtDevice.value
          : this.createdAtDevice,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      serverReceivedAt: data.serverReceivedAt.present
          ? data.serverReceivedAt.value
          : this.serverReceivedAt,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      updatedAtDevice: data.updatedAtDevice.present
          ? data.updatedAtDevice.value
          : this.updatedAtDevice,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      code: data.code.present ? data.code.value : this.code,
      colour: data.colour.present ? data.colour.value : this.colour,
      structure: data.structure.present ? data.structure.value : this.structure,
      role: data.role.present ? data.role.value : this.role,
      waterSupply: data.waterSupply.present
          ? data.waterSupply.value
          : this.waterSupply,
      lengthM: data.lengthM.present ? data.lengthM.value : this.lengthM,
      widthM: data.widthM.present ? data.widthM.value : this.widthM,
      surfaceM2Override: data.surfaceM2Override.present
          ? data.surfaceM2Override.value
          : this.surfaceM2Override,
      depthInletM: data.depthInletM.present
          ? data.depthInletM.value
          : this.depthInletM,
      depthOutletM: data.depthOutletM.present
          ? data.depthOutletM.value
          : this.depthOutletM,
      status: data.status.present ? data.status.value : this.status,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pond(')
          ..write('id: $id, ')
          ..write('associationId: $associationId, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('observedBy: $observedBy, ')
          ..write('createdAtDevice: $createdAtDevice, ')
          ..write('deviceId: $deviceId, ')
          ..write('serverReceivedAt: $serverReceivedAt, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('updatedAtDevice: $updatedAtDevice, ')
          ..write('siteId: $siteId, ')
          ..write('code: $code, ')
          ..write('colour: $colour, ')
          ..write('structure: $structure, ')
          ..write('role: $role, ')
          ..write('waterSupply: $waterSupply, ')
          ..write('lengthM: $lengthM, ')
          ..write('widthM: $widthM, ')
          ..write('surfaceM2Override: $surfaceM2Override, ')
          ..write('depthInletM: $depthInletM, ')
          ..write('depthOutletM: $depthOutletM, ')
          ..write('status: $status, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    associationId,
    enteredBy,
    observedBy,
    createdAtDevice,
    deviceId,
    serverReceivedAt,
    serverSeq,
    syncState,
    syncError,
    updatedAtDevice,
    siteId,
    code,
    colour,
    structure,
    role,
    waterSupply,
    lengthM,
    widthM,
    surfaceM2Override,
    depthInletM,
    depthOutletM,
    status,
    archived,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pond &&
          other.id == this.id &&
          other.associationId == this.associationId &&
          other.enteredBy == this.enteredBy &&
          other.observedBy == this.observedBy &&
          other.createdAtDevice == this.createdAtDevice &&
          other.deviceId == this.deviceId &&
          other.serverReceivedAt == this.serverReceivedAt &&
          other.serverSeq == this.serverSeq &&
          other.syncState == this.syncState &&
          other.syncError == this.syncError &&
          other.updatedAtDevice == this.updatedAtDevice &&
          other.siteId == this.siteId &&
          other.code == this.code &&
          other.colour == this.colour &&
          other.structure == this.structure &&
          other.role == this.role &&
          other.waterSupply == this.waterSupply &&
          other.lengthM == this.lengthM &&
          other.widthM == this.widthM &&
          other.surfaceM2Override == this.surfaceM2Override &&
          other.depthInletM == this.depthInletM &&
          other.depthOutletM == this.depthOutletM &&
          other.status == this.status &&
          other.archived == this.archived);
}

class PondsCompanion extends UpdateCompanion<Pond> {
  final Value<String> id;
  final Value<String> associationId;
  final Value<String> enteredBy;
  final Value<String?> observedBy;
  final Value<DateTime> createdAtDevice;
  final Value<String> deviceId;
  final Value<DateTime?> serverReceivedAt;
  final Value<int?> serverSeq;
  final Value<SyncState> syncState;
  final Value<String?> syncError;
  final Value<DateTime> updatedAtDevice;
  final Value<String> siteId;
  final Value<String> code;
  final Value<PondColour> colour;
  final Value<StructureType> structure;
  final Value<PondRole> role;
  final Value<WaterSupply?> waterSupply;
  final Value<double?> lengthM;
  final Value<double?> widthM;
  final Value<double?> surfaceM2Override;
  final Value<double?> depthInletM;
  final Value<double?> depthOutletM;
  final Value<PondStatus> status;
  final Value<bool> archived;
  final Value<int> rowid;
  const PondsCompanion({
    this.id = const Value.absent(),
    this.associationId = const Value.absent(),
    this.enteredBy = const Value.absent(),
    this.observedBy = const Value.absent(),
    this.createdAtDevice = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.serverReceivedAt = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncError = const Value.absent(),
    this.updatedAtDevice = const Value.absent(),
    this.siteId = const Value.absent(),
    this.code = const Value.absent(),
    this.colour = const Value.absent(),
    this.structure = const Value.absent(),
    this.role = const Value.absent(),
    this.waterSupply = const Value.absent(),
    this.lengthM = const Value.absent(),
    this.widthM = const Value.absent(),
    this.surfaceM2Override = const Value.absent(),
    this.depthInletM = const Value.absent(),
    this.depthOutletM = const Value.absent(),
    this.status = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PondsCompanion.insert({
    this.id = const Value.absent(),
    required String associationId,
    required String enteredBy,
    this.observedBy = const Value.absent(),
    this.createdAtDevice = const Value.absent(),
    required String deviceId,
    this.serverReceivedAt = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncError = const Value.absent(),
    this.updatedAtDevice = const Value.absent(),
    required String siteId,
    required String code,
    required PondColour colour,
    this.structure = const Value.absent(),
    required PondRole role,
    this.waterSupply = const Value.absent(),
    this.lengthM = const Value.absent(),
    this.widthM = const Value.absent(),
    this.surfaceM2Override = const Value.absent(),
    this.depthInletM = const Value.absent(),
    this.depthOutletM = const Value.absent(),
    this.status = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : associationId = Value(associationId),
       enteredBy = Value(enteredBy),
       deviceId = Value(deviceId),
       siteId = Value(siteId),
       code = Value(code),
       colour = Value(colour),
       role = Value(role);
  static Insertable<Pond> custom({
    Expression<String>? id,
    Expression<String>? associationId,
    Expression<String>? enteredBy,
    Expression<String>? observedBy,
    Expression<DateTime>? createdAtDevice,
    Expression<String>? deviceId,
    Expression<DateTime>? serverReceivedAt,
    Expression<int>? serverSeq,
    Expression<String>? syncState,
    Expression<String>? syncError,
    Expression<DateTime>? updatedAtDevice,
    Expression<String>? siteId,
    Expression<String>? code,
    Expression<String>? colour,
    Expression<String>? structure,
    Expression<String>? role,
    Expression<String>? waterSupply,
    Expression<double>? lengthM,
    Expression<double>? widthM,
    Expression<double>? surfaceM2Override,
    Expression<double>? depthInletM,
    Expression<double>? depthOutletM,
    Expression<String>? status,
    Expression<bool>? archived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (associationId != null) 'association_id': associationId,
      if (enteredBy != null) 'entered_by': enteredBy,
      if (observedBy != null) 'observed_by': observedBy,
      if (createdAtDevice != null) 'created_at_device': createdAtDevice,
      if (deviceId != null) 'device_id': deviceId,
      if (serverReceivedAt != null) 'server_received_at': serverReceivedAt,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (syncState != null) 'sync_state': syncState,
      if (syncError != null) 'sync_error': syncError,
      if (updatedAtDevice != null) 'updated_at_device': updatedAtDevice,
      if (siteId != null) 'site_id': siteId,
      if (code != null) 'code': code,
      if (colour != null) 'colour': colour,
      if (structure != null) 'structure': structure,
      if (role != null) 'role': role,
      if (waterSupply != null) 'water_supply': waterSupply,
      if (lengthM != null) 'length_m': lengthM,
      if (widthM != null) 'width_m': widthM,
      if (surfaceM2Override != null) 'surface_m2_override': surfaceM2Override,
      if (depthInletM != null) 'depth_inlet_m': depthInletM,
      if (depthOutletM != null) 'depth_outlet_m': depthOutletM,
      if (status != null) 'status': status,
      if (archived != null) 'archived': archived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PondsCompanion copyWith({
    Value<String>? id,
    Value<String>? associationId,
    Value<String>? enteredBy,
    Value<String?>? observedBy,
    Value<DateTime>? createdAtDevice,
    Value<String>? deviceId,
    Value<DateTime?>? serverReceivedAt,
    Value<int?>? serverSeq,
    Value<SyncState>? syncState,
    Value<String?>? syncError,
    Value<DateTime>? updatedAtDevice,
    Value<String>? siteId,
    Value<String>? code,
    Value<PondColour>? colour,
    Value<StructureType>? structure,
    Value<PondRole>? role,
    Value<WaterSupply?>? waterSupply,
    Value<double?>? lengthM,
    Value<double?>? widthM,
    Value<double?>? surfaceM2Override,
    Value<double?>? depthInletM,
    Value<double?>? depthOutletM,
    Value<PondStatus>? status,
    Value<bool>? archived,
    Value<int>? rowid,
  }) {
    return PondsCompanion(
      id: id ?? this.id,
      associationId: associationId ?? this.associationId,
      enteredBy: enteredBy ?? this.enteredBy,
      observedBy: observedBy ?? this.observedBy,
      createdAtDevice: createdAtDevice ?? this.createdAtDevice,
      deviceId: deviceId ?? this.deviceId,
      serverReceivedAt: serverReceivedAt ?? this.serverReceivedAt,
      serverSeq: serverSeq ?? this.serverSeq,
      syncState: syncState ?? this.syncState,
      syncError: syncError ?? this.syncError,
      updatedAtDevice: updatedAtDevice ?? this.updatedAtDevice,
      siteId: siteId ?? this.siteId,
      code: code ?? this.code,
      colour: colour ?? this.colour,
      structure: structure ?? this.structure,
      role: role ?? this.role,
      waterSupply: waterSupply ?? this.waterSupply,
      lengthM: lengthM ?? this.lengthM,
      widthM: widthM ?? this.widthM,
      surfaceM2Override: surfaceM2Override ?? this.surfaceM2Override,
      depthInletM: depthInletM ?? this.depthInletM,
      depthOutletM: depthOutletM ?? this.depthOutletM,
      status: status ?? this.status,
      archived: archived ?? this.archived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (associationId.present) {
      map['association_id'] = Variable<String>(associationId.value);
    }
    if (enteredBy.present) {
      map['entered_by'] = Variable<String>(enteredBy.value);
    }
    if (observedBy.present) {
      map['observed_by'] = Variable<String>(observedBy.value);
    }
    if (createdAtDevice.present) {
      map['created_at_device'] = Variable<DateTime>(createdAtDevice.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (serverReceivedAt.present) {
      map['server_received_at'] = Variable<DateTime>(serverReceivedAt.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $PondsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (updatedAtDevice.present) {
      map['updated_at_device'] = Variable<DateTime>(updatedAtDevice.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<String>(siteId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (colour.present) {
      map['colour'] = Variable<String>(
        $PondsTable.$convertercolour.toSql(colour.value),
      );
    }
    if (structure.present) {
      map['structure'] = Variable<String>(
        $PondsTable.$converterstructure.toSql(structure.value),
      );
    }
    if (role.present) {
      map['role'] = Variable<String>(
        $PondsTable.$converterrole.toSql(role.value),
      );
    }
    if (waterSupply.present) {
      map['water_supply'] = Variable<String>(
        $PondsTable.$converterwaterSupplyn.toSql(waterSupply.value),
      );
    }
    if (lengthM.present) {
      map['length_m'] = Variable<double>(lengthM.value);
    }
    if (widthM.present) {
      map['width_m'] = Variable<double>(widthM.value);
    }
    if (surfaceM2Override.present) {
      map['surface_m2_override'] = Variable<double>(surfaceM2Override.value);
    }
    if (depthInletM.present) {
      map['depth_inlet_m'] = Variable<double>(depthInletM.value);
    }
    if (depthOutletM.present) {
      map['depth_outlet_m'] = Variable<double>(depthOutletM.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $PondsTable.$converterstatus.toSql(status.value),
      );
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PondsCompanion(')
          ..write('id: $id, ')
          ..write('associationId: $associationId, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('observedBy: $observedBy, ')
          ..write('createdAtDevice: $createdAtDevice, ')
          ..write('deviceId: $deviceId, ')
          ..write('serverReceivedAt: $serverReceivedAt, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('updatedAtDevice: $updatedAtDevice, ')
          ..write('siteId: $siteId, ')
          ..write('code: $code, ')
          ..write('colour: $colour, ')
          ..write('structure: $structure, ')
          ..write('role: $role, ')
          ..write('waterSupply: $waterSupply, ')
          ..write('lengthM: $lengthM, ')
          ..write('widthM: $widthM, ')
          ..write('surfaceM2Override: $surfaceM2Override, ')
          ..write('depthInletM: $depthInletM, ')
          ..write('depthOutletM: $depthOutletM, ')
          ..write('status: $status, ')
          ..write('archived: $archived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BatchesTable extends Batches with TableInfo<$BatchesTable, Batch> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _associationIdMeta = const VerificationMeta(
    'associationId',
  );
  @override
  late final GeneratedColumn<String> associationId = GeneratedColumn<String>(
    'association_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enteredByMeta = const VerificationMeta(
    'enteredBy',
  );
  @override
  late final GeneratedColumn<String> enteredBy = GeneratedColumn<String>(
    'entered_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observedByMeta = const VerificationMeta(
    'observedBy',
  );
  @override
  late final GeneratedColumn<String> observedBy = GeneratedColumn<String>(
    'observed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtDeviceMeta = const VerificationMeta(
    'createdAtDevice',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtDevice =
      GeneratedColumn<DateTime>(
        'created_at_device',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        clientDefault: utcNow,
      );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverReceivedAtMeta = const VerificationMeta(
    'serverReceivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverReceivedAt =
      GeneratedColumn<DateTime>(
        'server_received_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.pending.name),
      ).withConverter<SyncState>($BatchesTable.$convertersyncState);
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtDeviceMeta = const VerificationMeta(
    'updatedAtDevice',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtDevice =
      GeneratedColumn<DateTime>(
        'updated_at_device',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        clientDefault: utcNow,
      );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<String> siteId = GeneratedColumn<String>(
    'site_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strainMeta = const VerificationMeta('strain');
  @override
  late final GeneratedColumn<String> strain = GeneratedColumn<String>(
    'strain',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hatcheryMeta = const VerificationMeta(
    'hatchery',
  );
  @override
  late final GeneratedColumn<String> hatchery = GeneratedColumn<String>(
    'hatchery',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _certificateNoMeta = const VerificationMeta(
    'certificateNo',
  );
  @override
  late final GeneratedColumn<String> certificateNo = GeneratedColumn<String>(
    'certificate_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monosexMeta = const VerificationMeta(
    'monosex',
  );
  @override
  late final GeneratedColumn<bool> monosex = GeneratedColumn<bool>(
    'monosex',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("monosex" IN (0, 1))',
    ),
  );
  static const VerificationMeta _plannedHarvestOnMeta = const VerificationMeta(
    'plannedHarvestOn',
  );
  @override
  late final GeneratedColumn<DateTime> plannedHarvestOn =
      GeneratedColumn<DateTime>(
        'planned_harvest_on',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<BatchStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BatchStatus>($BatchesTable.$converterstatus);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    associationId,
    enteredBy,
    observedBy,
    createdAtDevice,
    deviceId,
    serverReceivedAt,
    serverSeq,
    syncState,
    syncError,
    updatedAtDevice,
    siteId,
    code,
    strain,
    hatchery,
    certificateNo,
    monosex,
    plannedHarvestOn,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<Batch> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('association_id')) {
      context.handle(
        _associationIdMeta,
        associationId.isAcceptableOrUnknown(
          data['association_id']!,
          _associationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_associationIdMeta);
    }
    if (data.containsKey('entered_by')) {
      context.handle(
        _enteredByMeta,
        enteredBy.isAcceptableOrUnknown(data['entered_by']!, _enteredByMeta),
      );
    } else if (isInserting) {
      context.missing(_enteredByMeta);
    }
    if (data.containsKey('observed_by')) {
      context.handle(
        _observedByMeta,
        observedBy.isAcceptableOrUnknown(data['observed_by']!, _observedByMeta),
      );
    }
    if (data.containsKey('created_at_device')) {
      context.handle(
        _createdAtDeviceMeta,
        createdAtDevice.isAcceptableOrUnknown(
          data['created_at_device']!,
          _createdAtDeviceMeta,
        ),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('server_received_at')) {
      context.handle(
        _serverReceivedAtMeta,
        serverReceivedAt.isAcceptableOrUnknown(
          data['server_received_at']!,
          _serverReceivedAtMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('updated_at_device')) {
      context.handle(
        _updatedAtDeviceMeta,
        updatedAtDevice.isAcceptableOrUnknown(
          data['updated_at_device']!,
          _updatedAtDeviceMeta,
        ),
      );
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('strain')) {
      context.handle(
        _strainMeta,
        strain.isAcceptableOrUnknown(data['strain']!, _strainMeta),
      );
    }
    if (data.containsKey('hatchery')) {
      context.handle(
        _hatcheryMeta,
        hatchery.isAcceptableOrUnknown(data['hatchery']!, _hatcheryMeta),
      );
    }
    if (data.containsKey('certificate_no')) {
      context.handle(
        _certificateNoMeta,
        certificateNo.isAcceptableOrUnknown(
          data['certificate_no']!,
          _certificateNoMeta,
        ),
      );
    }
    if (data.containsKey('monosex')) {
      context.handle(
        _monosexMeta,
        monosex.isAcceptableOrUnknown(data['monosex']!, _monosexMeta),
      );
    }
    if (data.containsKey('planned_harvest_on')) {
      context.handle(
        _plannedHarvestOnMeta,
        plannedHarvestOn.isAcceptableOrUnknown(
          data['planned_harvest_on']!,
          _plannedHarvestOnMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Batch map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Batch(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      associationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}association_id'],
      )!,
      enteredBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entered_by'],
      )!,
      observedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observed_by'],
      ),
      createdAtDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_device'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      serverReceivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_received_at'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      syncState: $BatchesTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      updatedAtDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_device'],
      )!,
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      strain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strain'],
      ),
      hatchery: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hatchery'],
      ),
      certificateNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}certificate_no'],
      ),
      monosex: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}monosex'],
      ),
      plannedHarvestOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}planned_harvest_on'],
      ),
      status: $BatchesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
    );
  }

  @override
  $BatchesTable createAlias(String alias) {
    return $BatchesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
  static JsonTypeConverter2<BatchStatus, String, String> $converterstatus =
      const EnumNameConverter<BatchStatus>(BatchStatus.values);
}

class Batch extends DataClass implements Insertable<Batch> {
  final String id;
  final String associationId;
  final String enteredBy;
  final String? observedBy;
  final DateTime createdAtDevice;
  final String deviceId;
  final DateTime? serverReceivedAt;
  final int? serverSeq;
  final SyncState syncState;
  final String? syncError;
  final DateTime updatedAtDevice;
  final String siteId;
  final String code;
  final String? strain;
  final String? hatchery;
  final String? certificateNo;
  final bool? monosex;
  final DateTime? plannedHarvestOn;
  final BatchStatus status;
  const Batch({
    required this.id,
    required this.associationId,
    required this.enteredBy,
    this.observedBy,
    required this.createdAtDevice,
    required this.deviceId,
    this.serverReceivedAt,
    this.serverSeq,
    required this.syncState,
    this.syncError,
    required this.updatedAtDevice,
    required this.siteId,
    required this.code,
    this.strain,
    this.hatchery,
    this.certificateNo,
    this.monosex,
    this.plannedHarvestOn,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['association_id'] = Variable<String>(associationId);
    map['entered_by'] = Variable<String>(enteredBy);
    if (!nullToAbsent || observedBy != null) {
      map['observed_by'] = Variable<String>(observedBy);
    }
    map['created_at_device'] = Variable<DateTime>(createdAtDevice);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || serverReceivedAt != null) {
      map['server_received_at'] = Variable<DateTime>(serverReceivedAt);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    {
      map['sync_state'] = Variable<String>(
        $BatchesTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['updated_at_device'] = Variable<DateTime>(updatedAtDevice);
    map['site_id'] = Variable<String>(siteId);
    map['code'] = Variable<String>(code);
    if (!nullToAbsent || strain != null) {
      map['strain'] = Variable<String>(strain);
    }
    if (!nullToAbsent || hatchery != null) {
      map['hatchery'] = Variable<String>(hatchery);
    }
    if (!nullToAbsent || certificateNo != null) {
      map['certificate_no'] = Variable<String>(certificateNo);
    }
    if (!nullToAbsent || monosex != null) {
      map['monosex'] = Variable<bool>(monosex);
    }
    if (!nullToAbsent || plannedHarvestOn != null) {
      map['planned_harvest_on'] = Variable<DateTime>(plannedHarvestOn);
    }
    {
      map['status'] = Variable<String>(
        $BatchesTable.$converterstatus.toSql(status),
      );
    }
    return map;
  }

  BatchesCompanion toCompanion(bool nullToAbsent) {
    return BatchesCompanion(
      id: Value(id),
      associationId: Value(associationId),
      enteredBy: Value(enteredBy),
      observedBy: observedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(observedBy),
      createdAtDevice: Value(createdAtDevice),
      deviceId: Value(deviceId),
      serverReceivedAt: serverReceivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverReceivedAt),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      syncState: Value(syncState),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      updatedAtDevice: Value(updatedAtDevice),
      siteId: Value(siteId),
      code: Value(code),
      strain: strain == null && nullToAbsent
          ? const Value.absent()
          : Value(strain),
      hatchery: hatchery == null && nullToAbsent
          ? const Value.absent()
          : Value(hatchery),
      certificateNo: certificateNo == null && nullToAbsent
          ? const Value.absent()
          : Value(certificateNo),
      monosex: monosex == null && nullToAbsent
          ? const Value.absent()
          : Value(monosex),
      plannedHarvestOn: plannedHarvestOn == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedHarvestOn),
      status: Value(status),
    );
  }

  factory Batch.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Batch(
      id: serializer.fromJson<String>(json['id']),
      associationId: serializer.fromJson<String>(json['associationId']),
      enteredBy: serializer.fromJson<String>(json['enteredBy']),
      observedBy: serializer.fromJson<String?>(json['observedBy']),
      createdAtDevice: serializer.fromJson<DateTime>(json['createdAtDevice']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      serverReceivedAt: serializer.fromJson<DateTime?>(
        json['serverReceivedAt'],
      ),
      serverSeq: serializer.fromJson<int?>(json['serverSeq']),
      syncState: $BatchesTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      syncError: serializer.fromJson<String?>(json['syncError']),
      updatedAtDevice: serializer.fromJson<DateTime>(json['updatedAtDevice']),
      siteId: serializer.fromJson<String>(json['siteId']),
      code: serializer.fromJson<String>(json['code']),
      strain: serializer.fromJson<String?>(json['strain']),
      hatchery: serializer.fromJson<String?>(json['hatchery']),
      certificateNo: serializer.fromJson<String?>(json['certificateNo']),
      monosex: serializer.fromJson<bool?>(json['monosex']),
      plannedHarvestOn: serializer.fromJson<DateTime?>(
        json['plannedHarvestOn'],
      ),
      status: $BatchesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'associationId': serializer.toJson<String>(associationId),
      'enteredBy': serializer.toJson<String>(enteredBy),
      'observedBy': serializer.toJson<String?>(observedBy),
      'createdAtDevice': serializer.toJson<DateTime>(createdAtDevice),
      'deviceId': serializer.toJson<String>(deviceId),
      'serverReceivedAt': serializer.toJson<DateTime?>(serverReceivedAt),
      'serverSeq': serializer.toJson<int?>(serverSeq),
      'syncState': serializer.toJson<String>(
        $BatchesTable.$convertersyncState.toJson(syncState),
      ),
      'syncError': serializer.toJson<String?>(syncError),
      'updatedAtDevice': serializer.toJson<DateTime>(updatedAtDevice),
      'siteId': serializer.toJson<String>(siteId),
      'code': serializer.toJson<String>(code),
      'strain': serializer.toJson<String?>(strain),
      'hatchery': serializer.toJson<String?>(hatchery),
      'certificateNo': serializer.toJson<String?>(certificateNo),
      'monosex': serializer.toJson<bool?>(monosex),
      'plannedHarvestOn': serializer.toJson<DateTime?>(plannedHarvestOn),
      'status': serializer.toJson<String>(
        $BatchesTable.$converterstatus.toJson(status),
      ),
    };
  }

  Batch copyWith({
    String? id,
    String? associationId,
    String? enteredBy,
    Value<String?> observedBy = const Value.absent(),
    DateTime? createdAtDevice,
    String? deviceId,
    Value<DateTime?> serverReceivedAt = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    SyncState? syncState,
    Value<String?> syncError = const Value.absent(),
    DateTime? updatedAtDevice,
    String? siteId,
    String? code,
    Value<String?> strain = const Value.absent(),
    Value<String?> hatchery = const Value.absent(),
    Value<String?> certificateNo = const Value.absent(),
    Value<bool?> monosex = const Value.absent(),
    Value<DateTime?> plannedHarvestOn = const Value.absent(),
    BatchStatus? status,
  }) => Batch(
    id: id ?? this.id,
    associationId: associationId ?? this.associationId,
    enteredBy: enteredBy ?? this.enteredBy,
    observedBy: observedBy.present ? observedBy.value : this.observedBy,
    createdAtDevice: createdAtDevice ?? this.createdAtDevice,
    deviceId: deviceId ?? this.deviceId,
    serverReceivedAt: serverReceivedAt.present
        ? serverReceivedAt.value
        : this.serverReceivedAt,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    syncState: syncState ?? this.syncState,
    syncError: syncError.present ? syncError.value : this.syncError,
    updatedAtDevice: updatedAtDevice ?? this.updatedAtDevice,
    siteId: siteId ?? this.siteId,
    code: code ?? this.code,
    strain: strain.present ? strain.value : this.strain,
    hatchery: hatchery.present ? hatchery.value : this.hatchery,
    certificateNo: certificateNo.present
        ? certificateNo.value
        : this.certificateNo,
    monosex: monosex.present ? monosex.value : this.monosex,
    plannedHarvestOn: plannedHarvestOn.present
        ? plannedHarvestOn.value
        : this.plannedHarvestOn,
    status: status ?? this.status,
  );
  Batch copyWithCompanion(BatchesCompanion data) {
    return Batch(
      id: data.id.present ? data.id.value : this.id,
      associationId: data.associationId.present
          ? data.associationId.value
          : this.associationId,
      enteredBy: data.enteredBy.present ? data.enteredBy.value : this.enteredBy,
      observedBy: data.observedBy.present
          ? data.observedBy.value
          : this.observedBy,
      createdAtDevice: data.createdAtDevice.present
          ? data.createdAtDevice.value
          : this.createdAtDevice,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      serverReceivedAt: data.serverReceivedAt.present
          ? data.serverReceivedAt.value
          : this.serverReceivedAt,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      updatedAtDevice: data.updatedAtDevice.present
          ? data.updatedAtDevice.value
          : this.updatedAtDevice,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      code: data.code.present ? data.code.value : this.code,
      strain: data.strain.present ? data.strain.value : this.strain,
      hatchery: data.hatchery.present ? data.hatchery.value : this.hatchery,
      certificateNo: data.certificateNo.present
          ? data.certificateNo.value
          : this.certificateNo,
      monosex: data.monosex.present ? data.monosex.value : this.monosex,
      plannedHarvestOn: data.plannedHarvestOn.present
          ? data.plannedHarvestOn.value
          : this.plannedHarvestOn,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Batch(')
          ..write('id: $id, ')
          ..write('associationId: $associationId, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('observedBy: $observedBy, ')
          ..write('createdAtDevice: $createdAtDevice, ')
          ..write('deviceId: $deviceId, ')
          ..write('serverReceivedAt: $serverReceivedAt, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('updatedAtDevice: $updatedAtDevice, ')
          ..write('siteId: $siteId, ')
          ..write('code: $code, ')
          ..write('strain: $strain, ')
          ..write('hatchery: $hatchery, ')
          ..write('certificateNo: $certificateNo, ')
          ..write('monosex: $monosex, ')
          ..write('plannedHarvestOn: $plannedHarvestOn, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    associationId,
    enteredBy,
    observedBy,
    createdAtDevice,
    deviceId,
    serverReceivedAt,
    serverSeq,
    syncState,
    syncError,
    updatedAtDevice,
    siteId,
    code,
    strain,
    hatchery,
    certificateNo,
    monosex,
    plannedHarvestOn,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Batch &&
          other.id == this.id &&
          other.associationId == this.associationId &&
          other.enteredBy == this.enteredBy &&
          other.observedBy == this.observedBy &&
          other.createdAtDevice == this.createdAtDevice &&
          other.deviceId == this.deviceId &&
          other.serverReceivedAt == this.serverReceivedAt &&
          other.serverSeq == this.serverSeq &&
          other.syncState == this.syncState &&
          other.syncError == this.syncError &&
          other.updatedAtDevice == this.updatedAtDevice &&
          other.siteId == this.siteId &&
          other.code == this.code &&
          other.strain == this.strain &&
          other.hatchery == this.hatchery &&
          other.certificateNo == this.certificateNo &&
          other.monosex == this.monosex &&
          other.plannedHarvestOn == this.plannedHarvestOn &&
          other.status == this.status);
}

class BatchesCompanion extends UpdateCompanion<Batch> {
  final Value<String> id;
  final Value<String> associationId;
  final Value<String> enteredBy;
  final Value<String?> observedBy;
  final Value<DateTime> createdAtDevice;
  final Value<String> deviceId;
  final Value<DateTime?> serverReceivedAt;
  final Value<int?> serverSeq;
  final Value<SyncState> syncState;
  final Value<String?> syncError;
  final Value<DateTime> updatedAtDevice;
  final Value<String> siteId;
  final Value<String> code;
  final Value<String?> strain;
  final Value<String?> hatchery;
  final Value<String?> certificateNo;
  final Value<bool?> monosex;
  final Value<DateTime?> plannedHarvestOn;
  final Value<BatchStatus> status;
  final Value<int> rowid;
  const BatchesCompanion({
    this.id = const Value.absent(),
    this.associationId = const Value.absent(),
    this.enteredBy = const Value.absent(),
    this.observedBy = const Value.absent(),
    this.createdAtDevice = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.serverReceivedAt = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncError = const Value.absent(),
    this.updatedAtDevice = const Value.absent(),
    this.siteId = const Value.absent(),
    this.code = const Value.absent(),
    this.strain = const Value.absent(),
    this.hatchery = const Value.absent(),
    this.certificateNo = const Value.absent(),
    this.monosex = const Value.absent(),
    this.plannedHarvestOn = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BatchesCompanion.insert({
    this.id = const Value.absent(),
    required String associationId,
    required String enteredBy,
    this.observedBy = const Value.absent(),
    this.createdAtDevice = const Value.absent(),
    required String deviceId,
    this.serverReceivedAt = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncError = const Value.absent(),
    this.updatedAtDevice = const Value.absent(),
    required String siteId,
    required String code,
    this.strain = const Value.absent(),
    this.hatchery = const Value.absent(),
    this.certificateNo = const Value.absent(),
    this.monosex = const Value.absent(),
    this.plannedHarvestOn = const Value.absent(),
    required BatchStatus status,
    this.rowid = const Value.absent(),
  }) : associationId = Value(associationId),
       enteredBy = Value(enteredBy),
       deviceId = Value(deviceId),
       siteId = Value(siteId),
       code = Value(code),
       status = Value(status);
  static Insertable<Batch> custom({
    Expression<String>? id,
    Expression<String>? associationId,
    Expression<String>? enteredBy,
    Expression<String>? observedBy,
    Expression<DateTime>? createdAtDevice,
    Expression<String>? deviceId,
    Expression<DateTime>? serverReceivedAt,
    Expression<int>? serverSeq,
    Expression<String>? syncState,
    Expression<String>? syncError,
    Expression<DateTime>? updatedAtDevice,
    Expression<String>? siteId,
    Expression<String>? code,
    Expression<String>? strain,
    Expression<String>? hatchery,
    Expression<String>? certificateNo,
    Expression<bool>? monosex,
    Expression<DateTime>? plannedHarvestOn,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (associationId != null) 'association_id': associationId,
      if (enteredBy != null) 'entered_by': enteredBy,
      if (observedBy != null) 'observed_by': observedBy,
      if (createdAtDevice != null) 'created_at_device': createdAtDevice,
      if (deviceId != null) 'device_id': deviceId,
      if (serverReceivedAt != null) 'server_received_at': serverReceivedAt,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (syncState != null) 'sync_state': syncState,
      if (syncError != null) 'sync_error': syncError,
      if (updatedAtDevice != null) 'updated_at_device': updatedAtDevice,
      if (siteId != null) 'site_id': siteId,
      if (code != null) 'code': code,
      if (strain != null) 'strain': strain,
      if (hatchery != null) 'hatchery': hatchery,
      if (certificateNo != null) 'certificate_no': certificateNo,
      if (monosex != null) 'monosex': monosex,
      if (plannedHarvestOn != null) 'planned_harvest_on': plannedHarvestOn,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BatchesCompanion copyWith({
    Value<String>? id,
    Value<String>? associationId,
    Value<String>? enteredBy,
    Value<String?>? observedBy,
    Value<DateTime>? createdAtDevice,
    Value<String>? deviceId,
    Value<DateTime?>? serverReceivedAt,
    Value<int?>? serverSeq,
    Value<SyncState>? syncState,
    Value<String?>? syncError,
    Value<DateTime>? updatedAtDevice,
    Value<String>? siteId,
    Value<String>? code,
    Value<String?>? strain,
    Value<String?>? hatchery,
    Value<String?>? certificateNo,
    Value<bool?>? monosex,
    Value<DateTime?>? plannedHarvestOn,
    Value<BatchStatus>? status,
    Value<int>? rowid,
  }) {
    return BatchesCompanion(
      id: id ?? this.id,
      associationId: associationId ?? this.associationId,
      enteredBy: enteredBy ?? this.enteredBy,
      observedBy: observedBy ?? this.observedBy,
      createdAtDevice: createdAtDevice ?? this.createdAtDevice,
      deviceId: deviceId ?? this.deviceId,
      serverReceivedAt: serverReceivedAt ?? this.serverReceivedAt,
      serverSeq: serverSeq ?? this.serverSeq,
      syncState: syncState ?? this.syncState,
      syncError: syncError ?? this.syncError,
      updatedAtDevice: updatedAtDevice ?? this.updatedAtDevice,
      siteId: siteId ?? this.siteId,
      code: code ?? this.code,
      strain: strain ?? this.strain,
      hatchery: hatchery ?? this.hatchery,
      certificateNo: certificateNo ?? this.certificateNo,
      monosex: monosex ?? this.monosex,
      plannedHarvestOn: plannedHarvestOn ?? this.plannedHarvestOn,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (associationId.present) {
      map['association_id'] = Variable<String>(associationId.value);
    }
    if (enteredBy.present) {
      map['entered_by'] = Variable<String>(enteredBy.value);
    }
    if (observedBy.present) {
      map['observed_by'] = Variable<String>(observedBy.value);
    }
    if (createdAtDevice.present) {
      map['created_at_device'] = Variable<DateTime>(createdAtDevice.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (serverReceivedAt.present) {
      map['server_received_at'] = Variable<DateTime>(serverReceivedAt.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $BatchesTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (updatedAtDevice.present) {
      map['updated_at_device'] = Variable<DateTime>(updatedAtDevice.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<String>(siteId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (strain.present) {
      map['strain'] = Variable<String>(strain.value);
    }
    if (hatchery.present) {
      map['hatchery'] = Variable<String>(hatchery.value);
    }
    if (certificateNo.present) {
      map['certificate_no'] = Variable<String>(certificateNo.value);
    }
    if (monosex.present) {
      map['monosex'] = Variable<bool>(monosex.value);
    }
    if (plannedHarvestOn.present) {
      map['planned_harvest_on'] = Variable<DateTime>(plannedHarvestOn.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $BatchesTable.$converterstatus.toSql(status.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BatchesCompanion(')
          ..write('id: $id, ')
          ..write('associationId: $associationId, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('observedBy: $observedBy, ')
          ..write('createdAtDevice: $createdAtDevice, ')
          ..write('deviceId: $deviceId, ')
          ..write('serverReceivedAt: $serverReceivedAt, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('updatedAtDevice: $updatedAtDevice, ')
          ..write('siteId: $siteId, ')
          ..write('code: $code, ')
          ..write('strain: $strain, ')
          ..write('hatchery: $hatchery, ')
          ..write('certificateNo: $certificateNo, ')
          ..write('monosex: $monosex, ')
          ..write('plannedHarvestOn: $plannedHarvestOn, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockingsTable extends Stockings
    with TableInfo<$StockingsTable, Stocking> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _associationIdMeta = const VerificationMeta(
    'associationId',
  );
  @override
  late final GeneratedColumn<String> associationId = GeneratedColumn<String>(
    'association_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enteredByMeta = const VerificationMeta(
    'enteredBy',
  );
  @override
  late final GeneratedColumn<String> enteredBy = GeneratedColumn<String>(
    'entered_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observedByMeta = const VerificationMeta(
    'observedBy',
  );
  @override
  late final GeneratedColumn<String> observedBy = GeneratedColumn<String>(
    'observed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtDeviceMeta = const VerificationMeta(
    'createdAtDevice',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtDevice =
      GeneratedColumn<DateTime>(
        'created_at_device',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        clientDefault: utcNow,
      );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverReceivedAtMeta = const VerificationMeta(
    'serverReceivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverReceivedAt =
      GeneratedColumn<DateTime>(
        'server_received_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.pending.name),
      ).withConverter<SyncState>($StockingsTable.$convertersyncState);
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supersedesIdMeta = const VerificationMeta(
    'supersedesId',
  );
  @override
  late final GeneratedColumn<String> supersedesId = GeneratedColumn<String>(
    'supersedes_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isTombstoneMeta = const VerificationMeta(
    'isTombstone',
  );
  @override
  late final GeneratedColumn<bool> isTombstone = GeneratedColumn<bool>(
    'is_tombstone',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_tombstone" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pondIdMeta = const VerificationMeta('pondId');
  @override
  late final GeneratedColumn<String> pondId = GeneratedColumn<String>(
    'pond_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgWeightMgMeta = const VerificationMeta(
    'avgWeightMg',
  );
  @override
  late final GeneratedColumn<int> avgWeightMg = GeneratedColumn<int>(
    'avg_weight_mg',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acclimatisedMeta = const VerificationMeta(
    'acclimatised',
  );
  @override
  late final GeneratedColumn<bool> acclimatised = GeneratedColumn<bool>(
    'acclimatised',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("acclimatised" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    associationId,
    enteredBy,
    observedBy,
    createdAtDevice,
    deviceId,
    serverReceivedAt,
    serverSeq,
    syncState,
    syncError,
    recordedAt,
    supersedesId,
    isTombstone,
    batchId,
    pondId,
    count,
    avgWeightMg,
    acclimatised,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stockings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Stocking> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('association_id')) {
      context.handle(
        _associationIdMeta,
        associationId.isAcceptableOrUnknown(
          data['association_id']!,
          _associationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_associationIdMeta);
    }
    if (data.containsKey('entered_by')) {
      context.handle(
        _enteredByMeta,
        enteredBy.isAcceptableOrUnknown(data['entered_by']!, _enteredByMeta),
      );
    } else if (isInserting) {
      context.missing(_enteredByMeta);
    }
    if (data.containsKey('observed_by')) {
      context.handle(
        _observedByMeta,
        observedBy.isAcceptableOrUnknown(data['observed_by']!, _observedByMeta),
      );
    }
    if (data.containsKey('created_at_device')) {
      context.handle(
        _createdAtDeviceMeta,
        createdAtDevice.isAcceptableOrUnknown(
          data['created_at_device']!,
          _createdAtDeviceMeta,
        ),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('server_received_at')) {
      context.handle(
        _serverReceivedAtMeta,
        serverReceivedAt.isAcceptableOrUnknown(
          data['server_received_at']!,
          _serverReceivedAtMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('supersedes_id')) {
      context.handle(
        _supersedesIdMeta,
        supersedesId.isAcceptableOrUnknown(
          data['supersedes_id']!,
          _supersedesIdMeta,
        ),
      );
    }
    if (data.containsKey('is_tombstone')) {
      context.handle(
        _isTombstoneMeta,
        isTombstone.isAcceptableOrUnknown(
          data['is_tombstone']!,
          _isTombstoneMeta,
        ),
      );
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('pond_id')) {
      context.handle(
        _pondIdMeta,
        pondId.isAcceptableOrUnknown(data['pond_id']!, _pondIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pondIdMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    } else if (isInserting) {
      context.missing(_countMeta);
    }
    if (data.containsKey('avg_weight_mg')) {
      context.handle(
        _avgWeightMgMeta,
        avgWeightMg.isAcceptableOrUnknown(
          data['avg_weight_mg']!,
          _avgWeightMgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avgWeightMgMeta);
    }
    if (data.containsKey('acclimatised')) {
      context.handle(
        _acclimatisedMeta,
        acclimatised.isAcceptableOrUnknown(
          data['acclimatised']!,
          _acclimatisedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Stocking map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Stocking(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      associationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}association_id'],
      )!,
      enteredBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entered_by'],
      )!,
      observedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observed_by'],
      ),
      createdAtDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_device'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      serverReceivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_received_at'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      syncState: $StockingsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      supersedesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supersedes_id'],
      ),
      isTombstone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_tombstone'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      pondId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pond_id'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      avgWeightMg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avg_weight_mg'],
      )!,
      acclimatised: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}acclimatised'],
      ),
    );
  }

  @override
  $StockingsTable createAlias(String alias) {
    return $StockingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class Stocking extends DataClass implements Insertable<Stocking> {
  final String id;
  final String associationId;
  final String enteredBy;
  final String? observedBy;
  final DateTime createdAtDevice;
  final String deviceId;
  final DateTime? serverReceivedAt;
  final int? serverSeq;
  final SyncState syncState;
  final String? syncError;
  final DateTime recordedAt;
  final String? supersedesId;
  final bool isTombstone;
  final String batchId;
  final String pondId;
  final int count;
  final int avgWeightMg;
  final bool? acclimatised;
  const Stocking({
    required this.id,
    required this.associationId,
    required this.enteredBy,
    this.observedBy,
    required this.createdAtDevice,
    required this.deviceId,
    this.serverReceivedAt,
    this.serverSeq,
    required this.syncState,
    this.syncError,
    required this.recordedAt,
    this.supersedesId,
    required this.isTombstone,
    required this.batchId,
    required this.pondId,
    required this.count,
    required this.avgWeightMg,
    this.acclimatised,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['association_id'] = Variable<String>(associationId);
    map['entered_by'] = Variable<String>(enteredBy);
    if (!nullToAbsent || observedBy != null) {
      map['observed_by'] = Variable<String>(observedBy);
    }
    map['created_at_device'] = Variable<DateTime>(createdAtDevice);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || serverReceivedAt != null) {
      map['server_received_at'] = Variable<DateTime>(serverReceivedAt);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    {
      map['sync_state'] = Variable<String>(
        $StockingsTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || supersedesId != null) {
      map['supersedes_id'] = Variable<String>(supersedesId);
    }
    map['is_tombstone'] = Variable<bool>(isTombstone);
    map['batch_id'] = Variable<String>(batchId);
    map['pond_id'] = Variable<String>(pondId);
    map['count'] = Variable<int>(count);
    map['avg_weight_mg'] = Variable<int>(avgWeightMg);
    if (!nullToAbsent || acclimatised != null) {
      map['acclimatised'] = Variable<bool>(acclimatised);
    }
    return map;
  }

  StockingsCompanion toCompanion(bool nullToAbsent) {
    return StockingsCompanion(
      id: Value(id),
      associationId: Value(associationId),
      enteredBy: Value(enteredBy),
      observedBy: observedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(observedBy),
      createdAtDevice: Value(createdAtDevice),
      deviceId: Value(deviceId),
      serverReceivedAt: serverReceivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverReceivedAt),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      syncState: Value(syncState),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      recordedAt: Value(recordedAt),
      supersedesId: supersedesId == null && nullToAbsent
          ? const Value.absent()
          : Value(supersedesId),
      isTombstone: Value(isTombstone),
      batchId: Value(batchId),
      pondId: Value(pondId),
      count: Value(count),
      avgWeightMg: Value(avgWeightMg),
      acclimatised: acclimatised == null && nullToAbsent
          ? const Value.absent()
          : Value(acclimatised),
    );
  }

  factory Stocking.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Stocking(
      id: serializer.fromJson<String>(json['id']),
      associationId: serializer.fromJson<String>(json['associationId']),
      enteredBy: serializer.fromJson<String>(json['enteredBy']),
      observedBy: serializer.fromJson<String?>(json['observedBy']),
      createdAtDevice: serializer.fromJson<DateTime>(json['createdAtDevice']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      serverReceivedAt: serializer.fromJson<DateTime?>(
        json['serverReceivedAt'],
      ),
      serverSeq: serializer.fromJson<int?>(json['serverSeq']),
      syncState: $StockingsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      syncError: serializer.fromJson<String?>(json['syncError']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      supersedesId: serializer.fromJson<String?>(json['supersedesId']),
      isTombstone: serializer.fromJson<bool>(json['isTombstone']),
      batchId: serializer.fromJson<String>(json['batchId']),
      pondId: serializer.fromJson<String>(json['pondId']),
      count: serializer.fromJson<int>(json['count']),
      avgWeightMg: serializer.fromJson<int>(json['avgWeightMg']),
      acclimatised: serializer.fromJson<bool?>(json['acclimatised']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'associationId': serializer.toJson<String>(associationId),
      'enteredBy': serializer.toJson<String>(enteredBy),
      'observedBy': serializer.toJson<String?>(observedBy),
      'createdAtDevice': serializer.toJson<DateTime>(createdAtDevice),
      'deviceId': serializer.toJson<String>(deviceId),
      'serverReceivedAt': serializer.toJson<DateTime?>(serverReceivedAt),
      'serverSeq': serializer.toJson<int?>(serverSeq),
      'syncState': serializer.toJson<String>(
        $StockingsTable.$convertersyncState.toJson(syncState),
      ),
      'syncError': serializer.toJson<String?>(syncError),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'supersedesId': serializer.toJson<String?>(supersedesId),
      'isTombstone': serializer.toJson<bool>(isTombstone),
      'batchId': serializer.toJson<String>(batchId),
      'pondId': serializer.toJson<String>(pondId),
      'count': serializer.toJson<int>(count),
      'avgWeightMg': serializer.toJson<int>(avgWeightMg),
      'acclimatised': serializer.toJson<bool?>(acclimatised),
    };
  }

  Stocking copyWith({
    String? id,
    String? associationId,
    String? enteredBy,
    Value<String?> observedBy = const Value.absent(),
    DateTime? createdAtDevice,
    String? deviceId,
    Value<DateTime?> serverReceivedAt = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    SyncState? syncState,
    Value<String?> syncError = const Value.absent(),
    DateTime? recordedAt,
    Value<String?> supersedesId = const Value.absent(),
    bool? isTombstone,
    String? batchId,
    String? pondId,
    int? count,
    int? avgWeightMg,
    Value<bool?> acclimatised = const Value.absent(),
  }) => Stocking(
    id: id ?? this.id,
    associationId: associationId ?? this.associationId,
    enteredBy: enteredBy ?? this.enteredBy,
    observedBy: observedBy.present ? observedBy.value : this.observedBy,
    createdAtDevice: createdAtDevice ?? this.createdAtDevice,
    deviceId: deviceId ?? this.deviceId,
    serverReceivedAt: serverReceivedAt.present
        ? serverReceivedAt.value
        : this.serverReceivedAt,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    syncState: syncState ?? this.syncState,
    syncError: syncError.present ? syncError.value : this.syncError,
    recordedAt: recordedAt ?? this.recordedAt,
    supersedesId: supersedesId.present ? supersedesId.value : this.supersedesId,
    isTombstone: isTombstone ?? this.isTombstone,
    batchId: batchId ?? this.batchId,
    pondId: pondId ?? this.pondId,
    count: count ?? this.count,
    avgWeightMg: avgWeightMg ?? this.avgWeightMg,
    acclimatised: acclimatised.present ? acclimatised.value : this.acclimatised,
  );
  Stocking copyWithCompanion(StockingsCompanion data) {
    return Stocking(
      id: data.id.present ? data.id.value : this.id,
      associationId: data.associationId.present
          ? data.associationId.value
          : this.associationId,
      enteredBy: data.enteredBy.present ? data.enteredBy.value : this.enteredBy,
      observedBy: data.observedBy.present
          ? data.observedBy.value
          : this.observedBy,
      createdAtDevice: data.createdAtDevice.present
          ? data.createdAtDevice.value
          : this.createdAtDevice,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      serverReceivedAt: data.serverReceivedAt.present
          ? data.serverReceivedAt.value
          : this.serverReceivedAt,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      supersedesId: data.supersedesId.present
          ? data.supersedesId.value
          : this.supersedesId,
      isTombstone: data.isTombstone.present
          ? data.isTombstone.value
          : this.isTombstone,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      pondId: data.pondId.present ? data.pondId.value : this.pondId,
      count: data.count.present ? data.count.value : this.count,
      avgWeightMg: data.avgWeightMg.present
          ? data.avgWeightMg.value
          : this.avgWeightMg,
      acclimatised: data.acclimatised.present
          ? data.acclimatised.value
          : this.acclimatised,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Stocking(')
          ..write('id: $id, ')
          ..write('associationId: $associationId, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('observedBy: $observedBy, ')
          ..write('createdAtDevice: $createdAtDevice, ')
          ..write('deviceId: $deviceId, ')
          ..write('serverReceivedAt: $serverReceivedAt, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('supersedesId: $supersedesId, ')
          ..write('isTombstone: $isTombstone, ')
          ..write('batchId: $batchId, ')
          ..write('pondId: $pondId, ')
          ..write('count: $count, ')
          ..write('avgWeightMg: $avgWeightMg, ')
          ..write('acclimatised: $acclimatised')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    associationId,
    enteredBy,
    observedBy,
    createdAtDevice,
    deviceId,
    serverReceivedAt,
    serverSeq,
    syncState,
    syncError,
    recordedAt,
    supersedesId,
    isTombstone,
    batchId,
    pondId,
    count,
    avgWeightMg,
    acclimatised,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Stocking &&
          other.id == this.id &&
          other.associationId == this.associationId &&
          other.enteredBy == this.enteredBy &&
          other.observedBy == this.observedBy &&
          other.createdAtDevice == this.createdAtDevice &&
          other.deviceId == this.deviceId &&
          other.serverReceivedAt == this.serverReceivedAt &&
          other.serverSeq == this.serverSeq &&
          other.syncState == this.syncState &&
          other.syncError == this.syncError &&
          other.recordedAt == this.recordedAt &&
          other.supersedesId == this.supersedesId &&
          other.isTombstone == this.isTombstone &&
          other.batchId == this.batchId &&
          other.pondId == this.pondId &&
          other.count == this.count &&
          other.avgWeightMg == this.avgWeightMg &&
          other.acclimatised == this.acclimatised);
}

class StockingsCompanion extends UpdateCompanion<Stocking> {
  final Value<String> id;
  final Value<String> associationId;
  final Value<String> enteredBy;
  final Value<String?> observedBy;
  final Value<DateTime> createdAtDevice;
  final Value<String> deviceId;
  final Value<DateTime?> serverReceivedAt;
  final Value<int?> serverSeq;
  final Value<SyncState> syncState;
  final Value<String?> syncError;
  final Value<DateTime> recordedAt;
  final Value<String?> supersedesId;
  final Value<bool> isTombstone;
  final Value<String> batchId;
  final Value<String> pondId;
  final Value<int> count;
  final Value<int> avgWeightMg;
  final Value<bool?> acclimatised;
  final Value<int> rowid;
  const StockingsCompanion({
    this.id = const Value.absent(),
    this.associationId = const Value.absent(),
    this.enteredBy = const Value.absent(),
    this.observedBy = const Value.absent(),
    this.createdAtDevice = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.serverReceivedAt = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncError = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.supersedesId = const Value.absent(),
    this.isTombstone = const Value.absent(),
    this.batchId = const Value.absent(),
    this.pondId = const Value.absent(),
    this.count = const Value.absent(),
    this.avgWeightMg = const Value.absent(),
    this.acclimatised = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockingsCompanion.insert({
    this.id = const Value.absent(),
    required String associationId,
    required String enteredBy,
    this.observedBy = const Value.absent(),
    this.createdAtDevice = const Value.absent(),
    required String deviceId,
    this.serverReceivedAt = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncError = const Value.absent(),
    required DateTime recordedAt,
    this.supersedesId = const Value.absent(),
    this.isTombstone = const Value.absent(),
    required String batchId,
    required String pondId,
    required int count,
    required int avgWeightMg,
    this.acclimatised = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : associationId = Value(associationId),
       enteredBy = Value(enteredBy),
       deviceId = Value(deviceId),
       recordedAt = Value(recordedAt),
       batchId = Value(batchId),
       pondId = Value(pondId),
       count = Value(count),
       avgWeightMg = Value(avgWeightMg);
  static Insertable<Stocking> custom({
    Expression<String>? id,
    Expression<String>? associationId,
    Expression<String>? enteredBy,
    Expression<String>? observedBy,
    Expression<DateTime>? createdAtDevice,
    Expression<String>? deviceId,
    Expression<DateTime>? serverReceivedAt,
    Expression<int>? serverSeq,
    Expression<String>? syncState,
    Expression<String>? syncError,
    Expression<DateTime>? recordedAt,
    Expression<String>? supersedesId,
    Expression<bool>? isTombstone,
    Expression<String>? batchId,
    Expression<String>? pondId,
    Expression<int>? count,
    Expression<int>? avgWeightMg,
    Expression<bool>? acclimatised,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (associationId != null) 'association_id': associationId,
      if (enteredBy != null) 'entered_by': enteredBy,
      if (observedBy != null) 'observed_by': observedBy,
      if (createdAtDevice != null) 'created_at_device': createdAtDevice,
      if (deviceId != null) 'device_id': deviceId,
      if (serverReceivedAt != null) 'server_received_at': serverReceivedAt,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (syncState != null) 'sync_state': syncState,
      if (syncError != null) 'sync_error': syncError,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (supersedesId != null) 'supersedes_id': supersedesId,
      if (isTombstone != null) 'is_tombstone': isTombstone,
      if (batchId != null) 'batch_id': batchId,
      if (pondId != null) 'pond_id': pondId,
      if (count != null) 'count': count,
      if (avgWeightMg != null) 'avg_weight_mg': avgWeightMg,
      if (acclimatised != null) 'acclimatised': acclimatised,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockingsCompanion copyWith({
    Value<String>? id,
    Value<String>? associationId,
    Value<String>? enteredBy,
    Value<String?>? observedBy,
    Value<DateTime>? createdAtDevice,
    Value<String>? deviceId,
    Value<DateTime?>? serverReceivedAt,
    Value<int?>? serverSeq,
    Value<SyncState>? syncState,
    Value<String?>? syncError,
    Value<DateTime>? recordedAt,
    Value<String?>? supersedesId,
    Value<bool>? isTombstone,
    Value<String>? batchId,
    Value<String>? pondId,
    Value<int>? count,
    Value<int>? avgWeightMg,
    Value<bool?>? acclimatised,
    Value<int>? rowid,
  }) {
    return StockingsCompanion(
      id: id ?? this.id,
      associationId: associationId ?? this.associationId,
      enteredBy: enteredBy ?? this.enteredBy,
      observedBy: observedBy ?? this.observedBy,
      createdAtDevice: createdAtDevice ?? this.createdAtDevice,
      deviceId: deviceId ?? this.deviceId,
      serverReceivedAt: serverReceivedAt ?? this.serverReceivedAt,
      serverSeq: serverSeq ?? this.serverSeq,
      syncState: syncState ?? this.syncState,
      syncError: syncError ?? this.syncError,
      recordedAt: recordedAt ?? this.recordedAt,
      supersedesId: supersedesId ?? this.supersedesId,
      isTombstone: isTombstone ?? this.isTombstone,
      batchId: batchId ?? this.batchId,
      pondId: pondId ?? this.pondId,
      count: count ?? this.count,
      avgWeightMg: avgWeightMg ?? this.avgWeightMg,
      acclimatised: acclimatised ?? this.acclimatised,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (associationId.present) {
      map['association_id'] = Variable<String>(associationId.value);
    }
    if (enteredBy.present) {
      map['entered_by'] = Variable<String>(enteredBy.value);
    }
    if (observedBy.present) {
      map['observed_by'] = Variable<String>(observedBy.value);
    }
    if (createdAtDevice.present) {
      map['created_at_device'] = Variable<DateTime>(createdAtDevice.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (serverReceivedAt.present) {
      map['server_received_at'] = Variable<DateTime>(serverReceivedAt.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $StockingsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (supersedesId.present) {
      map['supersedes_id'] = Variable<String>(supersedesId.value);
    }
    if (isTombstone.present) {
      map['is_tombstone'] = Variable<bool>(isTombstone.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (pondId.present) {
      map['pond_id'] = Variable<String>(pondId.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (avgWeightMg.present) {
      map['avg_weight_mg'] = Variable<int>(avgWeightMg.value);
    }
    if (acclimatised.present) {
      map['acclimatised'] = Variable<bool>(acclimatised.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockingsCompanion(')
          ..write('id: $id, ')
          ..write('associationId: $associationId, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('observedBy: $observedBy, ')
          ..write('createdAtDevice: $createdAtDevice, ')
          ..write('deviceId: $deviceId, ')
          ..write('serverReceivedAt: $serverReceivedAt, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('supersedesId: $supersedesId, ')
          ..write('isTombstone: $isTombstone, ')
          ..write('batchId: $batchId, ')
          ..write('pondId: $pondId, ')
          ..write('count: $count, ')
          ..write('avgWeightMg: $avgWeightMg, ')
          ..write('acclimatised: $acclimatised, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransfersTable extends Transfers
    with TableInfo<$TransfersTable, Transfer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransfersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _associationIdMeta = const VerificationMeta(
    'associationId',
  );
  @override
  late final GeneratedColumn<String> associationId = GeneratedColumn<String>(
    'association_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enteredByMeta = const VerificationMeta(
    'enteredBy',
  );
  @override
  late final GeneratedColumn<String> enteredBy = GeneratedColumn<String>(
    'entered_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observedByMeta = const VerificationMeta(
    'observedBy',
  );
  @override
  late final GeneratedColumn<String> observedBy = GeneratedColumn<String>(
    'observed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtDeviceMeta = const VerificationMeta(
    'createdAtDevice',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtDevice =
      GeneratedColumn<DateTime>(
        'created_at_device',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        clientDefault: utcNow,
      );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverReceivedAtMeta = const VerificationMeta(
    'serverReceivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverReceivedAt =
      GeneratedColumn<DateTime>(
        'server_received_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.pending.name),
      ).withConverter<SyncState>($TransfersTable.$convertersyncState);
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supersedesIdMeta = const VerificationMeta(
    'supersedesId',
  );
  @override
  late final GeneratedColumn<String> supersedesId = GeneratedColumn<String>(
    'supersedes_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isTombstoneMeta = const VerificationMeta(
    'isTombstone',
  );
  @override
  late final GeneratedColumn<bool> isTombstone = GeneratedColumn<bool>(
    'is_tombstone',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_tombstone" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromPondIdMeta = const VerificationMeta(
    'fromPondId',
  );
  @override
  late final GeneratedColumn<String> fromPondId = GeneratedColumn<String>(
    'from_pond_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toPondIdMeta = const VerificationMeta(
    'toPondId',
  );
  @override
  late final GeneratedColumn<String> toPondId = GeneratedColumn<String>(
    'to_pond_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgWeightMgMeta = const VerificationMeta(
    'avgWeightMg',
  );
  @override
  late final GeneratedColumn<int> avgWeightMg = GeneratedColumn<int>(
    'avg_weight_mg',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    associationId,
    enteredBy,
    observedBy,
    createdAtDevice,
    deviceId,
    serverReceivedAt,
    serverSeq,
    syncState,
    syncError,
    recordedAt,
    supersedesId,
    isTombstone,
    batchId,
    fromPondId,
    toPondId,
    count,
    avgWeightMg,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transfer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('association_id')) {
      context.handle(
        _associationIdMeta,
        associationId.isAcceptableOrUnknown(
          data['association_id']!,
          _associationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_associationIdMeta);
    }
    if (data.containsKey('entered_by')) {
      context.handle(
        _enteredByMeta,
        enteredBy.isAcceptableOrUnknown(data['entered_by']!, _enteredByMeta),
      );
    } else if (isInserting) {
      context.missing(_enteredByMeta);
    }
    if (data.containsKey('observed_by')) {
      context.handle(
        _observedByMeta,
        observedBy.isAcceptableOrUnknown(data['observed_by']!, _observedByMeta),
      );
    }
    if (data.containsKey('created_at_device')) {
      context.handle(
        _createdAtDeviceMeta,
        createdAtDevice.isAcceptableOrUnknown(
          data['created_at_device']!,
          _createdAtDeviceMeta,
        ),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('server_received_at')) {
      context.handle(
        _serverReceivedAtMeta,
        serverReceivedAt.isAcceptableOrUnknown(
          data['server_received_at']!,
          _serverReceivedAtMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('supersedes_id')) {
      context.handle(
        _supersedesIdMeta,
        supersedesId.isAcceptableOrUnknown(
          data['supersedes_id']!,
          _supersedesIdMeta,
        ),
      );
    }
    if (data.containsKey('is_tombstone')) {
      context.handle(
        _isTombstoneMeta,
        isTombstone.isAcceptableOrUnknown(
          data['is_tombstone']!,
          _isTombstoneMeta,
        ),
      );
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('from_pond_id')) {
      context.handle(
        _fromPondIdMeta,
        fromPondId.isAcceptableOrUnknown(
          data['from_pond_id']!,
          _fromPondIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromPondIdMeta);
    }
    if (data.containsKey('to_pond_id')) {
      context.handle(
        _toPondIdMeta,
        toPondId.isAcceptableOrUnknown(data['to_pond_id']!, _toPondIdMeta),
      );
    } else if (isInserting) {
      context.missing(_toPondIdMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    } else if (isInserting) {
      context.missing(_countMeta);
    }
    if (data.containsKey('avg_weight_mg')) {
      context.handle(
        _avgWeightMgMeta,
        avgWeightMg.isAcceptableOrUnknown(
          data['avg_weight_mg']!,
          _avgWeightMgMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transfer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transfer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      associationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}association_id'],
      )!,
      enteredBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entered_by'],
      )!,
      observedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observed_by'],
      ),
      createdAtDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_device'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      serverReceivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_received_at'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      syncState: $TransfersTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      supersedesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supersedes_id'],
      ),
      isTombstone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_tombstone'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      fromPondId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_pond_id'],
      )!,
      toPondId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_pond_id'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      avgWeightMg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avg_weight_mg'],
      ),
    );
  }

  @override
  $TransfersTable createAlias(String alias) {
    return $TransfersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class Transfer extends DataClass implements Insertable<Transfer> {
  final String id;
  final String associationId;
  final String enteredBy;
  final String? observedBy;
  final DateTime createdAtDevice;
  final String deviceId;
  final DateTime? serverReceivedAt;
  final int? serverSeq;
  final SyncState syncState;
  final String? syncError;
  final DateTime recordedAt;
  final String? supersedesId;
  final bool isTombstone;
  final String batchId;
  final String fromPondId;
  final String toPondId;
  final int count;
  final int? avgWeightMg;
  const Transfer({
    required this.id,
    required this.associationId,
    required this.enteredBy,
    this.observedBy,
    required this.createdAtDevice,
    required this.deviceId,
    this.serverReceivedAt,
    this.serverSeq,
    required this.syncState,
    this.syncError,
    required this.recordedAt,
    this.supersedesId,
    required this.isTombstone,
    required this.batchId,
    required this.fromPondId,
    required this.toPondId,
    required this.count,
    this.avgWeightMg,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['association_id'] = Variable<String>(associationId);
    map['entered_by'] = Variable<String>(enteredBy);
    if (!nullToAbsent || observedBy != null) {
      map['observed_by'] = Variable<String>(observedBy);
    }
    map['created_at_device'] = Variable<DateTime>(createdAtDevice);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || serverReceivedAt != null) {
      map['server_received_at'] = Variable<DateTime>(serverReceivedAt);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    {
      map['sync_state'] = Variable<String>(
        $TransfersTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || supersedesId != null) {
      map['supersedes_id'] = Variable<String>(supersedesId);
    }
    map['is_tombstone'] = Variable<bool>(isTombstone);
    map['batch_id'] = Variable<String>(batchId);
    map['from_pond_id'] = Variable<String>(fromPondId);
    map['to_pond_id'] = Variable<String>(toPondId);
    map['count'] = Variable<int>(count);
    if (!nullToAbsent || avgWeightMg != null) {
      map['avg_weight_mg'] = Variable<int>(avgWeightMg);
    }
    return map;
  }

  TransfersCompanion toCompanion(bool nullToAbsent) {
    return TransfersCompanion(
      id: Value(id),
      associationId: Value(associationId),
      enteredBy: Value(enteredBy),
      observedBy: observedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(observedBy),
      createdAtDevice: Value(createdAtDevice),
      deviceId: Value(deviceId),
      serverReceivedAt: serverReceivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverReceivedAt),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      syncState: Value(syncState),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      recordedAt: Value(recordedAt),
      supersedesId: supersedesId == null && nullToAbsent
          ? const Value.absent()
          : Value(supersedesId),
      isTombstone: Value(isTombstone),
      batchId: Value(batchId),
      fromPondId: Value(fromPondId),
      toPondId: Value(toPondId),
      count: Value(count),
      avgWeightMg: avgWeightMg == null && nullToAbsent
          ? const Value.absent()
          : Value(avgWeightMg),
    );
  }

  factory Transfer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transfer(
      id: serializer.fromJson<String>(json['id']),
      associationId: serializer.fromJson<String>(json['associationId']),
      enteredBy: serializer.fromJson<String>(json['enteredBy']),
      observedBy: serializer.fromJson<String?>(json['observedBy']),
      createdAtDevice: serializer.fromJson<DateTime>(json['createdAtDevice']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      serverReceivedAt: serializer.fromJson<DateTime?>(
        json['serverReceivedAt'],
      ),
      serverSeq: serializer.fromJson<int?>(json['serverSeq']),
      syncState: $TransfersTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      syncError: serializer.fromJson<String?>(json['syncError']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      supersedesId: serializer.fromJson<String?>(json['supersedesId']),
      isTombstone: serializer.fromJson<bool>(json['isTombstone']),
      batchId: serializer.fromJson<String>(json['batchId']),
      fromPondId: serializer.fromJson<String>(json['fromPondId']),
      toPondId: serializer.fromJson<String>(json['toPondId']),
      count: serializer.fromJson<int>(json['count']),
      avgWeightMg: serializer.fromJson<int?>(json['avgWeightMg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'associationId': serializer.toJson<String>(associationId),
      'enteredBy': serializer.toJson<String>(enteredBy),
      'observedBy': serializer.toJson<String?>(observedBy),
      'createdAtDevice': serializer.toJson<DateTime>(createdAtDevice),
      'deviceId': serializer.toJson<String>(deviceId),
      'serverReceivedAt': serializer.toJson<DateTime?>(serverReceivedAt),
      'serverSeq': serializer.toJson<int?>(serverSeq),
      'syncState': serializer.toJson<String>(
        $TransfersTable.$convertersyncState.toJson(syncState),
      ),
      'syncError': serializer.toJson<String?>(syncError),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'supersedesId': serializer.toJson<String?>(supersedesId),
      'isTombstone': serializer.toJson<bool>(isTombstone),
      'batchId': serializer.toJson<String>(batchId),
      'fromPondId': serializer.toJson<String>(fromPondId),
      'toPondId': serializer.toJson<String>(toPondId),
      'count': serializer.toJson<int>(count),
      'avgWeightMg': serializer.toJson<int?>(avgWeightMg),
    };
  }

  Transfer copyWith({
    String? id,
    String? associationId,
    String? enteredBy,
    Value<String?> observedBy = const Value.absent(),
    DateTime? createdAtDevice,
    String? deviceId,
    Value<DateTime?> serverReceivedAt = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    SyncState? syncState,
    Value<String?> syncError = const Value.absent(),
    DateTime? recordedAt,
    Value<String?> supersedesId = const Value.absent(),
    bool? isTombstone,
    String? batchId,
    String? fromPondId,
    String? toPondId,
    int? count,
    Value<int?> avgWeightMg = const Value.absent(),
  }) => Transfer(
    id: id ?? this.id,
    associationId: associationId ?? this.associationId,
    enteredBy: enteredBy ?? this.enteredBy,
    observedBy: observedBy.present ? observedBy.value : this.observedBy,
    createdAtDevice: createdAtDevice ?? this.createdAtDevice,
    deviceId: deviceId ?? this.deviceId,
    serverReceivedAt: serverReceivedAt.present
        ? serverReceivedAt.value
        : this.serverReceivedAt,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    syncState: syncState ?? this.syncState,
    syncError: syncError.present ? syncError.value : this.syncError,
    recordedAt: recordedAt ?? this.recordedAt,
    supersedesId: supersedesId.present ? supersedesId.value : this.supersedesId,
    isTombstone: isTombstone ?? this.isTombstone,
    batchId: batchId ?? this.batchId,
    fromPondId: fromPondId ?? this.fromPondId,
    toPondId: toPondId ?? this.toPondId,
    count: count ?? this.count,
    avgWeightMg: avgWeightMg.present ? avgWeightMg.value : this.avgWeightMg,
  );
  Transfer copyWithCompanion(TransfersCompanion data) {
    return Transfer(
      id: data.id.present ? data.id.value : this.id,
      associationId: data.associationId.present
          ? data.associationId.value
          : this.associationId,
      enteredBy: data.enteredBy.present ? data.enteredBy.value : this.enteredBy,
      observedBy: data.observedBy.present
          ? data.observedBy.value
          : this.observedBy,
      createdAtDevice: data.createdAtDevice.present
          ? data.createdAtDevice.value
          : this.createdAtDevice,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      serverReceivedAt: data.serverReceivedAt.present
          ? data.serverReceivedAt.value
          : this.serverReceivedAt,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      supersedesId: data.supersedesId.present
          ? data.supersedesId.value
          : this.supersedesId,
      isTombstone: data.isTombstone.present
          ? data.isTombstone.value
          : this.isTombstone,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      fromPondId: data.fromPondId.present
          ? data.fromPondId.value
          : this.fromPondId,
      toPondId: data.toPondId.present ? data.toPondId.value : this.toPondId,
      count: data.count.present ? data.count.value : this.count,
      avgWeightMg: data.avgWeightMg.present
          ? data.avgWeightMg.value
          : this.avgWeightMg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transfer(')
          ..write('id: $id, ')
          ..write('associationId: $associationId, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('observedBy: $observedBy, ')
          ..write('createdAtDevice: $createdAtDevice, ')
          ..write('deviceId: $deviceId, ')
          ..write('serverReceivedAt: $serverReceivedAt, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('supersedesId: $supersedesId, ')
          ..write('isTombstone: $isTombstone, ')
          ..write('batchId: $batchId, ')
          ..write('fromPondId: $fromPondId, ')
          ..write('toPondId: $toPondId, ')
          ..write('count: $count, ')
          ..write('avgWeightMg: $avgWeightMg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    associationId,
    enteredBy,
    observedBy,
    createdAtDevice,
    deviceId,
    serverReceivedAt,
    serverSeq,
    syncState,
    syncError,
    recordedAt,
    supersedesId,
    isTombstone,
    batchId,
    fromPondId,
    toPondId,
    count,
    avgWeightMg,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transfer &&
          other.id == this.id &&
          other.associationId == this.associationId &&
          other.enteredBy == this.enteredBy &&
          other.observedBy == this.observedBy &&
          other.createdAtDevice == this.createdAtDevice &&
          other.deviceId == this.deviceId &&
          other.serverReceivedAt == this.serverReceivedAt &&
          other.serverSeq == this.serverSeq &&
          other.syncState == this.syncState &&
          other.syncError == this.syncError &&
          other.recordedAt == this.recordedAt &&
          other.supersedesId == this.supersedesId &&
          other.isTombstone == this.isTombstone &&
          other.batchId == this.batchId &&
          other.fromPondId == this.fromPondId &&
          other.toPondId == this.toPondId &&
          other.count == this.count &&
          other.avgWeightMg == this.avgWeightMg);
}

class TransfersCompanion extends UpdateCompanion<Transfer> {
  final Value<String> id;
  final Value<String> associationId;
  final Value<String> enteredBy;
  final Value<String?> observedBy;
  final Value<DateTime> createdAtDevice;
  final Value<String> deviceId;
  final Value<DateTime?> serverReceivedAt;
  final Value<int?> serverSeq;
  final Value<SyncState> syncState;
  final Value<String?> syncError;
  final Value<DateTime> recordedAt;
  final Value<String?> supersedesId;
  final Value<bool> isTombstone;
  final Value<String> batchId;
  final Value<String> fromPondId;
  final Value<String> toPondId;
  final Value<int> count;
  final Value<int?> avgWeightMg;
  final Value<int> rowid;
  const TransfersCompanion({
    this.id = const Value.absent(),
    this.associationId = const Value.absent(),
    this.enteredBy = const Value.absent(),
    this.observedBy = const Value.absent(),
    this.createdAtDevice = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.serverReceivedAt = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncError = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.supersedesId = const Value.absent(),
    this.isTombstone = const Value.absent(),
    this.batchId = const Value.absent(),
    this.fromPondId = const Value.absent(),
    this.toPondId = const Value.absent(),
    this.count = const Value.absent(),
    this.avgWeightMg = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransfersCompanion.insert({
    this.id = const Value.absent(),
    required String associationId,
    required String enteredBy,
    this.observedBy = const Value.absent(),
    this.createdAtDevice = const Value.absent(),
    required String deviceId,
    this.serverReceivedAt = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncError = const Value.absent(),
    required DateTime recordedAt,
    this.supersedesId = const Value.absent(),
    this.isTombstone = const Value.absent(),
    required String batchId,
    required String fromPondId,
    required String toPondId,
    required int count,
    this.avgWeightMg = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : associationId = Value(associationId),
       enteredBy = Value(enteredBy),
       deviceId = Value(deviceId),
       recordedAt = Value(recordedAt),
       batchId = Value(batchId),
       fromPondId = Value(fromPondId),
       toPondId = Value(toPondId),
       count = Value(count);
  static Insertable<Transfer> custom({
    Expression<String>? id,
    Expression<String>? associationId,
    Expression<String>? enteredBy,
    Expression<String>? observedBy,
    Expression<DateTime>? createdAtDevice,
    Expression<String>? deviceId,
    Expression<DateTime>? serverReceivedAt,
    Expression<int>? serverSeq,
    Expression<String>? syncState,
    Expression<String>? syncError,
    Expression<DateTime>? recordedAt,
    Expression<String>? supersedesId,
    Expression<bool>? isTombstone,
    Expression<String>? batchId,
    Expression<String>? fromPondId,
    Expression<String>? toPondId,
    Expression<int>? count,
    Expression<int>? avgWeightMg,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (associationId != null) 'association_id': associationId,
      if (enteredBy != null) 'entered_by': enteredBy,
      if (observedBy != null) 'observed_by': observedBy,
      if (createdAtDevice != null) 'created_at_device': createdAtDevice,
      if (deviceId != null) 'device_id': deviceId,
      if (serverReceivedAt != null) 'server_received_at': serverReceivedAt,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (syncState != null) 'sync_state': syncState,
      if (syncError != null) 'sync_error': syncError,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (supersedesId != null) 'supersedes_id': supersedesId,
      if (isTombstone != null) 'is_tombstone': isTombstone,
      if (batchId != null) 'batch_id': batchId,
      if (fromPondId != null) 'from_pond_id': fromPondId,
      if (toPondId != null) 'to_pond_id': toPondId,
      if (count != null) 'count': count,
      if (avgWeightMg != null) 'avg_weight_mg': avgWeightMg,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransfersCompanion copyWith({
    Value<String>? id,
    Value<String>? associationId,
    Value<String>? enteredBy,
    Value<String?>? observedBy,
    Value<DateTime>? createdAtDevice,
    Value<String>? deviceId,
    Value<DateTime?>? serverReceivedAt,
    Value<int?>? serverSeq,
    Value<SyncState>? syncState,
    Value<String?>? syncError,
    Value<DateTime>? recordedAt,
    Value<String?>? supersedesId,
    Value<bool>? isTombstone,
    Value<String>? batchId,
    Value<String>? fromPondId,
    Value<String>? toPondId,
    Value<int>? count,
    Value<int?>? avgWeightMg,
    Value<int>? rowid,
  }) {
    return TransfersCompanion(
      id: id ?? this.id,
      associationId: associationId ?? this.associationId,
      enteredBy: enteredBy ?? this.enteredBy,
      observedBy: observedBy ?? this.observedBy,
      createdAtDevice: createdAtDevice ?? this.createdAtDevice,
      deviceId: deviceId ?? this.deviceId,
      serverReceivedAt: serverReceivedAt ?? this.serverReceivedAt,
      serverSeq: serverSeq ?? this.serverSeq,
      syncState: syncState ?? this.syncState,
      syncError: syncError ?? this.syncError,
      recordedAt: recordedAt ?? this.recordedAt,
      supersedesId: supersedesId ?? this.supersedesId,
      isTombstone: isTombstone ?? this.isTombstone,
      batchId: batchId ?? this.batchId,
      fromPondId: fromPondId ?? this.fromPondId,
      toPondId: toPondId ?? this.toPondId,
      count: count ?? this.count,
      avgWeightMg: avgWeightMg ?? this.avgWeightMg,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (associationId.present) {
      map['association_id'] = Variable<String>(associationId.value);
    }
    if (enteredBy.present) {
      map['entered_by'] = Variable<String>(enteredBy.value);
    }
    if (observedBy.present) {
      map['observed_by'] = Variable<String>(observedBy.value);
    }
    if (createdAtDevice.present) {
      map['created_at_device'] = Variable<DateTime>(createdAtDevice.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (serverReceivedAt.present) {
      map['server_received_at'] = Variable<DateTime>(serverReceivedAt.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $TransfersTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (supersedesId.present) {
      map['supersedes_id'] = Variable<String>(supersedesId.value);
    }
    if (isTombstone.present) {
      map['is_tombstone'] = Variable<bool>(isTombstone.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (fromPondId.present) {
      map['from_pond_id'] = Variable<String>(fromPondId.value);
    }
    if (toPondId.present) {
      map['to_pond_id'] = Variable<String>(toPondId.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (avgWeightMg.present) {
      map['avg_weight_mg'] = Variable<int>(avgWeightMg.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransfersCompanion(')
          ..write('id: $id, ')
          ..write('associationId: $associationId, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('observedBy: $observedBy, ')
          ..write('createdAtDevice: $createdAtDevice, ')
          ..write('deviceId: $deviceId, ')
          ..write('serverReceivedAt: $serverReceivedAt, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('supersedesId: $supersedesId, ')
          ..write('isTombstone: $isTombstone, ')
          ..write('batchId: $batchId, ')
          ..write('fromPondId: $fromPondId, ')
          ..write('toPondId: $toPondId, ')
          ..write('count: $count, ')
          ..write('avgWeightMg: $avgWeightMg, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SitesTable sites = $SitesTable(this);
  late final $LocalMetaTable localMeta = $LocalMetaTable(this);
  late final $PeopleTable people = $PeopleTable(this);
  late final $PondsTable ponds = $PondsTable(this);
  late final $BatchesTable batches = $BatchesTable(this);
  late final $StockingsTable stockings = $StockingsTable(this);
  late final $TransfersTable transfers = $TransfersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sites,
    localMeta,
    people,
    ponds,
    batches,
    stockings,
    transfers,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SitesTableCreateCompanionBuilder = SitesCompanion Function({
  Value<String> id,
  required String associationId,
  required String enteredBy,
  Value<String?> observedBy,
  Value<DateTime> createdAtDevice,
  required String deviceId,
  Value<DateTime?> serverReceivedAt,
  Value<int?> serverSeq,
  Value<SyncState> syncState,
  Value<String?> syncError,
  Value<DateTime> updatedAtDevice,
  required String name,
  Value<String?> locationNote,
  Value<int> rowid,
});
typedef $$SitesTableUpdateCompanionBuilder = SitesCompanion Function({
  Value<String> id,
  Value<String> associationId,
  Value<String> enteredBy,
  Value<String?> observedBy,
  Value<DateTime> createdAtDevice,
  Value<String> deviceId,
  Value<DateTime?> serverReceivedAt,
  Value<int?> serverSeq,
  Value<SyncState> syncState,
  Value<String?> syncError,
  Value<DateTime> updatedAtDevice,
  Value<String> name,
  Value<String?> locationNote,
  Value<int> rowid,
});

class $$SitesTableFilterComposer extends Composer<_$AppDatabase, $SitesTable> {
  $$SitesTableFilterComposer({
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

  ColumnFilters<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enteredBy => $composableBuilder(
    column: $table.enteredBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtDevice => $composableBuilder(
    column: $table.updatedAtDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationNote => $composableBuilder(
    column: $table.locationNote,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SitesTableOrderingComposer
    extends Composer<_$AppDatabase, $SitesTable> {
  $$SitesTableOrderingComposer({
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

  ColumnOrderings<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enteredBy => $composableBuilder(
    column: $table.enteredBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtDevice => $composableBuilder(
    column: $table.updatedAtDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationNote => $composableBuilder(
    column: $table.locationNote,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SitesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SitesTable> {
  $$SitesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get enteredBy =>
      $composableBuilder(column: $table.enteredBy, builder: (column) => column);

  GeneratedColumn<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAtDevice => $composableBuilder(
    column: $table.updatedAtDevice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get locationNote => $composableBuilder(
    column: $table.locationNote,
    builder: (column) => column,
  );
}

class $$SitesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SitesTable,
          Site,
          $$SitesTableFilterComposer,
          $$SitesTableOrderingComposer,
          $$SitesTableAnnotationComposer,
          $$SitesTableCreateCompanionBuilder,
          $$SitesTableUpdateCompanionBuilder,
          (Site, BaseReferences<_$AppDatabase, $SitesTable, Site>),
          Site,
          PrefetchHooks Function()
        > {
  $$SitesTableTableManager(_$AppDatabase db, $SitesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SitesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SitesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SitesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> associationId = const Value.absent(),
                Value<String> enteredBy = const Value.absent(),
                Value<String?> observedBy = const Value.absent(),
                Value<DateTime> createdAtDevice = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime?> serverReceivedAt = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> updatedAtDevice = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> locationNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SitesCompanion(
                id: id,
                associationId: associationId,
                enteredBy: enteredBy,
                observedBy: observedBy,
                createdAtDevice: createdAtDevice,
                deviceId: deviceId,
                serverReceivedAt: serverReceivedAt,
                serverSeq: serverSeq,
                syncState: syncState,
                syncError: syncError,
                updatedAtDevice: updatedAtDevice,
                name: name,
                locationNote: locationNote,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String associationId,
                required String enteredBy,
                Value<String?> observedBy = const Value.absent(),
                Value<DateTime> createdAtDevice = const Value.absent(),
                required String deviceId,
                Value<DateTime?> serverReceivedAt = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> updatedAtDevice = const Value.absent(),
                required String name,
                Value<String?> locationNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SitesCompanion.insert(
                id: id,
                associationId: associationId,
                enteredBy: enteredBy,
                observedBy: observedBy,
                createdAtDevice: createdAtDevice,
                deviceId: deviceId,
                serverReceivedAt: serverReceivedAt,
                serverSeq: serverSeq,
                syncState: syncState,
                syncError: syncError,
                updatedAtDevice: updatedAtDevice,
                name: name,
                locationNote: locationNote,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SitesTable, Site>(table),
                  BaseReferences<_$AppDatabase, $SitesTable, Site>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SitesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SitesTable,
      Site,
      $$SitesTableFilterComposer,
      $$SitesTableOrderingComposer,
      $$SitesTableAnnotationComposer,
      $$SitesTableCreateCompanionBuilder,
      $$SitesTableUpdateCompanionBuilder,
      (Site, BaseReferences<_$AppDatabase, $SitesTable, Site>),
      Site,
      PrefetchHooks Function()
    >;
typedef $$LocalMetaTableCreateCompanionBuilder = LocalMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$LocalMetaTableUpdateCompanionBuilder = LocalMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$LocalMetaTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMetaTable> {
  $$LocalMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMetaTable> {
  $$LocalMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMetaTable> {
  $$LocalMetaTableAnnotationComposer({
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

class $$LocalMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMetaTable,
          LocalMetaData,
          $$LocalMetaTableFilterComposer,
          $$LocalMetaTableOrderingComposer,
          $$LocalMetaTableAnnotationComposer,
          $$LocalMetaTableCreateCompanionBuilder,
          $$LocalMetaTableUpdateCompanionBuilder,
          (
            LocalMetaData,
            BaseReferences<_$AppDatabase, $LocalMetaTable, LocalMetaData>,
          ),
          LocalMetaData,
          PrefetchHooks Function()
        > {
  $$LocalMetaTableTableManager(_$AppDatabase db, $LocalMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => LocalMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => LocalMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalMetaTable, LocalMetaData>(table),
                  BaseReferences<_$AppDatabase, $LocalMetaTable, LocalMetaData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMetaTable,
      LocalMetaData,
      $$LocalMetaTableFilterComposer,
      $$LocalMetaTableOrderingComposer,
      $$LocalMetaTableAnnotationComposer,
      $$LocalMetaTableCreateCompanionBuilder,
      $$LocalMetaTableUpdateCompanionBuilder,
      (
        LocalMetaData,
        BaseReferences<_$AppDatabase, $LocalMetaTable, LocalMetaData>,
      ),
      LocalMetaData,
      PrefetchHooks Function()
    >;
typedef $$PeopleTableCreateCompanionBuilder = PeopleCompanion Function({
  Value<String> id,
  required String associationId,
  required String enteredBy,
  Value<String?> observedBy,
  Value<DateTime> createdAtDevice,
  required String deviceId,
  Value<DateTime?> serverReceivedAt,
  Value<int?> serverSeq,
  Value<SyncState> syncState,
  Value<String?> syncError,
  Value<DateTime> updatedAtDevice,
  required String name,
  Value<String?> phone,
  Value<String?> note,
  Value<bool> active,
  Value<int> rowid,
});
typedef $$PeopleTableUpdateCompanionBuilder = PeopleCompanion Function({
  Value<String> id,
  Value<String> associationId,
  Value<String> enteredBy,
  Value<String?> observedBy,
  Value<DateTime> createdAtDevice,
  Value<String> deviceId,
  Value<DateTime?> serverReceivedAt,
  Value<int?> serverSeq,
  Value<SyncState> syncState,
  Value<String?> syncError,
  Value<DateTime> updatedAtDevice,
  Value<String> name,
  Value<String?> phone,
  Value<String?> note,
  Value<bool> active,
  Value<int> rowid,
});

class $$PeopleTableFilterComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableFilterComposer({
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

  ColumnFilters<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enteredBy => $composableBuilder(
    column: $table.enteredBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtDevice => $composableBuilder(
    column: $table.updatedAtDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeopleTableOrderingComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableOrderingComposer({
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

  ColumnOrderings<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enteredBy => $composableBuilder(
    column: $table.enteredBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtDevice => $composableBuilder(
    column: $table.updatedAtDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeopleTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get enteredBy =>
      $composableBuilder(column: $table.enteredBy, builder: (column) => column);

  GeneratedColumn<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAtDevice => $composableBuilder(
    column: $table.updatedAtDevice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);
}

class $$PeopleTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeopleTable,
          Person,
          $$PeopleTableFilterComposer,
          $$PeopleTableOrderingComposer,
          $$PeopleTableAnnotationComposer,
          $$PeopleTableCreateCompanionBuilder,
          $$PeopleTableUpdateCompanionBuilder,
          (Person, BaseReferences<_$AppDatabase, $PeopleTable, Person>),
          Person,
          PrefetchHooks Function()
        > {
  $$PeopleTableTableManager(_$AppDatabase db, $PeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> associationId = const Value.absent(),
                Value<String> enteredBy = const Value.absent(),
                Value<String?> observedBy = const Value.absent(),
                Value<DateTime> createdAtDevice = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime?> serverReceivedAt = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> updatedAtDevice = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeopleCompanion(
                id: id,
                associationId: associationId,
                enteredBy: enteredBy,
                observedBy: observedBy,
                createdAtDevice: createdAtDevice,
                deviceId: deviceId,
                serverReceivedAt: serverReceivedAt,
                serverSeq: serverSeq,
                syncState: syncState,
                syncError: syncError,
                updatedAtDevice: updatedAtDevice,
                name: name,
                phone: phone,
                note: note,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String associationId,
                required String enteredBy,
                Value<String?> observedBy = const Value.absent(),
                Value<DateTime> createdAtDevice = const Value.absent(),
                required String deviceId,
                Value<DateTime?> serverReceivedAt = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> updatedAtDevice = const Value.absent(),
                required String name,
                Value<String?> phone = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeopleCompanion.insert(
                id: id,
                associationId: associationId,
                enteredBy: enteredBy,
                observedBy: observedBy,
                createdAtDevice: createdAtDevice,
                deviceId: deviceId,
                serverReceivedAt: serverReceivedAt,
                serverSeq: serverSeq,
                syncState: syncState,
                syncError: syncError,
                updatedAtDevice: updatedAtDevice,
                name: name,
                phone: phone,
                note: note,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PeopleTable, Person>(table),
                  BaseReferences<_$AppDatabase, $PeopleTable, Person>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeopleTable,
      Person,
      $$PeopleTableFilterComposer,
      $$PeopleTableOrderingComposer,
      $$PeopleTableAnnotationComposer,
      $$PeopleTableCreateCompanionBuilder,
      $$PeopleTableUpdateCompanionBuilder,
      (Person, BaseReferences<_$AppDatabase, $PeopleTable, Person>),
      Person,
      PrefetchHooks Function()
    >;
typedef $$PondsTableCreateCompanionBuilder = PondsCompanion Function({
  Value<String> id,
  required String associationId,
  required String enteredBy,
  Value<String?> observedBy,
  Value<DateTime> createdAtDevice,
  required String deviceId,
  Value<DateTime?> serverReceivedAt,
  Value<int?> serverSeq,
  Value<SyncState> syncState,
  Value<String?> syncError,
  Value<DateTime> updatedAtDevice,
  required String siteId,
  required String code,
  required PondColour colour,
  Value<StructureType> structure,
  required PondRole role,
  Value<WaterSupply?> waterSupply,
  Value<double?> lengthM,
  Value<double?> widthM,
  Value<double?> surfaceM2Override,
  Value<double?> depthInletM,
  Value<double?> depthOutletM,
  Value<PondStatus> status,
  Value<bool> archived,
  Value<int> rowid,
});
typedef $$PondsTableUpdateCompanionBuilder = PondsCompanion Function({
  Value<String> id,
  Value<String> associationId,
  Value<String> enteredBy,
  Value<String?> observedBy,
  Value<DateTime> createdAtDevice,
  Value<String> deviceId,
  Value<DateTime?> serverReceivedAt,
  Value<int?> serverSeq,
  Value<SyncState> syncState,
  Value<String?> syncError,
  Value<DateTime> updatedAtDevice,
  Value<String> siteId,
  Value<String> code,
  Value<PondColour> colour,
  Value<StructureType> structure,
  Value<PondRole> role,
  Value<WaterSupply?> waterSupply,
  Value<double?> lengthM,
  Value<double?> widthM,
  Value<double?> surfaceM2Override,
  Value<double?> depthInletM,
  Value<double?> depthOutletM,
  Value<PondStatus> status,
  Value<bool> archived,
  Value<int> rowid,
});

class $$PondsTableFilterComposer extends Composer<_$AppDatabase, $PondsTable> {
  $$PondsTableFilterComposer({
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

  ColumnFilters<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enteredBy => $composableBuilder(
    column: $table.enteredBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtDevice => $composableBuilder(
    column: $table.updatedAtDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PondColour, PondColour, String> get colour =>
      $composableBuilder(
        column: $table.colour,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<StructureType, StructureType, String>
  get structure => $composableBuilder(
    column: $table.structure,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<PondRole, PondRole, String> get role =>
      $composableBuilder(
        column: $table.role,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<WaterSupply?, WaterSupply, String>
  get waterSupply => $composableBuilder(
    column: $table.waterSupply,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get lengthM => $composableBuilder(
    column: $table.lengthM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get widthM => $composableBuilder(
    column: $table.widthM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get surfaceM2Override => $composableBuilder(
    column: $table.surfaceM2Override,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get depthInletM => $composableBuilder(
    column: $table.depthInletM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get depthOutletM => $composableBuilder(
    column: $table.depthOutletM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PondStatus, PondStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PondsTableOrderingComposer
    extends Composer<_$AppDatabase, $PondsTable> {
  $$PondsTableOrderingComposer({
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

  ColumnOrderings<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enteredBy => $composableBuilder(
    column: $table.enteredBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtDevice => $composableBuilder(
    column: $table.updatedAtDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colour => $composableBuilder(
    column: $table.colour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get structure => $composableBuilder(
    column: $table.structure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waterSupply => $composableBuilder(
    column: $table.waterSupply,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lengthM => $composableBuilder(
    column: $table.lengthM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get widthM => $composableBuilder(
    column: $table.widthM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get surfaceM2Override => $composableBuilder(
    column: $table.surfaceM2Override,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get depthInletM => $composableBuilder(
    column: $table.depthInletM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get depthOutletM => $composableBuilder(
    column: $table.depthOutletM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PondsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PondsTable> {
  $$PondsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get enteredBy =>
      $composableBuilder(column: $table.enteredBy, builder: (column) => column);

  GeneratedColumn<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAtDevice => $composableBuilder(
    column: $table.updatedAtDevice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PondColour, String> get colour =>
      $composableBuilder(column: $table.colour, builder: (column) => column);

  GeneratedColumnWithTypeConverter<StructureType, String> get structure =>
      $composableBuilder(column: $table.structure, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PondRole, String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WaterSupply?, String> get waterSupply =>
      $composableBuilder(
        column: $table.waterSupply,
        builder: (column) => column,
      );

  GeneratedColumn<double> get lengthM =>
      $composableBuilder(column: $table.lengthM, builder: (column) => column);

  GeneratedColumn<double> get widthM =>
      $composableBuilder(column: $table.widthM, builder: (column) => column);

  GeneratedColumn<double> get surfaceM2Override => $composableBuilder(
    column: $table.surfaceM2Override,
    builder: (column) => column,
  );

  GeneratedColumn<double> get depthInletM => $composableBuilder(
    column: $table.depthInletM,
    builder: (column) => column,
  );

  GeneratedColumn<double> get depthOutletM => $composableBuilder(
    column: $table.depthOutletM,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PondStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);
}

class $$PondsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PondsTable,
          Pond,
          $$PondsTableFilterComposer,
          $$PondsTableOrderingComposer,
          $$PondsTableAnnotationComposer,
          $$PondsTableCreateCompanionBuilder,
          $$PondsTableUpdateCompanionBuilder,
          (Pond, BaseReferences<_$AppDatabase, $PondsTable, Pond>),
          Pond,
          PrefetchHooks Function()
        > {
  $$PondsTableTableManager(_$AppDatabase db, $PondsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PondsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PondsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PondsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> associationId = const Value.absent(),
                Value<String> enteredBy = const Value.absent(),
                Value<String?> observedBy = const Value.absent(),
                Value<DateTime> createdAtDevice = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime?> serverReceivedAt = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> updatedAtDevice = const Value.absent(),
                Value<String> siteId = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<PondColour> colour = const Value.absent(),
                Value<StructureType> structure = const Value.absent(),
                Value<PondRole> role = const Value.absent(),
                Value<WaterSupply?> waterSupply = const Value.absent(),
                Value<double?> lengthM = const Value.absent(),
                Value<double?> widthM = const Value.absent(),
                Value<double?> surfaceM2Override = const Value.absent(),
                Value<double?> depthInletM = const Value.absent(),
                Value<double?> depthOutletM = const Value.absent(),
                Value<PondStatus> status = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PondsCompanion(
                id: id,
                associationId: associationId,
                enteredBy: enteredBy,
                observedBy: observedBy,
                createdAtDevice: createdAtDevice,
                deviceId: deviceId,
                serverReceivedAt: serverReceivedAt,
                serverSeq: serverSeq,
                syncState: syncState,
                syncError: syncError,
                updatedAtDevice: updatedAtDevice,
                siteId: siteId,
                code: code,
                colour: colour,
                structure: structure,
                role: role,
                waterSupply: waterSupply,
                lengthM: lengthM,
                widthM: widthM,
                surfaceM2Override: surfaceM2Override,
                depthInletM: depthInletM,
                depthOutletM: depthOutletM,
                status: status,
                archived: archived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String associationId,
                required String enteredBy,
                Value<String?> observedBy = const Value.absent(),
                Value<DateTime> createdAtDevice = const Value.absent(),
                required String deviceId,
                Value<DateTime?> serverReceivedAt = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> updatedAtDevice = const Value.absent(),
                required String siteId,
                required String code,
                required PondColour colour,
                Value<StructureType> structure = const Value.absent(),
                required PondRole role,
                Value<WaterSupply?> waterSupply = const Value.absent(),
                Value<double?> lengthM = const Value.absent(),
                Value<double?> widthM = const Value.absent(),
                Value<double?> surfaceM2Override = const Value.absent(),
                Value<double?> depthInletM = const Value.absent(),
                Value<double?> depthOutletM = const Value.absent(),
                Value<PondStatus> status = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PondsCompanion.insert(
                id: id,
                associationId: associationId,
                enteredBy: enteredBy,
                observedBy: observedBy,
                createdAtDevice: createdAtDevice,
                deviceId: deviceId,
                serverReceivedAt: serverReceivedAt,
                serverSeq: serverSeq,
                syncState: syncState,
                syncError: syncError,
                updatedAtDevice: updatedAtDevice,
                siteId: siteId,
                code: code,
                colour: colour,
                structure: structure,
                role: role,
                waterSupply: waterSupply,
                lengthM: lengthM,
                widthM: widthM,
                surfaceM2Override: surfaceM2Override,
                depthInletM: depthInletM,
                depthOutletM: depthOutletM,
                status: status,
                archived: archived,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PondsTable, Pond>(table),
                  BaseReferences<_$AppDatabase, $PondsTable, Pond>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PondsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PondsTable,
      Pond,
      $$PondsTableFilterComposer,
      $$PondsTableOrderingComposer,
      $$PondsTableAnnotationComposer,
      $$PondsTableCreateCompanionBuilder,
      $$PondsTableUpdateCompanionBuilder,
      (Pond, BaseReferences<_$AppDatabase, $PondsTable, Pond>),
      Pond,
      PrefetchHooks Function()
    >;
typedef $$BatchesTableCreateCompanionBuilder = BatchesCompanion Function({
  Value<String> id,
  required String associationId,
  required String enteredBy,
  Value<String?> observedBy,
  Value<DateTime> createdAtDevice,
  required String deviceId,
  Value<DateTime?> serverReceivedAt,
  Value<int?> serverSeq,
  Value<SyncState> syncState,
  Value<String?> syncError,
  Value<DateTime> updatedAtDevice,
  required String siteId,
  required String code,
  Value<String?> strain,
  Value<String?> hatchery,
  Value<String?> certificateNo,
  Value<bool?> monosex,
  Value<DateTime?> plannedHarvestOn,
  required BatchStatus status,
  Value<int> rowid,
});
typedef $$BatchesTableUpdateCompanionBuilder = BatchesCompanion Function({
  Value<String> id,
  Value<String> associationId,
  Value<String> enteredBy,
  Value<String?> observedBy,
  Value<DateTime> createdAtDevice,
  Value<String> deviceId,
  Value<DateTime?> serverReceivedAt,
  Value<int?> serverSeq,
  Value<SyncState> syncState,
  Value<String?> syncError,
  Value<DateTime> updatedAtDevice,
  Value<String> siteId,
  Value<String> code,
  Value<String?> strain,
  Value<String?> hatchery,
  Value<String?> certificateNo,
  Value<bool?> monosex,
  Value<DateTime?> plannedHarvestOn,
  Value<BatchStatus> status,
  Value<int> rowid,
});

class $$BatchesTableFilterComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableFilterComposer({
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

  ColumnFilters<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enteredBy => $composableBuilder(
    column: $table.enteredBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtDevice => $composableBuilder(
    column: $table.updatedAtDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strain => $composableBuilder(
    column: $table.strain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hatchery => $composableBuilder(
    column: $table.hatchery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get certificateNo => $composableBuilder(
    column: $table.certificateNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get monosex => $composableBuilder(
    column: $table.monosex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get plannedHarvestOn => $composableBuilder(
    column: $table.plannedHarvestOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BatchStatus, BatchStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$BatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableOrderingComposer({
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

  ColumnOrderings<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enteredBy => $composableBuilder(
    column: $table.enteredBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtDevice => $composableBuilder(
    column: $table.updatedAtDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strain => $composableBuilder(
    column: $table.strain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hatchery => $composableBuilder(
    column: $table.hatchery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get certificateNo => $composableBuilder(
    column: $table.certificateNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get monosex => $composableBuilder(
    column: $table.monosex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get plannedHarvestOn => $composableBuilder(
    column: $table.plannedHarvestOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get enteredBy =>
      $composableBuilder(column: $table.enteredBy, builder: (column) => column);

  GeneratedColumn<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAtDevice => $composableBuilder(
    column: $table.updatedAtDevice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get strain =>
      $composableBuilder(column: $table.strain, builder: (column) => column);

  GeneratedColumn<String> get hatchery =>
      $composableBuilder(column: $table.hatchery, builder: (column) => column);

  GeneratedColumn<String> get certificateNo => $composableBuilder(
    column: $table.certificateNo,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get monosex =>
      $composableBuilder(column: $table.monosex, builder: (column) => column);

  GeneratedColumn<DateTime> get plannedHarvestOn => $composableBuilder(
    column: $table.plannedHarvestOn,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<BatchStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$BatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BatchesTable,
          Batch,
          $$BatchesTableFilterComposer,
          $$BatchesTableOrderingComposer,
          $$BatchesTableAnnotationComposer,
          $$BatchesTableCreateCompanionBuilder,
          $$BatchesTableUpdateCompanionBuilder,
          (Batch, BaseReferences<_$AppDatabase, $BatchesTable, Batch>),
          Batch,
          PrefetchHooks Function()
        > {
  $$BatchesTableTableManager(_$AppDatabase db, $BatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> associationId = const Value.absent(),
                Value<String> enteredBy = const Value.absent(),
                Value<String?> observedBy = const Value.absent(),
                Value<DateTime> createdAtDevice = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime?> serverReceivedAt = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> updatedAtDevice = const Value.absent(),
                Value<String> siteId = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String?> strain = const Value.absent(),
                Value<String?> hatchery = const Value.absent(),
                Value<String?> certificateNo = const Value.absent(),
                Value<bool?> monosex = const Value.absent(),
                Value<DateTime?> plannedHarvestOn = const Value.absent(),
                Value<BatchStatus> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BatchesCompanion(
                id: id,
                associationId: associationId,
                enteredBy: enteredBy,
                observedBy: observedBy,
                createdAtDevice: createdAtDevice,
                deviceId: deviceId,
                serverReceivedAt: serverReceivedAt,
                serverSeq: serverSeq,
                syncState: syncState,
                syncError: syncError,
                updatedAtDevice: updatedAtDevice,
                siteId: siteId,
                code: code,
                strain: strain,
                hatchery: hatchery,
                certificateNo: certificateNo,
                monosex: monosex,
                plannedHarvestOn: plannedHarvestOn,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String associationId,
                required String enteredBy,
                Value<String?> observedBy = const Value.absent(),
                Value<DateTime> createdAtDevice = const Value.absent(),
                required String deviceId,
                Value<DateTime?> serverReceivedAt = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> updatedAtDevice = const Value.absent(),
                required String siteId,
                required String code,
                Value<String?> strain = const Value.absent(),
                Value<String?> hatchery = const Value.absent(),
                Value<String?> certificateNo = const Value.absent(),
                Value<bool?> monosex = const Value.absent(),
                Value<DateTime?> plannedHarvestOn = const Value.absent(),
                required BatchStatus status,
                Value<int> rowid = const Value.absent(),
              }) => BatchesCompanion.insert(
                id: id,
                associationId: associationId,
                enteredBy: enteredBy,
                observedBy: observedBy,
                createdAtDevice: createdAtDevice,
                deviceId: deviceId,
                serverReceivedAt: serverReceivedAt,
                serverSeq: serverSeq,
                syncState: syncState,
                syncError: syncError,
                updatedAtDevice: updatedAtDevice,
                siteId: siteId,
                code: code,
                strain: strain,
                hatchery: hatchery,
                certificateNo: certificateNo,
                monosex: monosex,
                plannedHarvestOn: plannedHarvestOn,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BatchesTable, Batch>(table),
                  BaseReferences<_$AppDatabase, $BatchesTable, Batch>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BatchesTable,
      Batch,
      $$BatchesTableFilterComposer,
      $$BatchesTableOrderingComposer,
      $$BatchesTableAnnotationComposer,
      $$BatchesTableCreateCompanionBuilder,
      $$BatchesTableUpdateCompanionBuilder,
      (Batch, BaseReferences<_$AppDatabase, $BatchesTable, Batch>),
      Batch,
      PrefetchHooks Function()
    >;
typedef $$StockingsTableCreateCompanionBuilder = StockingsCompanion Function({
  Value<String> id,
  required String associationId,
  required String enteredBy,
  Value<String?> observedBy,
  Value<DateTime> createdAtDevice,
  required String deviceId,
  Value<DateTime?> serverReceivedAt,
  Value<int?> serverSeq,
  Value<SyncState> syncState,
  Value<String?> syncError,
  required DateTime recordedAt,
  Value<String?> supersedesId,
  Value<bool> isTombstone,
  required String batchId,
  required String pondId,
  required int count,
  required int avgWeightMg,
  Value<bool?> acclimatised,
  Value<int> rowid,
});
typedef $$StockingsTableUpdateCompanionBuilder = StockingsCompanion Function({
  Value<String> id,
  Value<String> associationId,
  Value<String> enteredBy,
  Value<String?> observedBy,
  Value<DateTime> createdAtDevice,
  Value<String> deviceId,
  Value<DateTime?> serverReceivedAt,
  Value<int?> serverSeq,
  Value<SyncState> syncState,
  Value<String?> syncError,
  Value<DateTime> recordedAt,
  Value<String?> supersedesId,
  Value<bool> isTombstone,
  Value<String> batchId,
  Value<String> pondId,
  Value<int> count,
  Value<int> avgWeightMg,
  Value<bool?> acclimatised,
  Value<int> rowid,
});

class $$StockingsTableFilterComposer
    extends Composer<_$AppDatabase, $StockingsTable> {
  $$StockingsTableFilterComposer({
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

  ColumnFilters<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enteredBy => $composableBuilder(
    column: $table.enteredBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supersedesId => $composableBuilder(
    column: $table.supersedesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTombstone => $composableBuilder(
    column: $table.isTombstone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pondId => $composableBuilder(
    column: $table.pondId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avgWeightMg => $composableBuilder(
    column: $table.avgWeightMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get acclimatised => $composableBuilder(
    column: $table.acclimatised,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockingsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockingsTable> {
  $$StockingsTableOrderingComposer({
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

  ColumnOrderings<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enteredBy => $composableBuilder(
    column: $table.enteredBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supersedesId => $composableBuilder(
    column: $table.supersedesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTombstone => $composableBuilder(
    column: $table.isTombstone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pondId => $composableBuilder(
    column: $table.pondId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avgWeightMg => $composableBuilder(
    column: $table.avgWeightMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get acclimatised => $composableBuilder(
    column: $table.acclimatised,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockingsTable> {
  $$StockingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get enteredBy =>
      $composableBuilder(column: $table.enteredBy, builder: (column) => column);

  GeneratedColumn<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supersedesId => $composableBuilder(
    column: $table.supersedesId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTombstone => $composableBuilder(
    column: $table.isTombstone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<String> get pondId =>
      $composableBuilder(column: $table.pondId, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<int> get avgWeightMg => $composableBuilder(
    column: $table.avgWeightMg,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get acclimatised => $composableBuilder(
    column: $table.acclimatised,
    builder: (column) => column,
  );
}

class $$StockingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockingsTable,
          Stocking,
          $$StockingsTableFilterComposer,
          $$StockingsTableOrderingComposer,
          $$StockingsTableAnnotationComposer,
          $$StockingsTableCreateCompanionBuilder,
          $$StockingsTableUpdateCompanionBuilder,
          (Stocking, BaseReferences<_$AppDatabase, $StockingsTable, Stocking>),
          Stocking,
          PrefetchHooks Function()
        > {
  $$StockingsTableTableManager(_$AppDatabase db, $StockingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> associationId = const Value.absent(),
                Value<String> enteredBy = const Value.absent(),
                Value<String?> observedBy = const Value.absent(),
                Value<DateTime> createdAtDevice = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime?> serverReceivedAt = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String?> supersedesId = const Value.absent(),
                Value<bool> isTombstone = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<String> pondId = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int> avgWeightMg = const Value.absent(),
                Value<bool?> acclimatised = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockingsCompanion(
                id: id,
                associationId: associationId,
                enteredBy: enteredBy,
                observedBy: observedBy,
                createdAtDevice: createdAtDevice,
                deviceId: deviceId,
                serverReceivedAt: serverReceivedAt,
                serverSeq: serverSeq,
                syncState: syncState,
                syncError: syncError,
                recordedAt: recordedAt,
                supersedesId: supersedesId,
                isTombstone: isTombstone,
                batchId: batchId,
                pondId: pondId,
                count: count,
                avgWeightMg: avgWeightMg,
                acclimatised: acclimatised,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String associationId,
                required String enteredBy,
                Value<String?> observedBy = const Value.absent(),
                Value<DateTime> createdAtDevice = const Value.absent(),
                required String deviceId,
                Value<DateTime?> serverReceivedAt = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                required DateTime recordedAt,
                Value<String?> supersedesId = const Value.absent(),
                Value<bool> isTombstone = const Value.absent(),
                required String batchId,
                required String pondId,
                required int count,
                required int avgWeightMg,
                Value<bool?> acclimatised = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockingsCompanion.insert(
                id: id,
                associationId: associationId,
                enteredBy: enteredBy,
                observedBy: observedBy,
                createdAtDevice: createdAtDevice,
                deviceId: deviceId,
                serverReceivedAt: serverReceivedAt,
                serverSeq: serverSeq,
                syncState: syncState,
                syncError: syncError,
                recordedAt: recordedAt,
                supersedesId: supersedesId,
                isTombstone: isTombstone,
                batchId: batchId,
                pondId: pondId,
                count: count,
                avgWeightMg: avgWeightMg,
                acclimatised: acclimatised,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StockingsTable, Stocking>(table),
                  BaseReferences<_$AppDatabase, $StockingsTable, Stocking>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockingsTable,
      Stocking,
      $$StockingsTableFilterComposer,
      $$StockingsTableOrderingComposer,
      $$StockingsTableAnnotationComposer,
      $$StockingsTableCreateCompanionBuilder,
      $$StockingsTableUpdateCompanionBuilder,
      (Stocking, BaseReferences<_$AppDatabase, $StockingsTable, Stocking>),
      Stocking,
      PrefetchHooks Function()
    >;
typedef $$TransfersTableCreateCompanionBuilder = TransfersCompanion Function({
  Value<String> id,
  required String associationId,
  required String enteredBy,
  Value<String?> observedBy,
  Value<DateTime> createdAtDevice,
  required String deviceId,
  Value<DateTime?> serverReceivedAt,
  Value<int?> serverSeq,
  Value<SyncState> syncState,
  Value<String?> syncError,
  required DateTime recordedAt,
  Value<String?> supersedesId,
  Value<bool> isTombstone,
  required String batchId,
  required String fromPondId,
  required String toPondId,
  required int count,
  Value<int?> avgWeightMg,
  Value<int> rowid,
});
typedef $$TransfersTableUpdateCompanionBuilder = TransfersCompanion Function({
  Value<String> id,
  Value<String> associationId,
  Value<String> enteredBy,
  Value<String?> observedBy,
  Value<DateTime> createdAtDevice,
  Value<String> deviceId,
  Value<DateTime?> serverReceivedAt,
  Value<int?> serverSeq,
  Value<SyncState> syncState,
  Value<String?> syncError,
  Value<DateTime> recordedAt,
  Value<String?> supersedesId,
  Value<bool> isTombstone,
  Value<String> batchId,
  Value<String> fromPondId,
  Value<String> toPondId,
  Value<int> count,
  Value<int?> avgWeightMg,
  Value<int> rowid,
});

class $$TransfersTableFilterComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableFilterComposer({
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

  ColumnFilters<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enteredBy => $composableBuilder(
    column: $table.enteredBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supersedesId => $composableBuilder(
    column: $table.supersedesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTombstone => $composableBuilder(
    column: $table.isTombstone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromPondId => $composableBuilder(
    column: $table.fromPondId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toPondId => $composableBuilder(
    column: $table.toPondId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avgWeightMg => $composableBuilder(
    column: $table.avgWeightMg,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransfersTableOrderingComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableOrderingComposer({
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

  ColumnOrderings<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enteredBy => $composableBuilder(
    column: $table.enteredBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supersedesId => $composableBuilder(
    column: $table.supersedesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTombstone => $composableBuilder(
    column: $table.isTombstone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromPondId => $composableBuilder(
    column: $table.fromPondId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toPondId => $composableBuilder(
    column: $table.toPondId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avgWeightMg => $composableBuilder(
    column: $table.avgWeightMg,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransfersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get associationId => $composableBuilder(
    column: $table.associationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get enteredBy =>
      $composableBuilder(column: $table.enteredBy, builder: (column) => column);

  GeneratedColumn<String> get observedBy => $composableBuilder(
    column: $table.observedBy,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtDevice => $composableBuilder(
    column: $table.createdAtDevice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get serverReceivedAt => $composableBuilder(
    column: $table.serverReceivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supersedesId => $composableBuilder(
    column: $table.supersedesId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTombstone => $composableBuilder(
    column: $table.isTombstone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<String> get fromPondId => $composableBuilder(
    column: $table.fromPondId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toPondId =>
      $composableBuilder(column: $table.toPondId, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<int> get avgWeightMg => $composableBuilder(
    column: $table.avgWeightMg,
    builder: (column) => column,
  );
}

class $$TransfersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransfersTable,
          Transfer,
          $$TransfersTableFilterComposer,
          $$TransfersTableOrderingComposer,
          $$TransfersTableAnnotationComposer,
          $$TransfersTableCreateCompanionBuilder,
          $$TransfersTableUpdateCompanionBuilder,
          (Transfer, BaseReferences<_$AppDatabase, $TransfersTable, Transfer>),
          Transfer,
          PrefetchHooks Function()
        > {
  $$TransfersTableTableManager(_$AppDatabase db, $TransfersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransfersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransfersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> associationId = const Value.absent(),
                Value<String> enteredBy = const Value.absent(),
                Value<String?> observedBy = const Value.absent(),
                Value<DateTime> createdAtDevice = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime?> serverReceivedAt = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String?> supersedesId = const Value.absent(),
                Value<bool> isTombstone = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<String> fromPondId = const Value.absent(),
                Value<String> toPondId = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int?> avgWeightMg = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransfersCompanion(
                id: id,
                associationId: associationId,
                enteredBy: enteredBy,
                observedBy: observedBy,
                createdAtDevice: createdAtDevice,
                deviceId: deviceId,
                serverReceivedAt: serverReceivedAt,
                serverSeq: serverSeq,
                syncState: syncState,
                syncError: syncError,
                recordedAt: recordedAt,
                supersedesId: supersedesId,
                isTombstone: isTombstone,
                batchId: batchId,
                fromPondId: fromPondId,
                toPondId: toPondId,
                count: count,
                avgWeightMg: avgWeightMg,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String associationId,
                required String enteredBy,
                Value<String?> observedBy = const Value.absent(),
                Value<DateTime> createdAtDevice = const Value.absent(),
                required String deviceId,
                Value<DateTime?> serverReceivedAt = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                required DateTime recordedAt,
                Value<String?> supersedesId = const Value.absent(),
                Value<bool> isTombstone = const Value.absent(),
                required String batchId,
                required String fromPondId,
                required String toPondId,
                required int count,
                Value<int?> avgWeightMg = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransfersCompanion.insert(
                id: id,
                associationId: associationId,
                enteredBy: enteredBy,
                observedBy: observedBy,
                createdAtDevice: createdAtDevice,
                deviceId: deviceId,
                serverReceivedAt: serverReceivedAt,
                serverSeq: serverSeq,
                syncState: syncState,
                syncError: syncError,
                recordedAt: recordedAt,
                supersedesId: supersedesId,
                isTombstone: isTombstone,
                batchId: batchId,
                fromPondId: fromPondId,
                toPondId: toPondId,
                count: count,
                avgWeightMg: avgWeightMg,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransfersTable, Transfer>(table),
                  BaseReferences<_$AppDatabase, $TransfersTable, Transfer>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransfersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransfersTable,
      Transfer,
      $$TransfersTableFilterComposer,
      $$TransfersTableOrderingComposer,
      $$TransfersTableAnnotationComposer,
      $$TransfersTableCreateCompanionBuilder,
      $$TransfersTableUpdateCompanionBuilder,
      (Transfer, BaseReferences<_$AppDatabase, $TransfersTable, Transfer>),
      Transfer,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db, _db.sites);
  $$LocalMetaTableTableManager get localMeta =>
      $$LocalMetaTableTableManager(_db, _db.localMeta);
  $$PeopleTableTableManager get people =>
      $$PeopleTableTableManager(_db, _db.people);
  $$PondsTableTableManager get ponds =>
      $$PondsTableTableManager(_db, _db.ponds);
  $$BatchesTableTableManager get batches =>
      $$BatchesTableTableManager(_db, _db.batches);
  $$StockingsTableTableManager get stockings =>
      $$StockingsTableTableManager(_db, _db.stockings);
  $$TransfersTableTableManager get transfers =>
      $$TransfersTableTableManager(_db, _db.transfers);
}
