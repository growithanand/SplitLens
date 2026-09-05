import 'package:uuid/uuid.dart';

abstract interface class LocalIdGenerator {
  String generate();
}

final class UuidV4LocalIdGenerator implements LocalIdGenerator {
  const UuidV4LocalIdGenerator();

  static const _uuid = Uuid();

  @override
  String generate() => _uuid.v4();
}
