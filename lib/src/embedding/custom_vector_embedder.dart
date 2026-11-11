import 'vector_embedder.dart';

/// Adapter embedder enabling developers to plug in any embedding model or API
/// (e.g. Google Gemini `text-embedding-004`, OpenAI `text-embedding-3-small`,
/// Ollama `nomic-embed-text`, or local ONNX/TFLite models).
class CustomVectorEmbedder extends VectorEmbedder {
  @override
  final int dimension;

  final Future<List<double>> Function(String text) _embedFunction;
  final Future<List<List<double>>> Function(List<String> texts)? _batchFunction;

  CustomVectorEmbedder({
    required this.dimension,
    required Future<List<double>> Function(String text) embedFunction,
    Future<List<List<double>>> Function(List<String> texts)? batchFunction,
  })  : _embedFunction = embedFunction,
        _batchFunction = batchFunction;

  @override
  Future<List<double>> embedText(String text) => _embedFunction(text);

  @override
  Future<List<List<double>>> embedBatch(List<String> texts) {
    final batchFn = _batchFunction;
    if (batchFn != null) {
      return batchFn(texts);
    }
    return super.embedBatch(texts);
  }
}
