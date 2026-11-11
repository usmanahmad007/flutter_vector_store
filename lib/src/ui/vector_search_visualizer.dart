import 'package:flutter/material.dart';
import '../models/search_result.dart';

/// Interactive Flutter widget that renders scored vector search results
/// with visual similarity percentage indicators, rank badges, and metadata tags.
class VectorSearchVisualizer extends StatelessWidget {
  /// The list of scored results returned from a search query.
  final List<SearchResult> results;

  /// Optional empty state message when no results match.
  final String emptyMessage;

  /// Callback when a user taps a result item.
  final ValueChanged<SearchResult>? onResultTap;

  /// Whether to use dark theme styling.
  final bool isDark;

  const VectorSearchVisualizer({
    super.key,
    required this.results,
    this.emptyMessage = 'No vector matches found',
    this.onResultTap,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.travel_explore_rounded,
                size: 40,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
              const SizedBox(height: 8),
              Text(
                emptyMessage,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final result = results[index];
        return _buildResultCard(context, result);
      },
    );
  }

  Widget _buildResultCard(BuildContext context, SearchResult result) {
    final doc = result.document;
    final scoreColor = _getScoreColor(result.score);

    return InkWell(
      onTap: onResultTap != null ? () => onResultTap!(result) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B26) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF263345) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Rank Badge & Similarity Score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${result.rank}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      doc.id,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    result.scorePercentage,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Similarity Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: result.score.clamp(0.0, 1.0),
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                minHeight: 4,
              ),
            ),

            // Content Snippet
            if (doc.content != null && doc.content!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                doc.content!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],

            // Metadata Chips
            if (doc.metadata.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: doc.metadata.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark ? Colors.white10 : Colors.black.withAlpha(12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${e.key}: ${e.value}',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.85) return const Color(0xFF10B981); // Emerald
    if (score >= 0.70) return const Color(0xFF06B6D4); // Cyan
    if (score >= 0.50) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }
}
