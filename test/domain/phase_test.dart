import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/phase.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cfg = DomainConfig.defaults;

  test('boundary weights belong to the heavier phase', () {
    expect(phaseFor(4.99, cfg), Phase.fry);
    expect(phaseFor(5.0, cfg), Phase.pregrow);
    expect(phaseFor(19.9, cfg), Phase.pregrow);
    expect(phaseFor(20.0, cfg), Phase.growout);
    expect(phaseFor(249.9, cfg), Phase.growout);
    expect(phaseFor(250.0, cfg), Phase.finishing);
  });

  test('feeding guide comes from config', () {
    expect(feedingGuideFor(Phase.growout, cfg).feedingsPerDay.max, 4);
  });
}
