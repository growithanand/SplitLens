abstract interface class ReceiptImageStorage {
  Future<String> persist({required String sourcePath, required String imageId});

  Future<void> delete(String storedPath);
}
