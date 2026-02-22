import 'sport_game_engine.dart';
import 'volleyball/volleyball_game_engine.dart';

/// Registry for sport-specific game engines.
///
/// Provides the appropriate [SportGameEngine] for a given sport string.
class SportEngineRegistry {
  SportEngineRegistry._();

  static final Map<String, SportGameEngine> _engines = {
    'volleyball': VolleyballGameEngine(),
  };

  /// Returns the game engine for the given sport.
  /// Throws [ArgumentError] if the sport is not registered.
  static SportGameEngine getEngine(String sport) {
    final engine = _engines[sport];
    if (engine == null) {
      throw ArgumentError('No game engine registered for sport: $sport');
    }
    return engine;
  }

  /// Returns the game engine if registered, or null.
  static SportGameEngine? tryGetEngine(String sport) => _engines[sport];

  /// Register a game engine for a sport (useful for testing).
  static void register(String sport, SportGameEngine engine) {
    _engines[sport] = engine;
  }
}
