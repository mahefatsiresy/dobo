import 'package:supabase_flutter/supabase_flutter.dart';

import '../../db/ids.dart';
import '../../domain/types.dart';
import '../../sync/auth_gateway.dart';
import '../../sync/server_errors.dart';
import 'console_api.dart';

/// [ConsoleApi] over Supabase (M9 plan Decision 7). The browser is one more
/// device: [deviceId] stamps every row it writes.
class SupabaseConsoleApi implements ConsoleApi {
  SupabaseConsoleApi(this.client, this.deviceId);

  final SupabaseClient client;
  final String deviceId;

  /// The signed-in admin, for `entered_by` and the association id.
  ConsoleMe? _me;

  @override
  bool get hasSession => client.auth.currentSession != null;

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await guardServer(
        () => client.auth.signInWithPassword(
          email: email.trim().toLowerCase(),
          password: password,
        ),
      );
    } on AuthApiException catch (e) {
      throw AuthFailed(e.code ?? 'auth_failed');
    }
  }

  @override
  Future<void> signOut() async {
    _me = null;
    await client.auth.signOut(scope: SignOutScope.local);
  }

  @override
  Future<ConsoleMe> me() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw const AuthFailed('no_member');
    final rows = await guardServer(
      () => client.from('members').select().eq('user_id', userId),
    );
    if (rows.isEmpty) throw const AuthFailed('no_member');
    final m = rows.single;
    final association = await guardServer(
      () => client
          .from('associations')
          .select('name')
          .eq('id', m['association_id'] as String)
          .single(),
    );
    return _me = ConsoleMe(
      memberId: m['id'] as String,
      associationId: m['association_id'] as String,
      associationName: association['name'] as String,
      name: m['name'] as String,
      role: MemberRole.values.byName(m['role'] as String),
      isAdmin: m['is_admin'] as bool,
      active: m['active'] as bool,
      locale: m['locale'] as String,
    );
  }

  Future<ConsoleMe> _admin() async => _me ?? await me();

  @override
  Future<void> foundAssociation(Founding f) async {
    try {
      await _invoke('found-association', f.toJson(deviceId));
    } on AuthFailed catch (e) {
      if (e.code != 'login_taken') rethrow;
      // Maybe this very form founded it and the answer was lost: if its
      // login opens the association this form planned, founding is done.
      try {
        await signIn(f.email, f.password);
        if ((await me()).associationId == f.associationId) return;
      } on AuthFailed {
        // Not this founder's login.
      }
      await signOut();
      rethrow;
    }
    await signIn(f.email, f.password);
  }

  @override
  Future<void> renameAssociation(String name) async {
    final me = await _admin();
    final rows = await guardServer(
      () => client
          .from('associations')
          .update({'name': name.trim()})
          .eq('id', me.associationId)
          .select(),
    );
    if (rows.isEmpty) throw const ConsoleWriteFailed('42501');
    _me = null;
  }

  Future<List<Map<String, Object?>>> _rows(String table) => guardServer(
    () => client.from(table).select().order('name', ascending: true),
  );

  @override
  Future<List<GroupRow>> groups() async =>
      [for (final r in await _rows('groups')) GroupRow.fromJson(r)];

  @override
  Future<List<MemberRow>> members() async =>
      [for (final r in await _rows('members')) MemberRow.fromJson(r)];

  @override
  Future<List<PersonRow>> people() async =>
      [for (final r in await _rows('people')) PersonRow.fromJson(r)];

  @override
  Future<void> saveGroup(GroupRow g, {bool isNew = false}) =>
      _save('groups', g.id, g.raw, g.fields, isNew: isNew);

  @override
  Future<void> saveMember(MemberRow m) =>
      _save('members', m.id, m.raw, m.fields, isNew: false);

  @override
  Future<void> savePerson(PersonRow p, {bool isNew = false}) =>
      _save('people', p.id, p.raw, p.fields, isNew: isNew);

  /// Sends one reference row through `sync_push`: the row as read with the
  /// edits applied, stamped by this browser; or a new row.
  Future<void> _save(
    String table,
    String id,
    Map<String, Object?> raw,
    Map<String, Object?> fields, {
    required bool isNew,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final Map<String, Object?> row;
    if (isNew) {
      final me = await _admin();
      row = {
        'id': id,
        'association_id': me.associationId,
        'entered_by': me.memberId,
        'observed_by': null,
        'created_at_device': now,
        ...fields,
      };
    } else {
      row = {...raw, ...fields}
        ..remove('user_id')
        ..remove('server_seq')
        ..remove('server_received_at');
    }
    row['device_id'] = deviceId;
    row['updated_at_device'] = now;
    final result = await guardServer(
      () => client.rpc<List<dynamic>>(
        'sync_push',
        params: {
          'p_table': table,
          'p_rows': [row],
        },
      ),
    );
    final outcome = (result.single as Map).cast<String, Object?>();
    final code = outcome['error_code'] as String?;
    if (code != null) {
      // A code the server raised (`last_admin`) comes as P0001 + message.
      throw ConsoleWriteFailed(
        code == 'P0001' ? '${outcome['error_message']}' : code,
      );
    }
  }

  @override
  Future<void> createAccount(NewAccount a) async {
    final personId = a.personId ?? accountPersonId(a.memberId);
    await savePerson(PersonRow(id: personId, name: a.name), isNew: true);
    await _invoke('create-account', {...a.toJson(), 'personId': personId});
  }

  @override
  Future<void> resetSecret(String memberId, String secret) =>
      _invoke('reset-secret', {'memberId': memberId, 'secret': secret});

  /// Calls an edge function; its `{error}` answer becomes [AuthFailed].
  Future<void> _invoke(String fn, Map<String, Object?> body) async {
    try {
      await guardServer(() => client.functions.invoke(fn, body: body));
    } on FunctionException catch (e) {
      final details = e.details;
      throw AuthFailed(
        details is Map && details['error'] is String
            ? details['error'] as String
            : 'status_${e.status}',
      );
    }
  }
}
