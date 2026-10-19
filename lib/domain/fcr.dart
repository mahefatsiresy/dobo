/// Feed conversion ratio: feed given ÷ weight gained. DOMAIN §Formulas.
sealed class FcrResult {
  const FcrResult();
}

final class FcrValue extends FcrResult {
  const FcrValue(this.value);

  final double value;
}

/// No weight gained, so the ratio is undefined.
final class FcrStalled extends FcrResult {
  const FcrStalled();
}

FcrResult _ratio(int feedG, int gainG) =>
    gainG <= 0 ? const FcrStalled() : FcrValue(feedG / gainG);

/// Economic FCR between two samples: deaths are not added back.
FcrResult periodFcr({
  required int feedG,
  required int biomassPrevG,
  required int biomassNowG,
  int outWeightG = 0,
  int inWeightG = 0,
}) =>
    _ratio(feedG, (biomassNowG + outWeightG) - (biomassPrevG + inWeightG));

FcrResult cycleFcr({
  required int totalFeedG,
  required int harvestedG,
  required int stockedG,
}) =>
    _ratio(totalFeedG, harvestedG - stockedG);

/// True when FCR rose at each of the last two samples. DOMAIN §Alert rules.
bool isFcrWorsening(List<FcrResult> chronological) {
  if (chronological.length < 3) return false;
  final last = chronological.sublist(chronological.length - 3);
  if (last.any((r) => r is! FcrValue)) return false;
  final v = [for (final r in last) (r as FcrValue).value];
  return v[0] < v[1] && v[1] < v[2];
}
