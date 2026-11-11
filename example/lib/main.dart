import 'package:flutter/material.dart';
import 'package:flutter_vector_store/flutter_vector_store.dart';

void main() {
  runApp(const VectorStoreExampleApp());
}

class VectorStoreExampleApp extends StatelessWidget {
  const VectorStoreExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Vector Store Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        colorSchemeSeed: const Color(0xFF6366F1),
        useMaterial3: true,
      ),
      home: const VectorStoreHomeScreen(),
    );
  }
}

class VectorStoreHomeScreen extends StatefulWidget {
  const VectorStoreHomeScreen({super.key});

  @override
  State<VectorStoreHomeScreen> createState() => _VectorStoreHomeScreenState();
}

class _VectorStoreHomeScreenState extends State<VectorStoreHomeScreen> {
  late final VectorStore _store;
  final TextEditingController _queryController = TextEditingController(
    text: 'optimal soil moisture and irrigation for high yield crops',
  );

  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  double _lastLatencyMs = 0.0;
  String _selectedCategory = 'All';
  DistanceMetric _selectedMetric = DistanceMetric.cosine;
  bool _useHnswIndex = true;

  final List<String> _categories = [
    'All',
    'Agriculture',
    'AI & ML',
    'Flutter',
    'Health',
  ];

  @override
  void initState() {
    super.initState();
    _initStore();
  }

  void _initStore() {
    final index = _useHnswIndex ? HNSWIndex() : FlatIndex();
    _store = VectorStore(
      index: index,
      embedder: HashVectorEmbedder(dimension: 64),
    );
    _populateKnowledgeBase();
  }

  Future<void> _populateKnowledgeBase() async {
    final seedData = [
      // Agriculture
      {
        'id': 'agri_rice',
        'text':
            'Paddy rice requires warm temperatures, high humidity, and continuous shallow standing water during early vegetative stages.',
        'metadata': {
          'category': 'Agriculture',
          'crop': 'Rice',
          'water': 'High'
        },
      },
      {
        'id': 'agri_wheat',
        'text':
            'Wheat thrives in moderate winter climates with well-drained loamy soil, requiring balanced nitrogen and moderate irrigation.',
        'metadata': {
          'category': 'Agriculture',
          'crop': 'Wheat',
          'water': 'Medium'
        },
      },
      {
        'id': 'agri_cotton',
        'text':
            'Cotton requires plenty of sunshine, high ambient heat, deep black soil, and dry weather during boll opening and harvesting.',
        'metadata': {
          'category': 'Agriculture',
          'crop': 'Cotton',
          'water': 'Low-Medium'
        },
      },
      {
        'id': 'agri_soil',
        'text':
            'Soil pH between 6.0 and 7.0 maximizes nutrient availability for nitrogen, phosphorus, and potassium absorption.',
        'metadata': {'category': 'Agriculture', 'topic': 'Soil Health'},
      },

      // AI & ML
      {
        'id': 'ai_rag',
        'text':
            'Retrieval-Augmented Generation (RAG) augments LLM prompts with relevant document chunks fetched from an on-device vector database.',
        'metadata': {'category': 'AI & ML', 'topic': 'RAG'},
      },
      {
        'id': 'ai_embeddings',
        'text':
            'Vector embeddings map unstructured words and sentences into continuous high-dimensional geometric representations preserving semantic proximity.',
        'metadata': {'category': 'AI & ML', 'topic': 'Embeddings'},
      },
      {
        'id': 'ai_quantization',
        'text':
            'Post-training weight quantization compresses FP32 model weights down to INT8 or INT4 to run fast on mobile neural accelerators.',
        'metadata': {'category': 'AI & ML', 'topic': 'Quantization'},
      },

      // Flutter
      {
        'id': 'flutter_impeller',
        'text':
            'Impeller is Flutter modern rendering engine delivering silky 120Hz frame rates by precompiling all GPU shaders to eliminate compilation jank.',
        'metadata': {'category': 'Flutter', 'topic': 'Graphics'},
      },
      {
        'id': 'flutter_isolate',
        'text':
            'Background Dart isolates run compute-intensive machine learning, vector indexing, or cryptography without blocking the UI frame thread.',
        'metadata': {'category': 'Flutter', 'topic': 'Performance'},
      },

      // Health
      {
        'id': 'health_hydration',
        'text':
            'Proper daily water intake supports cellular metabolism, temperature regulation, joint lubrication, and cognitive performance.',
        'metadata': {'category': 'Health', 'topic': 'Hydration'},
      },
    ];

    for (final item in seedData) {
      await _store.addText(
        item['text'] as String,
        id: item['id'] as String,
        metadata: item['metadata'] as Map<String, dynamic>,
      );
    }

    _performSearch();
  }

