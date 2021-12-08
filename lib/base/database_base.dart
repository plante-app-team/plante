import 'dart:io';

abstract class DatabaseBase {
  /// Deletes database, _MAKES THIS INSTANCE INVALID_.
  Future<void> deleteDatabase() async {
    final path = await dbFilePath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> dbFilePath();
}
