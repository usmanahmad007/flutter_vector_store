import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_vector_store/flutter_vector_store.dart';

void main() {
  group('VectorMath Tests', () {
    test(
        'cosineSimilarity calculates identical, opposite, and orthogonal vectors',
        () {
      final a = [1.0, 0.0, 0.0];
      final b = [1.0, 0.0, 0.0];
      final c = [-1.0, 0.0, 0.0];
      final d = [0.0, 1.0, 0.0];

      expect(VectorMath.cosineSimilarity(a, b), closeTo(1.0, 1e-6));
      expect(VectorMath.cosineSimilarity(a, c), closeTo(-1.0, 1e-6));
      expect(VectorMath.cosineSimilarity(a, d), closeTo(0.0, 1e-6));
    });

    test(
        'cosineSimilarityFast matches standard calculation with precomputed norms',
        () {
      final a = [1.0, 2.0, 3.0];
      final b = [4.0, 5.0, 6.0];
      final normA = VectorMath.l2Norm(a);
      final normB = VectorMath.l2Norm(b);

      final standard = VectorMath.cosineSimilarity(a, b);
      final fast = VectorMath.cosineSimilarityFast(a, normA, b, normB);

      expect(fast, closeTo(standard, 1e-6));
    });

    test('euclideanDistance and manhattanDistance calculations', () {
      final a = [0.0, 0.0];
      final b = [3.0, 4.0];

      expect(VectorMath.euclideanDistance(a, b), closeTo(5.0, 1e-6));
      expect(VectorMath.manhattanDistance(a, b), closeTo(7.0, 1e-6));
      expect(VectorMath.dotProduct(a, b), closeTo(0.0, 1e-6));
    });

    test('l2Normalize creates unit vector with norm 1.0', () {
      final v = [3.0, 4.0];
      final unit = VectorMath.l2Normalize(v);
      expect(unit[0], closeTo(0.6, 1e-6));
      expect(unit[1], closeTo(0.8, 1e-6));
      expect(VectorMath.l2Norm(unit), closeTo(1.0, 1e-6));
    });

    test('Throws ArgumentError on dimension mismatch', () {
      expect(
        () => VectorMath.cosineSimilarity([1.0], [1.0, 2.0]),
        throwsArgumentError,
      );
    });
  });

  group('DistanceMetric Tests', () {
    test('DistanceMetric cosine maps to [0, 1] similarity', () {
      final a = [1.0, 0.0];
      final b = [1.0, 0.0];
      final opp = [-1.0, 0.0];

      expect(DistanceMetric.cosine.similarity(a, b), closeTo(1.0, 1e-6));
      expect(DistanceMetric.cosine.similarity(a, opp), closeTo(0.0, 1e-6));
    });

    test('DistanceMetric euclidean maps inverse distance to [0, 1]', () {
      final a = [0.0, 0.0];
      final b = [0.0, 0.0];
      expect(DistanceMetric.euclidean.similarity(a, b), 1.0);
    });
  });

  group('VectorDocument & Serialization', () {
    test('JSON serialization round-trip retains fidelity', () {
      final doc = VectorDocument(
        id: 'doc_1',
        vector: [0.1, 0.2, 0.3],
        content: 'Machine learning for agriculture',
        metadata: {'category': 'farming', 'priority': 1},
      );

      final json = doc.toJson();
      final restored = VectorDocument.fromJson(json);

      expect(restored.id, doc.id);
      expect(restored.content, doc.content);
      expect(restored.metadata, doc.metadata);
      expect(restored.vector, doc.vector);
      expect(restored.norm, closeTo(doc.norm, 1e-6));
    });
  });

  group('MetadataFilter Tests', () {
    final doc = VectorDocument(
      id: 'test_doc',
      vector: [1.0, 0.0],
      metadata: {
        'category': 'crops',
        'rating': 4.8,
        'views': 1200,
        'tags': ['rice', 'soil', 'irrigation'],
        'verified': true,
      },
    );

    test('Exact match and direct equality', () {
      expect(MetadataFilter.matches(doc, {'category': 'crops'}), true);
      expect(MetadataFilter.matches(doc, {'category': 'tech'}), false);
      expect(MetadataFilter.matches(doc, {'verified': true}), true);
    });

    test(r'Comparison operators ($gt, $gte, $lt, $lte, $eq, $ne)', () {
      expect(
          MetadataFilter.matches(doc, {
            'rating': {r'$gt': 4.5}
          }),
          true);
      expect(
          MetadataFilter.matches(doc, {
            'rating': {r'$gt': 5.0}
          }),
          false);
      expect(
          MetadataFilter.matches(doc, {
            'views': {r'$gte': 1200, r'$lte': 1500}
          }),
          true);
      expect(
          MetadataFilter.matches(doc, {
            'category': {r'$ne': 'finance'}
          }),
          true);
    });

    test(r'Array inclusion ($in, $nin, $contains)', () {
      expect(
          MetadataFilter.matches(doc, {
            'tags': {
              r'$in': ['soil', 'weather']
            }
          }),
          true);
      expect(
          MetadataFilter.matches(doc, {
            'tags': {
              r'$nin': ['crypto']
            }
          }),
          true);
      expect(
          MetadataFilter.matches(doc, {
            'category': {r'$contains': 'crop'}
          }),
          true);
    });

    test(r'Logical operators ($and, $or)', () {
      expect(
        MetadataFilter.matches(doc, {
          r'$and': [
            {'category': 'crops'},
            {
              'rating': {r'$gt': 4.0}
            },
          ],
        }),
        true,
      );

      expect(
        MetadataFilter.matches(doc, {
          r'$or': [
            {'category': 'robotics'},
            {'verified': true},
          ],
        }),
        true,
      );
    });
  });

  group('Index Tests (FlatIndex & HNSWIndex)', () {
    final doc1 =
        VectorDocument(id: '1', vector: [1.0, 0.0, 0.0], content: 'Red');
    final doc2 =
        VectorDocument(id: '2', vector: [0.9, 0.1, 0.0], content: 'Crimson');
    final doc3 =
        VectorDocument(id: '3', vector: [0.0, 1.0, 0.0], content: 'Green');
    final doc4 =
        VectorDocument(id: '4', vector: [0.0, 0.0, 1.0], content: 'Blue');

    test('FlatIndex returns top nearest neighbors ordered by similarity', () {
      final index = FlatIndex(initialDocuments: [doc1, doc2, doc3, doc4]);
      expect(index.size, 4);

      final query = VectorQuery(vector: [1.0, 0.0, 0.0], topK: 2);
      final results = index.search(query);

      expect(results.length, 2);
      expect(results[0].document.id, '1');
      expect(results[0].rank, 1);
      expect(results[0].score, closeTo(1.0, 1e-4));
      expect(results[1].document.id, '2');
      expect(results[1].rank, 2);
    });

    test('HNSWIndex indexes and routes nearest neighbors', () {
      final hnsw = HNSWIndex(initialDocuments: [doc1, doc2, doc3, doc4]);
      expect(hnsw.size, 4);

      final query = VectorQuery(vector: [0.0, 0.0, 1.0], topK: 1);
      final results = hnsw.search(query);

      expect(results.length, 1);
      expect(results[0].document.id, '4');
      expect(results[0].score, closeTo(1.0, 1e-4));
    });

    test('Index removal and clear', () {
      final index = FlatIndex(initialDocuments: [doc1, doc2]);
      expect(index.remove('1'), true);
      expect(index.size, 1);
      expect(index.get('1'), isNull);

      index.clear();
      expect(index.size, 0);
    });
  });

  group('Storage Tests (JSON & Binary)', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('vec_store_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('JsonFileStorage saves and loads vector documents', () async {
      final path = '${tempDir.path}/store.json';
      final storage = JsonFileStorage(filePath: path);

      final docs = [
        VectorDocument(id: 'j1', vector: [0.1, 0.2], content: 'Hello JSON'),
        VectorDocument(id: 'j2', vector: [0.3, 0.4], content: 'World JSON'),
      ];

      await storage.save(docs);
      final loaded = await storage.load();

      expect(loaded.length, 2);
      expect(loaded[0].id, 'j1');
      expect(loaded[0].content, 'Hello JSON');
      expect(loaded[1].vector[0], closeTo(0.3, 1e-5));
    });

    test('BinaryVectorStorage saves and loads raw Float32 binary bytes',
        () async {
      final path = '${tempDir.path}/store.bin';
      final storage = BinaryVectorStorage(filePath: path);

      final docs = [
        VectorDocument(
          id: 'b1',
          vector: [1.25, -2.5, 3.75, 4.0],
          content: 'Binary high speed payload',
          metadata: {'cluster': 42},
        ),
      ];

      await storage.save(docs);
      final loaded = await storage.load();

      expect(loaded.length, 1);
      expect(loaded[0].id, 'b1');
      expect(loaded[0].content, 'Binary high speed payload');
      expect(loaded[0].metadata['cluster'], 42);
      expect(loaded[0].vector[0], closeTo(1.25, 1e-5));
      expect(loaded[0].vector[1], closeTo(-2.5, 1e-5));
    });
  });

  group('Embedding & VectorStore Integration Tests', () {
    test('HashVectorEmbedder generates deterministic unit vectors', () async {
      final embedder = HashVectorEmbedder(dimension: 32);
      final v1 = await embedder.embedText('Crop fertilizer advice');
      final v2 = await embedder.embedText('Crop fertilizer advice');
      final v3 = await embedder.embedText('Quantum particle physics');

      expect(v1.length, 32);
      expect(VectorMath.l2Norm(v1), closeTo(1.0, 1e-5));
      // Same text produces identical embeddings
      expect(v1, v2);

      // Semantic sub-word similarity: 'Crop fertilizer advice' should be closer to 'Crop fertilizer'
      final vClose = await embedder.embedText('Crop fertilizer tips');
      final simClose = VectorMath.cosineSimilarity(v1, vClose);
      final simFar = VectorMath.cosineSimilarity(v1, v3);
      expect(simClose, greaterThan(simFar));
    });

    test('VectorStore complete add, search, filter, and delete flow', () async {
      final store = VectorStore();

      await store.addText(
        'Rice requires standing water and warm humid climate',
        id: 'crop_rice',
        metadata: {'type': 'cereal', 'season': 'kharif'},
      );

      await store.addText(
        'Wheat thrives in moderate winter temperatures and well-drained loam',
        id: 'crop_wheat',
        metadata: {'type': 'cereal', 'season': 'rabi'},
      );

      await store.addText(
        'Coffee requires shade and high elevation rainfall',
        id: 'crop_coffee',
        metadata: {'type': 'plantation', 'season': 'perennial'},
      );

      expect(store.size, 3);

      // Search for rice-related query
      final results = await store.searchText('paddy water climate', topK: 1);
      expect(results.length, 1);
      expect(results.first.document.id, 'crop_rice');

      // Filtered search
      final rabiResults = await store.searchText(
        'farm crops',
        filter: {'season': 'rabi'},
      );
      expect(rabiResults.length, 1);
      expect(rabiResults.first.document.id, 'crop_wheat');

      // Remove item
      final removed = await store.remove('crop_coffee');
      expect(removed, true);
      expect(store.size, 2);
    });
  });

  group('UI Widgets Tests', () {
    testWidgets('VectorSearchVisualizer renders ranked results and badges',
        (tester) async {
      final doc = VectorDocument(
        id: 'doc_viz',
        vector: [1.0, 0.0],
        content: 'Visualizer test content',
        metadata: {'category': 'demo'},
      );
      final results = [
        SearchResult(document: doc, score: 0.942, distance: 0.058, rank: 1),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VectorSearchVisualizer(results: results),
          ),
        ),
      );

      expect(find.text('#1'), findsOneWidget);
      expect(find.text('doc_viz'), findsOneWidget);
      expect(find.text('94.2%'), findsOneWidget);
      expect(find.text('Visualizer test content'), findsOneWidget);
      expect(find.text('category: demo'), findsOneWidget);
    });

    testWidgets('VectorScatterPlot renders canvas without errors',
        (tester) async {
      final docs = [
        VectorDocument(id: 'p1', vector: [1.0, 2.0]),
        VectorDocument(id: 'p2', vector: [-1.0, 3.0]),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VectorScatterPlot(documents: docs),
          ),
        ),
      );

      expect(find.byType(VectorScatterPlot), findsOneWidget);
    });
  });
}
