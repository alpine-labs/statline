import 'package:uuid/uuid.dart';

/// Simple UUID v4 generator.
class UuidGenerator {
  UuidGenerator._();

  static const Uuid _uuid = Uuid();

  /// Generates and returns a new v4 UUID string.
  static String generate() => _uuid.v4();
}