  Future<void> _performSearch() async {
    final queryText = _queryController.text.trim();
    if (queryText.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    final stopwatch = Stopwatch()..start();

    Map<String, dynamic>? filter;
    if (_selectedCategory != 'All') {
      filter = {'category': _selectedCategory};
    }

    final results = await _store.searchText(
      queryText,
      topK: 5,
      metric: _selectedMetric,
      filter: filter,
    );

    stopwatch.stop();

    setState(() {
      _searchResults = results;
      _lastLatencyMs = stopwatch.elapsedMicroseconds / 1000.0;
      _isSearching = false;
    });
  }

  void _showAddDocumentDialog() {
    final textCtrl = TextEditingController();
    String category = 'Agriculture';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF161B26),
            title: const Row(
              children: [
                Icon(Icons.post_add_rounded,
                    color: Color(0xFF6366F1), size: 22),
                SizedBox(width: 8),
                Text('Add Document', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: textCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter text content to embed & index...',
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Category:',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    value: category,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E293B),
                    items: ['Agriculture', 'AI & ML', 'Flutter', 'Health']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => category = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final text = textCtrl.text.trim();
                  if (text.isNotEmpty) {
                    await _store
                        .addText(text, metadata: {'category': category});
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    if (mounted) {
                      _performSearch();
                    }
                  }
                },
                child: const Text('Embed & Store'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hub_rounded, color: Color(0xFF6366F1), size: 22),
            SizedBox(width: 8),
            Text(
              'Flutter Vector Store',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Vector Document',
            onPressed: _showAddDocumentDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Input Field
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: 'Ask or search semantically...',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: Color(0xFF6366F1)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.cyanAccent),
                  onPressed: _performSearch,
                ),
                filled: true,
                fillColor: const Color(0xFF161B26),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF263345)),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 12),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(cat, style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF6366F1),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedCategory = cat);
                          _performSearch();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Controls Bar: Index Type & Distance Metric
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF263345)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Text(
                          'Index: ',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          _useHnswIndex ? 'HNSW (Graph)' : 'Flat (Exact)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: Colors.cyanAccent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Switch(
                          value: _useHnswIndex,
                          activeColor: Colors.cyanAccent,
                          onChanged: (val) {
                            setState(() {
                              _useHnswIndex = val;
                              _initStore();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  DropdownButton<DistanceMetric>(
                    value: _selectedMetric,
                    underline: const SizedBox(),
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                    items: DistanceMetric.values.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(m.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (m) {
                      if (m != null) {
                        setState(() => _selectedMetric = m);
                        _performSearch();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2D Vector Embedding Projection Canvas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '2D Vector Projection Space',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${_store.size} indexed docs',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.cyanAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            VectorScatterPlot(
              documents: _store.getAll(),
              highlightedResults: _searchResults,
              height: 130,
            ),
            const SizedBox(height: 16),

            // Search Results Header & Performance Latency
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Matches (${_searchResults.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isSearching && _searchResults.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '⚡ ${_lastLatencyMs.toStringAsFixed(2)} ms',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Results List
            if (_isSearching)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              VectorSearchVisualizer(
                results: _searchResults,
                emptyMessage: 'No matching vector documents found.',
              ),
          ],
        ),
      ),
    );
  }
}
