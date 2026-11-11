import 'dart:typed_data';
import '../math/vector_math.dart';

/// Represents a persistent vector document in the vector database.
class VectorDocument {
  /// Unique identifier for this document.
  final String id;

  /// High-dimensional numerical embedding representation.
  final Float32List vector;

  /// The raw text or chunk content represented by this embedding.
  final String? content;

  /// Arbitrary structured metadata for filtering (tags, author, category, etc.).
  final Map<String, dynamic> metadata;

  /// Cached L2 norm of the vector for high-performance cosine similarity.
  final double norm;

  /// Timestamp when the document was initially added.
  final DateTime createdAt;

  /// Timestamp when the document was last updated.
  final DateTime updatedAt;

  VectorDocument({
    required this.id,
    required List<double> vector,
    this.content,
    Map<String, dynamic>? metadata,
    double? norm,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : vector = VectorMath.toFloat32List(vector),
        metadata = metadata != null ? Map<String, dynamic>.from(metadata) : {},
        norm = norm ?? VectorMath.l2Norm(vector),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Dimensionality of the embedding vector.
  int get dimension => vector.length;

  /// Creates a copy of this document with updated fields.
  VectorDocument copyWith({
    String? id,
    List<double>? vector,
    String? content,
    Map<String, dynamic>? metadata,
    DateTime? updatedAt,
  }) {
    return VectorDocument(
      id: id ?? this.id,
      vector: vector ?? this.vector,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Serializes this document to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vector': vector.toList(),
      if (content != null) 'content': content,
      'metadata': metadata,
      'norm': norm,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Deserializes a document from a JSON map.
  factory VectorDocument.fromJson(Map<String, dynamic> json) {
    final rawVec = json['vector'] as List;
    final vectorList = rawVec.map((e) => (e as num).toDouble()).toList();

    return VectorDocument(
      id: json['id'] as String,
      vector: vectorList,
      content: json['content'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      norm: (json['norm'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'VectorDocument(id: $id, dimension: $dimension, content: ${content?.length ?? 0} chars)';
}
