import 'package:dobo/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../golden_fonts.dart';
import '../../helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final code in ['fr', 'mg']) {
    appTest('every tab label fits on one line on a 360 dp phone ($code)', (
      tester,
      db,
    ) async {
      tester.view.physicalSize = const Size(720, 1560);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      appContainer(tester)
          .read(localeControllerProvider.notifier)
          .set(Locale(code));
      await tester.pumpAndSettle();
      final labels = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byType(Text),
      );
      expect(labels, findsWidgets);
      for (final label in labels.evaluate()) {
        final text = label.widget as Text;
        final style = DefaultTextStyle.of(label).style.merge(text.style);
        final oneLine = TextPainter(
          text: TextSpan(text: text.data, style: style),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(label),
        )..layout();
        expect(
          tester.getSize(find.byWidget(text)).height,
          lessThanOrEqualTo(oneLine.height),
          reason: '"${text.data}" wraps',
        );
        oneLine.dispose();
      }
    });
  }
}
