import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/team_providers.dart';
import '../../providers/game_providers.dart';
import '../../providers/stats_providers.dart';
import '../../providers/dashboard_insights_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/sport_icon.dart';
import '../../../core/theme/colors.dart';
import '../../../domain/models/game.dart';
import '../../../domain/models/team.dart';
import '../../../domain/models/season.dart';
import '../game_detail/game_detail_screen.dart';
import 'widgets/efficiency_trend_chart.dart';
import 'widgets/points_source_chart.dart';
import 'widgets/player_contribution_chart.dart';
import 'widgets/service_scatter_chart.dart';
import 'widgets/home_away_chart.dart';
import 'widgets/game_margin_chart.dart';
import 'widgets/recent_form_heatmap.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTeam = ref.watch(selectedTeamProvider);
    final activeSeason = ref.watch(activeSeasonProvider);
    final record = ref.watch(seasonRecordProvider);
    final gamesAsync = ref.watch(gamesProvider);
    final statsAsync = ref.watch(seasonStatsProvider);

    if (selectedTeam == null) {
      return _buildEmptyState(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SportIcon(sport: selectedTeam.sport, size: 28),
            const SizedBox(width: 8),
            Text(
              'StatLine',
              style: TextStyle(
                color: StatLineColors.logoGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          if (activeSeason != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  activeSeason.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(153),
                      ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch Team',
            onPressed: () {
              ref.read(selectedTeamProvider.notifier).state = null;
              ref.read(activeSeasonProvider.notifier).state = null;
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return _DashboardBody(
            isWide: isWide,
            selectedTeam: selectedTeam,
            gamesAsync: gamesAsync,
            statsAsync: statsAsync,
            record: record,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const _EmptyDashboard();
  }

  Widget _buildStartGameCard(BuildContext context, String teamName, List<Game> games) {
    // Check for in-progress game
    final inProgress = games.where((g) => g.status == GameStatus.inProgress).toList();
    if (inProgress.isNotEmpty) {
      final game = inProgress.first;
      return Card(
        color: const Color(0xFFE65100),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/live-game'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Row(
              children: [
                const Icon(Icons.play_arrow,
                    size: 48, color: StatLineColors.onPrimary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teamName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: StatLineColors.onPrimary.withAlpha(204),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Resume Game vs ${game.opponentName}',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: StatLineColors.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: StatLineColors.onPrimary, size: 20),
              ],
            ),
          ),
        ),
      );
    }

    // Check for upcoming scheduled game within 48 hours
    final now = DateTime.now();
    final upcoming = games
        .where((g) =>
            g.status == GameStatus.scheduled &&
            g.gameDate.isAfter(now) &&
            g.gameDate.isBefore(now.add(const Duration(hours: 48))))
        .toList()
      ..sort((a, b) => a.gameDate.compareTo(b.gameDate));

    if (upcoming.isNotEmpty) {
      final game = upcoming.first;
      final dateStr = _formatDate(game.gameDate);
      return Card(
        color: StatLineColors.nordicSlate,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/live-game'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Row(
              children: [
                const Icon(Icons.event,
                    size: 48, color: StatLineColors.onPrimary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teamName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: StatLineColors.onPrimary.withAlpha(204),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Next Up: vs ${game.opponentName} – $dateStr',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: StatLineColors.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: StatLineColors.onPrimary, size: 20),
              ],
            ),
          ),
        ),
      );
    }

    // Default: Start a new game
    return Card(
      color: StatLineColors.primaryAccent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/live-game'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Row(
            children: [
              const Icon(Icons.play_circle_filled,
                  size: 48, color: StatLineColors.onPrimary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: StatLineColors.onPrimary.withAlpha(204),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start a new game',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: StatLineColors.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: StatLineColors.onPrimary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Compute current streak from completed games sorted newest-first.
  String _computeStreak(List<Game> games) {
    final completed = games
        .where((g) => g.status == GameStatus.completed && g.result != null)
        .toList()
      ..sort((a, b) => b.gameDate.compareTo(a.gameDate));
    if (completed.isEmpty) return '';

    final firstResult = completed.first.result!;
    int count = 0;
    for (final game in completed) {
      if (game.result == firstResult) {
        count++;
      } else {
        break;
      }
    }
    if (count < 2) return '';

    switch (firstResult) {
      case GameResult.win:
        return '🔥 W$count';
      case GameResult.loss:
        return 'L$count';
      case GameResult.tie:
        return 'T$count';
    }
  }

  Widget _buildRecordCard(
      BuildContext context, Map<String, int> record, List<Game> games) {
    final wins = record['wins'] ?? 0;
    final losses = record['losses'] ?? 0;
    final ties = record['ties'] ?? 0;
    final streak = _computeStreak(games);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StatCard(
                  label: 'Wins',
                  value: '$wins',
                  valueColor: StatLineColors.pointScored,
                  width: 80,
                ),
                Text(
                  '-',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(102),
                      ),
                ),
                StatCard(
                  label: 'Losses',
                  value: '$losses',
                  valueColor: StatLineColors.pointLost,
                  width: 80,
                ),
                if (ties > 0) ...[
                  Text(
                    '-',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(102),
                        ),
                  ),
                  StatCard(
                    label: 'Ties',
                    value: '$ties',
                    width: 80,
                  ),
                ],
              ],
            ),
            if (streak.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                streak,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLastGameCard(BuildContext context, Game game) {
    final isWin = game.result == GameResult.win;
    final isLoss = game.result == GameResult.loss;
    final resultLabel = isWin
        ? 'W'
        : isLoss
            ? 'L'
            : 'T';
    final resultColor = isWin
        ? StatLineColors.pointScored
        : isLoss
            ? StatLineColors.pointLost
            : Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last Game', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: resultColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        resultLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: resultColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${game.isHome ? "vs" : "@"} ${game.opponentName}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(game.gameDate),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withAlpha(153),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${game.finalScoreUs ?? 0} - ${game.finalScoreThem ?? 0}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      softWrap: false,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GameDetailScreen(gameId: game.id, initialTabIndex: 1),
                        ),
                      );
                    },
                    child: const Text('View Game →'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameTile(BuildContext context, dynamic game) {
    final isWin = game.result == GameResult.win;
    final isLoss = game.result == GameResult.loss;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GameDetailScreen(gameId: game.id),
            ),
          );
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isWin
                ? StatLineColors.pointScored.withAlpha(51)
                : isLoss
                    ? StatLineColors.pointLost.withAlpha(51)
                    : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              isWin
                  ? 'W'
                  : isLoss
                      ? 'L'
                      : 'T',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isWin
                    ? StatLineColors.pointScored
                    : isLoss
                        ? StatLineColors.pointLost
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        title: Text(
          '${game.isHome ? "vs" : "@"} ${game.opponentName}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${game.finalScoreUs ?? 0} - ${game.finalScoreThem ?? 0}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Text(
          _formatDate(game.gameDate),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// ── Responsive Dashboard Body ────────────────────────────────────────────────

class _DashboardBody extends ConsumerStatefulWidget {
  final bool isWide;
  final Team selectedTeam;
  final AsyncValue<List<Game>> gamesAsync;
  final AsyncValue<List<dynamic>> statsAsync;
  final Map<String, int> record;

  const _DashboardBody({
    required this.isWide,
    required this.selectedTeam,
    required this.gamesAsync,
    required this.statsAsync,
    required this.record,
  });

  @override
  ConsumerState<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends ConsumerState<_DashboardBody> {
  bool _recentGamesExpanded = true;
  bool _teamLeadersExpanded = true;

  @override
  Widget build(BuildContext context) {
    final dashboard = DashboardScreen();
    final games = widget.gamesAsync.valueOrNull ?? [];

    // Shared widgets
    final heroCard = dashboard._buildStartGameCard(
        context, widget.selectedTeam.name, games);

    final recordCard = widget.gamesAsync.when(
      data: (games) => dashboard._buildRecordCard(context, widget.record, games),
      loading: () => dashboard._buildRecordCard(context, widget.record, []),
      error: (_, __) => dashboard._buildRecordCard(context, widget.record, []),
    );

    final needsAttention = const _NeedsAttentionCard();

    final insightsPanel = widget.gamesAsync.when(
      data: (games) => widget.statsAsync.when(
        data: (stats) => _InsightsPanel(games: games, stats: stats),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );

    final lastGameCard = widget.gamesAsync.when(
      data: (games) {
        final completed = games
            .where((g) => g.status == GameStatus.completed)
            .toList()
          ..sort((a, b) => b.gameDate.compareTo(a.gameDate));
        if (completed.isEmpty) return const SizedBox.shrink();
        return dashboard._buildLastGameCard(context, completed.first);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );

    final recentGamesContent = widget.gamesAsync.when(
      data: (games) {
        if (games.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No games yet')),
            ),
          );
        }
        final recent = games.take(5).toList();
        return Column(
          children: recent
              .map((game) => dashboard._buildGameTile(context, game))
              .toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );

    final teamLeadersContent = widget.statsAsync.when(
      data: (stats) {
        if (stats.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No stats yet')),
            ),
          );
        }
        return _TeamLeadersCard(stats: stats);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );

    // Collapsible sections
    final recentGamesSection = _CollapsibleSection(
      title: 'Recent Games',
      isExpanded: _recentGamesExpanded,
      onToggle: () => setState(() => _recentGamesExpanded = !_recentGamesExpanded),
      child: recentGamesContent,
    );

    final teamLeadersSection = _CollapsibleSection(
      title: 'Team Leaders',
      isExpanded: _teamLeadersExpanded,
      onToggle: () => setState(() => _teamLeadersExpanded = !_teamLeadersExpanded),
      child: teamLeadersContent,
    );

    if (widget.isWide) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Row 1: Hero (60%) + Last Game (40%)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: heroCard),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: lastGameCard),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: Needs Attention + Season Record side by side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: needsAttention),
              const SizedBox(width: 16),
              Expanded(child: recordCard),
            ],
          ),
          const SizedBox(height: 16),
          // Row 3: Insights Panel (full width)
          insightsPanel,
          const SizedBox(height: 16),
          // Row 4: Team Leaders (50%) + Recent Games (50%)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: teamLeadersSection),
              const SizedBox(width: 16),
              Expanded(child: recentGamesSection),
            ],
          ),
        ],
      );
    }

    // Mobile: single column
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        heroCard,
        const SizedBox(height: 16),
        recordCard,
        const SizedBox(height: 16),
        needsAttention,
        insightsPanel,
        const SizedBox(height: 16),
        lastGameCard,
        const SizedBox(height: 24),
        recentGamesSection,
        const SizedBox(height: 24),
        teamLeadersSection,
      ],
    );
  }
}

