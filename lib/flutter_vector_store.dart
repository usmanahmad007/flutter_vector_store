/// High-performance on-device Vector Database and Semantic Search engine for Flutter.
///
/// Features fast vector similarity metrics (Cosine, Euclidean, Dot Product, Manhattan),
/// exact (Flat) and approximate (HNSW) index algorithms, MongoDB-style metadata filtering,
/// multiple storage options (in-memory, JSON, compact raw Float32 binary), offline
/// deterministic text embedding, and pluggable custom embedders for Gemini, OpenAI, or local ML.
library flutter_vector_store;

// Core Coordinator
export 'src/core/vector_store.dart';

// Embeddings
export 'src/embedding/custom_vector_embedder.dart';
export 'src/embedding/hash_vector_embedder.dart';
export 'src/embedding/vector_embedder.dart';

// Filtering
export 'src/filter/metadata_filter.dart';

// Indexing
export 'src/index/flat_index.dart';
export 'src/index/hnsw_index.dart';
export 'src/index/vector_index.dart';

// Math
export 'src/math/vector_math.dart';

// Models
export 'src/models/distance_metric.dart';
export 'src/models/search_result.dart';
export 'src/models/vector_document.dart';
export 'src/models/vector_query.dart';

// Storage & Persistence
export 'src/storage/binary_vector_storage.dart';
export 'src/storage/in_memory_storage.dart';
export 'src/storage/json_file_storage.dart';
export 'src/storage/vector_storage.dart';

// UI Widgets
export 'src/ui/vector_scatter_plot.dart';
export 'src/ui/vector_search_visualizer.dart';
