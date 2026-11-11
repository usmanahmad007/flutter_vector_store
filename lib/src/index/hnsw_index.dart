import 'dart:math' as math;
import '../filter/metadata_filter.dart';
import '../models/search_result.dart';
import '../models/vector_document.dart';
import '../models/vector_query.dart';
import 'vector_index.dart';

/// Hierarchical Navigable Small World (HNSW) graph index.
///
/// Provides logarithmic-time Approximate Nearest Neighbor (ANN) search
/// across high-dimensional vector spaces. Ideal for large local document
/// collections (10,000+ vectors) on mobile and desktop.
class HNSWIndex extends VectorIndex {
  /// Maximum number of bidirectional outgoing connections per element per layer.
  final int maxNeighbors;

  /// Maximum connections on the bottom layer (layer 0).
  final int maxNeighborsLayer0;

  /// Size of the dynamic candidate list during graph construction.
  final int efConstruction;

  /// Default size of the dynamic candidate list during queries.
  final int efSearch;

  final Map<String, VectorDocument> _documents = {};
  final Map<String, _HNSWNode> _nodes = {};
  final math.Random _random = math.Random();

  _HNSWNode? _entryPoint;
  int _maxLayer = -1;
  int _dimension = 0;
  late final double _mL;

  HNSWIndex({
    this.maxNeighbors = 16,
    int? maxNeighborsLayer0,
    this.efConstruction = 64,
    this.efSearch = 32,
    List<VectorDocument>? initialDocuments,
  }) : maxNeighborsLayer0 = maxNeighborsLayer0 ?? (maxNeighbors * 2) {
    _mL = 1.0 / math.log(maxNeighbors.toDouble());
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

    if (_nodes.containsKey(document.id)) {
      remove(document.id);
    }

    _documents[document.id] = document;

    // Determine random level assignment
    final nodeLevel = _randomLevel();
    final node = _HNSWNode(document: document, level: nodeLevel);
    _nodes[document.id] = node;

    if (_entryPoint == null) {
      _entryPoint = node;
      _maxLayer = nodeLevel;
      return;
    }

    var currObj = _entryPoint!;

    // 1. Zoom through top layers down to nodeLevel
    for (int lc = _maxLayer; lc > nodeLevel; lc--) {
      currObj = _searchLayerGreedy(document.vector, currObj, lc);
    }

    // 2. Insert and connect node across layers from min(maxLayer, nodeLevel) down to 0
    final topLayerToConnect = math.min(_maxLayer, nodeLevel);
    for (int lc = topLayerToConnect; lc >= 0; lc--) {
      final candidates =
          _searchLayer(document.vector, currObj, efConstruction, lc);
      final m = lc == 0 ? maxNeighborsLayer0 : maxNeighbors;
      final neighbors = _selectNeighbors(candidates, m);

      // Connect node to neighbors
      for (final neighbor in neighbors) {
        node.addNeighbor(lc, neighbor);
        neighbor.addNeighbor(lc, node);

        // Shrink neighbors if exceeding capacity
        final neighborM = lc == 0 ? maxNeighborsLayer0 : maxNeighbors;
        if (neighbor.getNeighbors(lc).length > neighborM) {
          _shrinkNeighbors(neighbor, lc, neighborM);
        }
      }

      if (candidates.isNotEmpty) {
        currObj = candidates.first;
      }
    }

    if (nodeLevel > _maxLayer) {
      _maxLayer = nodeLevel;
      _entryPoint = node;
    }
  }

