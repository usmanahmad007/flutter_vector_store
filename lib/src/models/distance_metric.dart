import '../math/vector_math.dart';

/// Supported distance metrics for vector similarity calculations.
enum DistanceMetric {
  /// Cosine similarity: measures the angle between vectors (scale invariant).
  /// Similarity range: `0.0` (orthogonal/opposite) to `1.0` (identical).
  cosine,

  /// Euclidean distance: standard straight-line distance in L2 space.
  /// Distance range: `0.0` to `+infinity`.
  euclidean,

  /// Dot product: inner product of two vectors (magnitude sensitive).
  dotProduct,

  /// Manhattan distance: L1 distance (sum of absolute differences).
  manhattan;

  /// Calculates the similarity score between [a] and [b].
  ///
  /// For all metrics, a higher returned score indicates greater similarity.
  double similarity(List<double> a, List<double> b,
      {double? normA, double? normB}) {
    switch (this) {
      case DistanceMetric.cosine:
        if (normA != null && normB != null) {
          final cos = VectorMath.cosineSimilarityFast(a, normA, b, normB);
          // Scale from [-1, 1] to [0, 1] for intuitive percent scoring
          return (cos + 1.0) / 2.0;
        }
        final cos = VectorMath.cosineSimilarity(a, b);
        return (cos + 1.0) / 2.0;

      case DistanceMetric.euclidean:
        final dist = VectorMath.euclideanDistance(a, b);
        // Inverse distance mapping to [0, 1]
        return 1.0 / (1.0 + dist);

      case DistanceMetric.dotProduct:
        return VectorMath.dotProduct(a, b);

      case DistanceMetric.manhattan:
        final dist = VectorMath.manhattanDistance(a, b);
        return 1.0 / (1.0 + dist);
    }
  }

  /// Calculates the raw geometric distance between [a] and [b].
  double distance(List<double> a, List<double> b,
      {double? normA, double? normB}) {
    switch (this) {
      case DistanceMetric.cosine:
        final cos = normA != null && normB != null
            ? VectorMath.cosineSimilarityFast(a, normA, b, normB)
            : VectorMath.cosineSimilarity(a, b);
        return 1.0 - cos;

      case DistanceMetric.euclidean:
        return VectorMath.euclideanDistance(a, b);

      case DistanceMetric.dotProduct:
        return -VectorMath.dotProduct(a, b);

      case DistanceMetric.manhattan:
        return VectorMath.manhattanDistance(a, b);
    }
  }
}
