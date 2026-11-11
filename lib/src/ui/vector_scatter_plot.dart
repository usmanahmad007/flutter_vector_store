import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/search_result.dart';
import '../models/vector_document.dart';

/// Interactive 2D scatter plot canvas rendering high-dimensional vector clusters
/// using fast 2-axis projection and highlighting top search matches.
class VectorScatterPlot extends StatelessWidget {
  /// All documents in the store to plot.
  final List<VectorDocument> documents;

  /// Top search results to highlight with glowing markers.
  final List<SearchResult>? highlightedResults;

  /// Height of the canvas.
  final double height;

  /// Whether to use dark theme colors.
  final bool isDark;

  const VectorScatterPlot({
    super.key,
    required this.documents,
    this.highlightedResults,
    this.height = 200,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B26) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No vectors to plot',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      );
    }

    final matchedIds =
        highlightedResults?.map((r) => r.document.id).toSet() ?? {};

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B26) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF263345) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          size: Size.infinite,
          painter: _ScatterPainter(
            documents: documents,
            matchedIds: matchedIds,
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

class _ScatterPainter extends CustomPainter {
  final List<VectorDocument> documents;
  final Set<String> matchedIds;
  final bool isDark;

  _ScatterPainter({
    required this.documents,
    required this.matchedIds,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (documents.isEmpty || size.width <= 0 || size.height <= 0) return;

    // 1. Draw subtle background coordinate grid
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(8)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height), gridPaint);
    canvas.drawLine(Offset(0, size.height / 2),
        Offset(size.width, size.height / 2), gridPaint);

    // 2. Project vectors into 2D coordinates
    // We project using dim 0 and dim 1 (or weighted linear combinations)
    final points = <_ProjectedPoint>[];

    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;

    for (final doc in documents) {
      double x = 0.0;
      double y = 0.0;

      final v = doc.vector;
      final half = v.length ~/ 2;

      for (int i = 0; i < v.length; i++) {
        if (i < half) {
          x += v[i] * (1.0 / (i + 1));
        } else {
          y += v[i] * (1.0 / (i - half + 1));
        }
      }

      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);

      points.add(_ProjectedPoint(doc: doc, rawX: x, rawY: y));
    }

    final spanX = (maxX - minX) != 0.0 ? (maxX - minX) : 1.0;
    final spanY = (maxY - minY) != 0.0 ? (maxY - minY) : 1.0;

    const pad = 24.0;
    final w = size.width - (pad * 2);
    final h = size.height - (pad * 2);

    final dotPaint = Paint()
      ..color = const Color(0xFF6366F1).withAlpha(180)
      ..style = PaintingStyle.fill;

    final matchPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFF10B981).withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    for (final pt in points) {
      final nx = pad + ((pt.rawX - minX) / spanX) * w;
      final ny = pad + ((pt.rawY - minY) / spanY) * h;
      final center = Offset(nx, ny);

      final isMatch = matchedIds.contains(pt.doc.id);
      if (isMatch) {
        canvas.drawCircle(center, 9, glowPaint);
        canvas.drawCircle(center, 5, matchPaint);
      } else {
        canvas.drawCircle(center, 4, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScatterPainter oldDelegate) {
    return oldDelegate.documents != documents ||
        oldDelegate.matchedIds != matchedIds ||
        oldDelegate.isDark != isDark;
  }
}

class _ProjectedPoint {
  final VectorDocument doc;
  final double rawX;
  final double rawY;

  const _ProjectedPoint({
    required this.doc,
    required this.rawX,
    required this.rawY,
  });
}