// ── Collapsible Section ──────────────────────────────────────────────────────

class _CollapsibleSection extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  const _CollapsibleSection({
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              AnimatedRotation(
                turns: isExpanded ? 0.0 : -0.25,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.expand_more),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          firstChild: child,
          secondChild: const SizedBox.shrink(),
          crossFadeState:
              isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

// ── Insights Panel (tabbed charts + alert summary) ───────────────────────────

class _InsightsPanel extends ConsumerStatefulWidget {
  final List<Game> games;
  final List<dynamic> stats;

  const _InsightsPanel({required this.games, required this.stats});

  @override
  ConsumerState<_InsightsPanel> createState() => _InsightsPanelState();
}

class _InsightsPanelState extends ConsumerState<_InsightsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Generate text insight alerts from games and stats.
  List<String> _generateAlerts() {
    final alerts = <String>[];
    final completed = widget.games
        .where((g) => g.status == GameStatus.completed && g.result != null)
        .toList()
      ..sort((a, b) => b.gameDate.compareTo(a.gameDate));

    if (completed.length >= 3) {
      final firstResult = completed.first.result!;
      int count = 0;
      for (final g in completed) {
        if (g.result == firstResult) {
          count++;
        } else {
          break;
        }
      }
      if (count >= 3 && firstResult == GameResult.win) {
        alerts.add('🔥 $count-game win streak');
      } else if (count >= 3 && firstResult == GameResult.loss) {
        alerts.add('⚠️ $count-game losing streak');
      }
    }

    if (widget.stats.isNotEmpty) {
      final totalServiceErrors = widget.stats.fold<num>(
          0, (sum, s) => sum + ((s.statsTotals['serviceErrors'] ?? 0) as num));
      final totalGames = widget.stats
          .map((s) => s.gamesPlayed as int)
          .fold<int>(0, (a, b) => a > b ? a : b);
      if (totalGames > 0 && totalServiceErrors / totalGames > 5) {
        alerts.add('📈 High service errors');
      }
    }

    return alerts.isEmpty ? ['📊 Stats looking steady'] : alerts;
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _generateAlerts();
    final efficiencyTrend = ref.watch(efficiencyTrendProvider);
    final pointsSource = ref.watch(pointsSourceProvider);
    final playerContribution = ref.watch(playerContributionProvider);
    final serviceEfficiency = ref.watch(serviceEfficiencyProvider);
    final homeAway = ref.watch(homeAwayProvider);
    final gameMargin = ref.watch(gameMarginProvider);
    final recentForm = ref.watch(recentFormProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert summary row
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: alerts
                      .map((a) => Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(a,
                                style: Theme.of(context).textTheme.bodySmall),
                          ))
                      .toList(),
                ),
              ),
            ),
            // Tab bar
            TabBar(
              controller: _tabController,
              labelStyle: Theme.of(context).textTheme.labelMedium,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Trends'),
                Tab(text: 'Balance'),
                Tab(text: 'Context'),
                Tab(text: 'Form'),
              ],
            ),
            // Tab content
            SizedBox(
              height: 520,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Trends tab: Efficiency Trend + Service Scatter
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        EfficiencyTrendChart(data: efficiencyTrend),
                        const SizedBox(height: 24),
                        ServiceScatterChart(data: serviceEfficiency),
                      ],
                    ),
                  ),
                  // Balance tab: Points Source + Player Contribution
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        PointsSourceChart(data: pointsSource),
                        const SizedBox(height: 16),
                        PlayerContributionChart(data: playerContribution),
                      ],
                    ),
                  ),
                  // Context tab: Home vs Away + Game Margins
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        HomeAwayChart(data: homeAway),
                        const SizedBox(height: 16),
                        GameMarginChart(data: gameMargin),
                      ],
                    ),
                  ),
                  // Form tab: Recent Form Heatmap
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 12),
                    child: RecentFormHeatmap(data: recentForm),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Needs Attention Card ─────────────────────────────────────────────────────

