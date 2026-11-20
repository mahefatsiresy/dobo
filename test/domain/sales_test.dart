import 'package:dobo/domain/sales.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('what is left to sell is the harvest less its sales', () {
    expect(unsoldG(45000, [40000]), 5000);
  });

  test('a harvest with no sales is all left to sell', () {
    expect(unsoldG(45000, []), 45000);
  });

  test('sales above the harvest leave nothing, never a negative', () {
    expect(unsoldG(30000, [40000]), 0);
  });
}
