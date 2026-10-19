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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SitesTable sites = $SitesTable(this);
  late final $LocalMetaTable localMeta = $LocalMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [sites, localMeta];
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db, _db.sites);
  $$LocalMetaTableTableManager get localMeta =>
      $$LocalMetaTableTableManager(_db, _db.localMeta);
}
