import 'package:english_speech/list_extension.dart';
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
}
