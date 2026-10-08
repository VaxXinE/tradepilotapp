/// Port of the web `progression-level-observation.ts`.
///
/// The first fetched level is only a baseline; a level-up is celebrated when a
/// later in-session fetch shows both more XP and a higher level than anything
/// already acknowledged. Reloads, historical levels and level recalculations
/// after a rules change therefore never replay the celebration.
class ProgressionLevelObservationResult {
  const ProgressionLevelObservationResult({
    required this.highestAcknowledgedLevel,
    required this.celebrateLevel,
  });

  final int highestAcknowledgedLevel;
  final int? celebrateLevel;
}

ProgressionLevelObservationResult observeProgressionLevel({
  required int currentLevel,
  required int? previousLevel,
  required int currentTotalXp,
  required int? previousTotalXp,
  required int highestAcknowledgedLevel,
}) {
  final isNewLevel =
      previousLevel != null &&
      previousTotalXp != null &&
      currentTotalXp > previousTotalXp &&
      currentLevel > previousLevel &&
      currentLevel > highestAcknowledgedLevel;
  return ProgressionLevelObservationResult(
    highestAcknowledgedLevel: highestAcknowledgedLevel > currentLevel
        ? highestAcknowledgedLevel
        : currentLevel,
    celebrateLevel: isNewLevel ? currentLevel : null,
  );
}
