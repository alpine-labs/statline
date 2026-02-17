import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/team.dart';
import '../../domain/models/player.dart';
import '../../domain/models/season.dart';
import '../../domain/models/roster_entry.dart';

// ── Mock data ────────────────────────────────────────────────────────────────

final _now = DateTime.now();

final _mockPlayers = [
  Player(id: 'p1', firstName: 'Sarah', lastName: 'Johnson', jerseyNumber: '1', positions: ['S'], createdAt: _now, updatedAt: _now),
  Player(id: 'p2', firstName: 'Emily', lastName: 'Davis', jerseyNumber: '5', positions: ['OH'], createdAt: _now, updatedAt: _now),
  Player(id: 'p3', firstName: 'Mia', lastName: 'Martinez', jerseyNumber: '7', positions: ['OH'], createdAt: _now, updatedAt: _now),
  Player(id: 'p4', firstName: 'Ava', lastName: 'Wilson', jerseyNumber: '10', positions: ['MB'], createdAt: _now, updatedAt: _now),
  Player(id: 'p5', firstName: 'Olivia', lastName: 'Brown', jerseyNumber: '12', positions: ['MB'], createdAt: _now, updatedAt: _now),
  Player(id: 'p6', firstName: 'Sophia', lastName: 'Garcia', jerseyNumber: '14', positions: ['OPP'], createdAt: _now, updatedAt: _now),
  Player(id: 'p7', firstName: 'Isabella', lastName: 'Lee', jerseyNumber: '3', positions: ['L'], createdAt: _now, updatedAt: _now),
  Player(id: 'p8', firstName: 'Emma', lastName: 'Taylor', jerseyNumber: '8', positions: ['DS'], createdAt: _now, updatedAt: _now),
  Player(id: 'p9', firstName: 'Charlotte', lastName: 'Anderson', jerseyNumber: '15', positions: ['OH', 'OPP'], createdAt: _now, updatedAt: _now),
];

final _mockTeams = [
  Team(id: 't1', name: 'Thunder VBC 16-1', sport: 'volleyball', level: 'Club', gender: 'Female', ageGroup: '16U', createdAt: _now, updatedAt: _now),
  Team(id: 't2', name: 'Storm VBC 14-2', sport: 'volleyball', level: 'Club', gender: 'Female', ageGroup: '14U', createdAt: _now, updatedAt: _now),
];

final _mockSeasons = [
  Season(id: 's1', teamId: 't1', name: '2024-25 Season', startDate: DateTime(2024, 9, 1), isActive: true, createdAt: _now, updatedAt: _now),
  Season(id: 's2', teamId: 't1', name: '2023-24 Season', startDate: DateTime(2023, 9, 1), endDate: DateTime(2024, 6, 30), isActive: false, createdAt: _now, updatedAt: _now),
];

final _mockRoster = _mockPlayers.asMap().entries.map((entry) {
  final p = entry.value;
  return RosterEntry(
    id: 'r${entry.key + 1}',
    teamId: 't1',
    playerId: p.id,
    seasonId: 's1',
    jerseyNumber: p.jerseyNumber,
    role: entry.key < 6 ? 'starter' : 'reserve',
    isLibero: p.positions.contains('L'),
    joinedDate: _now,
    player: p,
  );
}).toList();

// ── Providers ────────────────────────────────────────────────────────────────

final teamsProvider =
    StateNotifierProvider<TeamsNotifier, AsyncValue<List<Team>>>((ref) {
  return TeamsNotifier();
});

final selectedTeamProvider = StateProvider<Team?>((ref) => null);

final activeSeasonProvider = StateProvider<Season?>((ref) => null);

final seasonsProvider =
    StateNotifierProvider<SeasonsNotifier, AsyncValue<List<Season>>>((ref) {
  return SeasonsNotifier();
});

final rosterProvider =
    StateNotifierProvider<RosterNotifier, AsyncValue<List<RosterEntry>>>((ref) {
  return RosterNotifier();
});

final playersProvider =
    StateNotifierProvider<PlayersNotifier, AsyncValue<List<Player>>>((ref) {
  return PlayersNotifier();
});

// ── Notifiers ────────────────────────────────────────────────────────────────

class TeamsNotifier extends StateNotifier<AsyncValue<List<Team>>> {
  TeamsNotifier() : super(const AsyncValue.loading()) {
    loadTeams();
  }

  void loadTeams() {
    state = AsyncValue.data(List.from(_mockTeams));
  }

  void addTeam(Team team) {
    state.whenData((teams) {
      state = AsyncValue.data([...teams, team]);
    });
  }

  void updateTeam(Team team) {
    state.whenData((teams) {
      state = AsyncValue.data(
        teams.map((t) => t.id == team.id ? team : t).toList(),
      );
    });
  }

  void deleteTeam(String id) {
    state.whenData((teams) {
      state = AsyncValue.data(teams.where((t) => t.id != id).toList());
    });
  }
}

class SeasonsNotifier extends StateNotifier<AsyncValue<List<Season>>> {
  SeasonsNotifier() : super(const AsyncValue.loading()) {
    loadSeasons();
  }

  void loadSeasons() {
    state = AsyncValue.data(List.from(_mockSeasons));
  }

  void addSeason(Season season) {
    state.whenData((seasons) {
      state = AsyncValue.data([...seasons, season]);
    });
  }

  void setActive(String id) {
    state.whenData((seasons) {
      state = AsyncValue.data(
        seasons.map((s) => s.copyWith(isActive: s.id == id)).toList(),
      );
    });
  }

  void deleteSeason(String id) {
    state.whenData((seasons) {
      state = AsyncValue.data(seasons.where((s) => s.id != id).toList());
    });
  }
}

class RosterNotifier extends StateNotifier<AsyncValue<List<RosterEntry>>> {
  RosterNotifier() : super(const AsyncValue.loading()) {
    loadRoster();
  }

  void loadRoster() {
    state = AsyncValue.data(List.from(_mockRoster));
  }

  void addEntry(RosterEntry entry) {
    state.whenData((roster) {
      state = AsyncValue.data([...roster, entry]);
    });
  }

  void removeEntry(String id) {
    state.whenData((roster) {
      state = AsyncValue.data(roster.where((r) => r.id != id).toList());
    });
  }

  void updateEntry(RosterEntry entry) {
    state.whenData((roster) {
      state = AsyncValue.data(
        roster.map((r) => r.id == entry.id ? entry : r).toList(),
      );
    });
  }
}

class PlayersNotifier extends StateNotifier<AsyncValue<List<Player>>> {
  PlayersNotifier() : super(const AsyncValue.loading()) {
    loadPlayers();
  }

  void loadPlayers() {
    state = AsyncValue.data(List.from(_mockPlayers));
  }

  void addPlayer(Player player) {
    state.whenData((players) {
      state = AsyncValue.data([...players, player]);
    });
  }

  void updatePlayer(Player player) {
    state.whenData((players) {
      state = AsyncValue.data(
        players.map((p) => p.id == player.id ? player : p).toList(),
      );
    });
  }

  void deletePlayer(String id) {
    state.whenData((players) {
      state = AsyncValue.data(players.where((p) => p.id != id).toList());
    });
  }
}
