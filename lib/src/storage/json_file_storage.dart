import 'dart:convert';
import 'dart:io';

import '../models/vector_document.dart';
import 'vector_storage.dart';

/// Portable JSON file persistence for local disk storage.
class JsonFileStorage implements VectorStorage {
  /// Path to the JSON database file on disk.
  final String filePath;

  JsonFileStorage({required this.filePath});

  @override
  Future<void> save(List<VectorDocument> documents) async {
    final file = File(filePath);
    final parentDir = file.parent;
    if (!parentDir.existsSync()) {
      parentDir.createSync(recursive: true);
    }

    final jsonList = documents.map((d) => d.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);
    await file.writeAsString(jsonStr, flush: true);
  }

  @override
  Future<List<VectorDocument>> load() async {
    final file = File(filePath);
    if (!file.existsSync()) return [];

    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];

    final dynamic decoded = jsonDecode(content);
    if (decoded is! List) return [];

    return decoded
        .map(
            (e) => VectorDocument.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> clear() async {
    final file = File(filePath);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
