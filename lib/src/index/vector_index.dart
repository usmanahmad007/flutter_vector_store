import '../models/search_result.dart';
import '../models/vector_document.dart';
import '../models/vector_query.dart';

/// Contract for vector indexing algorithms (e.g. Flat, HNSW, IVF).
abstract class VectorIndex {
  /// Adds a single document to the index.
  void add(VectorDocument document);

  /// Adds multiple documents in batch.
  void addMany(List<VectorDocument> documents) {
    for (final doc in documents) {
      add(doc);
    }
  }

  /// Searches for the top nearest neighbors matching [query].
  List<SearchResult> search(VectorQuery query);

  /// Removes a document by its [id]. Returns `true` if found and removed.
  bool remove(String id);

  /// Retrieves a document by its [id], or `null` if not found.
  VectorDocument? get(String id);

  /// Clears all indexed documents.
  void clear();

  /// Total count of indexed documents.
  int get size;

  /// All documents currently indexed.
  List<VectorDocument> get documents;

  /// Dimensionality of the vectors in this index (or 0 if empty).
  int get dimension;
}
