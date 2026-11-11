import '../models/vector_document.dart';

/// Evaluates structured MongoDB-style filter queries against a [VectorDocument]'s metadata.
class MetadataFilter {
  MetadataFilter._();

  /// Returns `true` if [document] satisfies the specified [filter].
  ///
  /// If [filter] is null or empty, returns `true`.
  static bool matches(VectorDocument document, Map<String, dynamic>? filter) {
    if (filter == null || filter.isEmpty) return true;
    return _evaluateCondition(document.metadata, filter);
  }

  static bool _evaluateCondition(
    Map<String, dynamic> metadata,
    Map<String, dynamic> filter,
  ) {
    for (final entry in filter.entries) {
      final key = entry.key;
      final value = entry.value;

      // 1. Logical $and
      if (key == r'$and') {
        if (value is! List) return false;
        for (final clause in value) {
          if (clause is Map<String, dynamic>) {
            if (!_evaluateCondition(metadata, clause)) return false;
          }
        }
        continue;
      }

      // 2. Logical $or
      if (key == r'$or') {
        if (value is! List || value.isEmpty) return false;
        bool anyMatched = false;
        for (final clause in value) {
          if (clause is Map<String, dynamic>) {
            if (_evaluateCondition(metadata, clause)) {
              anyMatched = true;
              break;
            }
          }
        }
        if (!anyMatched) return false;
        continue;
      }

      // 3. Logical $nor
      if (key == r'$nor') {
        if (value is! List) return false;
        for (final clause in value) {
          if (clause is Map<String, dynamic>) {
            if (_evaluateCondition(metadata, clause)) return false;
          }
        }
        continue;
      }

      // 4. Field comparison
      final actualValue = metadata[key];

      if (value is Map<String, dynamic>) {
        if (!_evaluateFieldOperators(actualValue, value)) {
          return false;
        }
      } else {
        // Direct equality
        if (!_isEqual(actualValue, value)) {
          return false;
        }
      }
    }

    return true;
  }

  static bool _evaluateFieldOperators(
    dynamic actual,
    Map<String, dynamic> operators,
  ) {
    for (final op in operators.entries) {
      final opCode = op.key;
      final expected = op.value;

      switch (opCode) {
        case r'$eq':
          if (!_isEqual(actual, expected)) return false;
          break;

        case r'$ne':
          if (_isEqual(actual, expected)) return false;
          break;

        case r'$gt':
          if (actual is! num || expected is! num) return false;
          if (actual <= expected) return false;
          break;

        case r'$gte':
          if (actual is! num || expected is! num) return false;
          if (actual < expected) return false;
          break;

        case r'$lt':
          if (actual is! num || expected is! num) return false;
          if (actual >= expected) return false;
          break;

        case r'$lte':
          if (actual is! num || expected is! num) return false;
          if (actual > expected) return false;
          break;

        case r'$in':
          if (expected is! Iterable) return false;
          if (actual is Iterable) {
            // Check if any element of actual matches expected
            final hasMatch = actual.any((a) => expected.contains(a));
            if (!hasMatch) return false;
          } else {
            if (!expected.contains(actual)) return false;
          }
          break;

        case r'$nin':
          if (expected is! Iterable) return false;
          if (actual is Iterable) {
            if (actual.any((a) => expected.contains(a))) return false;
          } else {
            if (expected.contains(actual)) return false;
          }
          break;

        case r'$contains':
          if (actual is String) {
            if (!actual
                .toLowerCase()
                .contains(expected.toString().toLowerCase())) {
              return false;
            }
          } else if (actual is Iterable) {
            if (!actual.contains(expected)) return false;
          } else {
            return false;
          }
          break;

        case r'$exists':
          final shouldExist = expected == true;
          final exists = actual != null;
          if (shouldExist != exists) return false;
          break;

        default:
          // Unrecognized operator
          return false;
      }
    }

    return true;
  }

  static bool _isEqual(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a is num && b is num) return a == b;
    return false;
  }
}