class _NeedsAttentionCard extends ConsumerWidget {
  const _NeedsAttentionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(needsAttentionProvider);
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: const Color(0xFFFFF3E0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Needs Attention',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE65100),
                    ),
              ),
              const SizedBox(height: 8),
              ...alerts.map((alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${alert.icon} ${alert.message}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF4E342E),
                          ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Team Leaders Card (FilterChip categories) ────────────────────────────────

enum _LeaderCategory { kills, hittingPct, aces, digs }

class _TeamLeadersCard extends ConsumerStatefulWidget {
  final List<dynamic> stats;

  const _TeamLeadersCard({required this.stats});

  @override
  ConsumerState<_TeamLeadersCard> createState() => _TeamLeadersCardState();
}

class _TeamLeadersCardState extends ConsumerState<_TeamLeadersCard> {
  _LeaderCategory _selected = _LeaderCategory.kills;

  Widget _buildTrendArrow(num value, num average) {
    if (average == 0) return const SizedBox.shrink();
    if (value > average) {
      return const Text(' ▲',
          style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12));
    } else if (value < average) {
      return const Text(' ▼',
          style: TextStyle(color: Color(0xFFF44336), fontSize: 12));
    }
    return const Text(' —',
        style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12));
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);
    final players = playersAsync.valueOrNull ?? [];

    String getPlayerName(String playerId) {
      final p = players.where((p) => p.id == playerId);
      return p.isNotEmpty ? p.first.shortName : playerId;
    }

    final categoryLabels = {
      _LeaderCategory.kills: 'Kills',
      _LeaderCategory.hittingPct: 'Hitting%',
      _LeaderCategory.aces: 'Aces',
      _LeaderCategory.digs: 'Digs',
    };

    List<dynamic> getSorted() {
      final sorted = List.from(widget.stats);
      switch (_selected) {
        case _LeaderCategory.kills:
          sorted.sort((a, b) => ((b.statsTotals['kills'] ?? 0) as num)
              .compareTo((a.statsTotals['kills'] ?? 0) as num));
        case _LeaderCategory.hittingPct:
          sorted.sort((a, b) =>
              ((b.computedMetrics['hittingPercentage'] ?? 0) as num)
                  .compareTo(
                      (a.computedMetrics['hittingPercentage'] ?? 0) as num));
        case _LeaderCategory.aces:
          sorted.sort((a, b) =>
              ((b.statsTotals['serviceAces'] ?? 0) as num)
                  .compareTo((a.statsTotals['serviceAces'] ?? 0) as num));
        case _LeaderCategory.digs:
          sorted.sort((a, b) => ((b.statsTotals['digs'] ?? 0) as num)
              .compareTo((a.statsTotals['digs'] ?? 0) as num));
      }
      return sorted.take(3).toList();
    }

    String formatValue(dynamic s) {
      switch (_selected) {
        case _LeaderCategory.kills:
          return '${s.statsTotals['kills'] ?? 0}';
        case _LeaderCategory.hittingPct:
          final hitPct =
              (s.computedMetrics['hittingPercentage'] ?? 0) as num;
          return '.${(hitPct * 1000).round().toString().padLeft(3, '0')}';
        case _LeaderCategory.aces:
          return '${s.statsTotals['serviceAces'] ?? 0}';
        case _LeaderCategory.digs:
          return '${s.statsTotals['digs'] ?? 0}';
      }
    }

    Widget trendArrow(dynamic s) {
      switch (_selected) {
        case _LeaderCategory.kills:
          final kills = (s.statsTotals['kills'] ?? 0) as num;
          final avgKills = (s.statsAverages['kills'] ?? 0) as num;
          final gp = s.gamesPlayed as int;
          final rate = gp > 0 ? kills / gp : 0;
          return _buildTrendArrow(rate, avgKills);
        case _LeaderCategory.hittingPct:
          final hitPct =
              (s.computedMetrics['hittingPercentage'] ?? 0) as num;
          return _buildTrendArrow(hitPct, 0.250);
        case _LeaderCategory.aces:
          final aces = (s.statsTotals['serviceAces'] ?? 0) as num;
          final avgAces = (s.statsAverages['serviceAces'] ?? 0) as num;
          final gp = s.gamesPlayed as int;
          final rate = gp > 0 ? aces / gp : 0;
          return _buildTrendArrow(rate, avgAces);
        case _LeaderCategory.digs:
          final digs = (s.statsTotals['digs'] ?? 0) as num;
          final avgDigs = (s.statsAverages['digs'] ?? 0) as num;
          final gp = s.gamesPlayed as int;
          final rate = gp > 0 ? digs / gp : 0;
          return _buildTrendArrow(rate, avgDigs);
      }
    }

    final top = getSorted();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FilterChips for categories
            Wrap(
              spacing: 8,
              children: _LeaderCategory.values.map((cat) {
                return FilterChip(
                  label: Text(categoryLabels[cat]!),
                  selected: _selected == cat,
                  onSelected: (selected) {
                    if (selected) setState(() => _selected = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            ...top.map((s) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        getPlayerName(s.playerId),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatValue(s),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trendArrow(s),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Empty Dashboard (no team selected) ───────────────────────────────────────

class _EmptyDashboard extends ConsumerWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsProvider);
    final seasonsAsync = ref.watch(seasonsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.sports_volleyball, color: StatLineColors.logoGreen),
            const SizedBox(width: 8),
            Text(
              'StatLine',
              style: TextStyle(
                color: StatLineColors.logoGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero section ──────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: StatLineColors.logoGreen.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sports_volleyball,
                      size: 44,
                      color: StatLineColors.logoGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to StatLine',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select a team below to view your dashboard',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Your Teams section ────────────────────────────────────
            Text(
              'Your Teams',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            teamsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading teams: $e'),
                ),
              ),
              data: (teams) {
                if (teams.isEmpty) {
                  return _buildNoTeamsCard(context, theme);
                }
                return Column(
                  children: [
                    ...teams.map((team) => _buildTeamCard(
                          context, ref, theme, team, seasonsAsync)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/teams'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Manage Teams'),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // ── Features overview ─────────────────────────────────────
            Text(
              'What You Can Track',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildFeatureRow(
              theme,
              Icons.play_circle_outline,
              'Live Scoring',
              'Tap-to-record play-by-play during games',
            ),
            _buildFeatureRow(
              theme,
              Icons.bar_chart,
              'Season Stats',
              'Kills, aces, digs, hitting % and more',
            ),
            _buildFeatureRow(
              theme,
              Icons.edit_note,
              'Post-Game Corrections',
              'Fix mistakes without losing data',
            ),
            _buildFeatureRow(
              theme,
              Icons.autorenew,
              'Auto-Rotate',
              'Rotation and serve tracking on side-outs',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Team team,
    AsyncValue<List<Season>> seasonsAsync,
  ) {
    final sportColor = StatLineColors.forSport(team.sport);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          ref.read(selectedTeamProvider.notifier).state = team;
          // Auto-select the active season for this team
          seasonsAsync.whenData((seasons) {
            final active = seasons
                .where((s) => s.teamId == team.id && s.isActive)
                .toList();
            if (active.isNotEmpty) {
              ref.read(activeSeasonProvider.notifier).state = active.first;
            }
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: sportColor, width: 4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SportIcon(sport: team.sport, size: 32, color: sportColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        team.sport[0].toUpperCase() + team.sport.substring(1),
                        team.level,
                        if (team.ageGroup != null) team.ageGroup!,
                        team.gender,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withAlpha(100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoTeamsCard(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.groups_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withAlpha(100),
            ),
            const SizedBox(height: 12),
            Text(
              'No teams yet',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Create your first team to start tracking stats',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/teams'),
              icon: const Icon(Icons.add),
              label: const Text('Create Team'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: StatLineColors.logoGreen.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: StatLineColors.logoGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(140),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
