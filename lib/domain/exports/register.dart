import '../dates.dart';
import '../farm_facts.dart';
import '../occupancy.dart';
import '../report/report_content.dart';
import '../types.dart';

/// A sale, with the pond of the harvest it came from.
class SaleFact {
  const SaleFact({
    required this.date,
    required this.batchId,
    required this.pondId,
    required this.weightG,
    required this.customerId,
    required this.form,
  });

  final DateTime date;
  final String batchId;
  final String pondId;
  final int weightG;
  final String customerId;
  final ProductForm form;
}

/// One line of the production register (handbook Annex A): one record.
sealed class RegisterRow {
  const RegisterRow();

  DateTime get date;
  String get pondId;

  /// The batches the line is about; for a daily log, those in its pond.
  List<String> get batchIds;

  /// Same-day order: stock movements, then feeding, then what leaves.
  int get _kind;
}

class StockingRow extends RegisterRow {
  const StockingRow(this.stocking);

  final StockingFact stocking;

  @override
  DateTime get date => stocking.date;
  @override
  String get pondId => stocking.pondId;
  @override
  List<String> get batchIds => [stocking.batchId];
  @override
  int get _kind => 0;
}

/// Under the pond the fish left; [toPondId] is where they went.
class TransferRow extends RegisterRow {
  const TransferRow(this.transfer);

  final TransferFact transfer;

  String get toPondId => transfer.toPondId;
  @override
  DateTime get date => transfer.date;
  @override
  String get pondId => transfer.fromPondId;
  @override
  List<String> get batchIds => [transfer.batchId];
  @override
  int get _kind => 1;
}

class LogRow extends RegisterRow {
  const LogRow(this.log, this.batchIds);

  final LogFact log;
  @override
  final List<String> batchIds;
  @override
  DateTime get date => log.date;
  @override
  String get pondId => log.pondId;
  @override
  int get _kind => 2;
}

class HarvestRow extends RegisterRow {
  const HarvestRow(this.harvest);

  final HarvestFact harvest;

  @override
  DateTime get date => harvest.date;
  @override
  String get pondId => harvest.pondId;
  @override
  List<String> get batchIds => [harvest.batchId];
  @override
  int get _kind => 3;
}

class SaleRow extends RegisterRow {
  const SaleRow(this.sale);

  final SaleFact sale;

  @override
  DateTime get date => sale.date;
  @override
  String get pondId => sale.pondId;
  @override
  List<String> get batchIds => [sale.batchId];
  @override
  int get _kind => 4;
}

class TreatmentRow extends RegisterRow {
  const TreatmentRow(this.pondId, this.treatment, this.batchIds);

  final TreatmentLine treatment;
  @override
  final String pondId;
  @override
  final List<String> batchIds;
  @override
  DateTime get date => treatment.at;
  @override
  int get _kind => 5;
}

class HealthRow extends RegisterRow {
  const HealthRow(this.pondId, this.event, this.batchIds);

  final HealthLine event;
  @override
  final String pondId;
  @override
  final List<String> batchIds;
  @override
  DateTime get date => event.at;
  @override
  int get _kind => 6;
}

/// The production register from [from] to [to] (farm days, both included),
/// for one pond or all (plan M8 Decision 7). Daily logs count once per
/// pond-day, as everywhere else ([countedLogs]). Sorted by farm day, then
/// kind, then pond id; the formatter sorts by pond code.
List<RegisterRow> productionRegister({
  required FarmFacts facts,
  List<SaleFact> sales = const [],
  List<(String pondId, TreatmentLine)> treatments = const [],
  List<(String pondId, HealthLine)> health = const [],
  required DateTime from,
  required DateTime to,
  String? pondId,
}) {
  final first = farmDayNumber(from);
  final last = farmDayNumber(to);
  bool inRange(DateTime t) {
    final n = farmDayNumber(t);
    return n >= first && n <= last;
  }

  bool inPond(String id) => pondId == null || id == pondId;

  /// Batches in [pond] at the end of the day before [day] or of [day]
  /// itself: fish stocked, moved out or harvested that day still count.
  List<String> batchesIn(String pond, DateTime day) {
    final farmDay = farmDate(day);
    final before = DateTime(farmDay.year, farmDay.month, farmDay.day - 1);
    return {
      for (final until in [before, farmDay])
        for (final p in placementsOf(facts, until: until))
          if (p.pondId == pond && p.live.count > 0) p.batchId,
    }.toList();
  }

  final rows = <RegisterRow>[
    for (final s in facts.stockings)
      if (inRange(s.date) && inPond(s.pondId)) StockingRow(s),
    for (final t in facts.transfers)
      if (inRange(t.date) && (inPond(t.fromPondId) || inPond(t.toPondId)))
        TransferRow(t),
    for (final l in countedLogs(facts))
      if (inRange(l.date) && inPond(l.pondId))
        LogRow(l, batchesIn(l.pondId, l.date)),
    for (final h in facts.harvests)
      if (inRange(h.date) && inPond(h.pondId)) HarvestRow(h),
    for (final s in sales)
      if (inRange(s.date) && inPond(s.pondId)) SaleRow(s),
    for (final (pond, t) in treatments)
      if (inRange(t.at) && inPond(pond))
        TreatmentRow(
          pond,
          t,
          t.batchId != null ? [t.batchId!] : batchesIn(pond, t.at),
        ),
    for (final (pond, h) in health)
      if (inRange(h.at) && inPond(pond))
        HealthRow(pond, h, batchesIn(pond, h.at)),
  ];
  // List.sort isn't stable: the input position breaks the last ties.
  final indexed = rows.indexed.toList()
    ..sort((a, b) {
      final (i, x) = a;
      final (j, y) = b;
      return [
        farmDayNumber(x.date).compareTo(farmDayNumber(y.date)),
        x._kind.compareTo(y._kind),
        x.pondId.compareTo(y.pondId),
        i.compareTo(j),
      ].firstWhere((c) => c != 0, orElse: () => 0);
    });
  return [for (final (_, r) in indexed) r];
}
