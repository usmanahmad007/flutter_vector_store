/// Contract for embedding models that convert text strings into numerical vectors.
abstract class VectorEmbedder {
  /// Converts a single [text] string into an embedding vector.
  Future<List<double>> embedText(String text);

  /// Converts multiple [texts] into embeddings in batch.
  Future<List<List<double>>> embedBatch(List<String> texts) async {
    final results = <List<double>>[];
    for (final text in texts) {
      results.add(await embedText(text));
    }
    return results;
  }

  /// Expected dimensionality of the vectors produced by this embedder.
  int get dimension;
}
