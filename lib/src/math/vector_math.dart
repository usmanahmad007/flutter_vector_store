import 'dart:math' as math;
import 'dart:typed_data';

/// High-performance vector math operations optimized for nearest-neighbor calculations.
class VectorMath {
  VectorMath._();

  /// Computes the cosine similarity between two vectors [a] and [b].
  ///
  /// Returns a value between `-1.0` (opposite directions) and `1.0` (identical directions).
  /// If either vector has a norm of zero, returns `0.0`.
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError(
        'Vector dimensions must match: got ${a.length} and ${b.length}',
      );
    }

    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      final ai = a[i];
      final bi = b[i];
      dot += ai * bi;
      normA += ai * ai;
      normB += bi * bi;
    }

    if (normA == 0.0 || normB == 0.0) {
      return 0.0;
    }

    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Computes cosine similarity when the norm of [b] or both are precalculated.
  static double cosineSimilarityFast(
    List<double> a,
    double normA,
    List<double> b,
    double normB,
  ) {
    if (normA == 0.0 || normB == 0.0) return 0.0;

    double dot = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }

    return dot / (normA * normB);
  }

  /// Computes the Euclidean distance (L2 distance) between [a] and [b].
  static double euclideanDistance(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError(
        'Vector dimensions must match: got ${a.length} and ${b.length}',
      );
    }

    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }

    return math.sqrt(sum);
  }

  /// Computes the Manhattan distance (L1 distance) between [a] and [b].
  static double manhattanDistance(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError(
        'Vector dimensions must match: got ${a.length} and ${b.length}',
      );
    }

    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += (a[i] - b[i]).abs();
    }

    return sum;
  }

  /// Computes the dot product between [a] and [b].
  static double dotProduct(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError(
        'Vector dimensions must match: got ${a.length} and ${b.length}',
      );
    }

    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }

    return sum;
  }

  /// Computes the L2 norm (magnitude) of vector [v].
  static double l2Norm(List<double> v) {
    double sum = 0.0;
    for (int i = 0; i < v.length; i++) {
      sum += v[i] * v[i];
    }
    return math.sqrt(sum);
  }

  /// Returns a new normalized unit vector (L2 norm = 1.0) for [v].
  static Float32List l2Normalize(List<double> v) {
    final norm = l2Norm(v);
    final result = Float32List(v.length);
    if (norm == 0.0) {
      return result;
    }

    for (int i = 0; i < v.length; i++) {
      result[i] = v[i] / norm;
    }
    return result;
  }

  /// Converts a standard `List<double>` into a memory-efficient `Float32List`.
  static Float32List toFloat32List(List<double> list) {
    if (list is Float32List) return list;
    final out = Float32List(list.length);
    for (int i = 0; i < list.length; i++) {
      out[i] = list[i];
    }
    return out;
  }
}
