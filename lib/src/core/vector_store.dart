import 'dart:math' as math;

import '../embedding/hash_vector_embedder.dart';
import '../embedding/vector_embedder.dart';
import '../filter/metadata_filter.dart';
import '../index/flat_index.dart';
import '../index/vector_index.dart';
import '../models/distance_metric.dart';
import '../models/search_result.dart';
import '../models/vector_document.dart';
import '../models/vector_query.dart';
import '../storage/in_memory_storage.dart';
import '../storage/vector_storage.dart';

/// The central coordinator for on-device vector database operations,
/// document indexing, metadata filtering, and semantic similarity search.
class VectorStore {
  final VectorIndex _index;
  final VectorStorage _storage;

  /// The active text embedder.
  VectorEmbedder embedder;

  final bool autoSave;

  VectorStore({
    VectorIndex? index,
    VectorStorage? storage,
    VectorEmbedder? embedder,
    this.autoSave = false,
  })  : _index = index ?? FlatIndex(),
        _storage = storage ?? InMemoryStorage(),
        embedder = embedder ?? HashVectorEmbedder();

  /// The active vector index.
  VectorIndex get index => _index;

  /// The active persistence storage engine.
  VectorStorage get storage => _storage;

  /// Total count of indexed vector documents.
  int get size => _index.size;

  /// Returns `true` if the vector database contains no documents.
  bool get isEmpty => _index.size == 0;

  /// Dimensionality of the vectors in this store.
  int get dimension =>
      _index.dimension != 0 ? _index.dimension : embedder.dimension;

  /// Adds a single pre-computed [document] into the vector store.
  Future<void> add(VectorDocument document) async {
    _index.add(document);
    if (autoSave) {
      await save();
    }
  }

  /// Adds multiple documents in batch.
  Future<void> addMany(List<VectorDocument> documents) async {
    _index.addMany(documents);
    if (autoSave) {
      await save();
    }
  }

  /// Automatically embeds raw [text] using the configured [embedder] and adds it to the store.
  ///
  /// If [id] is omitted, a unique alphanumeric ID is generated automatically.
  Future<VectorDocument> addText(
    String text, {
    String? id,
    Map<String, dynamic>? metadata,
  }) async {
    final docId = id ?? _generateId();
    final vector = await embedder.embedText(text);

    final doc = VectorDocument(
      id: docId,
      vector: vector,
      content: text,
      metadata: metadata,
    );

    await add(doc);
    return doc;
  }

  /// Automatically embeds and adds multiple text chunks in batch.
  Future<List<VectorDocument>> addTexts(
    List<String> texts, {
    List<String>? ids,
    List<Map<String, dynamic>>? metadatas,
  }) async {
    final vectors = await embedder.embedBatch(texts);
    final docs = <VectorDocument>[];

    for (int i = 0; i < texts.length; i++) {
      final docId = ids != null && i < ids.length ? ids[i] : _generateId();
      final meta =
          metadatas != null && i < metadatas.length ? metadatas[i] : null;

      docs.add(VectorDocument(
        id: docId,
        vector: vectors[i],
        content: texts[i],
        metadata: meta,
      ));
    }

    await addMany(docs);
    return docs;
  }

  /// Performs a vector similarity search using a pre-computed embedding vector.
  List<SearchResult> search(VectorQuery query) {
    return _index.search(query);
  }

  /// Embeds [queryText] and executes semantic similarity search.
  Future<List<SearchResult>> searchText(
    String queryText, {
    int topK = 5,
    double? minScore,
    DistanceMetric metric = DistanceMetric.cosine,
    Map<String, dynamic>? filter,
  }) async {
    final queryVector = await embedder.embedText(queryText);
    final query = VectorQuery(
      vector: queryVector,
      topK: topK,
      minScore: minScore,
      metric: metric,
      filter: filter,
    );
    return search(query);
  }

  /// Retrieves a document by its [id], or returns `null` if not found.
  VectorDocument? get(String id) => _index.get(id);

  /// Removes a document by [id]. Returns `true` if found and deleted.
  Future<bool> remove(String id) async {
    final success = _index.remove(id);
    if (success && autoSave) {
      await save();
    }
    return success;
  }

  /// Removes all documents that match the specified metadata [filter].
  ///
  /// Returns the number of documents removed.
  Future<int> removeWhere(Map<String, dynamic> filter) async {
    int removedCount = 0;
    final toRemove = <String>[];

    for (final doc in _index.documents) {
      if (MetadataFilter.matches(doc, filter)) {
        toRemove.add(doc.id);
      }
    }

    for (final id in toRemove) {
      if (_index.remove(id)) {
        removedCount++;
      }
    }

    if (removedCount > 0 && autoSave) {
      await save();
    }
    return removedCount;
  }

  /// Clears all vector documents from memory and storage.
  Future<void> clear() async {
    _index.clear();
    await _storage.clear();
  }

  /// Persists all currently indexed documents into storage.
  Future<void> save() async {
    await _storage.save(_index.documents);
  }

  /// Loads stored vector documents from persistence into the active index.
  Future<void> load() async {
    final docs = await _storage.load();
    _index.clear();
    _index.addMany(docs);
  }

  /// Returns all currently indexed documents.
  List<VectorDocument> getAll() => _index.documents;

  String _generateId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand =
        math.Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'doc_${now}_$rand';
  }
}
