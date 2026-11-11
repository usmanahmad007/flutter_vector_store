import '../filter/metadata_filter.dart';
import '../models/search_result.dart';
import '../models/vector_document.dart';
import '../models/vector_query.dart';
import 'vector_index.dart';

/// Exact brute-force vector index guaranteeing 100% recall.
///
/// Computes similarity scores across all candidate vectors. Highly efficient
/// for small to medium-sized collections (up to 50,000 vectors on modern mobile devices).
class FlatIndex extends VectorIndex {
  final Map<String, VectorDocument> _documents = {};
  int _dimension = 0;

  FlatIndex({List<VectorDocument>? initialDocuments}) {
    if (initialDocuments != null) {
      addMany(initialDocuments);
    }
  }

  @override
  void add(VectorDocument document) {
    if (_dimension == 0) {
      _dimension = document.dimension;
    } else if (document.dimension != _dimension) {
      throw ArgumentError(
        'Document dimension (${document.dimension}) does not match index dimension ($_dimension)',
      );
    }
    _documents[document.id] = document;
  }

  @override
  List<SearchResult> search(VectorQuery query) {
    if (_documents.isEmpty) return const [];
    if (_dimension != 0 && query.dimension != _dimension) {
      throw ArgumentError(
        'Query dimension (${query.dimension}) does not match index dimension ($_dimension)',
      );
    }

    final scored = <_Candidate>[];

    for (final doc in _documents.values) {
      // 1. Metadata filter evaluation
      if (query.filter != null && !MetadataFilter.matches(doc, query.filter)) {
        continue;
      }

      // 2. Compute similarity and raw distance
      final sim = query.metric.similarity(
        query.vector,
        doc.vector,
        normA: query.norm,
        normB: doc.norm,
      );

      // 3. Score threshold pruning
      if (query.minScore != null && sim < query.minScore!) {
        continue;
      }

      final dist = query.metric.distance(
        query.vector,
        doc.vector,
        normA: query.norm,
        normB: doc.norm,
      );

      scored.add(_Candidate(document: doc, score: sim, distance: dist));
    }

    // Sort descending by similarity score (highest similarity first)
    scored.sort((a, b) => b.score.compareTo(a.score));

    // Limit to topK
    final limit = query.topK > scored.length ? scored.length : query.topK;
    final results = <SearchResult>[];

    for (int i = 0; i < limit; i++) {
      final c = scored[i];
      results.add(SearchResult(
        document: c.document,
        score: c.score,
        distance: c.distance,
        rank: i + 1,
      ));
    }

    return results;
  }

  @override
  bool remove(String id) {
    final removed = _documents.remove(id);
    if (_documents.isEmpty) _dimension = 0;
    return removed != null;
  }

  @override
  VectorDocument? get(String id) => _documents[id];

  @override
  void clear() {
    _documents.clear();
    _dimension = 0;
  }

  @override
  int get size => _documents.length;

  @override
  List<VectorDocument> get documents => _documents.values.toList();

  @override
  int get dimension => _dimension;
}

class _Candidate {
  final VectorDocument document;
  final double score;
  final double distance;

  const _Candidate({
    required this.document,
    required this.score,
    required this.distance,
  });
}
