## 0.1.0

* Initial release of `flutter_vector_store`.
* Pure-Dart on-device vector database and semantic similarity search.
* Support for all platforms: Android, iOS, Web, macOS, Windows, and Linux.
* High-performance vector math operations: Cosine Similarity, Euclidean Distance, Dot Product, Manhattan Distance.
* Exact (Flat) and Approximate Nearest Neighbor (HNSW - Hierarchical Navigable Small World) index algorithms.
* MongoDB-style metadata filtering engine (`$eq`, `$ne`, `$gt`, `$gte`, `$lt`, `$lte`, `$in`, `$nin`, `$contains`, `$and`, `$or`).
* Multiple persistence drivers: in-memory, portable JSON, and compact raw Float32 binary storage (`BinaryVectorStorage`).
* Built-in deterministic offline text embedder (`HashVectorEmbedder`) and pluggable custom embedder interface (`CustomVectorEmbedder`).
* Pre-built interactive developer UI widgets: `VectorSearchVisualizer` and `VectorScatterPlot`.
* Interactive demonstration and benchmark app in `example/`.
