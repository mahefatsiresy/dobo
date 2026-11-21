import 'package:dobo/domain/types.dart';
import 'package:dobo/features/transcription/transcription_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final mon = DateTime(2026, 11, 9);
  final tue = DateTime(2026, 11, 10);
  final wed = DateTime(2026, 11, 11);

  test('a typed day becomes one log; deaths left empty mean 0', () {
    final r = sheetInputs(
      pondId: 'e1',
      personId: 'rakoto',
      typed: {mon: DayEntry()..kg = '7,4', tue: DayEntry()},
    );
    expect(r.missingFeed, isEmpty);
    expect(r.inputs, hasLength(1));
    final i = r.inputs.single;
    expect((i.pondId, i.date, i.feedGivenG, i.deaths), ('e1', mon, 7400, 0));
    expect(i.observedBy, 'rakoto');
  });

  test('deaths without feed hold the whole sheet back', () {
    final r = sheetInputs(
      pondId: 'e1',
      personId: 'rakoto',
      typed: {mon: DayEntry()..kg = '5', wed: DayEntry()..deaths = '2'},
    );
    expect(r.missingFeed, [wed]);
    expect(r.inputs, isEmpty);
  });

  test('a picked detail alone also asks for the feed', () {
    final r = sheetInputs(
      pondId: 'e1',
      personId: 'rakoto',
      typed: {tue: DayEntry()..colour = WaterColour.clear},
    );
    expect(r.missingFeed, [tue]);
  });

  test('signs, leftover and colour go with the log', () {
    final r = sheetInputs(
      pondId: 'e1',
      personId: 'rakoto',
      typed: {
        mon: DayEntry()
          ..kg = '3'
          ..deaths = '1'
          ..signs = {WarningSign.values.first}
          ..leftover = Leftover.some
          ..colour = WaterColour.darkGreen,
      },
    );
    final i = r.inputs.single;
    expect(i.deaths, 1);
    expect(i.warningSigns, {WarningSign.values.first});
    expect(i.leftover, Leftover.some);
    expect(i.waterColour, WaterColour.darkGreen);
  });

  test('an entry knows when it holds nothing', () {
    expect(DayEntry().isEmpty, isTrue);
    expect((DayEntry()..deaths = '0').isEmpty, isFalse);
    expect((DayEntry()..ateFast = true).hasDetails, isTrue);
  });
}
