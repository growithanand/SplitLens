import 'package:flutter_test/flutter_test.dart';
import 'package:splitlens/core/utils/local_id_generator.dart';
import 'package:uuid/uuid.dart';

void main() {
  test('generates distinct valid version 4 UUIDs for local records', () {
    const generator = UuidV4LocalIdGenerator();

    final first = generator.generate();
    final second = generator.generate();

    expect(Uuid.isValidUUID(fromString: first), isTrue);
    expect(Uuid.isValidUUID(fromString: second), isTrue);
    expect(first.split('-')[2].startsWith('4'), isTrue);
    expect(second.split('-')[2].startsWith('4'), isTrue);
    expect(second, isNot(first));
  });
}
