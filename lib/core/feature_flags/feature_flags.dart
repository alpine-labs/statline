/// Tier levels for feature gating.
enum FeatureTier { free, premium, pro }

/// Features that can be gated behind a [FeatureTier].
enum Feature {
  advancedCharts,
  cloudSync,
  multiTeam,
  liveSharing,
  playerComparison,
  exportPdf,
  radarCharts,
}

/// Lightweight feature flag system (singleton).
///
/// In development mode all features are enabled.
/// In production this would check the user's subscription tier.
class FeatureFlags {
  FeatureFlags._internal();

  static final FeatureFlags _instance = FeatureFlags._internal();

  /// Returns the singleton instance.
  factory FeatureFlags() => _instance;

  /// Mapping of each feature to the minimum tier required to unlock it.
  static const Map<Feature, FeatureTier> _featureTiers = {
    Feature.advancedCharts: FeatureTier.premium,
    Feature.cloudSync: FeatureTier.premium,
    Feature.multiTeam: FeatureTier.premium,
    Feature.liveSharing: FeatureTier.pro,
    Feature.playerComparison: FeatureTier.premium,
    Feature.exportPdf: FeatureTier.pro,
    Feature.radarCharts: FeatureTier.pro,
  };

  /// Whether we are running in development mode (all features unlocked).
  bool _devMode = true;

  /// The current user's subscription tier.
  FeatureTier _currentTier = FeatureTier.free;

  /// The active tier. In dev mode this effectively grants all features.
  FeatureTier get tier => _devMode ? FeatureTier.pro : _currentTier;

  /// Returns `true` if [feature] is enabled for the current tier.
  bool isEnabled(Feature feature) {
    if (_devMode) return true;

    final requiredTier = _featureTiers[feature] ?? FeatureTier.free;
    return _currentTier.index >= requiredTier.index;
  }

  /// Sets the user's subscription tier. Disables dev mode.
  void setTier(FeatureTier newTier) {
    _devMode = false;
    _currentTier = newTier;
  }

  /// Enables development mode (all features unlocked).
  void enableDevMode() {
    _devMode = true;
  }

  /// Returns the minimum tier required to unlock [feature].
  static FeatureTier requiredTier(Feature feature) {
    return _featureTiers[feature] ?? FeatureTier.free;
  }
}
