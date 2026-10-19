import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/pond.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cfg = DomainConfig.defaults;

  test('prep doses scale with surface', () {
    final d = prepDoses(500, cfg)!;
    expect(
      (d.limeKg.min, d.limeKg.max, d.manureKg.min, d.manureKg.max),
      (50.0, 100.0, 10.0, 15.0),
    );
  });

  test('no surface, no doses', () {
    expect(prepDoses(null, cfg), isNull);
    expect(prepDoses(0, cfg), isNull);
  });

  test('design warnings', () {
    Set<PondDesignWarning> w({
      double? l,
      double? wd,
      double? dIn,
      double? dOut,
    }) => pondDesignWarnings(
      lengthM: l,
      widthM: wd,
      depthInletM: dIn,
      depthOutletM: dOut,
      config: cfg,
    );
    expect(w(l: 30, wd: 15, dIn: 0.8, dOut: 1.2), isEmpty);
    expect(w(l: 40, wd: 12.5), {PondDesignWarning.tooElongated});
    expect(w(l: 10, wd: 10), {
      PondDesignWarning.surfaceTooSmall,
      PondDesignWarning.notElongated,
    });
    expect(w(l: 50, wd: 30), {
      PondDesignWarning.surfaceTooLarge,
      PondDesignWarning.notElongated,
    });
    expect(w(dIn: 0.6, dOut: 0.9), {PondDesignWarning.tooShallow});
    expect(w(), isEmpty);
  });
}
