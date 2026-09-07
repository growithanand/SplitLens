import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:splitlens/features/receipt_capture/domain/receipt_image_storage.dart';

final class LocalReceiptImageStorage implements ReceiptImageStorage {
  LocalReceiptImageStorage({Future<Directory> Function()? rootDirectory})
    : _rootDirectory = rootDirectory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _rootDirectory;

  @override
  Future<String> persist({
    required String sourcePath,
    required String imageId,
  }) async {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(imageId)) {
      throw ArgumentError.value(
        imageId,
        'imageId',
        'Must be a safe file name.',
      );
    }

    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Receipt image does not exist.', sourcePath);
    }

    final root = await _rootDirectory();
    final receiptsDirectory = Directory(path.join(root.path, 'receipts'));
    await receiptsDirectory.create(recursive: true);

    final extension = _safeExtension(sourcePath);
    final destination = File(
      path.join(receiptsDirectory.path, '$imageId$extension'),
    );

    try {
      final stored = await source.copy(destination.path);
      return stored.path;
    } on Object {
      if (await destination.exists()) {
        await destination.delete();
      }
      rethrow;
    }
  }

  @override
  Future<void> delete(String storedPath) async {
    final stored = File(storedPath);
    if (await stored.exists()) {
      await stored.delete();
    }
  }
}

String _safeExtension(String sourcePath) {
  final extension = path.extension(sourcePath).toLowerCase();
  return RegExp(r'^\.[a-z0-9]{1,10}$').hasMatch(extension) ? extension : '.img';
}
