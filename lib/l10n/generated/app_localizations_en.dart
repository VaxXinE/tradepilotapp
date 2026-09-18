// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Trade Pilot';

  @override
  String get tradePilotLogo => 'Trade Pilot logo';

  @override
  String get aiTradingAssistant => 'AI-powered trading analysis';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get dashboardDescription =>
      'Market overview, watchlist, and latest analyses';

  @override
  String get analysis => 'Analysis';

  @override
  String get analysisNotFound => 'Analysis not found';

  @override
  String get analysisCreateFailed => 'A new analysis could not be created.';

  @override
  String get analysisFeedbackTitle => 'Analysis feedback';

  @override
  String get analysisFeedbackQuestion => 'How did this analysis turn out?';

  @override
  String get feedbackCorrect => 'Correct';

  @override
  String get feedbackWrong => 'Wrong';

  @override
  String get feedbackUnknown => 'Not sure yet';

  @override
  String get feedbackNoteOptional => 'Feedback note (optional)';

  @override
  String get send => 'Send';

  @override
  String get feedbackThanks => 'Thanks for your feedback!';

  @override
  String get feedbackSendFailed => 'Feedback could not be sent.';

  @override
  String get noteSaved => 'Note saved.';

  @override
  String get noteDeleted => 'Note deleted.';

  @override
  String get noteSaveFailed => 'Note could not be saved.';

  @override
  String get tradingPlanTitle => 'Suggested Levels';

  @override
  String get tradingPlanDisclaimer =>
      'Use these levels as a risk structure, not as a guarantee that price will follow the scenario.';

  @override
  String get marketEvidence => 'Market evidence';

  @override
  String get marketEvidenceDescription =>
      'Market snapshot and fundamental context.';

  @override
  String get supportingData => 'Fundamental context';

  @override
  String fundamentalEvidenceSummary(int news, int events) {
    return '$news news items · $events economic events';
  }

  @override
  String get notesAndJournal => 'Notes & journal';

  @override
  String get notesAndJournalDescription =>
      'Use the journal for trade decisions and outcomes; use the private note for analysis-specific reminders.';

  @override
  String get learnAnalysisBasics => 'Learn analysis basics';

  @override
  String get learnBiasConfidence => 'Bias, confidence, and validity';

  @override
  String get learnTechnicalFundamental => 'Technical and fundamental evidence';

  @override
  String get technicalDetails => 'Technical indicators';

  @override
  String get technicalDetailsDescription =>
      'Live signal summaries and raw indicators.';

  @override
  String get providedContext => 'Context you provided';

  @override
  String get analysisInvalidationTitle => 'This analysis is cancelled if';

  @override
  String get mainScenario => 'Scenario A — Main';

  @override
  String get alternativeScenario => 'Scenario B — Alternative';

  @override
  String get waitScenario => 'Scenario C — Wait / No Position';

  @override
  String get scenariosTitle => 'Scenarios';

  @override
  String get waitScenarioBody =>
      'If confirmation is weak or an invalidation condition is approaching, waiting for a cleaner setup is the most conservative option.';

  @override
  String get technicalDrivers => 'Technical drivers';

  @override
  String get fundamentalDrivers => 'Fundamental drivers';

  @override
  String get proAnalysisDetailsTitle => 'Why this analysis?';

  @override
  String get proAnalysisDetailsDescription =>
      'Open to see the factors behind the AI conclusion.';

  @override
  String get analysisHelpfulQuestion => 'Was this analysis helpful?';

  @override
  String get helpful => 'Helpful';

  @override
  String get notHelpful => 'Not helpful';

  @override
  String get analysisSafetyDisclaimer =>
      'Trade Pilot is an analysis aid. Always limit risk and avoid opening a position based on a single indicator.';

  @override
  String get journalCreateForTrade => 'Journal this trade';

  @override
  String get journalEntryForTrade => 'My trade journal';

  @override
  String get journalReflectionHint =>
      'Save your decision and trade result for reflection.';

  @override
  String get priceLevelAlerts => 'Price alerts';

  @override
  String get priceLevelAlertsDescription =>
      'Get notified when price reaches an AI Entry, Stop Loss, or Take Profit level.';

  @override
  String priceLevelAlertsOn(int count) {
    return 'Alerts: ON · $count levels monitored';
  }

  @override
  String get priceLevelAlertsOff => 'Alerts: OFF';

  @override
  String get changeTimeframe => 'Change timeframe';

  @override
  String get changeTimeframeDescription =>
      'Same instrument, different timeframe — create a new analysis without leaving this page.';

  @override
  String get analyzeThisTimeframe => 'Analyze this timeframe';

  @override
  String get analysisUsesFreeQuota => 'Source: free analysis quota';

  @override
  String get analysisUsesOneCredit => 'Source: 1 credit (free quota used up)';

  @override
  String get analysisUsageUnavailable =>
      'Source will be confirmed before the request is processed';

  @override
  String get selectedAnalysisMarket => 'Selected market';

  @override
  String get changeSelection => 'Change';

  @override
  String get priceChart => 'Price Chart';

  @override
  String get openFullChart => 'Open full chart in TradingView';

  @override
  String get fundamentalContext => 'Fundamental Context';

  @override
  String get refreshFundamentals => 'Refresh fundamentals';

  @override
  String get fundamentalContextDescription =>
      'News and economic events used by the AI when creating this analysis.';

  @override
  String get liveTechnicalIndicators => 'Live Technical Indicators';

  @override
  String get liveTechnicalDisclaimer =>
      'Latest data; it may differ from the snapshot used for this analysis.';

  @override
  String get lastBar => 'Last bar';

  @override
  String get twentyBars => '20 bars';

  @override
  String get signalSummary => 'Signal summary';

  @override
  String technicalDataPoints(String timeframe, int count) {
    return '$timeframe data · $count candles';
  }

  @override
  String get beginnerBullish => 'Leaning Bullish';

  @override
  String get beginnerBearish => 'Leaning Bearish';

  @override
  String get beginnerWait => 'Wait for confirmation';

  @override
  String biasMeaning(String bias, String direction) {
    return 'A $bias bias means the AI sees a market that is $direction.';
  }

  @override
  String get directionUp => 'leaning upward';

  @override
  String get directionDown => 'leaning downward';

  @override
  String get directionNeutral => 'without a dominant direction';

  @override
  String get beginnerBuyAction =>
      'The analysis structure favors a Buy scenario, but entry should still wait for the area and conditions in the trading plan.';

  @override
  String get beginnerSellAction =>
      'The analysis structure favors a Sell scenario, but entry should still follow the defined area and risk limits.';

  @override
  String get beginnerWaitAction =>
      'The AI does not see a strong enough entry yet. Waiting for confirmation is a valid decision for beginners.';

  @override
  String get analysisSnapshotTitle => 'Context When Analysis Was Created';

  @override
  String get analysisSnapshotDescription =>
      'This is a snapshot of the data used by the AI when creating the analysis.';

  @override
  String get buy => 'Buy';

  @override
  String get sell => 'Sell';

  @override
  String get opportunity => 'Opportunity';

  @override
  String get executionInsight => 'How traders may respond';

  @override
  String get executionInsightDescription =>
      'How traders may approach each scenario without specific Entry, Stop Loss, or Take Profit levels.';

  @override
  String get executionScenarioALabel => 'If Scenario A continues';

  @override
  String get executionScenarioABullish =>
      'Traders typically watch the nearest support area as a zone of buying interest, with a conceptual exit plan if price breaks below that area.';

  @override
  String get executionScenarioABearish =>
      'Traders typically watch the nearest resistance area as a zone of selling interest, with a conceptual exit plan if price breaks above that area.';

  @override
  String get executionScenarioANeutral =>
      'With a neutral bias, many traders prefer to wait until there is a clear break out of the current range.';

  @override
  String get executionScenarioBLabel => 'If Scenario B plays out';

  @override
  String get executionScenarioBBody =>
      'If the main assumption is wrong and the alternative scenario unfolds, traders typically re-evaluate the thesis from scratch — not flip the position immediately.';

  @override
  String get executionScenarioCLabel => 'If waiting is the better choice';

  @override
  String get executionScenarioCBody =>
      'Wait until the invalidation conditions above are no longer at risk, or until a stronger signal confluence emerges.';

  @override
  String get riskHighLabel => 'High Risk';

  @override
  String get riskLowLabel => 'Low Risk';

  @override
  String get riskModerateLabel => 'Medium Risk';

  @override
  String get riskHighProGuidance =>
      'High volatility. Limit exposure and use the invalidation level as the risk boundary.';

  @override
  String get riskHighBeginnerGuidance =>
      'Movement may be aggressive. Avoid large position sizes and do not ignore the Stop Loss.';

  @override
  String get riskLowGuidance =>
      'Conditions appear more stable, but risk remains. Keep a loss limit.';

  @override
  String get riskModerateGuidance =>
      'Opportunity and uncertainty are both present. Wait for a clear setup and use a measured position size.';

  @override
  String get reanalyze => 'Analyze again';

  @override
  String get useForNewAnalysis => 'Use for a new analysis';

  @override
  String get basicFilters => 'Basic filters';

  @override
  String get saveBasicFilter => 'Save basic filter';

  @override
  String get basicFilterExplanation =>
      'Saves search, mode, instruments, timeframes, and date range. Evaluation status is not yet supported by backend presets.';

  @override
  String get history => 'History';

  @override
  String get historyPageTitle => 'Analysis History';

  @override
  String historyTotalAnalyses(int count) {
    return '$count saved analyses';
  }

  @override
  String get profile => 'Profile';

  @override
  String get account => 'Account';

  @override
  String get profileInformation => 'Profile Information';

  @override
  String get changeDisplayName => 'Change your display name';

  @override
  String get preferences => 'Preferences';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get indonesian => 'Bahasa Indonesia';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get appearance => 'Appearance';

  @override
  String get lightMode => 'Light';

  @override
  String get darkMode => 'Dark';

  @override
  String get roleUser => 'User';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleSuperAdmin => 'Super Admin';

  @override
  String get darkThemeEnabled => 'Enabled • comfortable in low light';

  @override
  String get darkThemeDisabled => 'Disabled • using light appearance';

  @override
  String get analysisMode => 'Analysis mode';

  @override
  String get proModeDescription => 'Current: Pro • complete technical details';

  @override
  String get beginnerModeDescription =>
      'Current: Beginner • simpler explanations';

  @override
  String get security => 'Security';

  @override
  String get changePassword => 'Change Password';

  @override
  String get securityQuestion => 'Security Question';

  @override
  String get changeSecurityQuestion => 'Change Security Question';

  @override
  String get newSecurityAnswer => 'New security answer';

  @override
  String get securityQuestionUpdated => 'Security question updated.';

  @override
  String get notAvailable => 'Not available';

  @override
  String get legalAndHelp => 'Legal & Help';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get appFooterDisclaimer =>
      'TradePilot is a decision-support tool, not financial advice or a trading service.';

  @override
  String get sponsoredBy => 'Sponsored by';

  @override
  String get newsDataVia => 'News data via newsmaker.id';

  @override
  String get marketNews => 'Market news';

  @override
  String get pauseTicker => 'Pause ticker';

  @override
  String get resumeTicker => 'Resume ticker';

  @override
  String get hideTicker => 'Hide ticker';

  @override
  String get showTicker => 'Show ticker';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get support => 'Support';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get linkOpenFailed => 'The link could not be opened.';

  @override
  String get insightsAndJournal => 'Insights & Journal';

  @override
  String get tradeJournal => 'Trade Journal';

  @override
  String get journalLoadFailed => 'The journal could not be loaded. Try again.';

  @override
  String get journalSaveFailed => 'The journal entry could not be saved.';

  @override
  String get journalDeleteTitle => 'Delete journal entry?';

  @override
  String get journalDeleteWarning => 'This action cannot be undone.';

  @override
  String get journalDeleteFailed => 'The journal entry could not be deleted.';

  @override
  String get journalSessionChanged => 'The session changed. Reopen this page.';

  @override
  String get add => 'Add';

  @override
  String get noJournalEntries => 'No journal entries yet.';

  @override
  String get journalOutcomeFilter => 'Outcome filter';

  @override
  String get open => 'Open';

  @override
  String get breakeven => 'Breakeven';

  @override
  String get skippedTrade => 'Not taken';

  @override
  String get journalPrivateLimit =>
      'Up to 100 latest entries from the server. This data is private.';

  @override
  String get edit => 'Edit';

  @override
  String get addJournal => 'Add journal entry';

  @override
  String get editJournal => 'Edit journal entry';

  @override
  String get instrumentRequired => 'Instrument is required.';

  @override
  String get side => 'Side';

  @override
  String get buyJournalSide => 'Buy (trade record)';

  @override
  String get sellJournalSide => 'Sell (trade record)';

  @override
  String get retrospectiveStatus => 'Retrospective status';

  @override
  String get tradeTime => 'Trade time';

  @override
  String get moodOptional => 'State of mind (optional)';

  @override
  String get reflectionOptional => 'Reflection (optional)';

  @override
  String get enterValidNumber => 'Enter a valid number.';

  @override
  String get entries => 'Entries';

  @override
  String get wins => 'Wins';

  @override
  String get losses => 'Losses';

  @override
  String get averageProfitLoss => 'Avg P/L';

  @override
  String get quantity => 'Quantity';

  @override
  String get tradeJournalDescription => 'Personal trade notes and reflections';

  @override
  String get analytics => 'Analytics';

  @override
  String get publicAiPerformance => 'Public AI Performance';

  @override
  String get performanceMethodology => 'Methodology';

  @override
  String get performanceDescription =>
      'An anonymized track record of all Trade Pilot AI analyses. These are not personal account statistics.';

  @override
  String performanceDays(int count) {
    return '$count days';
  }

  @override
  String performanceInsufficient(int need, int have) {
    return 'Not enough data for a responsible display. $need results required; currently $have.';
  }

  @override
  String performanceSampleProgress(int have, int need) {
    return '$have of $need samples collected';
  }

  @override
  String get otherInstruments => 'Other Instruments';

  @override
  String get performanceByInstrument => 'By instrument';

  @override
  String get performanceBySession => 'By market session';

  @override
  String get performanceByCondition => 'By market condition';

  @override
  String get performanceByVolatility => 'By volatility';

  @override
  String get performanceNewsActivity => 'News activity';

  @override
  String get performanceMethodologyTitle => 'Performance methodology';

  @override
  String get performanceMethodWhatTitle => 'What is measured';

  @override
  String get performanceMethodWhatBody =>
      'Only analyses with finalized outcomes. User data is anonymized and aggregated.';

  @override
  String get performanceMethodRatesTitle => 'Win rate and hit rate';

  @override
  String get performanceMethodRatesBody =>
      'Win rate compares wins with losses for triggered trades. Hit rate also includes expired analyses.';

  @override
  String get performanceMethodSampleTitle => 'Sample threshold';

  @override
  String get performanceMethodSampleBody =>
      'Small sample segments are hidden to avoid misleading results or exposing small-group activity.';

  @override
  String get performanceMethodExcludedTitle => 'What is excluded';

  @override
  String get performanceMethodExcludedBody =>
      'Figures exclude position size, spread, slippage, fees, taxes, and user execution decisions.';

  @override
  String get performancePastDisclaimer =>
      'Past performance does not guarantee future results.';

  @override
  String get performanceDeclining => 'Recent performance is declining';

  @override
  String get performanceWatch => 'Recent performance needs attention';

  @override
  String get performanceStable => 'Recent performance is stable';

  @override
  String performanceRecentBaseline(int days, String recent, String baseline) {
    return 'Latest $days days: $recent · baseline: $baseline.';
  }

  @override
  String performanceSummary(int days) {
    return '$days-day summary';
  }

  @override
  String get winRate => 'Win rate';

  @override
  String get hitRate => 'Hit rate';

  @override
  String performanceTotals(int wins, int losses, int expired, int total) {
    return '$wins wins · $losses losses · $expired expired · $total samples';
  }

  @override
  String sinceDate(String date) {
    return 'Since $date';
  }

  @override
  String performanceSegmentInsufficient(int have, int need) {
    return 'Not enough data: $have/$need samples.';
  }

  @override
  String performanceBucketTotals(int wins, int losses, int expired) {
    return '$wins wins · $losses losses · $expired expired';
  }

  @override
  String get performanceLoadFailed => 'Performance data could not be loaded.';

  @override
  String get offMainSession => 'Outside main sessions';

  @override
  String get uptrend => 'Uptrend';

  @override
  String get downtrend => 'Downtrend';

  @override
  String get activeNewsWeek => 'Active news week';

  @override
  String get quietWeek => 'Quiet week';

  @override
  String get rangingMarket => 'Ranging';

  @override
  String get volatileMarket => 'Volatile';

  @override
  String get choppyMarket => 'Choppy';

  @override
  String get analyticsDescription => 'Activity patterns and evaluation results';

  @override
  String get dailySummary => 'Daily Summary';

  @override
  String get traderMirror => 'Trader Mirror';

  @override
  String get traderMirrorDescription => 'Data-driven habit reflection';

  @override
  String get traderMindset => 'Trader\'s Mindset';

  @override
  String get traderMindsetDescription =>
      'Short lessons for disciplined decisions';

  @override
  String get guide => 'Guide Center';

  @override
  String get guideNavLabel => 'Guide';

  @override
  String get back => 'Back';

  @override
  String get guideDescription =>
      'Guides to features, analysis, risk, and trading discipline';

  @override
  String get mentalChecklistPreference => 'Pre-analysis mental checklist';

  @override
  String get mentalChecklistPreferenceHint =>
      'Show four discipline reminders before creating an analysis';

  @override
  String get mentalChecklistTitle => 'Pre-trade mental check';

  @override
  String get mentalChecklistRisk =>
      'I know exactly how much I will lose if this trade fails';

  @override
  String get mentalChecklistPlan =>
      'I have a written entry, stop-loss, and target';

  @override
  String get mentalChecklistChase =>
      'I am not chasing a move that already happened (no FOMO)';

  @override
  String get mentalChecklistCalm =>
      'I am not trading to recover a previous loss';

  @override
  String get mentalChecklistHint =>
      'Tick all four before you click Analyze. It\'s a nudge, not a block — but unchecked items are usually how losses start.';

  @override
  String get safeWait => 'Wait Safely';

  @override
  String get safeWaitHint =>
      'Acknowledge the risk and wait on the sidelines. Good discipline.';

  @override
  String get safeWaitRecorded => 'Your decision to wait was recorded.';

  @override
  String get safeWaitFailed =>
      'Your decision to wait could not be saved. Try again.';

  @override
  String get coolingOffBreathingTitle => 'Take a breath first';

  @override
  String coolingOffBreathingBody(String loss) {
    return 'You just took a $loss% loss. Follow this breathing pattern before choosing. The setup will still be there.';
  }

  @override
  String get coolingOffBreathingBodyGeneric =>
      'Follow this breathing pattern before choosing. The setup will still be there.';

  @override
  String get coolingOffBreathingInhale => 'Breathe in';

  @override
  String get coolingOffBreathingHold => 'Hold';

  @override
  String get coolingOffBreathingExhale => 'Breathe out';

  @override
  String get coolingOffBreathingWait => 'Wait it out';

  @override
  String get coolingOffBreathingContinue => 'Continue anyway';

  @override
  String xpAwarded(int xp, String activity) {
    return '+$xp XP for $activity';
  }

  @override
  String get checklistActivity => 'completing the pre-analysis checklist';

  @override
  String get guideComplete => 'Mark complete';

  @override
  String get guideReading =>
      'Read the material until the completion button becomes active.';

  @override
  String get guideProgressFailed => 'Guide progress could not be saved.';

  @override
  String get openFullExplanation => 'Open full explanation';

  @override
  String get learnAdaptivePosition => 'Learn the Position Size Recommendation';

  @override
  String get sponsoredBySolidPrime => 'Sponsored by SOLID PRIME';

  @override
  String get sponsorDisclosure =>
      'Sponsor links do not influence analysis independence and are not a recommendation to open an account or trade.';

  @override
  String get openSponsorWebsite => 'Open sponsor website';

  @override
  String get liveAnalysisTitle => 'Live Analysis';

  @override
  String get liveAnalysisSponsorSubtitle =>
      'Every weekday at 09:00 WIB on TikTok @solid.prime';

  @override
  String get progressionTitle => 'Progression';

  @override
  String get progressionSubtitle =>
      'Your private record of preparation, reflection, and discipline.';

  @override
  String get progressionLoading => 'Loading discipline data...';

  @override
  String get progressionLoadFailed => 'Could not load progression data.';

  @override
  String get progressionOverview => 'Overview';

  @override
  String get progressionAchievements => 'Achievements';

  @override
  String get progressionHistory => 'XP History';

  @override
  String get progressionCurrentStreak => 'Current streak';

  @override
  String get progressionLongestStreak => 'Longest streak';

  @override
  String progressionLevel(int level) {
    return 'Level $level';
  }

  @override
  String progressionMastery(int level) {
    return 'Mastery $level';
  }

  @override
  String progressionRank(String rank) {
    return 'Rank: $rank';
  }

  @override
  String progressionXpToNext(int xp) {
    return '$xp XP to the next level';
  }

  @override
  String progressionUnlocked(String date) {
    return 'Unlocked $date';
  }

  @override
  String get progressionLocked => 'Locked';

  @override
  String get progressionNoAchievements =>
      'Complete activities to unlock achievements.';

  @override
  String get progressionNoHistory =>
      'No activity yet. Start building your discipline routine.';

  @override
  String get progressionPrivate =>
      'Progress is private. XP rewards process—not profit, win rate, or account size.';

  @override
  String progressionActivity(int xp, String reason) {
    return '+$xp XP for $reason';
  }

  @override
  String get mindsetDisclaimer =>
      'Educational material only. It is not financial or psychological advice.';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirmation =>
      'Are you sure you want to sign out of this account?';

  @override
  String get cancel => 'Cancel';

  @override
  String get permanentAction => 'This action is permanent';

  @override
  String get deleteAccountWarning =>
      'Your profile, analyses, journal, watchlist, and account data will be deleted and cannot be recovered.';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get deleteAccountAcknowledgement =>
      'I understand that my account and data will be permanently deleted.';

  @override
  String get deleteAccountPermanently => 'Permanently Delete Account';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get displayName => 'Display Name';

  @override
  String get nameMinimumCharacters => 'Name must be at least 2 characters';

  @override
  String get nameTooLong => 'Name is too long';

  @override
  String get email => 'Email';

  @override
  String get emailChangeUnsupported => 'Changing email is not supported yet.';

  @override
  String get save => 'Save';

  @override
  String get profileUpdated => 'Profile updated successfully.';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get avatarRequirements =>
      'Use a JPG, PNG, WebP, or GIF image up to 5 MB.';

  @override
  String get avatarUploadFailed => 'Profile photo could not be uploaded.';

  @override
  String get passwordChanged => 'Password changed successfully.';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get currentPasswordRequired => 'Current password is required';

  @override
  String get passwordMinimumCharacters =>
      'Password must be at least 8 characters';

  @override
  String get passwordConfirmationMismatch =>
      'Password confirmation does not match';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get loginDescription => 'Sign in to continue your analysis';

  @override
  String get usernameEmail => 'Username / Email';

  @override
  String get usernameEmailHint => 'Your username or email';

  @override
  String get emailHint => 'your@email.com';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get rememberMe => 'Remember Me';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign In to Dashboard';

  @override
  String get or => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get googleDeleteReauthDescription =>
      'To protect your account, verify your identity with Google before deletion.';

  @override
  String get federatedDeleteReauthDescription =>
      'To protect your account, verify with the sign-in method linked to this account before deletion.';

  @override
  String get verifyGoogleAndDelete => 'Verify with Google and delete';

  @override
  String get verifyAppleAndDelete => 'Verify with Apple and delete';

  @override
  String get errGoogleTokenInvalid =>
      'Google could not verify this sign-in. Choose the same account and try again.';

  @override
  String get errGoogleAccountConflict =>
      'This email is linked to another sign-in method. Sign in with that method first.';

  @override
  String get errGoogleUnavailable =>
      'Google Sign-In is temporarily unavailable. Please try again later.';

  @override
  String get errGoogleConfiguration =>
      'Google Sign-In is not configured for this app build. Please contact support.';

  @override
  String get errGoogleSignInFailed =>
      'Could not sign in with Google. Please try again.';

  @override
  String get errAppleTokenInvalid =>
      'Apple could not verify this sign-in. Please try again.';

  @override
  String get errAppleAccountConflict =>
      'This email is linked to another sign-in method. Sign in with that method first.';

  @override
  String get errAppleUnavailable =>
      'Sign in with Apple is not available yet. Please try again later.';

  @override
  String get errAppleSignInFailed =>
      'Could not sign in with Apple. Please try again.';

  @override
  String get verifying => 'Verifying...';

  @override
  String get signInWithBiometrics => 'Sign in with fingerprint / face';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get register => 'Register free';

  @override
  String get biometricReason =>
      'Verify your identity to sign in to Trade Pilot';

  @override
  String get biometricUnavailable =>
      'Biometrics are unavailable. Use your email and password.';

  @override
  String get createAccount => 'Create Account';

  @override
  String get startTradingJourney => 'Start your trading journey';

  @override
  String get registerDescription => 'Join for free and start your analysis';

  @override
  String get registerValueInsight => 'Market insight, not blind signals';

  @override
  String get registerValueFast => 'First analysis in under 30 seconds';

  @override
  String get registerValueRisk => 'Know exactly when you\'re wrong';

  @override
  String get fullName => 'Full Name';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get minimumEightCharacters => 'At least 8 characters';

  @override
  String get experienceLevel => 'Experience Level';

  @override
  String get beginner => 'Beginner';

  @override
  String get pro => 'Pro';

  @override
  String get beginnerModeHelp => 'Simpler, step-by-step explanations.';

  @override
  String get proModeHelp => 'More concise and technical market information.';

  @override
  String get firstPetQuestion => 'What was the name of your first pet?';

  @override
  String get answer => 'Answer';

  @override
  String get answerRequired => 'Answer is required';

  @override
  String get registerConsent => 'By registering, you agree to:';

  @override
  String get andLabel => 'and';

  @override
  String get passwordResetSuccess =>
      'Password changed successfully. Please sign in.';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String stepOfThree(int step) {
    return 'Step $step of 3';
  }

  @override
  String get findYourAccount => 'Find your account';

  @override
  String get findAccountDescription =>
      'Enter your account email to start password recovery.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get verifyIdentity => 'Verify your identity';

  @override
  String get securityAnswerDescription =>
      'Answer the security question you created during registration.';

  @override
  String get verify => 'Verify';

  @override
  String get changeEmail => 'Change email';

  @override
  String get createNewPassword => 'Create a new password';

  @override
  String get newPasswordDescription =>
      'Use at least 8 characters and do not reuse your old password.';

  @override
  String get savePassword => 'Save Password';

  @override
  String get myPriceAlerts => 'My Price Alerts';

  @override
  String get priceAlertsSubtitle =>
      'Price alerts you\'ve set across instruments';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get realtimeActive => 'Realtime connected';

  @override
  String get realtimeConnecting => 'Connecting realtime…';

  @override
  String get notificationInbox => 'Inbox';

  @override
  String get notificationSettingsTab => 'Settings';

  @override
  String notificationUnreadCount(int count) {
    return '$count unread';
  }

  @override
  String get notificationAnalysisUnavailable =>
      'This analysis is unavailable or you do not have access.';

  @override
  String get mobilePush => 'Mobile Push';

  @override
  String get pushUpdatingDevice => 'Updating device settings…';

  @override
  String get pushDeviceRegistered => 'Device registered for push.';

  @override
  String pushDeviceRegisteredLastReceived(String date) {
    return 'Device registered for push. Last received $date.';
  }

  @override
  String get pushPermissionDenied =>
      'Permission denied. Enable it again in device settings.';

  @override
  String get pushReceiveWhenInactive =>
      'Receive push notifications while the app is inactive.';

  @override
  String get sendTestPush => 'Send test notification';

  @override
  String pushTestConfirmed(int count) {
    return 'Test notification received on this device. FCM accepted $count message(s) from the server.';
  }

  @override
  String get notificationPreferences => 'Notification preferences';

  @override
  String get notificationPreferencesDescription =>
      'Choose which notifications you want to receive.';

  @override
  String get notificationPreferencesLoadFailed =>
      'Notification preferences could not be loaded.';

  @override
  String get notificationExpiryTitle => 'Analysis expiry';

  @override
  String get notificationExpiryDescription =>
      'Reminder when an analysis window is about to end.';

  @override
  String get notificationBroadcastTitle => 'Announcements';

  @override
  String get notificationBroadcastDescription =>
      'Important information and broadcasts from Trade Pilot.';

  @override
  String get notificationDailyTitle => 'Daily summary';

  @override
  String get notificationDailyDescription =>
      'Daily activity and market summary.';

  @override
  String get notificationNewsTitle => 'Market news';

  @override
  String get notificationNewsDescription =>
      'Important news relevant to the market.';

  @override
  String get notificationCalendarTitle => 'Economic calendar';

  @override
  String get notificationCalendarDescription =>
      'Reminders for high-impact economic events.';

  @override
  String get notificationPriceTitle => 'Price movement';

  @override
  String get notificationPriceDescription =>
      'Significant price changes and anomalies.';

  @override
  String get notificationSignalTitle => 'Signal changes';

  @override
  String get notificationSignalDescription =>
      'When the AI bias changes meaningfully.';

  @override
  String get notificationWeeklyTitle => 'Weekly recap';

  @override
  String get notificationWeeklyDescription =>
      'Weekly trading activity summary.';

  @override
  String get notificationGuardrails => 'Decision guardrails';

  @override
  String get notificationRevengeTitle => 'Revenge trading warning';

  @override
  String get notificationRevengeDescription =>
      'A gentle warning after a recent loss.';

  @override
  String get notificationOvertradingTitle => 'Overtrading warning';

  @override
  String get notificationOvertradingDescription =>
      'A warning when analyses are created too close together.';

  @override
  String get notificationHighRiskTitle => 'High-risk warning';

  @override
  String get notificationHighRiskDescription =>
      'A warning for high-impact events within 30 minutes.';

  @override
  String get notificationCoolingOffTitle => '30-minute cooling-off';

  @override
  String get notificationCoolingOffDescription =>
      'An optional pause after a significant loss.';

  @override
  String get notificationSessionReminders => 'Market session reminders';

  @override
  String get quietHours => 'Quiet hours';

  @override
  String get quietHoursDescription =>
      'Hold non-urgent notifications during rest hours.';

  @override
  String get quietHoursStart => 'Start';

  @override
  String get quietHoursEnd => 'End';

  @override
  String get notificationTimezone => 'Time zone';

  @override
  String get quietHoursSecurityNotice =>
      'Security notifications may still be delivered during quiet hours.';

  @override
  String notificationAutoPaused(String category) {
    return 'Some ‘$category’ notifications were paused because they have not been opened recently.';
  }

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get trader => 'Trader';

  @override
  String get latestAnalyses => 'Latest Analyses';

  @override
  String get viewAll => 'View all';

  @override
  String get decisionDisclaimer =>
      'Trade Pilot helps you understand market conditions, but all decisions and risk management remain your responsibility.';

  @override
  String get wantMarketAnalysis => 'Want a market analysis?';

  @override
  String get getStarted => 'Get started with Trade Pilot';

  @override
  String get onboardingSteps =>
      'Choose a market, review the live context, then create your first analysis. Results are decision support—not trading orders.';

  @override
  String get chooseMarketAndStartAnalysis =>
      'Choose a market and start analysis';

  @override
  String get gotIt => 'Got it';

  @override
  String get liveMarkets => 'Live Markets';

  @override
  String get analysisPreparation =>
      'Review prices, market sessions, charts, indicators, and the economic calendar before requesting AI analysis.';

  @override
  String get startAnalysis => 'Start Analysis';

  @override
  String get marketWatchlist => 'Market Watchlist';

  @override
  String get manageWatchlist => 'Manage watchlist';

  @override
  String get watchlistDescription =>
      'Track your favorite markets without opening another page.';

  @override
  String pricesUpdatedAt(String time) {
    return 'Prices updated at $time';
  }

  @override
  String get livePriceUnavailable => 'Live price is unavailable';

  @override
  String get createPriceAlert => 'Create price alert';

  @override
  String get openAnalysis => 'Open analysis';

  @override
  String get watchlistEmpty => 'Your watchlist is empty';

  @override
  String get addSymbol => 'Add symbol';

  @override
  String get totalAnalyses => 'Total Analyses';

  @override
  String get beginnerMode => 'Beginner Mode';

  @override
  String get proMode => 'Pro Mode';

  @override
  String get aiConfidence => 'AI Confidence';

  @override
  String get unlimitedAnalysisQuota => 'Unlimited analysis quota';

  @override
  String get analysisQuota => 'Analysis Quota';

  @override
  String get analysisQuotaLoadFailed =>
      'The analysis quota could not be loaded.';

  @override
  String get perHour => 'Per hour';

  @override
  String get perDay => 'Per day';

  @override
  String get noAnalyses => 'No analyses yet';

  @override
  String get createFirstAnalysis => 'Create your first analysis';

  @override
  String priceAlertCreated(String instrument) {
    return 'Price alert for $instrument was created.';
  }

  @override
  String instrumentAddedToWatchlist(String instrument) {
    return '$instrument was added to your watchlist.';
  }

  @override
  String instrumentAlreadyInWatchlist(String instrument) {
    return '$instrument is already in your watchlist.';
  }

  @override
  String get removeFromWatchlist => 'Remove from watchlist?';

  @override
  String removeInstrumentConfirmation(String instrument) {
    return 'Remove $instrument from your watchlist?';
  }

  @override
  String get remove => 'Remove';

  @override
  String instrumentRemovedFromWatchlist(String instrument) {
    return '$instrument was removed from your watchlist.';
  }

  @override
  String removeInstrumentFailed(String instrument) {
    return 'Failed to remove $instrument.';
  }

  @override
  String get selectMarketsForDashboard =>
      'Select the markets you want to track on the Dashboard.';

  @override
  String get close => 'Close';

  @override
  String get tryAgain => 'Try again';

  @override
  String get watchlistUpdateFailed => 'Failed to update the watchlist.';

  @override
  String watchlistUpdated(String instrument) {
    return 'Watchlist updated for $instrument.';
  }

  @override
  String get alertNeedsLivePrice =>
      'A price alert requires a live price. A live price is not available for this instrument.';

  @override
  String get aiAnalysis => 'AI Analysis';

  @override
  String get analyzeTitle => 'New Analysis';

  @override
  String get otherInstrument => 'Other instrument…';

  @override
  String get quotaHour => 'Hourly remaining';

  @override
  String get quotaDay => 'Daily remaining';

  @override
  String get quotaHourShort => '/hr';

  @override
  String get quotaDayShort => '/day';

  @override
  String get selectInstrument => 'Select Instrument';

  @override
  String get instrumentCategoryCommoditiesIndices => 'Commodities & Indices';

  @override
  String get instrumentCategoryForex => 'Forex';

  @override
  String get instrumentCategoryCrypto => 'Crypto';

  @override
  String get selectMarketDescription =>
      'Select the market you want to understand.';

  @override
  String get tapToChangeInstrument => 'Tap to change the instrument';

  @override
  String get timeframe => 'Timeframe';

  @override
  String get timeframeDescription =>
      'The timeframe determines the perspective of the market analysis.';

  @override
  String get priceAlertUnavailable => 'Price Alert Unavailable';

  @override
  String get instrumentHasNoLiveFeed =>
      'This instrument does not have a live price feed that can be used for alerts.';

  @override
  String get additionalNotes => 'Additional Notes';

  @override
  String get decisionGuardrails => 'Decision guardrails';

  @override
  String get guardrailHint =>
      'This is a soft warning. Pause and reassess before continuing.';

  @override
  String guardrailRevenge(String minutes) {
    return 'A loss occurred $minutes minutes ago. Avoid revenge trading.';
  }

  @override
  String guardrailOvertrading(String count, String limit) {
    return 'You made $count analyses; the current limit is $limit.';
  }

  @override
  String guardrailHighRisk(String event, String minutes) {
    return '$event is expected in about $minutes minutes.';
  }

  @override
  String guardrailUnusualHour(String hour) {
    return 'This trading hour ($hour:00 UTC) is unusual for your history.';
  }

  @override
  String guardrailCoolingOff(String minutes) {
    return 'Cooling-off period: about $minutes minutes remaining.';
  }

  @override
  String get guardrailGeneric => 'A risk pattern was detected.';

  @override
  String get additionalNotesDescription =>
      'Optional. Describe the position or condition you want the AI to consider.';

  @override
  String get additionalNotesHint =>
      'Example: I do not have a position yet and want to wait for a safer entry...';

  @override
  String get analyzingMarket => 'Analyzing the market...';

  @override
  String get getAiAnalysis => 'Get AI Analysis';

  @override
  String analysesRemainingToday(int count) {
    return '$count analyses remaining today';
  }

  @override
  String get aiAnalysisDisclaimer =>
      'AI analysis is a decision-support tool, not a guarantee of profit. Always consider the risks before opening a position.';

  @override
  String get understandMarketBeforeEntry =>
      'Understand the market before entering';

  @override
  String get beginnerAnalysisIntro =>
      'Trade Pilot helps explain price, momentum, market sessions, and important events in simpler language.';

  @override
  String get livePrice => 'Live price';

  @override
  String get referencePrice => 'Reference price';

  @override
  String get addToWatchlist => 'Add to watchlist';

  @override
  String get partialChartUnavailable => 'Some chart data is unavailable.';

  @override
  String get cryptoMarketAlwaysOpen => 'Crypto Market 24/7';

  @override
  String get cryptoNoForexSessions => 'Crypto does not follow forex sessions.';

  @override
  String get marketClosedWeekend => 'Market closed for the weekend';

  @override
  String get noMainSessionActive => 'No major market session is active';

  @override
  String get sessionOverlap => 'Session overlap • liquidity is usually higher';

  @override
  String get marketSessionActive => 'Market session active';

  @override
  String sessionOpensIn(String session, String duration) {
    return '$session opens in $duration';
  }

  @override
  String sessionClosesIn(String session, String duration) {
    return '$session closes in $duration';
  }

  @override
  String get highImpactEventSoon => 'A high-impact event is coming soon';

  @override
  String get highImpactRisk => 'Prices may move quickly and spreads may widen.';

  @override
  String eventStartsInMinutes(int minutes) {
    return ' • in about $minutes min';
  }

  @override
  String get searchInstrumentOrNote => 'Search instruments or notes';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get filter => 'Filter';

  @override
  String get noMatchingAnalyses => 'No matching analyses';

  @override
  String get changeSearchOrFilter => 'Try changing the search term or filters.';

  @override
  String get analysesAppearHere => 'Your AI analyses will appear here.';

  @override
  String get resetFilter => 'Reset filters';

  @override
  String get modeBeginner => 'Mode: Beginner';

  @override
  String get modePro => 'Mode: Pro';

  @override
  String outcomeLabel(String outcome) {
    return 'Outcome: $outcome';
  }

  @override
  String confidenceAtLeast(int confidence) {
    return 'Confidence ≥ $confidence%';
  }

  @override
  String resultCount(int count) {
    return '$count results';
  }

  @override
  String get reset => 'Reset';

  @override
  String get positive => 'Positive';

  @override
  String get negative => 'Negative';

  @override
  String get pending => 'Pending';

  @override
  String get valid => 'Valid';

  @override
  String get expired => 'Expired';

  @override
  String analysisWindowActiveUntil(String date) {
    return 'Analysis window active until $date';
  }

  @override
  String analysisWindowExpiredAt(String date) {
    return 'Analysis window expired at $date';
  }

  @override
  String analysisCreatedAt(String date) {
    return 'Created $date';
  }

  @override
  String get historySummary => 'History summary';

  @override
  String get historyListTab => 'History';

  @override
  String get timeframePerformance => 'By timeframe';

  @override
  String get allTime => 'All time';

  @override
  String daysShort(int count) {
    return '${count}d';
  }

  @override
  String get partialSummary => 'Partial summary';

  @override
  String get visible => 'Visible';

  @override
  String get evaluated => 'Evaluated';

  @override
  String get averageConfidence => 'Average confidence';

  @override
  String positiveEvaluatedSummary(int rate) {
    return 'Targets were reached in $rate% of evaluated analyses.';
  }

  @override
  String get hasJournalNote => 'Has a journal note';

  @override
  String confidenceValue(String value) {
    return 'Confidence $value';
  }

  @override
  String riskValue(String value) {
    return 'Risk $value';
  }

  @override
  String get strongBullish => 'Strong bullish';

  @override
  String get strongBearish => 'Strong bearish';

  @override
  String get biasUnavailable => 'Bias unavailable';

  @override
  String get trendingUp => 'Uptrend';

  @override
  String get trendingDown => 'Downtrend';

  @override
  String get movingSideways => 'Moving sideways';

  @override
  String get trendingMarket => 'Trending';

  @override
  String get evaluationPending => 'Evaluation pending';

  @override
  String get referenceTargetOneHit => 'Reference target 1 reached';

  @override
  String get referenceTargetTwoHit => 'Reference target 2 reached';

  @override
  String get riskLimitHit => 'Risk limit reached';

  @override
  String get analysisPeriodEnded => 'Analysis period ended';

  @override
  String get analysisCannotBeEvaluated => 'Analysis cannot be evaluated';

  @override
  String get notYetEvaluated => 'Not yet evaluated';

  @override
  String get all => 'All';

  @override
  String get historyFilters => 'History Filters';

  @override
  String get mode => 'Mode';

  @override
  String get evaluationStatus => 'Evaluation status';

  @override
  String get minimumConfidence => 'Minimum confidence';

  @override
  String get sortOrder => 'Sort order';

  @override
  String get instrument => 'Instrument';

  @override
  String get dateRange => 'Date Range';

  @override
  String get selectDate => 'Select date';

  @override
  String get clearDateRange => 'Clear date range';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get positiveOutcome => 'Positive outcome';

  @override
  String get negativeOutcome => 'Negative outcome';

  @override
  String get newest => 'Newest';

  @override
  String get oldest => 'Oldest';

  @override
  String get highestConfidence => 'Highest confidence';

  @override
  String get marketSession => 'Market Session';

  @override
  String get cryptoMarket247 => 'Crypto Market 24/7';

  @override
  String get marketClosed => 'Market closed';

  @override
  String get activeUppercase => 'ACTIVE';

  @override
  String get closedUppercase => 'CLOSED';

  @override
  String get liquidity => 'Liquidity';

  @override
  String get next => 'Next';

  @override
  String get variesUppercase => 'VARIES';

  @override
  String get highUppercase => 'HIGH';

  @override
  String get mediumUppercase => 'MEDIUM';

  @override
  String get lowUppercase => 'LOW';

  @override
  String get sessionOverlapActivity =>
      'Session overlaps usually have higher market activity.';

  @override
  String sessionTransition(String session, String action, String duration) {
    return '$session $action in $duration';
  }

  @override
  String get opens => 'opens';

  @override
  String get closes => 'closes';

  @override
  String get technicalSummary => 'Technical Summary';

  @override
  String get indicatorEducationDisclaimer =>
      'We simplify indicators to make them easier to understand. This is not a trading signal or recommendation.';

  @override
  String get technicalSummaryLoadFailed =>
      'The technical summary could not be loaded.';

  @override
  String get technicalSummaryUnavailable =>
      'A technical summary is not available for this market yet.';

  @override
  String get trend => 'Trend';

  @override
  String get momentum => 'Momentum';

  @override
  String get risk => 'Risk';

  @override
  String get whatDoesItMean => 'What does it mean?';

  @override
  String get marketContext => 'Market Context';

  @override
  String get marketEducationDisclaimer =>
      'An educational summary of current market conditions. This is not a trading signal or recommendation.';

  @override
  String get marketContextLoadFailed =>
      'The market context could not be loaded.';

  @override
  String get insufficientMarketData =>
      'There is not enough data to assess market conditions.';

  @override
  String get why => 'Why?';

  @override
  String get riskLevel => 'Risk level';

  @override
  String get economicCalendar => 'Economic Calendar';

  @override
  String get economicEventRiskDisclaimer =>
      'Economic events may cause prices to move faster. This is risk information, not a trading signal.';

  @override
  String get economicCalendarLoadFailed =>
      'The economic calendar could not be loaded.';

  @override
  String get noUpcomingEconomicEvents =>
      'There are no relevant upcoming economic events.';

  @override
  String get marketOverview => 'Market Overview';

  @override
  String get priceDataUnavailable => 'Price data is unavailable.';

  @override
  String get latestDataUnavailable => 'The latest data is unavailable.';

  @override
  String get waitingForUpdate => 'Waiting for an update...';

  @override
  String get updatedJustNow => 'Updated just now';

  @override
  String updatedSecondsAgo(int seconds) {
    return 'Updated $seconds seconds ago';
  }

  @override
  String updatedAt(String time) {
    return 'Updated at $time';
  }

  @override
  String get chartDataUnavailable => 'Chart data is unavailable.';

  @override
  String get high => 'High';

  @override
  String get medium => 'Medium';

  @override
  String get low => 'Low';

  @override
  String get bullishBias => 'Bullish bias';

  @override
  String get bearishBias => 'Bearish bias';

  @override
  String get neutral => 'Neutral';

  @override
  String get historicalLevelsDisclaimer =>
      'Chart levels are historical references, not transaction recommendations.';

  @override
  String get candlestickHelp =>
      'Candlesticks: green = price rose, red = price fell.';

  @override
  String movementRisk(String risk) {
    return 'Movement risk: $risk. Support and resistance are reference levels from the visible data.';
  }

  @override
  String currentPrice(String price) {
    return 'Current $price';
  }

  @override
  String get addInstrument => 'Add instrument';

  @override
  String get searchInstrument => 'Search instruments';

  @override
  String get delete => 'Delete';

  @override
  String addedOn(String date) {
    return 'Added: $date';
  }

  @override
  String get noPreviousAnalysis => 'No previous analysis';

  @override
  String lastAnalysis(String date) {
    return 'Last analysis: $date';
  }

  @override
  String get invalidTargetPrice => 'Enter a valid target price.';

  @override
  String get noteMaximumCharacters => 'Notes can contain up to 200 characters.';

  @override
  String get priceAlertCreateFailed => 'Failed to create the price alert.';

  @override
  String priceAlertTitle(String instrument) {
    return '$instrument Price Alert';
  }

  @override
  String currentMarketPrice(String price) {
    return 'Current price $price';
  }

  @override
  String get notifyWhenPrice => 'Notify me when the price...';

  @override
  String get risesAbove => 'Rises above';

  @override
  String get fallsBelow => 'Falls below';

  @override
  String get targetPrice => 'Target Price';

  @override
  String get optionalNote => 'Note (optional)';

  @override
  String get priceAlertNoteHint => 'Example: review current market conditions';

  @override
  String get saving => 'Saving...';

  @override
  String get createPriceAlertButton => 'Create Price Alert';

  @override
  String get myPriceAlertsTitle => 'My Price Alerts';

  @override
  String get priceAlertDisclaimer =>
      'Price alerts notify you when a condition is reached. They are not trading signals or recommendations.';

  @override
  String get priceAlertsLoadFailed => 'Price alerts could not be loaded.';

  @override
  String get noPriceAlerts =>
      'No price alerts yet. Create one to be notified when a price reaches a specific level.';

  @override
  String get triggered => 'Triggered';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get monitored => 'Monitored';

  @override
  String get active => 'Active';

  @override
  String get deleteAlert => 'Delete alert';

  @override
  String get actual => 'Actual';

  @override
  String get previous => 'Previous';

  @override
  String get goldEventExplanation =>
      'Why it matters: USD data often affects Gold and may increase XAU/USD volatility.';

  @override
  String currencyEventExplanation(String currency, String instrument) {
    return 'Why it matters: $currency events directly relate to $instrument and may increase volatility.';
  }

  @override
  String genericEventExplanation(String instrument) {
    return 'Why it matters: This event may affect sentiment and volatility for $instrument.';
  }

  @override
  String get savedFilters => 'Saved filters';

  @override
  String get saveCurrentFilter => 'Save current filter';

  @override
  String get presetName => 'Filter name';

  @override
  String get noSavedFilters => 'No saved filters yet.';

  @override
  String get filterPresetSaved => 'Filter saved.';

  @override
  String get filterPresetFailed => 'Saved filters could not be updated.';

  @override
  String get recentMarkets => 'Recently analyzed';

  @override
  String get favoriteMarkets => 'Favorite markets';

  @override
  String get outcomeSummary => '30-day outcome summary';

  @override
  String get allHistorySummary => 'All analysis summary';

  @override
  String get targetReached => 'Target reached';

  @override
  String get riskLimitTouched => 'Risk limit reached';

  @override
  String get periodEnded => 'Period ended';

  @override
  String get cannotBeEvaluated => 'Cannot be evaluated';

  @override
  String get outcomeSummaryLoadFailed =>
      'The outcome summary could not be loaded.';

  @override
  String get targetHitRate => 'Target hit rate';

  @override
  String get stopHitRate => 'Risk-limit hit rate';

  @override
  String resolvedSample(int count) {
    return '$count resolved analyses';
  }

  @override
  String get appLocked => 'Trade Pilot is locked';

  @override
  String get appLockedDescription =>
      'Your session is still active. Verify your identity to continue.';

  @override
  String get unlock => 'Unlock';

  @override
  String get biometricUnlockReason =>
      'Verify your identity to unlock Trade Pilot';

  @override
  String get unlockFailed =>
      'Could not verify your identity. Try again or sign out.';

  @override
  String get biometricLock => 'Biometric lock';

  @override
  String get biometricLockOn =>
      'Ask for fingerprint or face each time the app opens';

  @override
  String get biometricLockOff => 'Open straight to your dashboard';

  @override
  String get biometricLockUnavailable =>
      'No fingerprint or face unlock is set up on this device.';

  @override
  String get riskMapTitle => 'Timeframe Risk Map';

  @override
  String get riskMapDescription =>
      'Compare technical risk across timeframes before creating an analysis.';

  @override
  String get riskMapLoading => 'Scanning timeframes...';

  @override
  String get riskMapError => 'Could not load the risk map.';

  @override
  String get riskMapOverallWait => 'Overall: wait';

  @override
  String get riskMapOverallCompare => 'Compare timeframe options';

  @override
  String get riskMapRelativeNote =>
      'This map indicates relative risk, not guaranteed profit.';

  @override
  String get riskLow => 'Low risk';

  @override
  String get riskModerate => 'Moderate risk';

  @override
  String get riskHigh => 'High risk';

  @override
  String get riskUnavailable => 'Unavailable';

  @override
  String get riskEligible => 'Eligible';

  @override
  String get riskCaution => 'Caution';

  @override
  String get riskWait => 'Wait';

  @override
  String get riskSelected => 'Selected';

  @override
  String useTimeframe(String timeframe) {
    return 'Use $timeframe';
  }

  @override
  String get standardRulesTitle => 'TP Standard Trading Rules';

  @override
  String get standardRulesDescription =>
      'Broker-neutral rules used as the basis for Trade Pilot estimates.';

  @override
  String get standardRulesLoading => 'Loading the standard trading rules...';

  @override
  String get standardRulesError =>
      'Standard trading rules are temporarily unavailable.';

  @override
  String get ruleVersion => 'Version';

  @override
  String get fixedConversionRate => 'Fixed conversion rate';

  @override
  String get contractSize => 'Contract size';

  @override
  String get tradingSession => 'Trading session';

  @override
  String get initialMargin => 'Initial margin';

  @override
  String get facilityFee => 'Facility fee';

  @override
  String get rollover => 'Rollover';

  @override
  String get spread => 'Spread';

  @override
  String get hecticSpread => 'Hectic-market spread';

  @override
  String get minimumMovement => 'Minimum movement';

  @override
  String get limitStopRange => 'Limit/stop range';

  @override
  String get priceSource => 'Price source / guidance';

  @override
  String get settlement => 'Settlement';

  @override
  String get allowedLotRange => 'Allowed open position';

  @override
  String get minimumDeposit => 'Minimum deposit';

  @override
  String get marginControls => 'Margin controls';

  @override
  String get profitLossFormula => 'P/L formula';

  @override
  String get sourceDocument => 'Source document';

  @override
  String get topUpCredit => 'Top Up Credit';

  @override
  String get analysisQuotaHourTitle => 'Hourly limit reached';

  @override
  String get analysisQuotaHourMessage =>
      'Your hourly analysis quota is used up. Try again after the wait period ends.';

  @override
  String get analysisTopUpInfo =>
      'Want to continue your analysis? See your options';

  @override
  String get analysisQuotaDayTitle => 'Daily limit reached';

  @override
  String get analysisQuotaDayMessage =>
      'Your daily analysis quota is used up. Try again tomorrow.';

  @override
  String get analysisQuotaConcurrentTitle => 'Analysis still in progress';

  @override
  String get analysisQuotaConcurrentMessage =>
      'Wait for the previous analysis to finish before creating another one.';

  @override
  String get analysisQuotaUnknownTitle => 'Analysis could not be created';

  @override
  String get analysisQuotaUnknownMessage =>
      'An analysis limit is active. Please try again later.';

  @override
  String analysisQuotaUsage(int used, int limit) {
    return 'Used $used of $limit';
  }

  @override
  String analysisRetryAfter(String duration) {
    return 'Try again in $duration';
  }

  @override
  String analysisSeconds(int count) {
    return '$count seconds';
  }

  @override
  String analysisMinutes(int count) {
    return '$count minutes';
  }

  @override
  String analysisQuotaBalances(int hourly, int daily, int credits) {
    return 'Hourly: $hourly • Daily: $daily • Credits: $credits';
  }

  @override
  String analysisCreditConsumed(int balance) {
    return '1 credit used. Remaining balance: $balance credits.';
  }

  @override
  String get analysisCreditConsumedUnknownBalance =>
      '1 credit used. Your balance is being refreshed.';

  @override
  String get creditBalance => 'Credit balance';

  @override
  String get creditBalanceFailed => 'Balance could not be loaded.';

  @override
  String get topUpScanQris =>
      'Scan this QRIS with your banking or e-wallet app, then submit the request below.';

  @override
  String get topUpQrisUnavailable => 'The QRIS code could not be loaded.';

  @override
  String topUpRatePerCredit(String amount) {
    return '$amount per credit';
  }

  @override
  String get topUpAmountLabel => 'Amount (Rupiah)';

  @override
  String get topUpAmountHint => 'e.g. 50000';

  @override
  String get topUpChooseAmount => 'Choose a top-up amount';

  @override
  String get topUpContinuePayment => 'Continue to payment';

  @override
  String get topUpPayment => 'Payment details';

  @override
  String get topUpChangeAmount => 'Change amount';

  @override
  String topUpPaymentSummary(String amount, int credits) {
    return 'Pay $amount to receive $credits credit';
  }

  @override
  String topUpCreditsPreview(int credits) {
    return 'You will receive $credits credit';
  }

  @override
  String get topUpAmountRequired => 'Enter the amount you paid.';

  @override
  String topUpAmountTooSmall(String amount) {
    return 'Minimum top-up is $amount.';
  }

  @override
  String get topUpReferenceLabel => 'Payment reference (optional)';

  @override
  String get topUpReferenceHint => 'e.g. sender name or transfer reference';

  @override
  String get topUpProofLabel => 'Payment proof (required)';

  @override
  String get topUpAddProof => 'Attach proof';

  @override
  String get topUpChangeProof => 'Change proof';

  @override
  String get topUpProofAttached => 'Proof attached';

  @override
  String get topUpSubmit => 'Submit top-up request';

  @override
  String get topUpSubmitted => 'Top-up request submitted.';

  @override
  String topUpApprovedInstantly(int credits) {
    return 'Top-up approved. $credits credit has been added to your balance.';
  }

  @override
  String get topUpProofRequiredHint =>
      'Required — upload your transfer proof before submitting.';

  @override
  String get topUpProofNoticeTitle => 'Transfer Proof Is Required';

  @override
  String get topUpProofNoticeBody =>
      'Before submitting, upload your transfer proof on this page. A request without proof cannot be sent.';

  @override
  String get topUpProofNoticeAcknowledge => 'Got it';

  @override
  String get topUpWhatsAppSupport =>
      'Having trouble? Contact support on WhatsApp';

  @override
  String get topUpWhatsAppMessage =>
      'Hi, I need help with a TradePilot.id credit top-up';

  @override
  String get topUpProofFailed =>
      'Payment proof could not be uploaded. The request was not submitted.';

  @override
  String get topUpConfigFailed => 'Top-up configuration could not be loaded.';

  @override
  String get topUpHistory => 'Top-up history';

  @override
  String get topUpHistoryEmpty => 'You have not made any top-up requests yet.';

  @override
  String get topUpLoadMore => 'Load more';

  @override
  String get topUpApproved => 'Approved';

  @override
  String get topUpRejected => 'Rejected';

  @override
  String topUpCreditsGranted(int credits) {
    return '$credits credit added';
  }

  @override
  String topUpReviewNote(String note) {
    return 'Admin note: $note';
  }

  @override
  String topUpRequestedCredits(int credits) {
    return '$credits credit';
  }

  @override
  String get errSessionExpiredRelogin =>
      'Your session has ended. Please sign in again.';

  @override
  String get errSessionExpired => 'Your session has ended.';

  @override
  String get errSignInAgain => 'Please sign in again.';

  @override
  String get errNoConnection =>
      'Could not reach the server. Check your internet connection.';

  @override
  String get errServerUnreachable => 'Could not reach the server.';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String get errServerProblem =>
      'The server is having trouble. Try again shortly.';

  @override
  String get errConnectionTimeout =>
      'The connection timed out. Please try again.';

  @override
  String get errRequestCancelled => 'The request was cancelled.';

  @override
  String get errInstrumentRequired => 'Instrument cannot be empty.';

  @override
  String get errInstrumentUnsupported => 'Instrument is not supported.';

  @override
  String get errTimeframeUnsupported => 'Timeframe is not supported.';

  @override
  String get errInvalidServerResponse => 'The server response was not valid.';

  @override
  String get errInvalidProfileResponse =>
      'The profile response from the server was not valid.';

  @override
  String errDisplayNameLength(int max) {
    return 'Name must be 2 to $max characters.';
  }

  @override
  String get errCurrentPasswordWrong => 'Your current password is incorrect.';

  @override
  String get errPasswordTooWeak =>
      'Password does not meet the security requirements.';

  @override
  String get errProfileInvalid =>
      'Profile data is not valid. Check your entries.';

  @override
  String get errChangePasswordFailed =>
      'Could not change your password. Please try again.';

  @override
  String get errUpdateProfileFailed =>
      'Could not update your profile. Please try again.';

  @override
  String get errTooManyAttempts =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get errDeleteAccountFailed =>
      'Could not delete your account. Please try again.';

  @override
  String get errSecurityAnswerWrong => 'That security answer is incorrect.';

  @override
  String get errCredentialsWrong => 'That email or password is incorrect.';

  @override
  String get errQuotaReached => 'Analysis quota reached. Try again later.';

  @override
  String get errAiTimeout =>
      'The AI is taking longer than usual to analyze. Please try again.';

  @override
  String get errAnalysisFailed => 'Analysis failed. Please try again.';

  @override
  String get errAnalysisSlowSync =>
      'The AI took a long time to respond. The analysis may still have been created — data will sync automatically.';

  @override
  String get errDateRangeInvalid =>
      'The start date cannot be later than the end date.';

  @override
  String get errNoteTooLong5000 => 'Notes are limited to 5,000 characters.';

  @override
  String get errNoteNotSaved =>
      'The note was not saved. Check your connection and try again.';

  @override
  String get errNoteSaveFailed =>
      'The note could not be saved. Please try again.';

  @override
  String get errBalanceLoadFailed => 'Credit balance could not be loaded.';

  @override
  String get errTopupConfigLoadFailed =>
      'Top-up configuration could not be loaded.';

  @override
  String get errTopupHistoryLoadFailed =>
      'Top-up history could not be loaded. Pull to try again.';

  @override
  String get errTopupSubmitFailed => 'The top-up request could not be sent.';

  @override
  String get errTopupAmountPositive =>
      'The top-up amount must be greater than 0.';

  @override
  String get errTopupProofRequired =>
      'Upload your transfer proof before submitting.';

  @override
  String get errLivePricesFailed => 'Could not load live prices.';

  @override
  String get errMarketDataPartial => 'Some market data is not available yet.';

  @override
  String get errTechnicalDataFailed => 'Could not load technical data.';

  @override
  String get errPriceAlertsLoadFailed => 'Could not load price alerts.';

  @override
  String get errPriceAlertCreateFailed => 'Could not create the price alert.';

  @override
  String get errPriceAlertDeleteFailed => 'Could not delete the price alert.';

  @override
  String get errTargetPricePositive => 'Target price must be greater than 0.';

  @override
  String get errNoteTooLong200 => 'Notes are limited to 200 characters.';

  @override
  String get errWatchlistLoadFailed => 'Could not load your watchlist.';

  @override
  String get errWatchlistUpdateFailed => 'Could not update your watchlist.';

  @override
  String get errNotificationsLoadFailed =>
      'Notifications could not be loaded. Pull to try again.';

  @override
  String get errNotificationPrefsLoadFailed =>
      'Could not load notification preferences.';

  @override
  String get errNotificationPrefsSaveFailed =>
      'Could not save notification preferences.';

  @override
  String get errMarketSessionReminderSaveFailed =>
      'Could not save the market session reminder.';

  @override
  String get errQuietHoursSaveFailed =>
      'Could not save notification quiet hours.';

  @override
  String get errPushPermissionSystem =>
      'Notification permission has not been granted in system settings.';

  @override
  String get errPushEnableFailed => 'Push notifications could not be enabled.';

  @override
  String get errPushPrefsSaveFailed =>
      'Mobile push preferences could not be saved.';

  @override
  String get errPushTokenUnavailable =>
      'A push token is not available on this device.';

  @override
  String get errPushRegisterFailed =>
      'The server could not register this device for push.';

  @override
  String get errPushTokenSyncFailed => 'The push token could not be synced.';

  @override
  String get errPushEnableFirst =>
      'Enable Mobile Push before sending a test notification.';

  @override
  String get errPushTestNoDevice =>
      'The server did not find a registered device, or the test endpoint has not been deployed yet.';

  @override
  String get errPushTestRateLimited =>
      'Too many test notifications were requested. Wait a moment and try again.';

  @override
  String get errPushTestNotReceived =>
      'The server accepted the test, but this device did not receive an FCM message within 15 seconds. Backend Firebase credentials and project configuration need to be checked.';

  @override
  String get errPushTestFailed =>
      'The test notification request failed. Check your connection and try again.';

  @override
  String get errPushTestRejected =>
      'FCM rejected every test message. Check the device tokens and backend Firebase configuration.';

  @override
  String get errPushTestNotConfigured =>
      'The push notification service is not configured on the backend.';

  @override
  String get appErrInstrumentUnsupported =>
      'This instrument does not support the Position Size Recommendation.';

  @override
  String get appErrNoStandardPlan =>
      'The Standard Plan or Standard Trading Rules TP is not available.';

  @override
  String get appErrFundsPositive =>
      'Available trading funds must be greater than 0.';

  @override
  String get appErrMaxLossPositive =>
      'The maximum loss limit must be greater than 0.';

  @override
  String get appErrMaxLossExceedsFunds =>
      'The maximum loss limit cannot exceed available funds.';

  @override
  String get appErrExposureNegative => 'Running exposure cannot be negative.';

  @override
  String get appErrTpRulesInvalid =>
      'The Standard Trading Rules TP does not match or is not valid.';

  @override
  String get appErrLevelsInvalid =>
      'The Standard Plan Entry and Stop Loss levels are not valid.';

  @override
  String get appErrSnapshotConflict =>
      'The technical snapshot conflicts with the market direction.';

  @override
  String get appErrBelowMinimumLot =>
      'Funds or loss limit are not enough for this tier\'s minimum lot.';

  @override
  String get mindsetPacingTitle => 'Evaluation pause';

  @override
  String get mindsetPacingBody =>
      'Several analyses were created close together. Consider leaving time to evaluate the previous one.';

  @override
  String get mindsetConcentrationTitle => 'Instrument focus';

  @override
  String mindsetConcentrationBody(int count, int total, String instrument) {
    return '$count of $total analyses currently loaded focus on $instrument.';
  }

  @override
  String get mindsetPendingTitle => 'Analyses still pending';

  @override
  String mindsetPendingBody(int count) {
    return '$count analyses currently loaded have not finished evaluating. Use the next result as reflection, not certainty.';
  }

  @override
  String get mindsetJournalTitle => 'Note consistency';

  @override
  String get mindsetJournalBody =>
      'Personal notes are still rare. Writing your initial reasoning helps reflection once an evaluation arrives.';

  @override
  String get localTraderSentiment => 'Local trader sentiment';

  @override
  String journalSentimentGated(int entries, int traders) {
    return 'Hidden until at least $entries entries from $traders traders are available.';
  }

  @override
  String journalSentimentSample(int entries, int days) {
    return '$entries entries · $days days';
  }

  @override
  String get journalSentimentDisclaimer =>
      'An anonymous aggregate of community journals, not a trading signal.';

  @override
  String get personalNote => 'Personal note';

  @override
  String get addNote => 'Add note';

  @override
  String get notePrivateHint =>
      'Stored privately in your account and never sent to the AI.';

  @override
  String get noteHint => 'Write your reasoning, observations, or lessons…';

  @override
  String get deleteNote => 'Delete note';

  @override
  String get noNoteYet => 'No note for this analysis yet.';

  @override
  String get newsLinkFailed => 'That news link could not be opened.';

  @override
  String get newsLoadFailed => 'News could not be loaded.';

  @override
  String get newsEmpty => 'No recent news yet.';

  @override
  String get newsDisclaimer =>
      'News is informational and not an investment recommendation.';

  @override
  String get newsSourceFallback => 'News source';

  @override
  String get latestNews => 'Latest News';

  @override
  String get refresh => 'Refresh';

  @override
  String get scrollForMore => 'Swipe to see more';

  @override
  String get publicAiPerformanceSubtitle =>
      'An anonymous track record of every Trade Pilot analysis';

  @override
  String get analyticsLoadFailed =>
      'Analytics could not be loaded. Please try again.';

  @override
  String get sessionChangedReopen =>
      'Your session changed. Please reopen this page.';

  @override
  String get analyticsDisclaimer =>
      'These statistics describe analysis habits, not trading profit.';

  @override
  String get analyticsActivitySummary => 'Activity summary';

  @override
  String get analyticsWeeklyActivity => 'Weekly activity';

  @override
  String get metricAllAnalyses => 'All analyses';

  @override
  String get metricThisMonth => 'This month';

  @override
  String get metricThisWeek => 'This week';

  @override
  String get metricFeedbackGiven => 'Feedback given';

  @override
  String get metricDominantMode => 'Dominant mode';

  @override
  String get metricOutcomeAccuracy => 'Outcome accuracy';

  @override
  String get instrumentRanking => 'Instrument ranking';

  @override
  String countAnalyses(int count) {
    return '$count analyses';
  }

  @override
  String get loadedResults => 'Results currently loaded';

  @override
  String analyticsPartialScope(int loaded, int total) {
    return 'Counting only $loaded of $total analyses. Load more in History to widen this summary.';
  }

  @override
  String analyticsFullScope(int loaded) {
    return 'Counting all $loaded analyses currently available on this device.';
  }

  @override
  String get metricEvaluated => 'Evaluated';

  @override
  String get metricPending => 'Pending';

  @override
  String get metricPositiveOutcomes => 'Positive outcomes';

  @override
  String get metricNegativeOutcomes => 'Negative outcomes';

  @override
  String get metricHasNote => 'Has a note';

  @override
  String get metricAverageConfidence => 'Average confidence';

  @override
  String get metricTopTimeframe => 'Top timeframe';

  @override
  String get metricTopInstrument => 'Top instrument';

  @override
  String get traderMirrorLoadFailed => 'Trader Mirror could not be loaded.';

  @override
  String get traderMirrorDisclaimer =>
      'This habit mirror is retrospective and gives no trading instructions.';

  @override
  String get traderMirrorNoHighlights =>
      'Not enough data to build highlights yet.';

  @override
  String traderMirrorCoverage(int days, int resolved) {
    return 'Covering $days days · $resolved completed evaluations';
  }

  @override
  String get traderMirrorSessions => 'Market sessions';

  @override
  String get traderMirrorInstruments => 'Instrument concentration';

  @override
  String get traderMirrorTiming => 'Analysis timing';

  @override
  String get traderMirrorPostLoss => 'Patterns after a negative outcome';

  @override
  String get traderMirrorEvaluationDiscipline => 'Evaluation discipline';

  @override
  String get traderMirrorProcessReflection => 'Process reflection';

  @override
  String traderMirrorSamples(int count) {
    return '$count samples';
  }

  @override
  String traderMirrorBasedOn(int count) {
    return 'Based on $count analyses currently loaded on this device.';
  }

  @override
  String get traderMirrorNeedMore =>
      'At least 3 analyses are needed for a careful reflection.';

  @override
  String traderMirrorGated(String need, int have) {
    return 'Needs $need data points; $have available.';
  }

  @override
  String get traderMirrorUngated => 'Enough data to show the details.';

  @override
  String get traderMirrorNeedMoreGeneric => 'more';

  @override
  String get dailySummaryLoadFailed =>
      'The daily briefing could not be loaded.';

  @override
  String get dailySummarySaveFailed => 'Briefing settings could not be saved.';

  @override
  String get dailySummaryEmpty => 'No briefing for today yet.';

  @override
  String dailySummaryTimezone(String timezone) {
    return 'Time zone: $timezone';
  }

  @override
  String get dailySummaryDeliveryTime => 'Delivery time';

  @override
  String get dailySummaryFullDigest => 'Full digest';

  @override
  String get dailySummaryQuotaOnly => 'Quota only';

  @override
  String dailySummaryPreferredSide(String side) {
    return 'Preferred side: $side';
  }

  @override
  String get guideSearchHint => 'Search guide...';

  @override
  String get guideQuickStart => 'Quick start';

  @override
  String get guideQuickStartHint =>
      'Three guides to understand the core workflow.';

  @override
  String get guideSubtitle => 'Knowledge, features, and mindset.';

  @override
  String get guideNoResults => 'No articles found.';

  @override
  String get marketChartUnavailable => 'The market chart is not available yet.';

  @override
  String get journalCheckFailed => 'The journal could not be checked.';

  @override
  String get alertStatusLoadFailed => 'Alert status could not be loaded.';

  @override
  String get alertNeedsNotificationPermission =>
      'Enable notification permission so price alerts can work.';

  @override
  String get alertEnableFailed =>
      'The alert could not be enabled. Make sure notifications are on and the instrument has a live price feed.';

  @override
  String get alertDisableFailed =>
      'The alert could not be disabled. Try again shortly.';

  @override
  String get fundamentalDriftNone =>
      'The latest fundamentals still support every original source.';

  @override
  String fundamentalDriftSome(int missing, int total) {
    return '$missing of $total original sources are no longer in the latest window.';
  }

  @override
  String get outcomePendingLabel => 'Awaiting result';

  @override
  String get outcomePendingBody =>
      'The market is still running and the system is evaluating whether the TP or SL level was touched.';

  @override
  String get outcomeTp1Label => 'TP1 Reached';

  @override
  String get outcomeTp1Body =>
      'Price reached the first profit target from the analysis scenario.';

  @override
  String get outcomeTp2Label => 'TP2 Reached';

  @override
  String get outcomeTp2Body =>
      'Price reached the second profit target from the analysis scenario.';

  @override
  String get outcomeSlLabel => 'Stop Loss Hit';

  @override
  String get outcomeSlBody =>
      'Price reached the risk limit first. This is why a Stop Loss matters in every setup.';

  @override
  String get outcomeExpiredLabel => 'Expired';

  @override
  String get outcomeExpiredBody =>
      'The analysis window ended without a main target confirmed.';

  @override
  String get outcomeInvalidatedLabel => 'Analysis Invalidated';

  @override
  String get outcomeInvalidatedBody =>
      'The setup no longer matches the original analysis structure.';

  @override
  String get outcomeUnknownLabel => 'Status not available';

  @override
  String get outcomeUnknownBody => 'The outcome cannot be evaluated yet.';

  @override
  String get whyNotHigherConfidence => 'Why isn\'t confidence higher?';

  @override
  String get citedSources => 'Cited sources';

  @override
  String get awaitConfirmationNotice =>
      'Wait for confirmation — the AI does not recommend Buy or Sell right now.';

  @override
  String get instrumentRulesUnavailable =>
      'Instrument rules are not available.';

  @override
  String get tradingRulesLoadFailed => 'Trading rules could not be loaded.';

  @override
  String get tradingRulesUnavailable => 'Trading rules are not available.';

  @override
  String get positionSizeRecommendation => 'Position Size Recommendation';

  @override
  String get adaptivePlanIntro =>
      'Turn the Standard Plan into a position size that fits your funds and loss limit.';

  @override
  String get adaptivePlanDisclaimer =>
      'This calculator does not change AI levels and does not send orders. Enter free funds after deducting margin used by other positions.';

  @override
  String get availableTradingFunds => 'Available trading funds';

  @override
  String get maxLossLimit => 'Maximum loss limit';

  @override
  String get buildPositionPlan => 'Build position plan';

  @override
  String get copyPositionPlan => 'Copy plan';

  @override
  String get positionPlanCopied => 'Position plan copied.';

  @override
  String get positionPlanCopyFailed => 'Position plan could not be copied.';

  @override
  String get positionDirection => 'Direction';

  @override
  String get riskStyle => 'Risk style';

  @override
  String get riskStyleConservative => 'Conservative';

  @override
  String get riskStyleBalanced => 'Balanced';

  @override
  String get riskStyleAggressive => 'Aggressive';

  @override
  String get totalLots => 'Total lots';

  @override
  String get marginRequired => 'Required margin';

  @override
  String get estimatedCycleLoss => 'Estimated cycle loss';

  @override
  String get adaptiveCopyManualContext =>
      'Use this as manual planning context, not an execution instruction.';

  @override
  String get notRecommended => 'Not recommended';

  @override
  String get adaptivePlanFootnote =>
      'Day trading only. Estimates exclude spread, slippage, fees, VAT, rollover, and broker auto-liquidation.';

  @override
  String get lossToSl => 'Loss to SL';

  @override
  String get entryZone => 'Entry zone';

  @override
  String get primaryScenario => 'Primary scenario';
}
