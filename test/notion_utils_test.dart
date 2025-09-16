import 'package:english_speech/notion/notion_web_articles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('setRowNumberForTableRows', () {
    // Helper function to create a mock Paragraph for testing
    Paragraph createParagraph(String id) =>
        Paragraph(id: id, type: 'paragraph', hasChildren: false, richTexts: []);

    // Helper function to create a mock TableRow for testing
    TableRow createTableRow(String id) =>
        TableRow(id: id, type: 'table_row', hasChildren: false, cells: []);

    test('should return an empty list when given an empty list', () {
      // Arrange
      final List<Block> blocks = [];

      // Act
      final result = setRowNumberForTableRows(blocks);

      // Assert
      expect(result, isEmpty);
    });

    test('should number a list containing only TableRow blocks', () {
      // Arrange
      final blocks = [
        createTableRow('row1'),
        createTableRow('row2'),
        createTableRow('row3'),
      ];

      // Act
      final result = setRowNumberForTableRows(blocks);

      // Assert
      expect(result, hasLength(3));
      expect((result[0] as TableRow).rowNo, 1);
      expect((result[1] as TableRow).rowNo, 2);
      expect((result[2] as TableRow).rowNo, 3);
    });

    test('should return the original list if no TableRow blocks are present', () {
      // Arrange
      final blocks = [createParagraph('p1'), createParagraph('p2')];

      // Act
      final result = setRowNumberForTableRows(blocks);

      // Assert
      expect(result, hasLength(2));
      // Ensure the original objects are returned (or at least are not TableRows)
      expect(result[0], isA<Paragraph>());
      expect(result[1], isA<Paragraph>());
    });

    test('should correctly number TableRows in a mixed list', () {
      // Arrange
      final blocks = [
        createParagraph('p1'),
        createTableRow('row1'),
        createTableRow('row2'),
        createParagraph('p2'),
      ];

      // Act
      final result = setRowNumberForTableRows(blocks);

      // Assert
      expect(result, hasLength(4));
      expect(result[0], isA<Paragraph>());
      expect((result[1] as TableRow).rowNo, 1);
      expect((result[2] as TableRow).rowNo, 2);
      expect(result[3], isA<Paragraph>());
    });

    test('should reset numbering for separate groups of TableRows', () {
      // Arrange
      final blocks = [
        createTableRow('row1a'),
        createTableRow('row1b'),
        createParagraph('p1'),
        createTableRow('row2a'),
        createTableRow('row2b'),
        createTableRow('row2c'),
      ];

      // Act
      final result = setRowNumberForTableRows(blocks);

      // Assert
      expect(result, hasLength(6));
      // First group
      expect((result[0] as TableRow).rowNo, 1);
      expect((result[1] as TableRow).rowNo, 2);
      // Intermediary block
      expect(result[2], isA<Paragraph>());
      // Second group (numbering resets)
      expect((result[3] as TableRow).rowNo, 1);
      expect((result[4] as TableRow).rowNo, 2);
      expect((result[5] as TableRow).rowNo, 3);
    });
  });
}
