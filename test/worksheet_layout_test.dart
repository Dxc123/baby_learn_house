import 'package:flutter_test/flutter_test.dart';
import 'package:baby_learn_house/app/services/worksheet_pdf_service.dart';

void main() {
  test('A4 whole blocks: six default -> 2; sixty four rows -> 30', () {
    expect(
      WorksheetLayout.paginate(
        WorksheetConfig(itemIds: List.generate(6, (i) => '$i')),
      ).length,
      2,
    );
    final config = WorksheetConfig(
      itemIds: List.generate(60, (i) => '$i'),
      rowsPerCharacter: 4,
    );
    final pages = WorksheetLayout.paginate(config);
    expect(pages.length, 30);
    expect(pages.expand((p) => p), config.itemIds);
  });
  test('invalid selection and row limits rejected', () {
    for (final config in [
      WorksheetConfig(itemIds: []),
      WorksheetConfig(itemIds: ['x', 'x']),
      WorksheetConfig(itemIds: List.generate(61, (i) => '$i')),
      WorksheetConfig(itemIds: ['x'], rowsPerCharacter: 0),
      WorksheetConfig(itemIds: ['x'], rowsPerCharacter: 5),
    ]) {
      expect(() => WorksheetLayout.paginate(config), throwsArgumentError);
    }
  });
}
