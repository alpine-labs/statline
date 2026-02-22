import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:statline/presentation/providers/dashboard_insights_provider.dart';
import 'package:statline/presentation/screens/dashboard/widgets/efficiency_trend_chart.dart';
import 'package:statline/presentation/screens/dashboard/widgets/points_source_chart.dart';
import 'package:statline/presentation/screens/dashboard/widgets/player_contribution_chart.dart';
import 'package:statline/presentation/screens/dashboard/widgets/service_scatter_chart.dart';
import 'package:statline/presentation/screens/dashboard/widgets/home_away_chart.dart';

void main() {
  // ── Efficiency Trend Chart ──────────────────────────────────────────────

  group('EfficiencyTrendChart', () {
    testWidgets('renders with valid data (3+ games)', (tester) async {
      final data = [
        const EfficiencyTrendPoint(gameLabel: 'vs A', hittingPct: 0.300, isWin: true),
        const EfficiencyTrendPoint(gameLabel: 'vs B', hittingPct: 0.200, isWin: false),
        const EfficiencyTrendPoint(gameLabel: 'vs C', hittingPct: 0.250, rollingAvg: 0.250, isWin: true),
        const EfficiencyTrendPoint(gameLabel: 'vs D', hittingPct: 0.280, rollingAvg: 0.243, isWin: true),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EfficiencyTrendChart(data: data),
            ),
          ),
        ),
      );

      expect(find.text('Offensive Efficiency Trend'), findsOneWidget);
      expect(find.text('Need 3+ games to show trends'), findsNothing);
    });

    testWidgets('renders empty state with < 3 games', (tester) async {
      final data = [
        const EfficiencyTrendPoint(gameLabel: 'vs A', hittingPct: 0.300, isWin: true),
        const EfficiencyTrendPoint(gameLabel: 'vs B', hittingPct: 0.200, isWin: false),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EfficiencyTrendChart(data: data),
          ),
        ),
      );

      expect(find.text('Need 3+ games to show trends'), findsOneWidget);
    });

    testWidgets('renders empty state with empty data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EfficiencyTrendChart(data: []),
          ),
        ),
      );

      expect(find.text('Need 3+ games to show trends'), findsOneWidget);
    });
  });

  // ── Points Source Chart ─────────────────────────────────────────────────

  group('PointsSourceChart', () {
    testWidgets('renders with valid data', (tester) async {
      const data = PointsSourceData(
        kills: 60,
        aces: 12,
        blocks: 8,
        opponentErrors: 10,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PointsSourceChart(data: data),
            ),
          ),
        ),
      );

      expect(find.text('Points Source'), findsOneWidget);
      expect(find.text('90'), findsOneWidget); // total
      expect(find.text('pts'), findsOneWidget);
      expect(find.text('No points data yet'), findsNothing);
    });

    testWidgets('renders empty state with zero data', (tester) async {
      const data = PointsSourceData(
        kills: 0,
        aces: 0,
        blocks: 0,
        opponentErrors: 0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PointsSourceChart(data: data),
          ),
        ),
      );

      expect(find.text('No points data yet'), findsOneWidget);
    });

    testWidgets('legend shows correct labels', (tester) async {
      const data = PointsSourceData(
        kills: 50,
        aces: 10,
        blocks: 5,
        opponentErrors: 5,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PointsSourceChart(data: data),
            ),
          ),
        ),
      );

      expect(find.text('Kills (50)'), findsOneWidget);
      expect(find.text('Aces (10)'), findsOneWidget);
      expect(find.text('Blocks (5)'), findsOneWidget);
      expect(find.text('Other (5)'), findsOneWidget);
    });
  });

  // ── Player Contribution Chart ──────────────────────────────────────────

  group('PlayerContributionChart', () {
    testWidgets('renders with valid data', (tester) async {
      final data = [
        const PlayerContributionData(playerName: 'E. Davis', playerId: 'p1', kills: 48, digs: 22, aces: 8),
        const PlayerContributionData(playerName: 'M. Martinez', playerId: 'p2', kills: 42, digs: 30, aces: 6),
        const PlayerContributionData(playerName: 'S. Garcia', playerId: 'p3', kills: 35, digs: 14, aces: 7),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlayerContributionChart(data: data),
            ),
          ),
        ),
      );

      expect(find.text('Top 5 Player Contributions'), findsOneWidget);
      expect(find.text('Kills'), findsOneWidget);
      expect(find.text('Digs'), findsOneWidget);
      expect(find.text('Aces'), findsOneWidget);
      expect(find.text('No player data yet'), findsNothing);
    });

    testWidgets('renders empty state with no data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayerContributionChart(data: []),
          ),
        ),
      );

      expect(find.text('No player data yet'), findsOneWidget);
    });

    testWidgets('shows abbreviated names', (tester) async {
      final data = [
        const PlayerContributionData(
          playerName: 'Very Long Player Name',
          playerId: 'p1',
          kills: 20,
          digs: 10,
          aces: 5,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlayerContributionChart(data: data),
            ),
          ),
        ),
      );

      // Name should be truncated to 10 chars + ellipsis
      expect(find.text('Very Long …'), findsOneWidget);
    });
  });

  // ── Service Scatter Chart ──────────────────────────────────────────────

  group('ServiceScatterChart', () {
    testWidgets('renders with valid data', (tester) async {
      final data = [
        const ServiceEfficiencyPoint(gameLabel: 'vs A', aces: 5, errors: 2, isWin: true),
        const ServiceEfficiencyPoint(gameLabel: '@ B', aces: 2, errors: 4, isWin: false),
        const ServiceEfficiencyPoint(gameLabel: 'vs C', aces: 3, errors: 3, isWin: true),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ServiceScatterChart(data: data),
            ),
          ),
        ),
      );

      expect(find.text('Service Efficiency'), findsOneWidget);
      expect(find.text('Win'), findsOneWidget);
      expect(find.text('Loss'), findsOneWidget);
      expect(find.text('Need game data to show service efficiency'), findsNothing);
    });

    testWidgets('renders empty state with no data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServiceScatterChart(data: []),
          ),
        ),
      );

      expect(find.text('Need game data to show service efficiency'), findsOneWidget);
    });
  });

  // ── Home Away Chart ────────────────────────────────────────────────────

  group('HomeAwayChart', () {
    testWidgets('renders with valid data', (tester) async {
      const data = HomeAwayComparison(
        homeWinPct: 75.0,
        awayWinPct: 50.0,
        homeHittingPct: 0.280,
        awayHittingPct: 0.220,
        homeAcesPerGame: 7.5,
        awayAcesPerGame: 5.0,
        homeDigsPerGame: 32.0,
        awayDigsPerGame: 28.0,
        homeGames: 3,
        awayGames: 2,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeAwayChart(data: data),
            ),
          ),
        ),
      );

      expect(find.text('Home vs Away'), findsOneWidget);
      expect(find.textContaining('Home'), findsWidgets);
      expect(find.textContaining('Away'), findsWidgets);
      expect(find.text('All games have been at home so far'), findsNothing);
    });

    testWidgets('shows all-home message when no away games', (tester) async {
      const data = HomeAwayComparison(
        homeWinPct: 100.0,
        awayWinPct: 0.0,
        homeHittingPct: 0.300,
        awayHittingPct: 0.0,
        homeAcesPerGame: 8.0,
        awayAcesPerGame: 0.0,
        homeDigsPerGame: 30.0,
        awayDigsPerGame: 0.0,
        homeGames: 5,
        awayGames: 0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeAwayChart(data: data),
          ),
        ),
      );

      expect(find.text('All games have been at home so far'), findsOneWidget);
    });
  });
}
