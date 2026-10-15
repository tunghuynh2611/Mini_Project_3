import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service responsible for persisting receipt images and cache thumbnails locally.
class ReceiptStorageService {
  ReceiptStorageService._();
  static final ReceiptStorageService instance = ReceiptStorageService._();

  /// Directory name for stored receipts inside documents directory
  static const String receiptDirName = 'receipts';

  /// Saves an image file securely to app documents directory
  Future<String> saveReceiptImage(String sourceFilePath) async {
    try {
      if (kIsWeb) return sourceFilePath;

      final docsDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(docsDir.path, receiptDirName));

      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final ext = p.extension(sourceFilePath).isNotEmpty
          ? p.extension(sourceFilePath)
          : '.jpg';
      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}$ext';
      final targetPath = p.join(receiptsDir.path, fileName);

      final sourceFile = File(sourceFilePath);
      if (await sourceFile.exists()) {
        final copiedFile = await sourceFile.copy(targetPath);
        return copiedFile.path;
      }

      return sourceFilePath;
    } catch (e) {
      debugPrint('Error saving receipt image: $e');
      return sourceFilePath;
    }
  }

  /// Deletes a stored receipt image when the associated expense is deleted
  Future<bool> deleteReceiptImage(String filePath) async {
    try {
      if (filePath.isEmpty || kIsWeb) return false;
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting receipt image: $e');
      return false;
    }
  }
}

