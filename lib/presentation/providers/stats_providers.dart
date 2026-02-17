import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/stats.dart';

// ── Mock data ────────────────────────────────────────────────────────────────

final _now = DateTime.now().millisecondsSinceEpoch;

final _mockSeasonStats = [
  PlayerSeasonStatsModel(
    id: 'ss1', seasonId: 's1', playerId: 'p2', sport: 'volleyball',
    gamesPlayed: 5,
    statsTotals: {'kills': 48, 'errors': 12, 'totalAttempts': 110, 'assists': 3, 'serviceAces': 8, 'serviceErrors': 5, 'digs': 22, 'blockSolos': 2, 'blockAssists': 6, 'receptionErrors': 4, 'points': 58},
    statsAverages: {'kills': 9.6, 'errors': 2.4, 'totalAttempts': 22.0, 'assists': 0.6, 'serviceAces': 1.6, 'serviceErrors': 1.0, 'digs': 4.4, 'blockSolos': 0.4, 'blockAssists': 1.2, 'points': 11.6},
    computedMetrics: {'hittingPercentage': 0.327},
    computedAt: _now,
  ),
  PlayerSeasonStatsModel(
    id: 'ss2', seasonId: 's1', playerId: 'p3', sport: 'volleyball',
    gamesPlayed: 5,
    statsTotals: {'kills': 42, 'errors': 15, 'totalAttempts': 105, 'assists': 5, 'serviceAces': 6, 'serviceErrors': 7, 'digs': 30, 'blockSolos': 1, 'blockAssists': 4, 'receptionErrors': 6, 'points': 49},
    statsAverages: {'kills': 8.4, 'errors': 3.0, 'totalAttempts': 21.0, 'assists': 1.0, 'serviceAces': 1.2, 'serviceErrors': 1.4, 'digs': 6.0, 'blockSolos': 0.2, 'blockAssists': 0.8, 'points': 9.8},
    computedMetrics: {'hittingPercentage': 0.257},
    computedAt: _now,
  ),
  PlayerSeasonStatsModel(
    id: 'ss3', seasonId: 's1', playerId: 'p1', sport: 'volleyball',
    gamesPlayed: 5,
    statsTotals: {'kills': 5, 'errors': 2, 'totalAttempts': 15, 'assists': 152, 'serviceAces': 10, 'serviceErrors': 4, 'digs': 18, 'blockSolos': 0, 'blockAssists': 3, 'receptionErrors': 1, 'points': 15},
    statsAverages: {'kills': 1.0, 'errors': 0.4, 'totalAttempts': 3.0, 'assists': 30.4, 'serviceAces': 2.0, 'serviceErrors': 0.8, 'digs': 3.6, 'blockSolos': 0.0, 'blockAssists': 0.6, 'points': 3.0},
    computedMetrics: {'hittingPercentage': 0.200},
    computedAt: _now,
  ),
  PlayerSeasonStatsModel(
    id: 'ss4', seasonId: 's1', playerId: 'p4', sport: 'volleyball',
    gamesPlayed: 5,
    statsTotals: {'kills': 30, 'errors': 8, 'totalAttempts': 70, 'assists': 2, 'serviceAces': 4, 'serviceErrors': 6, 'digs': 8, 'blockSolos': 10, 'blockAssists': 12, 'receptionErrors': 0, 'points': 44},
    statsAverages: {'kills': 6.0, 'errors': 1.6, 'totalAttempts': 14.0, 'assists': 0.4, 'serviceAces': 0.8, 'serviceErrors': 1.2, 'digs': 1.6, 'blockSolos': 2.0, 'blockAssists': 2.4, 'points': 8.8},
    computedMetrics: {'hittingPercentage': 0.314},
    computedAt: _now,
  ),
  PlayerSeasonStatsModel(
    id: 'ss5', seasonId: 's1', playerId: 'p6', sport: 'volleyball',
    gamesPlayed: 5,
    statsTotals: {'kills': 35, 'errors': 10, 'totalAttempts': 85, 'assists': 1, 'serviceAces': 7, 'serviceErrors': 3, 'digs': 14, 'blockSolos': 4, 'blockAssists': 8, 'receptionErrors': 3, 'points': 46},
    statsAverages: {'kills': 7.0, 'errors': 2.0, 'totalAttempts': 17.0, 'assists': 0.2, 'serviceAces': 1.4, 'serviceErrors': 0.6, 'digs': 2.8, 'blockSolos': 0.8, 'blockAssists': 1.6, 'points': 9.2},
    computedMetrics: {'hittingPercentage': 0.294},
    computedAt: _now,
  ),
  PlayerSeasonStatsModel(
    id: 'ss6', seasonId: 's1', playerId: 'p7', sport: 'volleyball',
    gamesPlayed: 5,
    statsTotals: {'kills': 0, 'errors': 0, 'totalAttempts': 0, 'assists': 4, 'serviceAces': 0, 'serviceErrors': 0, 'digs': 65, 'blockSolos': 0, 'blockAssists': 0, 'receptionErrors': 3, 'points': 0},
    statsAverages: {'kills': 0.0, 'errors': 0.0, 'totalAttempts': 0.0, 'assists': 0.8, 'serviceAces': 0.0, 'serviceErrors': 0.0, 'digs': 13.0, 'blockSolos': 0.0, 'blockAssists': 0.0, 'points': 0.0},
    computedMetrics: {'hittingPercentage': 0.0},
    computedAt: _now,
  ),
];

// ── Providers ────────────────────────────────────────────────────────────────

final seasonStatsProvider = StateNotifierProvider<SeasonStatsNotifier,
    AsyncValue<List<PlayerSeasonStatsModel>>>((ref) {
  return SeasonStatsNotifier();
});

final playerDetailProvider =
    StateProvider.family<PlayerSeasonStatsModel?, String>(
        (ref, playerId) {
  final stats = ref.watch(seasonStatsProvider);
  return stats.whenOrNull(
    data: (list) {
      try {
        return list.firstWhere((s) => s.playerId == playerId);
      } catch (_) {
        return null;
      }
    },
  );
});

// ── Notifiers ────────────────────────────────────────────────────────────────

class SeasonStatsNotifier
    extends StateNotifier<AsyncValue<List<PlayerSeasonStatsModel>>> {
  SeasonStatsNotifier() : super(const AsyncValue.loading()) {
    loadStats();
  }

  void loadStats() {
    state = AsyncValue.data(List.from(_mockSeasonStats));
  }

  void updateStats(PlayerSeasonStatsModel stats) {
    state.whenData((list) {
      state = AsyncValue.data(
        list.map((s) => s.id == stats.id ? stats : s).toList(),
      );
    });
  }

  void clearStats() {
    state = const AsyncValue.data([]);
  }
}
