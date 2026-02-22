import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:statline/presentation/providers/dashboard_insights_provider.dart';
import 'package:statline/presentation/screens/dashboard/widgets/efficiency_trend_chart.dart';
import 'package:statline/presentation/screens/dashboard/widgets/points_source_chart.dart';
import 'package:statline/presentation/screens/dashboard/widgets/player_contribution_chart.dart';

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
}
