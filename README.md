# flutter_vector_store

[![pub package](https://img.shields.io/pub/v/flutter_vector_store.svg)](https://pub.dev/packages/flutter_vector_store)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.3.0-02569B?logo=flutter)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-green.svg)](https://pub.dev/packages/flutter_vector_store)

A high-performance, on-device **Vector Database and Semantic Search engine** for Flutter.
Store, index, and query high-dimensional embeddings 100% locally with **zero external cloud servers, zero API costs, and zero native C++ compilation headaches**.

---

## 📱 Supported Platforms

Built in pure Dart, `flutter_vector_store` runs with zero native dependencies across all platforms supported by Flutter:

| Platform | Support | Storage Backend | Minimum OS |
| :--- | :---: | :--- | :--- |
| 🤖 **Android** | ✅ Supported | Raw Float32 Binary & JSON File Storage | Android 5.0 (API 21+) |
| 🍎 **iOS** | ✅ Supported | Raw Float32 Binary & JSON File Storage | iOS 12.0+ |
| 🌐 **Web** | ✅ Supported | In-Memory & IndexedDB Storage | All modern browsers |
| 💻 **macOS** | ✅ Supported | Raw Float32 Binary & JSON File Storage | macOS 10.14+ |
| 🪟 **Windows** | ✅ Supported | Raw Float32 Binary & JSON File Storage | Windows 10+ |
| 🐧 **Linux** | ✅ Supported | Raw Float32 Binary & JSON File Storage | Any modern distro |

---

## 🌟 Key Features

* 🚀 **100% Pure Dart**: No C++ CMake dependencies, no FFI issues, no platform-specific crashes.
* ⚡ **Nearest-Neighbor Algorithms**:
  * **`FlatIndex`**: Exact brute-force scan guaranteeing 100% recall.
  * **`HNSWIndex`**: Hierarchical Navigable Small World graph for sub-millisecond approximate nearest neighbor (ANN) retrieval on large collections.
* 📏 **Multiple Distance Metrics**: Cosine Similarity, Euclidean Distance (L2), Dot Product, and Manhattan Distance (L1).
* 🔎 **MongoDB-Style Metadata Filtering**: Filter documents simultaneously during vector search with `$eq`, `$ne`, `$gt`, `$gte`, `$lt`, `$lte`, `$in`, `$nin`, `$contains`, `$and`, and `$or`.
* 💾 **Compact Binary Storage (`BinaryVectorStorage`)**: Saves vectors directly as raw contiguous `Float32List` bytes on disk, slashing storage requirements by up to 70% compared to JSON.
* 🧠 **Flexible Embedders**:
  * **`HashVectorEmbedder`**: Built-in deterministic token/n-gram embedder for instant offline testing without API keys.
  * **`CustomVectorEmbedder`**: One-line hook to connect Google Gemini (`text-embedding-004`), OpenAI (`text-embedding-3-small`), Ollama (`nomic-embed-text`), or local ONNX/TFLite models.
* 📺 **Pre-Built Interactive UI Widgets**:
  * `VectorSearchVisualizer`: Visual scored results list with percentage progress bars and metadata chips.
  * `VectorScatterPlot`: 2D vector cluster projection canvas.

---

## 🚀 Getting Started

### 1. Add dependency

Add `flutter_vector_store` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_vector_store: ^0.1.0
```

### 2. Basic Semantic Search Example

```dart
import 'package:flutter_vector_store/flutter_vector_store.dart';

void main() async {
  // 1. Create a VectorStore with HNSW graph indexing
  final store = VectorStore(
    index: HNSWIndex(),
  );

  // 2. Add text documents (embedded automatically)
  await store.addText(
    'Paddy rice requires warm temperatures and high humidity',
    id: 'crop_rice',
    metadata: {'category': 'Agriculture', 'water': 'High'},
  );

  await store.addText(
    'Wheat grows well in moderate winter climates and well-drained soil',
    id: 'crop_wheat',
    metadata: {'category': 'Agriculture', 'water': 'Medium'},
  );

  // 3. Search semantically
  final results = await store.searchText(
    'Which crop needs lots of water and heat?',
    topK: 1,
  );

  for (final result in results) {
    print('Match: ${result.document.content}');
    print('Score: ${result.scorePercentage}'); // e.g. 94.2%
    print('Rank: #${result.rank}');
  }
}
```

---

## 🔌 Connecting Embedding Models (Gemini, OpenAI, Ollama)

You can plug any AI embedding model into `VectorStore` using `CustomVectorEmbedder`:

```dart
// Google Gemini Embedding Example
final store = VectorStore(
  embedder: CustomVectorEmbedder(
    dimension: 768,
    embedFunction: (text) async {
      // Call your Gemini / OpenAI / Ollama API client here
      final response = await geminiClient.embedContent(text);
      return response.embedding.values;
    },
  ),
);
```

---

## 🔎 Metadata Filtering

Narrow down semantic vector searches using structured query filters:

```dart
final results = await store.searchText(
  'sustainable farming methods',
  topK: 5,
  filter: {
    r'$and': [
      {'category': 'Agriculture'},
      {'rating': {r'$gte': 4.5}},
      {'tags': {r'$in': ['soil', 'organic']}},
    ],
  },
);
```

---

## 💾 Local Disk Persistence

Save and reload your vector database across app sessions using `BinaryVectorStorage`:

```dart
// Initialize with binary persistence
final storage = BinaryVectorStorage(
  filePath: '/path/to/app/documents/knowledge_base.bin',
);

final store = VectorStore(
  storage: storage,
  autoSave: true, // Automatically saves on any add or delete
);

// Load existing database on app launch
await store.load();
```

---

## 📺 Pre-Built UI Widgets

### 1. `VectorSearchVisualizer`
Display semantic search results with percentage similarity bars, rank badges, and metadata chips:

```dart
VectorSearchVisualizer(
  results: searchResults,
  onResultTap: (result) {
    print('Tapped document ${result.document.id}');
  },
)
```

### 2. `VectorScatterPlot`
Render a 2D projection scatter plot showing vector distribution and highlighting search hits:

```dart
VectorScatterPlot(
  documents: store.getAll(),
  highlightedResults: searchResults,
  height: 180,
)
```

---

## 🧪 Testing

Run the comprehensive unit and widget test suite:

```bash
flutter test
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
