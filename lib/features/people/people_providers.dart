import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';

final peopleProvider = StreamProvider<List<Person>>(
  (ref) => ref.watch(personRepositoryProvider).watchAll(),
);
