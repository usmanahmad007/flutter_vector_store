import 'dart:typed_data';
import '../math/vector_math.dart';
import 'vector_embedder.dart';

/// Offline deterministic vector embedder using character n-grams and hashing.
///
/// Produces consistent, normalized unit vectors without requiring an external
/// API key, internet connection, or heavy native library. Excellent for instant
/// testing, prototyping, and privacy-preserving on-device semantic search.
class HashVectorEmbedder extends VectorEmbedder {
  @override
  final int dimension;

  /// N-gram window size for sub-word tokenization.
  final int ngramSize;

  HashVectorEmbedder({
    this.dimension = 64,
    this.ngramSize = 3,
  }) {
    if (dimension <= 0) {
      throw ArgumentError('Dimension must be greater than zero');
    }
  }

  @override
  Future<List<double>> embedText(String text) async {
    final clean = text.toLowerCase().trim();
    if (clean.isEmpty) {
      return Float32List(dimension).toList();
    }

    final rawVector = Float32List(dimension);

    // 1. Word token hashing
    final words = clean.split(RegExp(r'\s+'));
    for (final word in words) {
      final h = _hashString(word);
      final idx = h.abs() % dimension;
      rawVector[idx] += 1.5;
    }

    // 2. Character n-gram hashing for sub-word semantic similarity
    if (clean.length >= ngramSize) {
      for (int i = 0; i <= clean.length - ngramSize; i++) {
        final ngram = clean.substring(i, i + ngramSize);
        final h = _hashString(ngram);
        final idx = h.abs() % dimension;
        rawVector[idx] += 1.0;
      }
    } else {
      final h = _hashString(clean);
      rawVector[h.abs() % dimension] += 1.0;
    }

    // 3. Normalize into unit sphere (L2 norm = 1.0)
    final normalized = VectorMath.l2Normalize(rawVector);
    return normalized.toList();
  }

  /// 32-bit FNV-1a hash algorithm.
  int _hashString(String str) {
    int hash = 0x811c9dc5;
    for (int i = 0; i < str.length; i++) {
      hash ^= str.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}