  @override
  List<SearchResult> search(VectorQuery query) {
    if (_documents.isEmpty || _entryPoint == null) return const [];
    if (_dimension != 0 && query.dimension != _dimension) {
      throw ArgumentError(
        'Query dimension (${query.dimension}) does not match index dimension ($_dimension)',
      );
    }

    // Small dataset optimization: when few items exist, exact scan ensures 100% recall
    if (_documents.length < maxNeighbors * 2) {
      return _exactSearch(query);
    }

    var currObj = _entryPoint!;

    // 1. Greedy routing in upper layers
    for (int lc = _maxLayer; lc > 0; lc--) {
      currObj = _searchLayerGreedy(query.vector, currObj, lc);
    }

    // 2. Beam search on ground layer 0
    final ef = math.max(query.topK, efSearch);
    final candidates = _searchLayer(query.vector, currObj, ef, 0);

    // 3. Score and filter candidates
    final scored = <_Candidate>[];
    for (final node in candidates) {
      final doc = node.document;
      if (query.filter != null && !MetadataFilter.matches(doc, query.filter)) {
        continue;
      }

      final sim = query.metric.similarity(
        query.vector,
        doc.vector,
        normA: query.norm,
        normB: doc.norm,
      );

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

    // If metadata filter pruned too aggressively, supplement with exact scan
    if (scored.length < query.topK && query.filter != null) {
      return _exactSearch(query);
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    final limit = math.min(query.topK, scored.length);
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

  List<SearchResult> _exactSearch(VectorQuery query) {
    final scored = <_Candidate>[];
    for (final doc in _documents.values) {
      if (query.filter != null && !MetadataFilter.matches(doc, query.filter)) {
        continue;
      }
      final sim = query.metric.similarity(
        query.vector,
        doc.vector,
        normA: query.norm,
        normB: doc.norm,
      );
      if (query.minScore != null && sim < query.minScore!) continue;

      final dist = query.metric.distance(
        query.vector,
        doc.vector,
        normA: query.norm,
        normB: doc.norm,
      );
      scored.add(_Candidate(document: doc, score: sim, distance: dist));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final limit = math.min(query.topK, scored.length);
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

  _HNSWNode _searchLayerGreedy(List<double> query, _HNSWNode entry, int layer) {
    var curr = entry;
    var currDist = _computeDistance(query, curr.document.vector);

    bool changed = true;
    while (changed) {
      changed = false;
      for (final neighbor in curr.getNeighbors(layer)) {
        final d = _computeDistance(query, neighbor.document.vector);
        if (d < currDist) {
          currDist = d;
          curr = neighbor;
          changed = true;
        }
      }
    }
    return curr;
  }

  List<_HNSWNode> _searchLayer(
    List<double> query,
    _HNSWNode entry,
    int ef,
    int layer,
  ) {
    final visited = <String>{entry.document.id};
    final candidates = <_ScoredNode>[];
    final w = <_ScoredNode>[];

    final initialDist = _computeDistance(query, entry.document.vector);
    final initialNode = _ScoredNode(node: entry, distance: initialDist);

    candidates.add(initialNode);
    w.add(initialNode);

    while (candidates.isNotEmpty) {
      // Extract candidate with smallest distance
      candidates.sort((a, b) => a.distance.compareTo(b.distance));
      final c = candidates.removeAt(0);

      // Find furthest item in W
      w.sort((a, b) => a.distance.compareTo(b.distance));
      final furthestInW = w.last;

      if (c.distance > furthestInW.distance) {
        break;
      }

      for (final neighbor in c.node.getNeighbors(layer)) {
        if (!visited.contains(neighbor.document.id)) {
          visited.add(neighbor.document.id);

          final d = _computeDistance(query, neighbor.document.vector);
          if (d < furthestInW.distance || w.length < ef) {
            final neighborScored = _ScoredNode(node: neighbor, distance: d);
            candidates.add(neighborScored);
            w.add(neighborScored);

            if (w.length > ef) {
              w.sort((a, b) => a.distance.compareTo(b.distance));
              w.removeLast();
            }
          }
        }
      }
    }

    w.sort((a, b) => a.distance.compareTo(b.distance));
    return w.map((e) => e.node).toList();
  }

  List<_HNSWNode> _selectNeighbors(List<_HNSWNode> candidates, int m) {
    if (candidates.length <= m) return candidates;
    return candidates.sublist(0, m);
  }

  void _shrinkNeighbors(_HNSWNode node, int layer, int max) {
    final neighbors = node.getNeighbors(layer);
    if (neighbors.length <= max) return;

    neighbors.sort((a, b) {
      final da = _computeDistance(node.document.vector, a.document.vector);
      final db = _computeDistance(node.document.vector, b.document.vector);
      return da.compareTo(db);
    });

    node.setNeighbors(layer, neighbors.sublist(0, max));
  }

  double _computeDistance(List<double> a, List<double> b) {
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }
    return sum;
  }

  int _randomLevel() {
    final r = _random.nextDouble();
    if (r == 0.0) return 0;
    final lvl = (-math.log(r) * _mL).floor();
    return lvl;
  }

  @override
  bool remove(String id) {
    final doc = _documents.remove(id);
    final node = _nodes.remove(id);

    if (node != null) {
      // Remove node from all neighbors' adjacency lists
      for (int l = 0; l <= node.level; l++) {
        for (final neighbor in node.getNeighbors(l)) {
          neighbor.removeNeighbor(l, node);
        }
      }

      if (_entryPoint?.document.id == id) {
        _entryPoint = _nodes.isNotEmpty ? _nodes.values.first : null;
        _maxLayer = _entryPoint?.level ?? -1;
      }
    }

    if (_documents.isEmpty) {
      _dimension = 0;
      _maxLayer = -1;
      _entryPoint = null;
    }

    return doc != null;
  }

  @override
  VectorDocument? get(String id) => _documents[id];

  @override
  void clear() {
    _documents.clear();
    _nodes.clear();
    _entryPoint = null;
    _maxLayer = -1;
    _dimension = 0;
  }

  @override
  int get size => _documents.length;

  @override
  List<VectorDocument> get documents => _documents.values.toList();

  @override
  int get dimension => _dimension;
}

class _HNSWNode {
  final VectorDocument document;
  final int level;
  final List<List<_HNSWNode>> neighborsByLayer;

  _HNSWNode({required this.document, required this.level})
      : neighborsByLayer = List.generate(level + 1, (_) => <_HNSWNode>[]);

  List<_HNSWNode> getNeighbors(int layer) {
    if (layer >= neighborsByLayer.length) return const [];
    return neighborsByLayer[layer];
  }

  void addNeighbor(int layer, _HNSWNode neighbor) {
    if (layer < neighborsByLayer.length) {
      final list = neighborsByLayer[layer];
      if (!list.contains(neighbor)) {
        list.add(neighbor);
      }
    }
  }

  void removeNeighbor(int layer, _HNSWNode neighbor) {
    if (layer < neighborsByLayer.length) {
      neighborsByLayer[layer].remove(neighbor);
    }
  }

  void setNeighbors(int layer, List<_HNSWNode> neighbors) {
    if (layer < neighborsByLayer.length) {
      neighborsByLayer[layer] = neighbors;
    }
  }
}

class _ScoredNode {
  final _HNSWNode node;
  final double distance;

  const _ScoredNode({required this.node, required this.distance});
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
