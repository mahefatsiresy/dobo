import 'package:drift/drift.dart';

import '../domain/types.dart';

/// A set of enum values stored as their names, comma-separated, in
/// declaration order. Names this version doesn't know (written by a newer
/// app on another phone) are skipped rather than crashing.
class EnumSetConverter<E extends Enum> extends TypeConverter<Set<E>, String> {
  const EnumSetConverter(this.values);

  final List<E> values;

  @override
  Set<E> fromSql(String fromDb) {
    final names = fromDb.split(',').toSet();
    return {
      for (final v in values)
        if (names.contains(v.name)) v,
    };
  }

  @override
  String toSql(Set<E> value) => [
    for (final v in values)
      if (value.contains(v)) v.name,
  ].join(',');
}

const warningSignsConverter = EnumSetConverter(WarningSign.values);
const healthActionsConverter = EnumSetConverter(HealthAction.values);
