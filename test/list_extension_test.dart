import 'package:english_speech/extension/list_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListExtension.span', () {
    test('should return two empty lists for an empty list', () {
      // Arrange
      final list = <int>[];

      // Act
      final (ys, zs) = list.span((n) => n < 3);

      // Assert
      expect(ys, isEmpty);
      expect(zs, isEmpty);
    });

    test(
      'should return all elements in the first list when all satisfy the predicate',
      () {
        // Arrange
        final list = [1, 2, 3, 4];

        // Act
        final (ys, zs) = list.span((n) => n < 5);

        // Assert
        expect(ys, equals([1, 2, 3, 4]));
        expect(zs, isEmpty);
      },
    );

    test(
      'should return all elements in the second list when none satisfy the predicate',
      () {
        // Arrange
        final list = [1, 2, 3, 4];

        // Act
        final (ys, zs) = list.span((n) => n > 5);

        // Assert
        expect(ys, isEmpty);
        expect(zs, equals([1, 2, 3, 4]));
      },
    );

    test('should split the list where the predicate first fails', () {
      // Arrange
      final list = [1, 2, 3, 4, 5, 1, 2];

      // Act
      final (ys, zs) = list.span((n) => n < 4);

      // Assert
      expect(ys, equals([1, 2, 3]));
      expect(zs, equals([4, 5, 1, 2]));
    });

    test(
      'should handle a single-element list that satisfies the predicate',
      () {
        // Arrange
        final list = [1];

        // Act
        final (ys, zs) = list.span((n) => n < 2);

        // Assert
        expect(ys, equals([1]));
        expect(zs, isEmpty);
      },
    );

    test(
      'should handle a single-element list that does not satisfy the predicate',
      () {
        // Arrange
        final list = [3];

        // Act
        final (ys, zs) = list.span((n) => n < 2);

        // Assert
        expect(ys, isEmpty);
        expect(zs, equals([3]));
      },
    );
  });

  group('ListExtension.divideBy', () {
    test('should return an empty list when dividing an empty list', () {
      // Arrange
      final list = <int>[];

      // Act
      final result = list.divideBy(3);

      // Assert
      expect(result, isEmpty);
    });

    test('should divide a list into chunks of the specified length', () {
      // Arrange
      final list = [1, 2, 3, 4, 5, 6];

      // Act
      final result = list.divideBy(2);

      // Assert
      expect(
        result,
        equals([
          [1, 2],
          [3, 4],
          [5, 6],
        ]),
      );
    });

    test('should handle a list where the last chunk is smaller', () {
      // Arrange
      final list = [1, 2, 3, 4, 5];

      // Act
      final result = list.divideBy(3);

      // Assert
      expect(
        result,
        equals([
          [1, 2, 3],
          [4, 5],
        ]),
      );
    });

    test('should return one chunk if length is greater than list size', () {
      // Arrange
      final list = [1, 2, 3];

      // Act
      final result = list.divideBy(5);

      // Assert
      expect(
        result,
        equals([
          [1, 2, 3],
        ]),
      );
    });

    test('should divide the list into single-element lists if length is 1', () {
      // Arrange
      final list = [1, 2, 3];

      // Act
      final result = list.divideBy(1);

      // Assert
      expect(
        result,
        equals([
          [1],
          [2],
          [3],
        ]),
      );
    });
  });
}
