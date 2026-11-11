import '../models/vector_document.dart';

/// Contract for vector database persistence engines.
abstract class VectorStorage {
  /// Persists the full list of [documents].
  Future<void> save(List<VectorDocument> documents);

  /// Loads all stored vector documents.
  Future<List<VectorDocument>> load();

  /// Deletes or clears the underlying storage.
  Future<void> clear();
}
