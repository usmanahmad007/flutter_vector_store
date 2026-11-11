import 'dart:typed_data';
import '../math/vector_math.dart';
import 'distance_metric.dart';

/// Specification for a vector nearest-neighbor similarity query.
class VectorQuery {
  /// The target embedding vector to find matches for.
  final Float32List vector;

  /// Maximum number of top nearest matches to return.
  final int topK;

  /// Minimum similarity score threshold (`0.0` to `1.0`).
  /// Results with a similarity score below this value are filtered out.
  final double? minScore;

  /// The distance metric used for similarity calculations.
  final DistanceMetric metric;

  /// Optional MongoDB-style metadata filter (e.g. `{'category': 'agriculture'}`).
  final Map<String, dynamic>? filter;

  VectorQuery({
    required List<double> vector,
    this.topK = 5,
    this.minScore,
    this.metric = DistanceMetric.cosine,
    this.filter,
  }) : vector = VectorMath.toFloat32List(vector);

  /// Cached norm of the query vector.
  late final double norm = VectorMath.l2Norm(vector);

  /// Dimension of the query vector.
  int get dimension => vector.length;
}
