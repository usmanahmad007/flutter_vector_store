import '../models/vector_document.dart';
import 'vector_storage.dart';

/// Ephemeral in-memory storage for test suites and transient session RAG.
class InMemoryStorage implements VectorStorage {
  final List<VectorDocument> _stored = [];

  @override
  Future<void> save(List<VectorDocument> documents) async {
    _stored.clear();
    _stored.addAll(documents);
  }

  @override
  Future<List<VectorDocument>> load() async {
    return List<VectorDocument>.from(_stored);
  }

  @override
  Future<void> clear() async {
    _stored.clear();
  }
}
