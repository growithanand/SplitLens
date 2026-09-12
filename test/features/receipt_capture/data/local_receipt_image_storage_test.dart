import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:splitlens/features/receipt_capture/data/local_receipt_image_storage.dart';

void main() {
  late Directory root;
  late LocalReceiptImageStorage storage;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('splitlens-receipts-');
    storage = LocalReceiptImageStorage(rootDirectory: () async => root);
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test(
    'copies a receipt into managed storage and preserves its bytes',
    () async {
      final source = File(path.join(root.path, 'selected-receipt.JPG'));
      await source.writeAsBytes([1, 2, 3, 4]);

      final storedPath = await storage.persist(
        sourcePath: source.path,
        imageId: 'expense-123',
      );

      expect(storedPath, path.join(root.path, 'receipts', 'expense-123.jpg'));
      expect(await File(storedPath).readAsBytes(), [1, 2, 3, 4]);
      expect(await source.exists(), isTrue);
    },
  );

  test('uses a safe fallback extension and deletes idempotently', () async {
    final source = File(path.join(root.path, 'receipt.unsafe-extension-name'));
    await source.writeAsBytes([5, 9, 9]);

    final storedPath = await storage.persist(
      sourcePath: source.path,
      imageId: 'expense-456',
    );
    expect(storedPath, endsWith('expense-456.img'));

    await storage.delete(storedPath);
    await storage.delete(storedPath);

    expect(await File(storedPath).exists(), isFalse);
  });

  test('rejects missing sources and unsafe generated identifiers', () async {
    await expectLater(
      storage.persist(sourcePath: 'missing.png', imageId: 'expense-789'),
      throwsA(isA<FileSystemException>()),
    );

    final source = File(path.join(root.path, 'receipt.png'));
    await source.writeAsBytes([1]);
    await expectLater(
      storage.persist(sourcePath: source.path, imageId: '../outside'),
      throwsArgumentError,
    );
  });

  test('refuses to delete files outside managed receipt storage', () async {
    final outside = File(path.join(root.path, 'outside-receipt.png'));
    await outside.writeAsBytes([5, 9, 9]);

    await expectLater(storage.delete(outside.path), throwsArgumentError);

    expect(await outside.exists(), isTrue);
  });
}
