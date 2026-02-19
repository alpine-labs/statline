import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/models/game.dart';
import '../domain/models/game_period.dart';

/// Captures Flutter widgets as images for social sharing.
class ImageExporter {
  ImageExporter._();

  static final _screenshotController = ScreenshotController();

  /// Capture the widget associated with [key] as a PNG image.
  ///
  /// Returns `null` if the render boundary cannot be found.
  static Future<Uint8List?> captureWidget(GlobalKey key) async {
    final boundary = key.currentContext?.findRenderObject();
    if (boundary == null) return null;

    return _screenshotController.captureFromWidget(
      Builder(builder: (_) {
        // The widget tree under the key is already built; we re-render via
        // the screenshot controller which paints the boundary off-screen.
        final widget = key.currentContext?.widget;
        return widget ?? const SizedBox.shrink();
      }),
      pixelRatio: 3.0,
    );
  }

  /// Capture an arbitrary [widget] to a PNG image without requiring it to be
  /// part of the current widget tree.
  static Future<Uint8List> captureFromWidget(
    Widget widget, {
    double pixelRatio = 3.0,
    Size targetSize = Size.zero,
  }) {
    return _screenshotController.captureFromWidget(
      widget,
      pixelRatio: pixelRatio,
      targetSize: targetSize == Size.zero ? null : targetSize,
    );
  }

  /// Generate a styled box score card as a PNG image.
  ///
  /// [playerStats] maps playerId → stat map with keys like 'kills', 'errors',
  /// 'totalAttempts', 'assists', 'serviceAces', 'digs', etc.
  static Future<Uint8List?> generateBoxScoreImage({
    required Game game,
    required List<GamePeriod> periods,
    required Map<String, Map<String, dynamic>> playerStats,
    required Map<String, String> playerNames,
  }) async {
    final widget = _BoxScoreCard(
      game: game,
      periods: periods,
      playerStats: playerStats,
      playerNames: playerNames,
    );

    return _screenshotController.captureFromWidget(
      widget,
      pixelRatio: 3.0,
    );
  }

  /// Save [imageBytes] to a temp file and share it via the platform share
  /// sheet.
  static Future<void> shareImage(
    Uint8List imageBytes,
    String title,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/${title.replaceAll(RegExp(r'[^\w\-.]'), '_')}.png',
    );
    await file.writeAsBytes(imageBytes);
    await Share.shareXFiles([XFile(file.path)], text: title);
  }
}

// ── Box Score Card Widget (rendered off-screen to PNG) ──────────────────────

class _BoxScoreCard extends StatelessWidget {
  final Game game;
  final List<GamePeriod> periods;
  final Map<String, Map<String, dynamic>> playerStats;
  final Map<String, String> playerNames;

  static const _bg = Color(0xFF121212);
  static const _surface = Color(0xFF1E1E1E);
  static const _accent = Color(0xFFFF6B35);
  static const _textPrimary = Color(0xFFF5F5F5);
  static const _textSecondary = Color(0xFFB0B0B0);
  static const _divider = Color(0xFF333333);
  static final _dateFmt = DateFormat('MMM d, yyyy');

  const _BoxScoreCard({
    required this.game,
    required this.periods,
    required this.playerStats,
    required this.playerNames,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<GamePeriod>.from(periods)
      ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));

    // Determine final set score
    int setsUs = 0, setsThem = 0;
    for (final p in sorted) {
      if (p.scoreUs > p.scoreThem) {
        setsUs++;
      } else if (p.scoreThem > p.scoreUs) {
        setsThem++;
      }
    }
    final finalScore = game.finalScoreUs != null
        ? '${game.finalScoreUs} – ${game.finalScoreThem}'
        : '$setsUs – $setsThem';

    // Top 3 players by kills
    final ranked = playerStats.entries.toList()
      ..sort((a, b) {
        final ka = (a.value['kills'] ?? 0) as num;
        final kb = (b.value['kills'] ?? 0) as num;
        return kb.compareTo(ka);
      });
    final top = ranked.take(3).toList();

    return Container(
      width: 420,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Text(
                  'BOX SCORE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${game.teamId}  vs  ${game.opponentName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Date + Final score
          Text(
            _dateFmt.format(game.gameDate),
            style: const TextStyle(fontSize: 12, color: _textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Final: $finalScore',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // Set-by-set scores
          if (sorted.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 60,
                    child: Text('', style: TextStyle(color: _textSecondary)),
                  ),
                  ...sorted.map((p) => Expanded(
                        child: Center(
                          child: Text(
                            'S${p.periodNumber}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _textSecondary,
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 2),
            _setScoreRow(game.teamId, sorted, true),
            const SizedBox(height: 2),
            _setScoreRow(game.opponentName, sorted, false),
            const SizedBox(height: 14),
          ],

          // Stat table header
          Divider(color: _divider, height: 1),
          const SizedBox(height: 10),
          _statHeader(),
          const SizedBox(height: 4),
          Divider(color: _divider, height: 1),
          const SizedBox(height: 4),

          // Top player rows
          ...top.map((e) => _statRow(e.key, e.value)),

          const SizedBox(height: 12),

          // Footer
          const Text(
            'STATLINE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _accent,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _setScoreRow(String label, List<GamePeriod> sorted, bool isUs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label.length > 8 ? '${label.substring(0, 8)}…' : label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...sorted.map((p) => Expanded(
                child: Center(
                  child: Text(
                    '${isUs ? p.scoreUs : p.scoreThem}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _statHeader() {
    const style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: _textSecondary,
    );
    return Row(
      children: const [
        Expanded(flex: 3, child: Text('PLAYER', style: style)),
        Expanded(child: Center(child: Text('K', style: style))),
        Expanded(child: Center(child: Text('E', style: style))),
        Expanded(child: Center(child: Text('TA', style: style))),
        Expanded(child: Center(child: Text('Hit%', style: style))),
        Expanded(child: Center(child: Text('A', style: style))),
        Expanded(child: Center(child: Text('SA', style: style))),
        Expanded(child: Center(child: Text('D', style: style))),
      ],
    );
  }

  Widget _statRow(String playerId, Map<String, dynamic> stats) {
    final name = playerNames[playerId] ?? playerId;
    final kills = stats['kills'] ?? 0;
    final errors = stats['errors'] ?? 0;
    final ta = stats['totalAttempts'] ?? 0;
    final hitPct = ta > 0 ? ((kills - errors) / ta) : 0.0;
    final assists = stats['assists'] ?? 0;
    final aces = stats['serviceAces'] ?? 0;
    final digs = stats['digs'] ?? 0;

    const valStyle = TextStyle(
      fontSize: 12,
      color: _textPrimary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(child: Center(child: Text('$kills', style: valStyle))),
          Expanded(child: Center(child: Text('$errors', style: valStyle))),
          Expanded(child: Center(child: Text('$ta', style: valStyle))),
          Expanded(
            child: Center(
              child: Text(
                hitPct == 0.0 ? '.000' : hitPct.toStringAsFixed(3),
                style: valStyle,
              ),
            ),
          ),
          Expanded(child: Center(child: Text('$assists', style: valStyle))),
          Expanded(child: Center(child: Text('$aces', style: valStyle))),
          Expanded(child: Center(child: Text('$digs', style: valStyle))),
        ],
      ),
    );
  }
}
