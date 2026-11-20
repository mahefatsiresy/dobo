/// What is left to sell of a harvest: its weight less the sales linked to
/// it, never below zero (a harvest corrected to less than was sold).
int unsoldG(int harvestG, Iterable<int> soldG) {
  final left = harvestG - soldG.fold<int>(0, (n, g) => n + g);
  return left < 0 ? 0 : left;
}
