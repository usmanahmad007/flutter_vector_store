import 'vector_document.dart';

/// Represents a scored document returned from a vector nearest-neighbor search.
class SearchResult {
  /// The matched document.
  final VectorDocument document;

  /// Normalized similarity score from `0.0` (unrelated) to `1.0` (exact match).
  final double score;

  /// Raw mathematical distance calculated by the active distance metric.
  final double distance;

  /// The ranking position (1-based index: 1 = closest match).
  final int rank;

  const SearchResult({
    required this.document,
    required this.score,
    required this.distance,
    required this.rank,
  });

  /// Formatted similarity percentage (e.g. `98.5%`).
  String get scorePercentage => '${(score * 100).toStringAsFixed(1)}%';

  @override
  String toString() =>
      'SearchResult(rank: $rank, id: ${document.id}, score: $scorePercentage)';
}
