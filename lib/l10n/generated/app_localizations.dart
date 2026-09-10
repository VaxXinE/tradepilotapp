import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Trade Pilot'**
  String get appTitle;

  /// No description provided for @tradePilotLogo.
  ///
  /// In en, this message translates to:
  /// **'Trade Pilot logo'**
  String get tradePilotLogo;

  /// No description provided for @aiTradingAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI-powered trading analysis'**
  String get aiTradingAssistant;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @dashboardDescription.
  ///
  /// In en, this message translates to:
  /// **'Market overview, watchlist, and latest analyses'**
  String get dashboardDescription;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @analysisNotFound.
  ///
  /// In en, this message translates to:
  /// **'Analysis not found'**
  String get analysisNotFound;

  /// No description provided for @analysisCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'A new analysis could not be created.'**
  String get analysisCreateFailed;

  /// No description provided for @analysisFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis feedback'**
  String get analysisFeedbackTitle;

  /// No description provided for @analysisFeedbackQuestion.
  ///
  /// In en, this message translates to:
  /// **'How did this analysis turn out?'**
  String get analysisFeedbackQuestion;

  /// No description provided for @feedbackCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get feedbackCorrect;

  /// No description provided for @feedbackWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get feedbackWrong;

  /// No description provided for @feedbackUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not sure yet'**
  String get feedbackUnknown;

  /// No description provided for @feedbackNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Feedback note (optional)'**
  String get feedbackNoteOptional;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @feedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback!'**
  String get feedbackThanks;

  /// No description provided for @feedbackSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Feedback could not be sent.'**
  String get feedbackSendFailed;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved.'**
  String get noteSaved;

  /// No description provided for @noteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Note deleted.'**
  String get noteDeleted;

  /// No description provided for @noteSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Note could not be saved.'**
  String get noteSaveFailed;

  /// No description provided for @tradingPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Trading Plan'**
  String get tradingPlanTitle;

  /// No description provided for @tradingPlanDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Use these levels as a risk structure, not as a guarantee that price will follow the scenario.'**
  String get tradingPlanDisclaimer;

  /// No description provided for @marketEvidence.
  ///
  /// In en, this message translates to:
  /// **'Market evidence'**
  String get marketEvidence;

  /// No description provided for @marketEvidenceDescription.
  ///
  /// In en, this message translates to:
  /// **'Market snapshot and fundamental context.'**
  String get marketEvidenceDescription;

  /// No description provided for @technicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get technicalDetails;

  /// No description provided for @technicalDetailsDescription.
  ///
  /// In en, this message translates to:
  /// **'Live signal summaries and raw indicators.'**
  String get technicalDetailsDescription;

  /// No description provided for @providedContext.
  ///
  /// In en, this message translates to:
  /// **'Context you provided'**
  String get providedContext;

  /// No description provided for @analysisInvalidationTitle.
  ///
  /// In en, this message translates to:
  /// **'This analysis is cancelled if'**
  String get analysisInvalidationTitle;

  /// No description provided for @mainScenario.
  ///
  /// In en, this message translates to:
  /// **'Scenario A — Main'**
  String get mainScenario;

  /// No description provided for @alternativeScenario.
  ///
  /// In en, this message translates to:
  /// **'Scenario B — Alternative'**
  String get alternativeScenario;

  /// No description provided for @waitScenario.
  ///
  /// In en, this message translates to:
  /// **'Scenario C — Wait / No Position'**
  String get waitScenario;

  /// No description provided for @scenariosTitle.
  ///
  /// In en, this message translates to:
  /// **'Scenarios'**
  String get scenariosTitle;

  /// No description provided for @waitScenarioBody.
  ///
  /// In en, this message translates to:
  /// **'If confirmation is weak or an invalidation condition is approaching, waiting for a cleaner setup is the most conservative option.'**
  String get waitScenarioBody;

  /// No description provided for @technicalDrivers.
  ///
  /// In en, this message translates to:
  /// **'Technical drivers'**
  String get technicalDrivers;

  /// No description provided for @fundamentalDrivers.
  ///
  /// In en, this message translates to:
  /// **'Fundamental drivers'**
  String get fundamentalDrivers;

  /// No description provided for @proAnalysisDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Why this analysis?'**
  String get proAnalysisDetailsTitle;

  /// No description provided for @proAnalysisDetailsDescription.
  ///
  /// In en, this message translates to:
  /// **'Open to see the factors behind the AI conclusion.'**
  String get proAnalysisDetailsDescription;

  /// No description provided for @analysisHelpfulQuestion.
  ///
  /// In en, this message translates to:
  /// **'Was this analysis helpful?'**
  String get analysisHelpfulQuestion;

  /// No description provided for @helpful.
  ///
  /// In en, this message translates to:
  /// **'Helpful'**
  String get helpful;

  /// No description provided for @notHelpful.
  ///
  /// In en, this message translates to:
  /// **'Not helpful'**
  String get notHelpful;

  /// No description provided for @analysisSafetyDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Trade Pilot is an analysis aid. Always limit risk and avoid opening a position based on a single indicator.'**
  String get analysisSafetyDisclaimer;

  /// No description provided for @journalCreateForTrade.
  ///
  /// In en, this message translates to:
  /// **'Journal this trade'**
  String get journalCreateForTrade;

  /// No description provided for @journalEntryForTrade.
  ///
  /// In en, this message translates to:
  /// **'My trade journal'**
  String get journalEntryForTrade;

  /// No description provided for @journalReflectionHint.
  ///
  /// In en, this message translates to:
  /// **'Save your decision and trade result for reflection.'**
  String get journalReflectionHint;

  /// No description provided for @priceLevelAlerts.
  ///
  /// In en, this message translates to:
  /// **'Price alerts'**
  String get priceLevelAlerts;

  /// No description provided for @priceLevelAlertsDescription.
  ///
  /// In en, this message translates to:
  /// **'Get notified when price reaches an AI Entry, Stop Loss, or Take Profit level.'**
  String get priceLevelAlertsDescription;

  /// No description provided for @priceLevelAlertsOn.
  ///
  /// In en, this message translates to:
  /// **'Alerts: ON · {count} levels monitored'**
  String priceLevelAlertsOn(int count);

  /// No description provided for @priceLevelAlertsOff.
  ///
  /// In en, this message translates to:
  /// **'Alerts: OFF'**
  String get priceLevelAlertsOff;

  /// No description provided for @changeTimeframe.
  ///
  /// In en, this message translates to:
  /// **'Change timeframe'**
  String get changeTimeframe;

  /// No description provided for @changeTimeframeDescription.
  ///
  /// In en, this message translates to:
  /// **'Same instrument, different timeframe — create a new analysis without leaving this page.'**
  String get changeTimeframeDescription;

  /// No description provided for @analyzeThisTimeframe.
  ///
  /// In en, this message translates to:
  /// **'Analyze this timeframe'**
  String get analyzeThisTimeframe;

  /// No description provided for @priceChart.
  ///
  /// In en, this message translates to:
  /// **'Price Chart'**
  String get priceChart;

  /// No description provided for @openFullChart.
  ///
  /// In en, this message translates to:
  /// **'Open full chart in TradingView'**
  String get openFullChart;

  /// No description provided for @fundamentalContext.
  ///
  /// In en, this message translates to:
  /// **'Fundamental Context'**
  String get fundamentalContext;

  /// No description provided for @refreshFundamentals.
  ///
  /// In en, this message translates to:
  /// **'Refresh fundamentals'**
  String get refreshFundamentals;

  /// No description provided for @fundamentalContextDescription.
  ///
  /// In en, this message translates to:
  /// **'News and economic events used by the AI when creating this analysis.'**
  String get fundamentalContextDescription;

  /// No description provided for @liveTechnicalIndicators.
  ///
  /// In en, this message translates to:
  /// **'Live Technical Indicators'**
  String get liveTechnicalIndicators;

  /// No description provided for @liveTechnicalDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Latest data; it may differ from the snapshot used for this analysis.'**
  String get liveTechnicalDisclaimer;

  /// No description provided for @lastBar.
  ///
  /// In en, this message translates to:
  /// **'Last bar'**
  String get lastBar;

  /// No description provided for @twentyBars.
  ///
  /// In en, this message translates to:
  /// **'20 bars'**
  String get twentyBars;

  /// No description provided for @signalSummary.
  ///
  /// In en, this message translates to:
  /// **'Signal summary'**
  String get signalSummary;

  /// No description provided for @technicalDataPoints.
  ///
  /// In en, this message translates to:
  /// **'{timeframe} data · {count} candles'**
  String technicalDataPoints(String timeframe, int count);

  /// No description provided for @beginnerBullish.
  ///
  /// In en, this message translates to:
  /// **'Leaning Bullish'**
  String get beginnerBullish;

  /// No description provided for @beginnerBearish.
  ///
  /// In en, this message translates to:
  /// **'Leaning Bearish'**
  String get beginnerBearish;

  /// No description provided for @beginnerWait.
  ///
  /// In en, this message translates to:
  /// **'Wait for confirmation'**
  String get beginnerWait;

  /// No description provided for @biasMeaning.
  ///
  /// In en, this message translates to:
  /// **'A {bias} bias means the AI sees a market that is {direction}.'**
  String biasMeaning(String bias, String direction);

  /// No description provided for @directionUp.
  ///
  /// In en, this message translates to:
  /// **'leaning upward'**
  String get directionUp;

  /// No description provided for @directionDown.
  ///
  /// In en, this message translates to:
  /// **'leaning downward'**
  String get directionDown;

  /// No description provided for @directionNeutral.
  ///
  /// In en, this message translates to:
  /// **'without a dominant direction'**
  String get directionNeutral;

  /// No description provided for @beginnerBuyAction.
  ///
  /// In en, this message translates to:
  /// **'The analysis structure favors a Buy scenario, but entry should still wait for the area and conditions in the trading plan.'**
  String get beginnerBuyAction;

  /// No description provided for @beginnerSellAction.
  ///
  /// In en, this message translates to:
  /// **'The analysis structure favors a Sell scenario, but entry should still follow the defined area and risk limits.'**
  String get beginnerSellAction;

  /// No description provided for @beginnerWaitAction.
  ///
  /// In en, this message translates to:
  /// **'The AI does not see a strong enough entry yet. Waiting for confirmation is a valid decision for beginners.'**
  String get beginnerWaitAction;

  /// No description provided for @analysisSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Context When Analysis Was Created'**
  String get analysisSnapshotTitle;

  /// No description provided for @analysisSnapshotDescription.
  ///
  /// In en, this message translates to:
  /// **'This is a snapshot of the data used by the AI when creating the analysis.'**
  String get analysisSnapshotDescription;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @sell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sell;

  /// No description provided for @opportunity.
  ///
  /// In en, this message translates to:
  /// **'Opportunity'**
  String get opportunity;

  /// No description provided for @executionInsight.
  ///
  /// In en, this message translates to:
  /// **'How traders may respond'**
  String get executionInsight;

  /// No description provided for @executionInsightDescription.
  ///
  /// In en, this message translates to:
  /// **'How traders may approach each scenario without specific Entry, Stop Loss, or Take Profit levels.'**
  String get executionInsightDescription;

  /// No description provided for @executionScenarioALabel.
  ///
  /// In en, this message translates to:
  /// **'If Scenario A continues'**
  String get executionScenarioALabel;

  /// No description provided for @executionScenarioABullish.
  ///
  /// In en, this message translates to:
  /// **'Traders typically watch the nearest support area as a zone of buying interest, with a conceptual exit plan if price breaks below that area.'**
  String get executionScenarioABullish;

  /// No description provided for @executionScenarioABearish.
  ///
  /// In en, this message translates to:
  /// **'Traders typically watch the nearest resistance area as a zone of selling interest, with a conceptual exit plan if price breaks above that area.'**
  String get executionScenarioABearish;

  /// No description provided for @executionScenarioANeutral.
  ///
  /// In en, this message translates to:
  /// **'With a neutral bias, many traders prefer to wait until there is a clear break out of the current range.'**
  String get executionScenarioANeutral;

  /// No description provided for @executionScenarioBLabel.
  ///
  /// In en, this message translates to:
  /// **'If Scenario B plays out'**
  String get executionScenarioBLabel;

  /// No description provided for @executionScenarioBBody.
  ///
  /// In en, this message translates to:
  /// **'If the main assumption is wrong and the alternative scenario unfolds, traders typically re-evaluate the thesis from scratch — not flip the position immediately.'**
  String get executionScenarioBBody;

  /// No description provided for @executionScenarioCLabel.
  ///
  /// In en, this message translates to:
  /// **'If waiting is the better choice'**
  String get executionScenarioCLabel;

  /// No description provided for @executionScenarioCBody.
  ///
  /// In en, this message translates to:
  /// **'Wait until the invalidation conditions above are no longer at risk, or until a stronger signal confluence emerges.'**
  String get executionScenarioCBody;

  /// No description provided for @riskHighLabel.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get riskHighLabel;

  /// No description provided for @riskLowLabel.
  ///
  /// In en, this message translates to:
  /// **'Relatively Low Risk'**
  String get riskLowLabel;

  /// No description provided for @riskModerateLabel.
  ///
  /// In en, this message translates to:
  /// **'Moderate Risk'**
  String get riskModerateLabel;

  /// No description provided for @riskHighProGuidance.
  ///
  /// In en, this message translates to:
  /// **'High volatility. Limit exposure and use the invalidation level as the risk boundary.'**
  String get riskHighProGuidance;

  /// No description provided for @riskHighBeginnerGuidance.
  ///
  /// In en, this message translates to:
  /// **'Movement may be aggressive. Avoid large position sizes and do not ignore the Stop Loss.'**
  String get riskHighBeginnerGuidance;

  /// No description provided for @riskLowGuidance.
  ///
  /// In en, this message translates to:
  /// **'Conditions appear more stable, but risk remains. Keep a loss limit.'**
  String get riskLowGuidance;

  /// No description provided for @riskModerateGuidance.
  ///
  /// In en, this message translates to:
  /// **'Opportunity and uncertainty are both present. Wait for a clear setup and use a measured position size.'**
  String get riskModerateGuidance;

  /// No description provided for @reanalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze again'**
  String get reanalyze;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @historyPageTitle.
  ///
  /// In en, this message translates to:
  /// **'History & Analysis Performance'**
  String get historyPageTitle;

  /// No description provided for @historyTotalAnalyses.
  ///
  /// In en, this message translates to:
  /// **'{count} analyses total'**
  String historyTotalAnalyses(int count);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @profileInformation.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInformation;

  /// No description provided for @changeDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Change your display name'**
  String get changeDisplayName;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @indonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get indonesian;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// No description provided for @roleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get roleUser;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get roleSuperAdmin;

  /// No description provided for @darkThemeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled • comfortable in low light'**
  String get darkThemeEnabled;

  /// No description provided for @darkThemeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled • using light appearance'**
  String get darkThemeDisabled;

  /// No description provided for @analysisMode.
  ///
  /// In en, this message translates to:
  /// **'Analysis mode'**
  String get analysisMode;

  /// No description provided for @proModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Current: Pro • complete technical details'**
  String get proModeDescription;

  /// No description provided for @beginnerModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Current: Beginner • simpler explanations'**
  String get beginnerModeDescription;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @securityQuestion.
  ///
  /// In en, this message translates to:
  /// **'Security Question'**
  String get securityQuestion;

  /// No description provided for @changeSecurityQuestion.
  ///
  /// In en, this message translates to:
  /// **'Change Security Question'**
  String get changeSecurityQuestion;

  /// No description provided for @newSecurityAnswer.
  ///
  /// In en, this message translates to:
  /// **'New security answer'**
  String get newSecurityAnswer;

  /// No description provided for @securityQuestionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Security question updated.'**
  String get securityQuestionUpdated;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @legalAndHelp.
  ///
  /// In en, this message translates to:
  /// **'Legal & Help'**
  String get legalAndHelp;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @appFooterDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'TradePilot is a decision-support tool, not financial advice or a trading service.'**
  String get appFooterDisclaimer;

  /// No description provided for @sponsoredBy.
  ///
  /// In en, this message translates to:
  /// **'Sponsored by'**
  String get sponsoredBy;

  /// No description provided for @newsDataVia.
  ///
  /// In en, this message translates to:
  /// **'News data via newsmaker.id'**
  String get newsDataVia;

  /// No description provided for @marketNews.
  ///
  /// In en, this message translates to:
  /// **'Market news'**
  String get marketNews;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @linkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'The link could not be opened.'**
  String get linkOpenFailed;

  /// No description provided for @insightsAndJournal.
  ///
  /// In en, this message translates to:
  /// **'Insights & Journal'**
  String get insightsAndJournal;

  /// No description provided for @tradeJournal.
  ///
  /// In en, this message translates to:
  /// **'Trade Journal'**
  String get tradeJournal;

  /// No description provided for @journalLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The journal could not be loaded. Try again.'**
  String get journalLoadFailed;

  /// No description provided for @journalSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The journal entry could not be saved.'**
  String get journalSaveFailed;

  /// No description provided for @journalDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete journal entry?'**
  String get journalDeleteTitle;

  /// No description provided for @journalDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get journalDeleteWarning;

  /// No description provided for @journalDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'The journal entry could not be deleted.'**
  String get journalDeleteFailed;

  /// No description provided for @journalSessionChanged.
  ///
  /// In en, this message translates to:
  /// **'The session changed. Reopen this page.'**
  String get journalSessionChanged;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @noJournalEntries.
  ///
  /// In en, this message translates to:
  /// **'No journal entries yet.'**
  String get noJournalEntries;

  /// No description provided for @journalOutcomeFilter.
  ///
  /// In en, this message translates to:
  /// **'Outcome filter'**
  String get journalOutcomeFilter;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @breakeven.
  ///
  /// In en, this message translates to:
  /// **'Breakeven'**
  String get breakeven;

  /// No description provided for @skippedTrade.
  ///
  /// In en, this message translates to:
  /// **'Not taken'**
  String get skippedTrade;

  /// No description provided for @journalPrivateLimit.
  ///
  /// In en, this message translates to:
  /// **'Up to 100 latest entries from the server. This data is private.'**
  String get journalPrivateLimit;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @addJournal.
  ///
  /// In en, this message translates to:
  /// **'Add journal entry'**
  String get addJournal;

  /// No description provided for @editJournal.
  ///
  /// In en, this message translates to:
  /// **'Edit journal entry'**
  String get editJournal;

  /// No description provided for @instrumentRequired.
  ///
  /// In en, this message translates to:
  /// **'Instrument is required.'**
  String get instrumentRequired;

  /// No description provided for @side.
  ///
  /// In en, this message translates to:
  /// **'Side'**
  String get side;

  /// No description provided for @buyJournalSide.
  ///
  /// In en, this message translates to:
  /// **'Buy (trade record)'**
  String get buyJournalSide;

  /// No description provided for @sellJournalSide.
  ///
  /// In en, this message translates to:
  /// **'Sell (trade record)'**
  String get sellJournalSide;

  /// No description provided for @retrospectiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Retrospective status'**
  String get retrospectiveStatus;

  /// No description provided for @tradeTime.
  ///
  /// In en, this message translates to:
  /// **'Trade time'**
  String get tradeTime;

  /// No description provided for @moodOptional.
  ///
  /// In en, this message translates to:
  /// **'State of mind (optional)'**
  String get moodOptional;

  /// No description provided for @reflectionOptional.
  ///
  /// In en, this message translates to:
  /// **'Reflection (optional)'**
  String get reflectionOptional;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number.'**
  String get enterValidNumber;

  /// No description provided for @entries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get entries;

  /// No description provided for @wins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get wins;

  /// No description provided for @losses.
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get losses;

  /// No description provided for @averageProfitLoss.
  ///
  /// In en, this message translates to:
  /// **'Avg P/L'**
  String get averageProfitLoss;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @tradeJournalDescription.
  ///
  /// In en, this message translates to:
  /// **'Personal trade notes and reflections'**
  String get tradeJournalDescription;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @publicAiPerformance.
  ///
  /// In en, this message translates to:
  /// **'Public AI Performance'**
  String get publicAiPerformance;

  /// No description provided for @performanceMethodology.
  ///
  /// In en, this message translates to:
  /// **'Methodology'**
  String get performanceMethodology;

  /// No description provided for @performanceDescription.
  ///
  /// In en, this message translates to:
  /// **'An anonymized track record of all Trade Pilot AI analyses. These are not personal account statistics.'**
  String get performanceDescription;

  /// No description provided for @performanceDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String performanceDays(int count);

  /// No description provided for @performanceInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Not enough data for a responsible display. {need} results required; currently {have}.'**
  String performanceInsufficient(int need, int have);

  /// No description provided for @performanceByInstrument.
  ///
  /// In en, this message translates to:
  /// **'By instrument'**
  String get performanceByInstrument;

  /// No description provided for @performanceBySession.
  ///
  /// In en, this message translates to:
  /// **'By market session'**
  String get performanceBySession;

  /// No description provided for @performanceByCondition.
  ///
  /// In en, this message translates to:
  /// **'By market condition'**
  String get performanceByCondition;

  /// No description provided for @performanceByVolatility.
  ///
  /// In en, this message translates to:
  /// **'By volatility'**
  String get performanceByVolatility;

  /// No description provided for @performanceNewsActivity.
  ///
  /// In en, this message translates to:
  /// **'News activity'**
  String get performanceNewsActivity;

  /// No description provided for @performanceMethodologyTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance methodology'**
  String get performanceMethodologyTitle;

  /// No description provided for @performanceMethodWhatTitle.
  ///
  /// In en, this message translates to:
  /// **'What is measured'**
  String get performanceMethodWhatTitle;

  /// No description provided for @performanceMethodWhatBody.
  ///
  /// In en, this message translates to:
  /// **'Only analyses with finalized outcomes. User data is anonymized and aggregated.'**
  String get performanceMethodWhatBody;

  /// No description provided for @performanceMethodRatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Win rate and hit rate'**
  String get performanceMethodRatesTitle;

  /// No description provided for @performanceMethodRatesBody.
  ///
  /// In en, this message translates to:
  /// **'Win rate compares wins with losses for triggered trades. Hit rate also includes expired analyses.'**
  String get performanceMethodRatesBody;

  /// No description provided for @performanceMethodSampleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample threshold'**
  String get performanceMethodSampleTitle;

  /// No description provided for @performanceMethodSampleBody.
  ///
  /// In en, this message translates to:
  /// **'Small sample segments are hidden to avoid misleading results or exposing small-group activity.'**
  String get performanceMethodSampleBody;

  /// No description provided for @performanceMethodExcludedTitle.
  ///
  /// In en, this message translates to:
  /// **'What is excluded'**
  String get performanceMethodExcludedTitle;

  /// No description provided for @performanceMethodExcludedBody.
  ///
  /// In en, this message translates to:
  /// **'Figures exclude position size, spread, slippage, fees, taxes, and user execution decisions.'**
  String get performanceMethodExcludedBody;

  /// No description provided for @performancePastDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Past performance does not guarantee future results.'**
  String get performancePastDisclaimer;

  /// No description provided for @performanceDeclining.
  ///
  /// In en, this message translates to:
  /// **'Recent performance is declining'**
  String get performanceDeclining;

  /// No description provided for @performanceWatch.
  ///
  /// In en, this message translates to:
  /// **'Recent performance needs attention'**
  String get performanceWatch;

  /// No description provided for @performanceStable.
  ///
  /// In en, this message translates to:
  /// **'Recent performance is stable'**
  String get performanceStable;

  /// No description provided for @performanceRecentBaseline.
  ///
  /// In en, this message translates to:
  /// **'Latest {days} days: {recent} · baseline: {baseline}.'**
  String performanceRecentBaseline(int days, String recent, String baseline);

  /// No description provided for @performanceSummary.
  ///
  /// In en, this message translates to:
  /// **'{days}-day summary'**
  String performanceSummary(int days);

  /// No description provided for @winRate.
  ///
  /// In en, this message translates to:
  /// **'Win rate'**
  String get winRate;

  /// No description provided for @hitRate.
  ///
  /// In en, this message translates to:
  /// **'Hit rate'**
  String get hitRate;

  /// No description provided for @performanceTotals.
  ///
  /// In en, this message translates to:
  /// **'{wins} wins · {losses} losses · {expired} expired · {total} samples'**
  String performanceTotals(int wins, int losses, int expired, int total);

  /// No description provided for @sinceDate.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String sinceDate(String date);

  /// No description provided for @performanceSegmentInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Not enough data: {have}/{need} samples.'**
  String performanceSegmentInsufficient(int have, int need);

  /// No description provided for @performanceBucketTotals.
  ///
  /// In en, this message translates to:
  /// **'{wins} wins · {losses} losses · {expired} expired'**
  String performanceBucketTotals(int wins, int losses, int expired);

  /// No description provided for @performanceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Performance data could not be loaded.'**
  String get performanceLoadFailed;

  /// No description provided for @offMainSession.
  ///
  /// In en, this message translates to:
  /// **'Outside main sessions'**
  String get offMainSession;

  /// No description provided for @uptrend.
  ///
  /// In en, this message translates to:
  /// **'Uptrend'**
  String get uptrend;

  /// No description provided for @downtrend.
  ///
  /// In en, this message translates to:
  /// **'Downtrend'**
  String get downtrend;

  /// No description provided for @activeNewsWeek.
  ///
  /// In en, this message translates to:
  /// **'Active news week'**
  String get activeNewsWeek;

  /// No description provided for @quietWeek.
  ///
  /// In en, this message translates to:
  /// **'Quiet week'**
  String get quietWeek;

  /// No description provided for @rangingMarket.
  ///
  /// In en, this message translates to:
  /// **'Ranging'**
  String get rangingMarket;

  /// No description provided for @volatileMarket.
  ///
  /// In en, this message translates to:
  /// **'Volatile'**
  String get volatileMarket;

  /// No description provided for @choppyMarket.
  ///
  /// In en, this message translates to:
  /// **'Choppy'**
  String get choppyMarket;

  /// No description provided for @analyticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Activity patterns and evaluation results'**
  String get analyticsDescription;

  /// No description provided for @dailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get dailySummary;

  /// No description provided for @traderMirror.
  ///
  /// In en, this message translates to:
  /// **'Trader Mirror'**
  String get traderMirror;

  /// No description provided for @traderMirrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Data-driven habit reflection'**
  String get traderMirrorDescription;

  /// No description provided for @traderMindset.
  ///
  /// In en, this message translates to:
  /// **'Trader\'s Mindset'**
  String get traderMindset;

  /// No description provided for @traderMindsetDescription.
  ///
  /// In en, this message translates to:
  /// **'Short lessons for disciplined decisions'**
  String get traderMindsetDescription;

  /// No description provided for @guide.
  ///
  /// In en, this message translates to:
  /// **'Guide Center'**
  String get guide;

  /// No description provided for @guideNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get guideNavLabel;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @guideDescription.
  ///
  /// In en, this message translates to:
  /// **'Guides to features, analysis, risk, and trading discipline'**
  String get guideDescription;

  /// No description provided for @mentalChecklistPreference.
  ///
  /// In en, this message translates to:
  /// **'Pre-analysis mental checklist'**
  String get mentalChecklistPreference;

  /// No description provided for @mentalChecklistPreferenceHint.
  ///
  /// In en, this message translates to:
  /// **'Show four discipline reminders before creating an analysis'**
  String get mentalChecklistPreferenceHint;

  /// No description provided for @mentalChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Pre-trade mental check'**
  String get mentalChecklistTitle;

  /// No description provided for @mentalChecklistRisk.
  ///
  /// In en, this message translates to:
  /// **'I know exactly how much I will lose if this trade fails'**
  String get mentalChecklistRisk;

  /// No description provided for @mentalChecklistPlan.
  ///
  /// In en, this message translates to:
  /// **'I have a written entry, stop-loss, and target'**
  String get mentalChecklistPlan;

  /// No description provided for @mentalChecklistChase.
  ///
  /// In en, this message translates to:
  /// **'I am not chasing a move that already happened (no FOMO)'**
  String get mentalChecklistChase;

  /// No description provided for @mentalChecklistCalm.
  ///
  /// In en, this message translates to:
  /// **'I am not trading to recover a previous loss'**
  String get mentalChecklistCalm;

  /// No description provided for @mentalChecklistHint.
  ///
  /// In en, this message translates to:
  /// **'Tick all four before you click Analyze. It\'s a nudge, not a block — but unchecked items are usually how losses start.'**
  String get mentalChecklistHint;

  /// No description provided for @safeWait.
  ///
  /// In en, this message translates to:
  /// **'Wait Safely'**
  String get safeWait;

  /// No description provided for @safeWaitHint.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge the risk and wait on the sidelines. Good discipline.'**
  String get safeWaitHint;

  /// No description provided for @safeWaitRecorded.
  ///
  /// In en, this message translates to:
  /// **'Your decision to wait was recorded.'**
  String get safeWaitRecorded;

  /// No description provided for @safeWaitFailed.
  ///
  /// In en, this message translates to:
  /// **'Your decision to wait could not be saved. Try again.'**
  String get safeWaitFailed;

  /// No description provided for @coolingOffBreathingTitle.
  ///
  /// In en, this message translates to:
  /// **'Take a breath first'**
  String get coolingOffBreathingTitle;

  /// No description provided for @coolingOffBreathingBody.
  ///
  /// In en, this message translates to:
  /// **'You just took a {loss}% loss. Follow this breathing pattern before choosing. The setup will still be there.'**
  String coolingOffBreathingBody(String loss);

  /// No description provided for @coolingOffBreathingBodyGeneric.
  ///
  /// In en, this message translates to:
  /// **'Follow this breathing pattern before choosing. The setup will still be there.'**
  String get coolingOffBreathingBodyGeneric;

  /// No description provided for @coolingOffBreathingInhale.
  ///
  /// In en, this message translates to:
  /// **'Breathe in'**
  String get coolingOffBreathingInhale;

  /// No description provided for @coolingOffBreathingHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get coolingOffBreathingHold;

  /// No description provided for @coolingOffBreathingExhale.
  ///
  /// In en, this message translates to:
  /// **'Breathe out'**
  String get coolingOffBreathingExhale;

  /// No description provided for @coolingOffBreathingWait.
  ///
  /// In en, this message translates to:
  /// **'Wait it out'**
  String get coolingOffBreathingWait;

  /// No description provided for @coolingOffBreathingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get coolingOffBreathingContinue;

  /// No description provided for @xpAwarded.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP for {activity}'**
  String xpAwarded(int xp, String activity);

  /// No description provided for @checklistActivity.
  ///
  /// In en, this message translates to:
  /// **'completing the pre-analysis checklist'**
  String get checklistActivity;

  /// No description provided for @guideComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get guideComplete;

  /// No description provided for @guideReading.
  ///
  /// In en, this message translates to:
  /// **'Read the material until the completion button becomes active.'**
  String get guideReading;

  /// No description provided for @guideProgressFailed.
  ///
  /// In en, this message translates to:
  /// **'Guide progress could not be saved.'**
  String get guideProgressFailed;

  /// No description provided for @openFullExplanation.
  ///
  /// In en, this message translates to:
  /// **'Open full explanation'**
  String get openFullExplanation;

  /// No description provided for @learnAdaptivePosition.
  ///
  /// In en, this message translates to:
  /// **'Learn adaptive positioning'**
  String get learnAdaptivePosition;

  /// No description provided for @sponsoredBySolidPrime.
  ///
  /// In en, this message translates to:
  /// **'Sponsored by SOLID PRIME'**
  String get sponsoredBySolidPrime;

  /// No description provided for @sponsorDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Sponsor links do not influence analysis independence and are not a recommendation to open an account or trade.'**
  String get sponsorDisclosure;

  /// No description provided for @openSponsorWebsite.
  ///
  /// In en, this message translates to:
  /// **'Open sponsor website'**
  String get openSponsorWebsite;

  /// No description provided for @liveAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Analysis'**
  String get liveAnalysisTitle;

  /// No description provided for @liveAnalysisSponsorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every weekday at 09:00 WIB on TikTok @solid.prime'**
  String get liveAnalysisSponsorSubtitle;

  /// No description provided for @progressionTitle.
  ///
  /// In en, this message translates to:
  /// **'Progression'**
  String get progressionTitle;

  /// No description provided for @progressionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your private record of preparation, reflection, and discipline.'**
  String get progressionSubtitle;

  /// No description provided for @progressionLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading discipline data...'**
  String get progressionLoading;

  /// No description provided for @progressionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load progression data.'**
  String get progressionLoadFailed;

  /// No description provided for @progressionOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get progressionOverview;

  /// No description provided for @progressionAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get progressionAchievements;

  /// No description provided for @progressionHistory.
  ///
  /// In en, this message translates to:
  /// **'XP History'**
  String get progressionHistory;

  /// No description provided for @progressionCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get progressionCurrentStreak;

  /// No description provided for @progressionLongestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest streak'**
  String get progressionLongestStreak;

  /// No description provided for @progressionLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String progressionLevel(int level);

  /// No description provided for @progressionMastery.
  ///
  /// In en, this message translates to:
  /// **'Mastery {level}'**
  String progressionMastery(int level);

  /// No description provided for @progressionRank.
  ///
  /// In en, this message translates to:
  /// **'Rank: {rank}'**
  String progressionRank(String rank);

  /// No description provided for @progressionXpToNext.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP to the next level'**
  String progressionXpToNext(int xp);

  /// No description provided for @progressionUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked {date}'**
  String progressionUnlocked(String date);

  /// No description provided for @progressionLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get progressionLocked;

  /// No description provided for @progressionNoAchievements.
  ///
  /// In en, this message translates to:
  /// **'Complete activities to unlock achievements.'**
  String get progressionNoAchievements;

  /// No description provided for @progressionNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No activity yet. Start building your discipline routine.'**
  String get progressionNoHistory;

  /// No description provided for @progressionPrivate.
  ///
  /// In en, this message translates to:
  /// **'Progress is private. XP rewards process—not profit, win rate, or account size.'**
  String get progressionPrivate;

  /// No description provided for @progressionActivity.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP for {reason}'**
  String progressionActivity(int xp, String reason);

  /// No description provided for @mindsetDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Educational material only. It is not financial or psychological advice.'**
  String get mindsetDisclaimer;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out of this account?'**
  String get signOutConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @permanentAction.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent'**
  String get permanentAction;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'Your profile, analyses, journal, watchlist, and account data will be deleted and cannot be recovered.'**
  String get deleteAccountWarning;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @deleteAccountAcknowledgement.
  ///
  /// In en, this message translates to:
  /// **'I understand that my account and data will be permanently deleted.'**
  String get deleteAccountAcknowledgement;

  /// No description provided for @deleteAccountPermanently.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete Account'**
  String get deleteAccountPermanently;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @nameMinimumCharacters.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMinimumCharacters;

  /// No description provided for @nameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name is too long'**
  String get nameTooLong;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailChangeUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Changing email is not supported yet.'**
  String get emailChangeUnsupported;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get profileUpdated;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @avatarRequirements.
  ///
  /// In en, this message translates to:
  /// **'Use a JPG, PNG, WebP, or GIF image up to 5 MB.'**
  String get avatarRequirements;

  /// No description provided for @avatarUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Profile photo could not be uploaded.'**
  String get avatarUploadFailed;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully.'**
  String get passwordChanged;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get currentPasswordRequired;

  /// No description provided for @passwordMinimumCharacters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinimumCharacters;

  /// No description provided for @passwordConfirmationMismatch.
  ///
  /// In en, this message translates to:
  /// **'Password confirmation does not match'**
  String get passwordConfirmationMismatch;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your analysis'**
  String get loginDescription;

  /// No description provided for @usernameEmail.
  ///
  /// In en, this message translates to:
  /// **'Username / Email'**
  String get usernameEmail;

  /// No description provided for @usernameEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Your username or email'**
  String get usernameEmailHint;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get emailHint;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In to Dashboard'**
  String get signIn;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @googleDeleteReauthDescription.
  ///
  /// In en, this message translates to:
  /// **'To protect your account, verify your identity with Google before deletion.'**
  String get googleDeleteReauthDescription;

  /// No description provided for @verifyGoogleAndDelete.
  ///
  /// In en, this message translates to:
  /// **'Verify with Google and delete'**
  String get verifyGoogleAndDelete;

  /// No description provided for @errGoogleTokenInvalid.
  ///
  /// In en, this message translates to:
  /// **'Google could not verify this sign-in. Choose the same account and try again.'**
  String get errGoogleTokenInvalid;

  /// No description provided for @errGoogleAccountConflict.
  ///
  /// In en, this message translates to:
  /// **'This email is linked to another sign-in method. Sign in with that method first.'**
  String get errGoogleAccountConflict;

  /// No description provided for @errGoogleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In is temporarily unavailable. Please try again later.'**
  String get errGoogleUnavailable;

  /// No description provided for @errGoogleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in with Google. Please try again.'**
  String get errGoogleSignInFailed;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifying;

  /// No description provided for @signInWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Sign in with fingerprint / face'**
  String get signInWithBiometrics;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccount;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register free'**
  String get register;

  /// No description provided for @biometricReason.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to sign in to Trade Pilot'**
  String get biometricReason;

  /// No description provided for @biometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics are unavailable. Use your email and password.'**
  String get biometricUnavailable;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @startTradingJourney.
  ///
  /// In en, this message translates to:
  /// **'Start your trading journey'**
  String get startTradingJourney;

  /// No description provided for @registerDescription.
  ///
  /// In en, this message translates to:
  /// **'Create an account and tailor the analysis to your experience.'**
  String get registerDescription;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @minimumEightCharacters.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get minimumEightCharacters;

  /// No description provided for @experienceLevel.
  ///
  /// In en, this message translates to:
  /// **'Experience Level'**
  String get experienceLevel;

  /// No description provided for @beginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get beginner;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get pro;

  /// No description provided for @beginnerModeHelp.
  ///
  /// In en, this message translates to:
  /// **'Simpler, step-by-step explanations.'**
  String get beginnerModeHelp;

  /// No description provided for @proModeHelp.
  ///
  /// In en, this message translates to:
  /// **'More concise and technical market information.'**
  String get proModeHelp;

  /// No description provided for @firstPetQuestion.
  ///
  /// In en, this message translates to:
  /// **'What was the name of your first pet?'**
  String get firstPetQuestion;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @answerRequired.
  ///
  /// In en, this message translates to:
  /// **'Answer is required'**
  String get answerRequired;

  /// No description provided for @registerConsent.
  ///
  /// In en, this message translates to:
  /// **'By registering, you agree to:'**
  String get registerConsent;

  /// No description provided for @andLabel.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get andLabel;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully. Please sign in.'**
  String get passwordResetSuccess;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @stepOfThree.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 3'**
  String stepOfThree(int step);

  /// No description provided for @findYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Find your account'**
  String get findYourAccount;

  /// No description provided for @findAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email to start password recovery.'**
  String get findAccountDescription;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @verifyIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity'**
  String get verifyIdentity;

  /// No description provided for @securityAnswerDescription.
  ///
  /// In en, this message translates to:
  /// **'Answer the security question you created during registration.'**
  String get securityAnswerDescription;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmail;

  /// No description provided for @createNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a new password'**
  String get createNewPassword;

  /// No description provided for @newPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters and do not reuse your old password.'**
  String get newPasswordDescription;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save Password'**
  String get savePassword;

  /// No description provided for @myPriceAlerts.
  ///
  /// In en, this message translates to:
  /// **'My Price Alerts'**
  String get myPriceAlerts;

  /// No description provided for @priceAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Price alerts you\'ve set across instruments'**
  String get priceAlertsSubtitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @realtimeActive.
  ///
  /// In en, this message translates to:
  /// **'Realtime connected'**
  String get realtimeActive;

  /// No description provided for @realtimeConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting realtime…'**
  String get realtimeConnecting;

  /// No description provided for @notificationInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get notificationInbox;

  /// No description provided for @notificationUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String notificationUnreadCount(int count);

  /// No description provided for @notificationAnalysisUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This analysis is unavailable or you do not have access.'**
  String get notificationAnalysisUnavailable;

  /// No description provided for @mobilePush.
  ///
  /// In en, this message translates to:
  /// **'Mobile Push'**
  String get mobilePush;

  /// No description provided for @pushUpdatingDevice.
  ///
  /// In en, this message translates to:
  /// **'Updating device settings…'**
  String get pushUpdatingDevice;

  /// No description provided for @pushDeviceRegistered.
  ///
  /// In en, this message translates to:
  /// **'Device registered for push.'**
  String get pushDeviceRegistered;

  /// No description provided for @pushDeviceRegisteredLastReceived.
  ///
  /// In en, this message translates to:
  /// **'Device registered for push. Last received {date}.'**
  String pushDeviceRegisteredLastReceived(String date);

  /// No description provided for @pushPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Enable it again in device settings.'**
  String get pushPermissionDenied;

  /// No description provided for @pushReceiveWhenInactive.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications while the app is inactive.'**
  String get pushReceiveWhenInactive;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notificationPreferences;

  /// No description provided for @notificationPreferencesDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose which notifications you want to receive.'**
  String get notificationPreferencesDescription;

  /// No description provided for @notificationPreferencesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences could not be loaded.'**
  String get notificationPreferencesLoadFailed;

  /// No description provided for @notificationExpiryTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis expiry'**
  String get notificationExpiryTitle;

  /// No description provided for @notificationExpiryDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminder when an analysis window is about to end.'**
  String get notificationExpiryDescription;

  /// No description provided for @notificationBroadcastTitle.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get notificationBroadcastTitle;

  /// No description provided for @notificationBroadcastDescription.
  ///
  /// In en, this message translates to:
  /// **'Important information and broadcasts from Trade Pilot.'**
  String get notificationBroadcastDescription;

  /// No description provided for @notificationDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily summary'**
  String get notificationDailyTitle;

  /// No description provided for @notificationDailyDescription.
  ///
  /// In en, this message translates to:
  /// **'Daily activity and market summary.'**
  String get notificationDailyDescription;

  /// No description provided for @notificationNewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Market news'**
  String get notificationNewsTitle;

  /// No description provided for @notificationNewsDescription.
  ///
  /// In en, this message translates to:
  /// **'Important news relevant to the market.'**
  String get notificationNewsDescription;

  /// No description provided for @notificationCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Economic calendar'**
  String get notificationCalendarTitle;

  /// No description provided for @notificationCalendarDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders for high-impact economic events.'**
  String get notificationCalendarDescription;

  /// No description provided for @notificationPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Price movement'**
  String get notificationPriceTitle;

  /// No description provided for @notificationPriceDescription.
  ///
  /// In en, this message translates to:
  /// **'Significant price changes and anomalies.'**
  String get notificationPriceDescription;

  /// No description provided for @notificationSignalTitle.
  ///
  /// In en, this message translates to:
  /// **'Signal changes'**
  String get notificationSignalTitle;

  /// No description provided for @notificationSignalDescription.
  ///
  /// In en, this message translates to:
  /// **'When the AI bias changes meaningfully.'**
  String get notificationSignalDescription;

  /// No description provided for @notificationWeeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly recap'**
  String get notificationWeeklyTitle;

  /// No description provided for @notificationWeeklyDescription.
  ///
  /// In en, this message translates to:
  /// **'Weekly trading activity summary.'**
  String get notificationWeeklyDescription;

  /// No description provided for @notificationGuardrails.
  ///
  /// In en, this message translates to:
  /// **'Decision guardrails'**
  String get notificationGuardrails;

  /// No description provided for @notificationRevengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revenge trading warning'**
  String get notificationRevengeTitle;

  /// No description provided for @notificationRevengeDescription.
  ///
  /// In en, this message translates to:
  /// **'A gentle warning after a recent loss.'**
  String get notificationRevengeDescription;

  /// No description provided for @notificationOvertradingTitle.
  ///
  /// In en, this message translates to:
  /// **'Overtrading warning'**
  String get notificationOvertradingTitle;

  /// No description provided for @notificationOvertradingDescription.
  ///
  /// In en, this message translates to:
  /// **'A warning when analyses are created too close together.'**
  String get notificationOvertradingDescription;

  /// No description provided for @notificationHighRiskTitle.
  ///
  /// In en, this message translates to:
  /// **'High-risk warning'**
  String get notificationHighRiskTitle;

  /// No description provided for @notificationHighRiskDescription.
  ///
  /// In en, this message translates to:
  /// **'A warning for high-impact events within 30 minutes.'**
  String get notificationHighRiskDescription;

  /// No description provided for @notificationCoolingOffTitle.
  ///
  /// In en, this message translates to:
  /// **'30-minute cooling-off'**
  String get notificationCoolingOffTitle;

  /// No description provided for @notificationCoolingOffDescription.
  ///
  /// In en, this message translates to:
  /// **'An optional pause after a significant loss.'**
  String get notificationCoolingOffDescription;

  /// No description provided for @notificationSessionReminders.
  ///
  /// In en, this message translates to:
  /// **'Market session reminders'**
  String get notificationSessionReminders;

  /// No description provided for @quietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get quietHours;

  /// No description provided for @quietHoursDescription.
  ///
  /// In en, this message translates to:
  /// **'Hold non-urgent notifications during rest hours.'**
  String get quietHoursDescription;

  /// No description provided for @quietHoursStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get quietHoursStart;

  /// No description provided for @quietHoursEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get quietHoursEnd;

  /// No description provided for @notificationTimezone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get notificationTimezone;

  /// No description provided for @quietHoursSecurityNotice.
  ///
  /// In en, this message translates to:
  /// **'Security notifications may still be delivered during quiet hours.'**
  String get quietHoursSecurityNotice;

  /// No description provided for @notificationAutoPaused.
  ///
  /// In en, this message translates to:
  /// **'Some ‘{category}’ notifications were paused because they have not been opened recently.'**
  String notificationAutoPaused(String category);

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @trader.
  ///
  /// In en, this message translates to:
  /// **'Trader'**
  String get trader;

  /// No description provided for @latestAnalyses.
  ///
  /// In en, this message translates to:
  /// **'Latest Analyses'**
  String get latestAnalyses;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @decisionDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Trade Pilot helps you understand market conditions, but all decisions and risk management remain your responsibility.'**
  String get decisionDisclaimer;

  /// No description provided for @wantMarketAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Want a market analysis?'**
  String get wantMarketAnalysis;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started with Trade Pilot'**
  String get getStarted;

  /// No description provided for @onboardingSteps.
  ///
  /// In en, this message translates to:
  /// **'Choose a market, review the live context, then create your first analysis. Results are decision support—not trading orders.'**
  String get onboardingSteps;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @liveMarkets.
  ///
  /// In en, this message translates to:
  /// **'Live Markets'**
  String get liveMarkets;

  /// No description provided for @analysisPreparation.
  ///
  /// In en, this message translates to:
  /// **'Review prices, market sessions, charts, indicators, and the economic calendar before requesting AI analysis.'**
  String get analysisPreparation;

  /// No description provided for @startAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Start Analysis'**
  String get startAnalysis;

  /// No description provided for @marketWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Market Watchlist'**
  String get marketWatchlist;

  /// No description provided for @manageWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Manage watchlist'**
  String get manageWatchlist;

  /// No description provided for @watchlistDescription.
  ///
  /// In en, this message translates to:
  /// **'Track your favorite markets without opening another page.'**
  String get watchlistDescription;

  /// No description provided for @pricesUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Prices updated at {time}'**
  String pricesUpdatedAt(String time);

  /// No description provided for @livePriceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live price is unavailable'**
  String get livePriceUnavailable;

  /// No description provided for @createPriceAlert.
  ///
  /// In en, this message translates to:
  /// **'Create price alert'**
  String get createPriceAlert;

  /// No description provided for @openAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Open analysis'**
  String get openAnalysis;

  /// No description provided for @watchlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your watchlist is empty'**
  String get watchlistEmpty;

  /// No description provided for @addSymbol.
  ///
  /// In en, this message translates to:
  /// **'Add symbol'**
  String get addSymbol;

  /// No description provided for @totalAnalyses.
  ///
  /// In en, this message translates to:
  /// **'Total Analyses'**
  String get totalAnalyses;

  /// No description provided for @beginnerMode.
  ///
  /// In en, this message translates to:
  /// **'Beginner Mode'**
  String get beginnerMode;

  /// No description provided for @proMode.
  ///
  /// In en, this message translates to:
  /// **'Pro Mode'**
  String get proMode;

  /// No description provided for @aiConfidence.
  ///
  /// In en, this message translates to:
  /// **'AI Confidence'**
  String get aiConfidence;

  /// No description provided for @unlimitedAnalysisQuota.
  ///
  /// In en, this message translates to:
  /// **'Unlimited analysis quota'**
  String get unlimitedAnalysisQuota;

  /// No description provided for @analysisQuota.
  ///
  /// In en, this message translates to:
  /// **'Analysis Quota'**
  String get analysisQuota;

  /// No description provided for @perHour.
  ///
  /// In en, this message translates to:
  /// **'Per hour'**
  String get perHour;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'Per day'**
  String get perDay;

  /// No description provided for @noAnalyses.
  ///
  /// In en, this message translates to:
  /// **'No analyses yet'**
  String get noAnalyses;

  /// No description provided for @createFirstAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Create your first analysis'**
  String get createFirstAnalysis;

  /// No description provided for @priceAlertCreated.
  ///
  /// In en, this message translates to:
  /// **'Price alert for {instrument} was created.'**
  String priceAlertCreated(String instrument);

  /// No description provided for @instrumentAddedToWatchlist.
  ///
  /// In en, this message translates to:
  /// **'{instrument} was added to your watchlist.'**
  String instrumentAddedToWatchlist(String instrument);

  /// No description provided for @instrumentAlreadyInWatchlist.
  ///
  /// In en, this message translates to:
  /// **'{instrument} is already in your watchlist.'**
  String instrumentAlreadyInWatchlist(String instrument);

  /// No description provided for @removeFromWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Remove from watchlist?'**
  String get removeFromWatchlist;

  /// No description provided for @removeInstrumentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Remove {instrument} from your watchlist?'**
  String removeInstrumentConfirmation(String instrument);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @instrumentRemovedFromWatchlist.
  ///
  /// In en, this message translates to:
  /// **'{instrument} was removed from your watchlist.'**
  String instrumentRemovedFromWatchlist(String instrument);

  /// No description provided for @removeInstrumentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove {instrument}.'**
  String removeInstrumentFailed(String instrument);

  /// No description provided for @selectMarketsForDashboard.
  ///
  /// In en, this message translates to:
  /// **'Select the markets you want to track on the Dashboard.'**
  String get selectMarketsForDashboard;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @watchlistUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update the watchlist.'**
  String get watchlistUpdateFailed;

  /// No description provided for @watchlistUpdated.
  ///
  /// In en, this message translates to:
  /// **'Watchlist updated for {instrument}.'**
  String watchlistUpdated(String instrument);

  /// No description provided for @alertNeedsLivePrice.
  ///
  /// In en, this message translates to:
  /// **'A price alert requires a live price. A live price is not available for this instrument.'**
  String get alertNeedsLivePrice;

  /// No description provided for @aiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis'**
  String get aiAnalysis;

  /// No description provided for @analyzeTitle.
  ///
  /// In en, this message translates to:
  /// **'New Analysis'**
  String get analyzeTitle;

  /// No description provided for @otherInstrument.
  ///
  /// In en, this message translates to:
  /// **'Other instrument…'**
  String get otherInstrument;

  /// No description provided for @quotaHour.
  ///
  /// In en, this message translates to:
  /// **'Hourly remaining'**
  String get quotaHour;

  /// No description provided for @quotaDay.
  ///
  /// In en, this message translates to:
  /// **'Daily remaining'**
  String get quotaDay;

  /// No description provided for @quotaHourShort.
  ///
  /// In en, this message translates to:
  /// **'/hr'**
  String get quotaHourShort;

  /// No description provided for @quotaDayShort.
  ///
  /// In en, this message translates to:
  /// **'/day'**
  String get quotaDayShort;

  /// No description provided for @selectInstrument.
  ///
  /// In en, this message translates to:
  /// **'Select Instrument'**
  String get selectInstrument;

  /// No description provided for @selectMarketDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the market you want to understand.'**
  String get selectMarketDescription;

  /// No description provided for @tapToChangeInstrument.
  ///
  /// In en, this message translates to:
  /// **'Tap to change the instrument'**
  String get tapToChangeInstrument;

  /// No description provided for @timeframe.
  ///
  /// In en, this message translates to:
  /// **'Timeframe'**
  String get timeframe;

  /// No description provided for @timeframeDescription.
  ///
  /// In en, this message translates to:
  /// **'The timeframe determines the perspective of the market analysis.'**
  String get timeframeDescription;

  /// No description provided for @priceAlertUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Price Alert Unavailable'**
  String get priceAlertUnavailable;

  /// No description provided for @instrumentHasNoLiveFeed.
  ///
  /// In en, this message translates to:
  /// **'This instrument does not have a live price feed that can be used for alerts.'**
  String get instrumentHasNoLiveFeed;

  /// No description provided for @additionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes'**
  String get additionalNotes;

  /// No description provided for @decisionGuardrails.
  ///
  /// In en, this message translates to:
  /// **'Decision guardrails'**
  String get decisionGuardrails;

  /// No description provided for @guardrailHint.
  ///
  /// In en, this message translates to:
  /// **'This is a soft warning. Pause and reassess before continuing.'**
  String get guardrailHint;

  /// No description provided for @guardrailRevenge.
  ///
  /// In en, this message translates to:
  /// **'A loss occurred {minutes} minutes ago. Avoid revenge trading.'**
  String guardrailRevenge(String minutes);

  /// No description provided for @guardrailOvertrading.
  ///
  /// In en, this message translates to:
  /// **'You made {count} analyses; the current limit is {limit}.'**
  String guardrailOvertrading(String count, String limit);

  /// No description provided for @guardrailHighRisk.
  ///
  /// In en, this message translates to:
  /// **'{event} is expected in about {minutes} minutes.'**
  String guardrailHighRisk(String event, String minutes);

  /// No description provided for @guardrailUnusualHour.
  ///
  /// In en, this message translates to:
  /// **'This trading hour ({hour}:00 UTC) is unusual for your history.'**
  String guardrailUnusualHour(String hour);

  /// No description provided for @guardrailCoolingOff.
  ///
  /// In en, this message translates to:
  /// **'Cooling-off period: about {minutes} minutes remaining.'**
  String guardrailCoolingOff(String minutes);

  /// No description provided for @guardrailGeneric.
  ///
  /// In en, this message translates to:
  /// **'A risk pattern was detected.'**
  String get guardrailGeneric;

  /// No description provided for @additionalNotesDescription.
  ///
  /// In en, this message translates to:
  /// **'Optional. Describe the position or condition you want the AI to consider.'**
  String get additionalNotesDescription;

  /// No description provided for @additionalNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Example: I do not have a position yet and want to wait for a safer entry...'**
  String get additionalNotesHint;

  /// No description provided for @analyzingMarket.
  ///
  /// In en, this message translates to:
  /// **'Analyzing the market...'**
  String get analyzingMarket;

  /// No description provided for @getAiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Get AI Analysis'**
  String get getAiAnalysis;

  /// No description provided for @analysesRemainingToday.
  ///
  /// In en, this message translates to:
  /// **'{count} analyses remaining today'**
  String analysesRemainingToday(int count);

  /// No description provided for @aiAnalysisDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI analysis is a decision-support tool, not a guarantee of profit. Always consider the risks before opening a position.'**
  String get aiAnalysisDisclaimer;

  /// No description provided for @understandMarketBeforeEntry.
  ///
  /// In en, this message translates to:
  /// **'Understand the market before entering'**
  String get understandMarketBeforeEntry;

  /// No description provided for @beginnerAnalysisIntro.
  ///
  /// In en, this message translates to:
  /// **'Trade Pilot helps explain price, momentum, market sessions, and important events in simpler language.'**
  String get beginnerAnalysisIntro;

  /// No description provided for @livePrice.
  ///
  /// In en, this message translates to:
  /// **'Live price'**
  String get livePrice;

  /// No description provided for @referencePrice.
  ///
  /// In en, this message translates to:
  /// **'Reference price'**
  String get referencePrice;

  /// No description provided for @addToWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Add to watchlist'**
  String get addToWatchlist;

  /// No description provided for @partialChartUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Some chart data is unavailable.'**
  String get partialChartUnavailable;

  /// No description provided for @cryptoMarketAlwaysOpen.
  ///
  /// In en, this message translates to:
  /// **'Crypto Market 24/7'**
  String get cryptoMarketAlwaysOpen;

  /// No description provided for @cryptoNoForexSessions.
  ///
  /// In en, this message translates to:
  /// **'Crypto does not follow forex sessions.'**
  String get cryptoNoForexSessions;

  /// No description provided for @marketClosedWeekend.
  ///
  /// In en, this message translates to:
  /// **'Market closed for the weekend'**
  String get marketClosedWeekend;

  /// No description provided for @noMainSessionActive.
  ///
  /// In en, this message translates to:
  /// **'No major market session is active'**
  String get noMainSessionActive;

  /// No description provided for @sessionOverlap.
  ///
  /// In en, this message translates to:
  /// **'Session overlap • liquidity is usually higher'**
  String get sessionOverlap;

  /// No description provided for @marketSessionActive.
  ///
  /// In en, this message translates to:
  /// **'Market session active'**
  String get marketSessionActive;

  /// No description provided for @sessionOpensIn.
  ///
  /// In en, this message translates to:
  /// **'{session} opens in {duration}'**
  String sessionOpensIn(String session, String duration);

  /// No description provided for @sessionClosesIn.
  ///
  /// In en, this message translates to:
  /// **'{session} closes in {duration}'**
  String sessionClosesIn(String session, String duration);

  /// No description provided for @highImpactEventSoon.
  ///
  /// In en, this message translates to:
  /// **'A high-impact event is coming soon'**
  String get highImpactEventSoon;

  /// No description provided for @highImpactRisk.
  ///
  /// In en, this message translates to:
  /// **'Prices may move quickly and spreads may widen.'**
  String get highImpactRisk;

  /// No description provided for @eventStartsInMinutes.
  ///
  /// In en, this message translates to:
  /// **' • in about {minutes} min'**
  String eventStartsInMinutes(int minutes);

  /// No description provided for @searchInstrumentOrNote.
  ///
  /// In en, this message translates to:
  /// **'Search instruments or notes'**
  String get searchInstrumentOrNote;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @noMatchingAnalyses.
  ///
  /// In en, this message translates to:
  /// **'No matching analyses'**
  String get noMatchingAnalyses;

  /// No description provided for @changeSearchOrFilter.
  ///
  /// In en, this message translates to:
  /// **'Try changing the search term or filters.'**
  String get changeSearchOrFilter;

  /// No description provided for @analysesAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your AI analyses will appear here.'**
  String get analysesAppearHere;

  /// No description provided for @resetFilter.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get resetFilter;

  /// No description provided for @modeBeginner.
  ///
  /// In en, this message translates to:
  /// **'Mode: Beginner'**
  String get modeBeginner;

  /// No description provided for @modePro.
  ///
  /// In en, this message translates to:
  /// **'Mode: Pro'**
  String get modePro;

  /// No description provided for @outcomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Outcome: {outcome}'**
  String outcomeLabel(String outcome);

  /// No description provided for @confidenceAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Confidence ≥ {confidence}%'**
  String confidenceAtLeast(int confidence);

  /// No description provided for @resultCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String resultCount(int count);

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @positive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get positive;

  /// No description provided for @negative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get negative;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @valid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get valid;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @analysisWindowActiveUntil.
  ///
  /// In en, this message translates to:
  /// **'Analysis window active until {date}'**
  String analysisWindowActiveUntil(String date);

  /// No description provided for @analysisWindowExpiredAt.
  ///
  /// In en, this message translates to:
  /// **'Analysis window expired at {date}'**
  String analysisWindowExpiredAt(String date);

  /// No description provided for @analysisCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String analysisCreatedAt(String date);

  /// No description provided for @historySummary.
  ///
  /// In en, this message translates to:
  /// **'History summary'**
  String get historySummary;

  /// No description provided for @partialSummary.
  ///
  /// In en, this message translates to:
  /// **'Partial summary'**
  String get partialSummary;

  /// No description provided for @visible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get visible;

  /// No description provided for @evaluated.
  ///
  /// In en, this message translates to:
  /// **'Evaluated'**
  String get evaluated;

  /// No description provided for @averageConfidence.
  ///
  /// In en, this message translates to:
  /// **'Average confidence'**
  String get averageConfidence;

  /// No description provided for @positiveEvaluatedSummary.
  ///
  /// In en, this message translates to:
  /// **'{rate}% positive outcomes from evaluated analyses.'**
  String positiveEvaluatedSummary(int rate);

  /// No description provided for @hasJournalNote.
  ///
  /// In en, this message translates to:
  /// **'Has a journal note'**
  String get hasJournalNote;

  /// No description provided for @confidenceValue.
  ///
  /// In en, this message translates to:
  /// **'Confidence {value}'**
  String confidenceValue(String value);

  /// No description provided for @riskValue.
  ///
  /// In en, this message translates to:
  /// **'Risk {value}'**
  String riskValue(String value);

  /// No description provided for @strongBullish.
  ///
  /// In en, this message translates to:
  /// **'Strong bullish'**
  String get strongBullish;

  /// No description provided for @strongBearish.
  ///
  /// In en, this message translates to:
  /// **'Strong bearish'**
  String get strongBearish;

  /// No description provided for @biasUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Bias unavailable'**
  String get biasUnavailable;

  /// No description provided for @trendingUp.
  ///
  /// In en, this message translates to:
  /// **'Uptrend'**
  String get trendingUp;

  /// No description provided for @trendingDown.
  ///
  /// In en, this message translates to:
  /// **'Downtrend'**
  String get trendingDown;

  /// No description provided for @movingSideways.
  ///
  /// In en, this message translates to:
  /// **'Moving sideways'**
  String get movingSideways;

  /// No description provided for @trendingMarket.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trendingMarket;

  /// No description provided for @evaluationPending.
  ///
  /// In en, this message translates to:
  /// **'Evaluation pending'**
  String get evaluationPending;

  /// No description provided for @referenceTargetOneHit.
  ///
  /// In en, this message translates to:
  /// **'Reference target 1 reached'**
  String get referenceTargetOneHit;

  /// No description provided for @referenceTargetTwoHit.
  ///
  /// In en, this message translates to:
  /// **'Reference target 2 reached'**
  String get referenceTargetTwoHit;

  /// No description provided for @riskLimitHit.
  ///
  /// In en, this message translates to:
  /// **'Risk limit reached'**
  String get riskLimitHit;

  /// No description provided for @analysisPeriodEnded.
  ///
  /// In en, this message translates to:
  /// **'Analysis period ended'**
  String get analysisPeriodEnded;

  /// No description provided for @analysisCannotBeEvaluated.
  ///
  /// In en, this message translates to:
  /// **'Analysis cannot be evaluated'**
  String get analysisCannotBeEvaluated;

  /// No description provided for @notYetEvaluated.
  ///
  /// In en, this message translates to:
  /// **'Not yet evaluated'**
  String get notYetEvaluated;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @historyFilters.
  ///
  /// In en, this message translates to:
  /// **'History Filters'**
  String get historyFilters;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @evaluationStatus.
  ///
  /// In en, this message translates to:
  /// **'Evaluation status'**
  String get evaluationStatus;

  /// No description provided for @minimumConfidence.
  ///
  /// In en, this message translates to:
  /// **'Minimum confidence'**
  String get minimumConfidence;

  /// No description provided for @sortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort order'**
  String get sortOrder;

  /// No description provided for @instrument.
  ///
  /// In en, this message translates to:
  /// **'Instrument'**
  String get instrument;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @clearDateRange.
  ///
  /// In en, this message translates to:
  /// **'Clear date range'**
  String get clearDateRange;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @positiveOutcome.
  ///
  /// In en, this message translates to:
  /// **'Positive outcome'**
  String get positiveOutcome;

  /// No description provided for @negativeOutcome.
  ///
  /// In en, this message translates to:
  /// **'Negative outcome'**
  String get negativeOutcome;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get oldest;

  /// No description provided for @highestConfidence.
  ///
  /// In en, this message translates to:
  /// **'Highest confidence'**
  String get highestConfidence;

  /// No description provided for @marketSession.
  ///
  /// In en, this message translates to:
  /// **'Market Session'**
  String get marketSession;

  /// No description provided for @cryptoMarket247.
  ///
  /// In en, this message translates to:
  /// **'Crypto Market 24/7'**
  String get cryptoMarket247;

  /// No description provided for @marketClosed.
  ///
  /// In en, this message translates to:
  /// **'Market closed'**
  String get marketClosed;

  /// No description provided for @activeUppercase.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get activeUppercase;

  /// No description provided for @closedUppercase.
  ///
  /// In en, this message translates to:
  /// **'CLOSED'**
  String get closedUppercase;

  /// No description provided for @liquidity.
  ///
  /// In en, this message translates to:
  /// **'Liquidity'**
  String get liquidity;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @variesUppercase.
  ///
  /// In en, this message translates to:
  /// **'VARIES'**
  String get variesUppercase;

  /// No description provided for @highUppercase.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get highUppercase;

  /// No description provided for @mediumUppercase.
  ///
  /// In en, this message translates to:
  /// **'MEDIUM'**
  String get mediumUppercase;

  /// No description provided for @lowUppercase.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get lowUppercase;

  /// No description provided for @sessionOverlapActivity.
  ///
  /// In en, this message translates to:
  /// **'Session overlaps usually have higher market activity.'**
  String get sessionOverlapActivity;

  /// No description provided for @sessionTransition.
  ///
  /// In en, this message translates to:
  /// **'{session} {action} in {duration}'**
  String sessionTransition(String session, String action, String duration);

  /// No description provided for @opens.
  ///
  /// In en, this message translates to:
  /// **'opens'**
  String get opens;

  /// No description provided for @closes.
  ///
  /// In en, this message translates to:
  /// **'closes'**
  String get closes;

  /// No description provided for @technicalSummary.
  ///
  /// In en, this message translates to:
  /// **'Technical Summary'**
  String get technicalSummary;

  /// No description provided for @indicatorEducationDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'We simplify indicators to make them easier to understand. This is not a trading signal or recommendation.'**
  String get indicatorEducationDisclaimer;

  /// No description provided for @technicalSummaryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The technical summary could not be loaded.'**
  String get technicalSummaryLoadFailed;

  /// No description provided for @technicalSummaryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'A technical summary is not available for this market yet.'**
  String get technicalSummaryUnavailable;

  /// No description provided for @trend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get trend;

  /// No description provided for @momentum.
  ///
  /// In en, this message translates to:
  /// **'Momentum'**
  String get momentum;

  /// No description provided for @risk.
  ///
  /// In en, this message translates to:
  /// **'Risk'**
  String get risk;

  /// No description provided for @whatDoesItMean.
  ///
  /// In en, this message translates to:
  /// **'What does it mean?'**
  String get whatDoesItMean;

  /// No description provided for @marketContext.
  ///
  /// In en, this message translates to:
  /// **'Market Context'**
  String get marketContext;

  /// No description provided for @marketEducationDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'An educational summary of current market conditions. This is not a trading signal or recommendation.'**
  String get marketEducationDisclaimer;

  /// No description provided for @marketContextLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The market context could not be loaded.'**
  String get marketContextLoadFailed;

  /// No description provided for @insufficientMarketData.
  ///
  /// In en, this message translates to:
  /// **'There is not enough data to assess market conditions.'**
  String get insufficientMarketData;

  /// No description provided for @why.
  ///
  /// In en, this message translates to:
  /// **'Why?'**
  String get why;

  /// No description provided for @riskLevel.
  ///
  /// In en, this message translates to:
  /// **'Risk level'**
  String get riskLevel;

  /// No description provided for @economicCalendar.
  ///
  /// In en, this message translates to:
  /// **'Economic Calendar'**
  String get economicCalendar;

  /// No description provided for @economicEventRiskDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Economic events may cause prices to move faster. This is risk information, not a trading signal.'**
  String get economicEventRiskDisclaimer;

  /// No description provided for @economicCalendarLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The economic calendar could not be loaded.'**
  String get economicCalendarLoadFailed;

  /// No description provided for @noUpcomingEconomicEvents.
  ///
  /// In en, this message translates to:
  /// **'There are no relevant upcoming economic events.'**
  String get noUpcomingEconomicEvents;

  /// No description provided for @marketOverview.
  ///
  /// In en, this message translates to:
  /// **'Market Overview'**
  String get marketOverview;

  /// No description provided for @priceDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Price data is unavailable.'**
  String get priceDataUnavailable;

  /// No description provided for @latestDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The latest data is unavailable.'**
  String get latestDataUnavailable;

  /// No description provided for @waitingForUpdate.
  ///
  /// In en, this message translates to:
  /// **'Waiting for an update...'**
  String get waitingForUpdate;

  /// No description provided for @updatedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Updated just now'**
  String get updatedJustNow;

  /// No description provided for @updatedSecondsAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated {seconds} seconds ago'**
  String updatedSecondsAgo(int seconds);

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at {time}'**
  String updatedAt(String time);

  /// No description provided for @chartDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Chart data is unavailable.'**
  String get chartDataUnavailable;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @bullishBias.
  ///
  /// In en, this message translates to:
  /// **'Bullish bias'**
  String get bullishBias;

  /// No description provided for @bearishBias.
  ///
  /// In en, this message translates to:
  /// **'Bearish bias'**
  String get bearishBias;

  /// No description provided for @neutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get neutral;

  /// No description provided for @historicalLevelsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Chart levels are historical references, not transaction recommendations.'**
  String get historicalLevelsDisclaimer;

  /// No description provided for @candlestickHelp.
  ///
  /// In en, this message translates to:
  /// **'Candlesticks: green = price rose, red = price fell.'**
  String get candlestickHelp;

  /// No description provided for @movementRisk.
  ///
  /// In en, this message translates to:
  /// **'Movement risk: {risk}. Support and resistance are reference levels from the visible data.'**
  String movementRisk(String risk);

  /// No description provided for @currentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current {price}'**
  String currentPrice(String price);

  /// No description provided for @addInstrument.
  ///
  /// In en, this message translates to:
  /// **'Add instrument'**
  String get addInstrument;

  /// No description provided for @searchInstrument.
  ///
  /// In en, this message translates to:
  /// **'Search instruments'**
  String get searchInstrument;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @addedOn.
  ///
  /// In en, this message translates to:
  /// **'Added: {date}'**
  String addedOn(String date);

  /// No description provided for @noPreviousAnalysis.
  ///
  /// In en, this message translates to:
  /// **'No previous analysis'**
  String get noPreviousAnalysis;

  /// No description provided for @lastAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Last analysis: {date}'**
  String lastAnalysis(String date);

  /// No description provided for @invalidTargetPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid target price.'**
  String get invalidTargetPrice;

  /// No description provided for @noteMaximumCharacters.
  ///
  /// In en, this message translates to:
  /// **'Notes can contain up to 200 characters.'**
  String get noteMaximumCharacters;

  /// No description provided for @priceAlertCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create the price alert.'**
  String get priceAlertCreateFailed;

  /// No description provided for @priceAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'{instrument} Price Alert'**
  String priceAlertTitle(String instrument);

  /// No description provided for @currentMarketPrice.
  ///
  /// In en, this message translates to:
  /// **'Current price {price}'**
  String currentMarketPrice(String price);

  /// No description provided for @notifyWhenPrice.
  ///
  /// In en, this message translates to:
  /// **'Notify me when the price...'**
  String get notifyWhenPrice;

  /// No description provided for @risesAbove.
  ///
  /// In en, this message translates to:
  /// **'Rises above'**
  String get risesAbove;

  /// No description provided for @fallsBelow.
  ///
  /// In en, this message translates to:
  /// **'Falls below'**
  String get fallsBelow;

  /// No description provided for @targetPrice.
  ///
  /// In en, this message translates to:
  /// **'Target Price'**
  String get targetPrice;

  /// No description provided for @optionalNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get optionalNote;

  /// No description provided for @priceAlertNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Example: review current market conditions'**
  String get priceAlertNoteHint;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @createPriceAlertButton.
  ///
  /// In en, this message translates to:
  /// **'Create Price Alert'**
  String get createPriceAlertButton;

  /// No description provided for @myPriceAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Price Alerts'**
  String get myPriceAlertsTitle;

  /// No description provided for @priceAlertDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Price alerts notify you when a condition is reached. They are not trading signals or recommendations.'**
  String get priceAlertDisclaimer;

  /// No description provided for @priceAlertsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Price alerts could not be loaded.'**
  String get priceAlertsLoadFailed;

  /// No description provided for @noPriceAlerts.
  ///
  /// In en, this message translates to:
  /// **'No price alerts yet. Create one to be notified when a price reaches a specific level.'**
  String get noPriceAlerts;

  /// No description provided for @triggered.
  ///
  /// In en, this message translates to:
  /// **'Triggered'**
  String get triggered;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @monitored.
  ///
  /// In en, this message translates to:
  /// **'Monitored'**
  String get monitored;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @deleteAlert.
  ///
  /// In en, this message translates to:
  /// **'Delete alert'**
  String get deleteAlert;

  /// No description provided for @actual.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get actual;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @goldEventExplanation.
  ///
  /// In en, this message translates to:
  /// **'Why it matters: USD data often affects Gold and may increase XAU/USD volatility.'**
  String get goldEventExplanation;

  /// No description provided for @currencyEventExplanation.
  ///
  /// In en, this message translates to:
  /// **'Why it matters: {currency} events directly relate to {instrument} and may increase volatility.'**
  String currencyEventExplanation(String currency, String instrument);

  /// No description provided for @genericEventExplanation.
  ///
  /// In en, this message translates to:
  /// **'Why it matters: This event may affect sentiment and volatility for {instrument}.'**
  String genericEventExplanation(String instrument);

  /// No description provided for @savedFilters.
  ///
  /// In en, this message translates to:
  /// **'Saved filters'**
  String get savedFilters;

  /// No description provided for @saveCurrentFilter.
  ///
  /// In en, this message translates to:
  /// **'Save current filter'**
  String get saveCurrentFilter;

  /// No description provided for @presetName.
  ///
  /// In en, this message translates to:
  /// **'Filter name'**
  String get presetName;

  /// No description provided for @noSavedFilters.
  ///
  /// In en, this message translates to:
  /// **'No saved filters yet.'**
  String get noSavedFilters;

  /// No description provided for @filterPresetSaved.
  ///
  /// In en, this message translates to:
  /// **'Filter saved.'**
  String get filterPresetSaved;

  /// No description provided for @filterPresetFailed.
  ///
  /// In en, this message translates to:
  /// **'Saved filters could not be updated.'**
  String get filterPresetFailed;

  /// No description provided for @recentMarkets.
  ///
  /// In en, this message translates to:
  /// **'Recently analyzed'**
  String get recentMarkets;

  /// No description provided for @favoriteMarkets.
  ///
  /// In en, this message translates to:
  /// **'Favorite markets'**
  String get favoriteMarkets;

  /// No description provided for @outcomeSummary.
  ///
  /// In en, this message translates to:
  /// **'30-day outcome summary'**
  String get outcomeSummary;

  /// No description provided for @targetHitRate.
  ///
  /// In en, this message translates to:
  /// **'Target hit rate'**
  String get targetHitRate;

  /// No description provided for @stopHitRate.
  ///
  /// In en, this message translates to:
  /// **'Risk-limit hit rate'**
  String get stopHitRate;

  /// No description provided for @resolvedSample.
  ///
  /// In en, this message translates to:
  /// **'{count} resolved analyses'**
  String resolvedSample(int count);

  /// Title on the biometric app-lock screen
  ///
  /// In en, this message translates to:
  /// **'Trade Pilot is locked'**
  String get appLocked;

  /// Explains that the session survived and only needs unlocking
  ///
  /// In en, this message translates to:
  /// **'Your session is still active. Verify your identity to continue.'**
  String get appLockedDescription;

  /// Button that starts the biometric prompt on the lock screen
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// System biometric prompt reason when unlocking an existing session
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to unlock Trade Pilot'**
  String get biometricUnlockReason;

  /// Shown when biometric verification fails on the lock screen
  ///
  /// In en, this message translates to:
  /// **'Could not verify your identity. Try again or sign out.'**
  String get unlockFailed;

  /// Profile setting that gates the app behind biometrics
  ///
  /// In en, this message translates to:
  /// **'Biometric lock'**
  String get biometricLock;

  /// Subtitle when the biometric lock setting is on
  ///
  /// In en, this message translates to:
  /// **'Ask for fingerprint or face each time the app opens'**
  String get biometricLockOn;

  /// Subtitle when the biometric lock setting is off
  ///
  /// In en, this message translates to:
  /// **'Open straight to your dashboard'**
  String get biometricLockOff;

  /// Shown when the device has no enrolled biometrics
  ///
  /// In en, this message translates to:
  /// **'No fingerprint or face unlock is set up on this device.'**
  String get biometricLockUnavailable;

  /// No description provided for @riskMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeframe Risk Map'**
  String get riskMapTitle;

  /// No description provided for @riskMapDescription.
  ///
  /// In en, this message translates to:
  /// **'Compare technical risk across timeframes before creating an analysis.'**
  String get riskMapDescription;

  /// No description provided for @riskMapLoading.
  ///
  /// In en, this message translates to:
  /// **'Scanning timeframes...'**
  String get riskMapLoading;

  /// No description provided for @riskMapError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the risk map.'**
  String get riskMapError;

  /// No description provided for @riskMapOverallWait.
  ///
  /// In en, this message translates to:
  /// **'Overall: wait'**
  String get riskMapOverallWait;

  /// No description provided for @riskMapOverallCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare timeframe options'**
  String get riskMapOverallCompare;

  /// No description provided for @riskMapRelativeNote.
  ///
  /// In en, this message translates to:
  /// **'This map indicates relative risk, not guaranteed profit.'**
  String get riskMapRelativeNote;

  /// No description provided for @riskLow.
  ///
  /// In en, this message translates to:
  /// **'Low risk'**
  String get riskLow;

  /// No description provided for @riskModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate risk'**
  String get riskModerate;

  /// No description provided for @riskHigh.
  ///
  /// In en, this message translates to:
  /// **'High risk'**
  String get riskHigh;

  /// No description provided for @riskUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get riskUnavailable;

  /// No description provided for @riskEligible.
  ///
  /// In en, this message translates to:
  /// **'Eligible'**
  String get riskEligible;

  /// No description provided for @riskCaution.
  ///
  /// In en, this message translates to:
  /// **'Caution'**
  String get riskCaution;

  /// No description provided for @riskWait.
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get riskWait;

  /// No description provided for @riskSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get riskSelected;

  /// No description provided for @useTimeframe.
  ///
  /// In en, this message translates to:
  /// **'Use {timeframe}'**
  String useTimeframe(String timeframe);

  /// No description provided for @standardRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'TP Standard Trading Rules'**
  String get standardRulesTitle;

  /// No description provided for @standardRulesDescription.
  ///
  /// In en, this message translates to:
  /// **'Broker-neutral rules used as the basis for Trade Pilot estimates.'**
  String get standardRulesDescription;

  /// No description provided for @standardRulesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading the standard trading rules...'**
  String get standardRulesLoading;

  /// No description provided for @standardRulesError.
  ///
  /// In en, this message translates to:
  /// **'Standard trading rules are temporarily unavailable.'**
  String get standardRulesError;

  /// No description provided for @ruleVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get ruleVersion;

  /// No description provided for @fixedConversionRate.
  ///
  /// In en, this message translates to:
  /// **'Fixed conversion rate'**
  String get fixedConversionRate;

  /// No description provided for @contractSize.
  ///
  /// In en, this message translates to:
  /// **'Contract size'**
  String get contractSize;

  /// No description provided for @tradingSession.
  ///
  /// In en, this message translates to:
  /// **'Trading session'**
  String get tradingSession;

  /// No description provided for @initialMargin.
  ///
  /// In en, this message translates to:
  /// **'Initial margin'**
  String get initialMargin;

  /// No description provided for @facilityFee.
  ///
  /// In en, this message translates to:
  /// **'Facility fee'**
  String get facilityFee;

  /// No description provided for @rollover.
  ///
  /// In en, this message translates to:
  /// **'Rollover'**
  String get rollover;

  /// No description provided for @spread.
  ///
  /// In en, this message translates to:
  /// **'Spread'**
  String get spread;

  /// No description provided for @hecticSpread.
  ///
  /// In en, this message translates to:
  /// **'Hectic-market spread'**
  String get hecticSpread;

  /// No description provided for @minimumMovement.
  ///
  /// In en, this message translates to:
  /// **'Minimum movement'**
  String get minimumMovement;

  /// No description provided for @limitStopRange.
  ///
  /// In en, this message translates to:
  /// **'Limit/stop range'**
  String get limitStopRange;

  /// No description provided for @priceSource.
  ///
  /// In en, this message translates to:
  /// **'Price source / guidance'**
  String get priceSource;

  /// No description provided for @settlement.
  ///
  /// In en, this message translates to:
  /// **'Settlement'**
  String get settlement;

  /// No description provided for @allowedLotRange.
  ///
  /// In en, this message translates to:
  /// **'Allowed open position'**
  String get allowedLotRange;

  /// No description provided for @minimumDeposit.
  ///
  /// In en, this message translates to:
  /// **'Minimum deposit'**
  String get minimumDeposit;

  /// No description provided for @marginControls.
  ///
  /// In en, this message translates to:
  /// **'Margin controls'**
  String get marginControls;

  /// No description provided for @profitLossFormula.
  ///
  /// In en, this message translates to:
  /// **'P/L formula'**
  String get profitLossFormula;

  /// No description provided for @sourceDocument.
  ///
  /// In en, this message translates to:
  /// **'Source document'**
  String get sourceDocument;

  /// No description provided for @topUpCredit.
  ///
  /// In en, this message translates to:
  /// **'Top Up Credit'**
  String get topUpCredit;

  /// No description provided for @analysisQuotaHourTitle.
  ///
  /// In en, this message translates to:
  /// **'Hourly limit reached'**
  String get analysisQuotaHourTitle;

  /// No description provided for @analysisQuotaHourMessage.
  ///
  /// In en, this message translates to:
  /// **'Your hourly analysis quota is used up. Try again after the wait period ends.'**
  String get analysisQuotaHourMessage;

  /// No description provided for @analysisQuotaDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached'**
  String get analysisQuotaDayTitle;

  /// No description provided for @analysisQuotaDayMessage.
  ///
  /// In en, this message translates to:
  /// **'Your free daily quota is used up. Use a credit or try again tomorrow.'**
  String get analysisQuotaDayMessage;

  /// No description provided for @analysisQuotaConcurrentTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis still in progress'**
  String get analysisQuotaConcurrentTitle;

  /// No description provided for @analysisQuotaConcurrentMessage.
  ///
  /// In en, this message translates to:
  /// **'Wait for the previous analysis to finish before creating another one.'**
  String get analysisQuotaConcurrentMessage;

  /// No description provided for @analysisQuotaUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis could not be created'**
  String get analysisQuotaUnknownTitle;

  /// No description provided for @analysisQuotaUnknownMessage.
  ///
  /// In en, this message translates to:
  /// **'An analysis limit is active. Please try again later.'**
  String get analysisQuotaUnknownMessage;

  /// No description provided for @analysisQuotaUsage.
  ///
  /// In en, this message translates to:
  /// **'Used {used} of {limit}'**
  String analysisQuotaUsage(int used, int limit);

  /// No description provided for @analysisRetryAfter.
  ///
  /// In en, this message translates to:
  /// **'Try again in {duration}'**
  String analysisRetryAfter(String duration);

  /// No description provided for @analysisSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count} seconds'**
  String analysisSeconds(int count);

  /// No description provided for @analysisMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String analysisMinutes(int count);

  /// No description provided for @analysisQuotaBalances.
  ///
  /// In en, this message translates to:
  /// **'Hourly: {hourly} • Daily: {daily} • Credits: {credits}'**
  String analysisQuotaBalances(int hourly, int daily, int credits);

  /// No description provided for @analysisCreditConsumed.
  ///
  /// In en, this message translates to:
  /// **'1 credit used. Remaining balance: {balance} credits.'**
  String analysisCreditConsumed(int balance);

  /// No description provided for @analysisCreditConsumedUnknownBalance.
  ///
  /// In en, this message translates to:
  /// **'1 credit used. Your balance is being refreshed.'**
  String get analysisCreditConsumedUnknownBalance;

  /// No description provided for @creditBalance.
  ///
  /// In en, this message translates to:
  /// **'Credit balance'**
  String get creditBalance;

  /// No description provided for @creditBalanceFailed.
  ///
  /// In en, this message translates to:
  /// **'Balance could not be loaded.'**
  String get creditBalanceFailed;

  /// No description provided for @topUpScanQris.
  ///
  /// In en, this message translates to:
  /// **'Scan this QRIS with your banking or e-wallet app, then submit the request below.'**
  String get topUpScanQris;

  /// No description provided for @topUpQrisUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The QRIS code could not be loaded.'**
  String get topUpQrisUnavailable;

  /// No description provided for @topUpRatePerCredit.
  ///
  /// In en, this message translates to:
  /// **'{amount} per credit'**
  String topUpRatePerCredit(String amount);

  /// No description provided for @topUpAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (Rupiah)'**
  String get topUpAmountLabel;

  /// No description provided for @topUpAmountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 50000'**
  String get topUpAmountHint;

  /// No description provided for @topUpChooseAmount.
  ///
  /// In en, this message translates to:
  /// **'Choose a top-up amount'**
  String get topUpChooseAmount;

  /// No description provided for @topUpContinuePayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to payment'**
  String get topUpContinuePayment;

  /// No description provided for @topUpPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment details'**
  String get topUpPayment;

  /// No description provided for @topUpChangeAmount.
  ///
  /// In en, this message translates to:
  /// **'Change amount'**
  String get topUpChangeAmount;

  /// No description provided for @topUpPaymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} to receive {credits} credit'**
  String topUpPaymentSummary(String amount, int credits);

  /// No description provided for @topUpCreditsPreview.
  ///
  /// In en, this message translates to:
  /// **'You will receive {credits} credit'**
  String topUpCreditsPreview(int credits);

  /// No description provided for @topUpAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount you paid.'**
  String get topUpAmountRequired;

  /// No description provided for @topUpAmountTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Minimum top-up is {amount}.'**
  String topUpAmountTooSmall(String amount);

  /// No description provided for @topUpReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment reference (optional)'**
  String get topUpReferenceLabel;

  /// No description provided for @topUpReferenceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. sender name or transfer reference'**
  String get topUpReferenceHint;

  /// No description provided for @topUpProofLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment proof (optional)'**
  String get topUpProofLabel;

  /// No description provided for @topUpAddProof.
  ///
  /// In en, this message translates to:
  /// **'Attach proof'**
  String get topUpAddProof;

  /// No description provided for @topUpChangeProof.
  ///
  /// In en, this message translates to:
  /// **'Change proof'**
  String get topUpChangeProof;

  /// No description provided for @topUpProofAttached.
  ///
  /// In en, this message translates to:
  /// **'Proof attached'**
  String get topUpProofAttached;

  /// No description provided for @topUpSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit top-up request'**
  String get topUpSubmit;

  /// No description provided for @topUpSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Top-up request submitted. It will be reviewed shortly.'**
  String get topUpSubmitted;

  /// No description provided for @topUpProofFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment proof could not be uploaded. The request was not submitted.'**
  String get topUpProofFailed;

  /// No description provided for @topUpConfigFailed.
  ///
  /// In en, this message translates to:
  /// **'Top-up configuration could not be loaded.'**
  String get topUpConfigFailed;

  /// No description provided for @topUpHistory.
  ///
  /// In en, this message translates to:
  /// **'Top-up history'**
  String get topUpHistory;

  /// No description provided for @topUpHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not made any top-up requests yet.'**
  String get topUpHistoryEmpty;

  /// No description provided for @topUpLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get topUpLoadMore;

  /// No description provided for @topUpApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get topUpApproved;

  /// No description provided for @topUpRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get topUpRejected;

  /// No description provided for @topUpCreditsGranted.
  ///
  /// In en, this message translates to:
  /// **'{credits} credit added'**
  String topUpCreditsGranted(int credits);

  /// No description provided for @topUpReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Admin note: {note}'**
  String topUpReviewNote(String note);

  /// No description provided for @topUpRequestedCredits.
  ///
  /// In en, this message translates to:
  /// **'{credits} credit'**
  String topUpRequestedCredits(int credits);

  /// No description provided for @errSessionExpiredRelogin.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Please sign in again.'**
  String get errSessionExpiredRelogin;

  /// No description provided for @errSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended.'**
  String get errSessionExpired;

  /// No description provided for @errSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get errSignInAgain;

  /// No description provided for @errNoConnection.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your internet connection.'**
  String get errNoConnection;

  /// No description provided for @errServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server.'**
  String get errServerUnreachable;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errGeneric;

  /// No description provided for @errServerProblem.
  ///
  /// In en, this message translates to:
  /// **'The server is having trouble. Try again shortly.'**
  String get errServerProblem;

  /// No description provided for @errConnectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'The connection timed out. Please try again.'**
  String get errConnectionTimeout;

  /// No description provided for @errRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'The request was cancelled.'**
  String get errRequestCancelled;

  /// No description provided for @errInstrumentRequired.
  ///
  /// In en, this message translates to:
  /// **'Instrument cannot be empty.'**
  String get errInstrumentRequired;

  /// No description provided for @errInstrumentUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Instrument is not supported.'**
  String get errInstrumentUnsupported;

  /// No description provided for @errTimeframeUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Timeframe is not supported.'**
  String get errTimeframeUnsupported;

  /// No description provided for @errInvalidServerResponse.
  ///
  /// In en, this message translates to:
  /// **'The server response was not valid.'**
  String get errInvalidServerResponse;

  /// No description provided for @errInvalidProfileResponse.
  ///
  /// In en, this message translates to:
  /// **'The profile response from the server was not valid.'**
  String get errInvalidProfileResponse;

  /// No description provided for @errDisplayNameLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be 2 to {max} characters.'**
  String errDisplayNameLength(int max);

  /// No description provided for @errCurrentPasswordWrong.
  ///
  /// In en, this message translates to:
  /// **'Your current password is incorrect.'**
  String get errCurrentPasswordWrong;

  /// No description provided for @errPasswordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'Password does not meet the security requirements.'**
  String get errPasswordTooWeak;

  /// No description provided for @errProfileInvalid.
  ///
  /// In en, this message translates to:
  /// **'Profile data is not valid. Check your entries.'**
  String get errProfileInvalid;

  /// No description provided for @errChangePasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change your password. Please try again.'**
  String get errChangePasswordFailed;

  /// No description provided for @errUpdateProfileFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update your profile. Please try again.'**
  String get errUpdateProfileFailed;

  /// No description provided for @errTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get errTooManyAttempts;

  /// No description provided for @errDeleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete your account. Please try again.'**
  String get errDeleteAccountFailed;

  /// No description provided for @errSecurityAnswerWrong.
  ///
  /// In en, this message translates to:
  /// **'That security answer is incorrect.'**
  String get errSecurityAnswerWrong;

  /// No description provided for @errCredentialsWrong.
  ///
  /// In en, this message translates to:
  /// **'That email or password is incorrect.'**
  String get errCredentialsWrong;

  /// No description provided for @errQuotaReached.
  ///
  /// In en, this message translates to:
  /// **'Analysis quota reached. Try again later.'**
  String get errQuotaReached;

  /// No description provided for @errAiTimeout.
  ///
  /// In en, this message translates to:
  /// **'The AI is taking longer than usual to analyze. Please try again.'**
  String get errAiTimeout;

  /// No description provided for @errAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed. Please try again.'**
  String get errAnalysisFailed;

  /// No description provided for @errAnalysisSlowSync.
  ///
  /// In en, this message translates to:
  /// **'The AI took a long time to respond. The analysis may still have been created — data will sync automatically.'**
  String get errAnalysisSlowSync;

  /// No description provided for @errDateRangeInvalid.
  ///
  /// In en, this message translates to:
  /// **'The start date cannot be later than the end date.'**
  String get errDateRangeInvalid;

  /// No description provided for @errNoteTooLong5000.
  ///
  /// In en, this message translates to:
  /// **'Notes are limited to 5,000 characters.'**
  String get errNoteTooLong5000;

  /// No description provided for @errNoteNotSaved.
  ///
  /// In en, this message translates to:
  /// **'The note was not saved. Check your connection and try again.'**
  String get errNoteNotSaved;

  /// No description provided for @errNoteSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The note could not be saved. Please try again.'**
  String get errNoteSaveFailed;

  /// No description provided for @errBalanceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Credit balance could not be loaded.'**
  String get errBalanceLoadFailed;

  /// No description provided for @errTopupConfigLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Top-up configuration could not be loaded.'**
  String get errTopupConfigLoadFailed;

  /// No description provided for @errTopupHistoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Top-up history could not be loaded. Pull to try again.'**
  String get errTopupHistoryLoadFailed;

  /// No description provided for @errTopupSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'The top-up request could not be sent.'**
  String get errTopupSubmitFailed;

  /// No description provided for @errTopupAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'The top-up amount must be greater than 0.'**
  String get errTopupAmountPositive;

  /// No description provided for @errLivePricesFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load live prices.'**
  String get errLivePricesFailed;

  /// No description provided for @errMarketDataPartial.
  ///
  /// In en, this message translates to:
  /// **'Some market data is not available yet.'**
  String get errMarketDataPartial;

  /// No description provided for @errTechnicalDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load technical data.'**
  String get errTechnicalDataFailed;

  /// No description provided for @errPriceAlertsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load price alerts.'**
  String get errPriceAlertsLoadFailed;

  /// No description provided for @errPriceAlertCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the price alert.'**
  String get errPriceAlertCreateFailed;

  /// No description provided for @errPriceAlertDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the price alert.'**
  String get errPriceAlertDeleteFailed;

  /// No description provided for @errTargetPricePositive.
  ///
  /// In en, this message translates to:
  /// **'Target price must be greater than 0.'**
  String get errTargetPricePositive;

  /// No description provided for @errNoteTooLong200.
  ///
  /// In en, this message translates to:
  /// **'Notes are limited to 200 characters.'**
  String get errNoteTooLong200;

  /// No description provided for @errWatchlistLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your watchlist.'**
  String get errWatchlistLoadFailed;

  /// No description provided for @errWatchlistUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update your watchlist.'**
  String get errWatchlistUpdateFailed;

  /// No description provided for @errNotificationsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Notifications could not be loaded. Pull to try again.'**
  String get errNotificationsLoadFailed;

  /// No description provided for @errNotificationPrefsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load notification preferences.'**
  String get errNotificationPrefsLoadFailed;

  /// No description provided for @errNotificationPrefsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save notification preferences.'**
  String get errNotificationPrefsSaveFailed;

  /// No description provided for @errMarketSessionReminderSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the market session reminder.'**
  String get errMarketSessionReminderSaveFailed;

  /// No description provided for @errQuietHoursSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save notification quiet hours.'**
  String get errQuietHoursSaveFailed;

  /// No description provided for @errPushPermissionSystem.
  ///
  /// In en, this message translates to:
  /// **'Notification permission has not been granted in system settings.'**
  String get errPushPermissionSystem;

  /// No description provided for @errPushEnableFailed.
  ///
  /// In en, this message translates to:
  /// **'Push notifications could not be enabled.'**
  String get errPushEnableFailed;

  /// No description provided for @errPushPrefsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Mobile push preferences could not be saved.'**
  String get errPushPrefsSaveFailed;

  /// No description provided for @errPushTokenUnavailable.
  ///
  /// In en, this message translates to:
  /// **'A push token is not available on this device.'**
  String get errPushTokenUnavailable;

  /// No description provided for @errPushRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'The server could not register this device for push.'**
  String get errPushRegisterFailed;

  /// No description provided for @errPushTokenSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'The push token could not be synced.'**
  String get errPushTokenSyncFailed;

  /// No description provided for @appErrInstrumentUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This instrument does not support the Adaptive Position Plan.'**
  String get appErrInstrumentUnsupported;

  /// No description provided for @appErrNoStandardPlan.
  ///
  /// In en, this message translates to:
  /// **'The Standard Plan or Standard Trading Rules TP is not available.'**
  String get appErrNoStandardPlan;

  /// No description provided for @appErrFundsPositive.
  ///
  /// In en, this message translates to:
  /// **'Available trading funds must be greater than 0.'**
  String get appErrFundsPositive;

  /// No description provided for @appErrMaxLossPositive.
  ///
  /// In en, this message translates to:
  /// **'The maximum loss limit must be greater than 0.'**
  String get appErrMaxLossPositive;

  /// No description provided for @appErrMaxLossExceedsFunds.
  ///
  /// In en, this message translates to:
  /// **'The maximum loss limit cannot exceed available funds.'**
  String get appErrMaxLossExceedsFunds;

  /// No description provided for @appErrExposureNegative.
  ///
  /// In en, this message translates to:
  /// **'Running exposure cannot be negative.'**
  String get appErrExposureNegative;

  /// No description provided for @appErrTpRulesInvalid.
  ///
  /// In en, this message translates to:
  /// **'The Standard Trading Rules TP does not match or is not valid.'**
  String get appErrTpRulesInvalid;

  /// No description provided for @appErrLevelsInvalid.
  ///
  /// In en, this message translates to:
  /// **'The Standard Plan Entry and Stop Loss levels are not valid.'**
  String get appErrLevelsInvalid;

  /// No description provided for @appErrSnapshotConflict.
  ///
  /// In en, this message translates to:
  /// **'The technical snapshot conflicts with the market direction.'**
  String get appErrSnapshotConflict;

  /// No description provided for @appErrBelowMinimumLot.
  ///
  /// In en, this message translates to:
  /// **'Funds or loss limit are not enough for this tier\'s minimum lot.'**
  String get appErrBelowMinimumLot;

  /// No description provided for @mindsetPacingTitle.
  ///
  /// In en, this message translates to:
  /// **'Evaluation pause'**
  String get mindsetPacingTitle;

  /// No description provided for @mindsetPacingBody.
  ///
  /// In en, this message translates to:
  /// **'Several analyses were created close together. Consider leaving time to evaluate the previous one.'**
  String get mindsetPacingBody;

  /// No description provided for @mindsetConcentrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Instrument focus'**
  String get mindsetConcentrationTitle;

  /// No description provided for @mindsetConcentrationBody.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} analyses currently loaded focus on {instrument}.'**
  String mindsetConcentrationBody(int count, int total, String instrument);

  /// No description provided for @mindsetPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyses still pending'**
  String get mindsetPendingTitle;

  /// No description provided for @mindsetPendingBody.
  ///
  /// In en, this message translates to:
  /// **'{count} analyses currently loaded have not finished evaluating. Use the next result as reflection, not certainty.'**
  String mindsetPendingBody(int count);

  /// No description provided for @mindsetJournalTitle.
  ///
  /// In en, this message translates to:
  /// **'Note consistency'**
  String get mindsetJournalTitle;

  /// No description provided for @mindsetJournalBody.
  ///
  /// In en, this message translates to:
  /// **'Personal notes are still rare. Writing your initial reasoning helps reflection once an evaluation arrives.'**
  String get mindsetJournalBody;

  /// No description provided for @localTraderSentiment.
  ///
  /// In en, this message translates to:
  /// **'Local trader sentiment'**
  String get localTraderSentiment;

  /// No description provided for @journalSentimentGated.
  ///
  /// In en, this message translates to:
  /// **'Hidden until at least {entries} entries from {traders} traders are available.'**
  String journalSentimentGated(int entries, int traders);

  /// No description provided for @journalSentimentSample.
  ///
  /// In en, this message translates to:
  /// **'{entries} entries · {days} days'**
  String journalSentimentSample(int entries, int days);

  /// No description provided for @journalSentimentDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'An anonymous aggregate of community journals, not a trading signal.'**
  String get journalSentimentDisclaimer;

  /// No description provided for @personalNote.
  ///
  /// In en, this message translates to:
  /// **'Personal note'**
  String get personalNote;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @notePrivateHint.
  ///
  /// In en, this message translates to:
  /// **'Stored privately in your account and never sent to the AI.'**
  String get notePrivateHint;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Write your reasoning, observations, or lessons…'**
  String get noteHint;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get deleteNote;

  /// No description provided for @noNoteYet.
  ///
  /// In en, this message translates to:
  /// **'No note for this analysis yet.'**
  String get noNoteYet;

  /// No description provided for @newsLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'That news link could not be opened.'**
  String get newsLinkFailed;

  /// No description provided for @newsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'News could not be loaded.'**
  String get newsLoadFailed;

  /// No description provided for @newsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent news yet.'**
  String get newsEmpty;

  /// No description provided for @newsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'News is informational and not an investment recommendation.'**
  String get newsDisclaimer;

  /// No description provided for @newsSourceFallback.
  ///
  /// In en, this message translates to:
  /// **'News source'**
  String get newsSourceFallback;

  /// No description provided for @publicAiPerformanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'An anonymous track record of every Trade Pilot analysis'**
  String get publicAiPerformanceSubtitle;

  /// No description provided for @analyticsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Analytics could not be loaded. Please try again.'**
  String get analyticsLoadFailed;

  /// No description provided for @sessionChangedReopen.
  ///
  /// In en, this message translates to:
  /// **'Your session changed. Please reopen this page.'**
  String get sessionChangedReopen;

  /// No description provided for @analyticsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'These statistics describe analysis habits, not trading profit.'**
  String get analyticsDisclaimer;

  /// No description provided for @analyticsActivitySummary.
  ///
  /// In en, this message translates to:
  /// **'Activity summary'**
  String get analyticsActivitySummary;

  /// No description provided for @analyticsWeeklyActivity.
  ///
  /// In en, this message translates to:
  /// **'Weekly activity'**
  String get analyticsWeeklyActivity;

  /// No description provided for @metricAllAnalyses.
  ///
  /// In en, this message translates to:
  /// **'All analyses'**
  String get metricAllAnalyses;

  /// No description provided for @metricThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get metricThisMonth;

  /// No description provided for @metricThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get metricThisWeek;

  /// No description provided for @metricFeedbackGiven.
  ///
  /// In en, this message translates to:
  /// **'Feedback given'**
  String get metricFeedbackGiven;

  /// No description provided for @metricDominantMode.
  ///
  /// In en, this message translates to:
  /// **'Dominant mode'**
  String get metricDominantMode;

  /// No description provided for @metricOutcomeAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Outcome accuracy'**
  String get metricOutcomeAccuracy;

  /// No description provided for @instrumentRanking.
  ///
  /// In en, this message translates to:
  /// **'Instrument ranking'**
  String get instrumentRanking;

  /// No description provided for @countAnalyses.
  ///
  /// In en, this message translates to:
  /// **'{count} analyses'**
  String countAnalyses(int count);

  /// No description provided for @loadedResults.
  ///
  /// In en, this message translates to:
  /// **'Results currently loaded'**
  String get loadedResults;

  /// No description provided for @analyticsPartialScope.
  ///
  /// In en, this message translates to:
  /// **'Counting only {loaded} of {total} analyses. Load more in History to widen this summary.'**
  String analyticsPartialScope(int loaded, int total);

  /// No description provided for @analyticsFullScope.
  ///
  /// In en, this message translates to:
  /// **'Counting all {loaded} analyses currently available on this device.'**
  String analyticsFullScope(int loaded);

  /// No description provided for @metricEvaluated.
  ///
  /// In en, this message translates to:
  /// **'Evaluated'**
  String get metricEvaluated;

  /// No description provided for @metricPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get metricPending;

  /// No description provided for @metricPositiveOutcomes.
  ///
  /// In en, this message translates to:
  /// **'Positive outcomes'**
  String get metricPositiveOutcomes;

  /// No description provided for @metricNegativeOutcomes.
  ///
  /// In en, this message translates to:
  /// **'Negative outcomes'**
  String get metricNegativeOutcomes;

  /// No description provided for @metricHasNote.
  ///
  /// In en, this message translates to:
  /// **'Has a note'**
  String get metricHasNote;

  /// No description provided for @metricAverageConfidence.
  ///
  /// In en, this message translates to:
  /// **'Average confidence'**
  String get metricAverageConfidence;

  /// No description provided for @metricTopTimeframe.
  ///
  /// In en, this message translates to:
  /// **'Top timeframe'**
  String get metricTopTimeframe;

  /// No description provided for @metricTopInstrument.
  ///
  /// In en, this message translates to:
  /// **'Top instrument'**
  String get metricTopInstrument;

  /// No description provided for @traderMirrorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Trader Mirror could not be loaded.'**
  String get traderMirrorLoadFailed;

  /// No description provided for @traderMirrorDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This habit mirror is retrospective and gives no trading instructions.'**
  String get traderMirrorDisclaimer;

  /// No description provided for @traderMirrorNoHighlights.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to build highlights yet.'**
  String get traderMirrorNoHighlights;

  /// No description provided for @traderMirrorCoverage.
  ///
  /// In en, this message translates to:
  /// **'Covering {days} days · {resolved} completed evaluations'**
  String traderMirrorCoverage(int days, int resolved);

  /// No description provided for @traderMirrorSessions.
  ///
  /// In en, this message translates to:
  /// **'Market sessions'**
  String get traderMirrorSessions;

  /// No description provided for @traderMirrorInstruments.
  ///
  /// In en, this message translates to:
  /// **'Instrument concentration'**
  String get traderMirrorInstruments;

  /// No description provided for @traderMirrorTiming.
  ///
  /// In en, this message translates to:
  /// **'Analysis timing'**
  String get traderMirrorTiming;

  /// No description provided for @traderMirrorPostLoss.
  ///
  /// In en, this message translates to:
  /// **'Patterns after a negative outcome'**
  String get traderMirrorPostLoss;

  /// No description provided for @traderMirrorEvaluationDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Evaluation discipline'**
  String get traderMirrorEvaluationDiscipline;

  /// No description provided for @traderMirrorProcessReflection.
  ///
  /// In en, this message translates to:
  /// **'Process reflection'**
  String get traderMirrorProcessReflection;

  /// No description provided for @traderMirrorSamples.
  ///
  /// In en, this message translates to:
  /// **'{count} samples'**
  String traderMirrorSamples(int count);

  /// No description provided for @traderMirrorBasedOn.
  ///
  /// In en, this message translates to:
  /// **'Based on {count} analyses currently loaded on this device.'**
  String traderMirrorBasedOn(int count);

  /// No description provided for @traderMirrorNeedMore.
  ///
  /// In en, this message translates to:
  /// **'At least 3 analyses are needed for a careful reflection.'**
  String get traderMirrorNeedMore;

  /// No description provided for @traderMirrorGated.
  ///
  /// In en, this message translates to:
  /// **'Needs {need} data points; {have} available.'**
  String traderMirrorGated(String need, int have);

  /// No description provided for @traderMirrorUngated.
  ///
  /// In en, this message translates to:
  /// **'Enough data to show the details.'**
  String get traderMirrorUngated;

  /// No description provided for @traderMirrorNeedMoreGeneric.
  ///
  /// In en, this message translates to:
  /// **'more'**
  String get traderMirrorNeedMoreGeneric;

  /// No description provided for @dailySummaryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The daily briefing could not be loaded.'**
  String get dailySummaryLoadFailed;

  /// No description provided for @dailySummarySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Briefing settings could not be saved.'**
  String get dailySummarySaveFailed;

  /// No description provided for @dailySummaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No briefing for today yet.'**
  String get dailySummaryEmpty;

  /// No description provided for @dailySummaryTimezone.
  ///
  /// In en, this message translates to:
  /// **'Time zone: {timezone}'**
  String dailySummaryTimezone(String timezone);

  /// No description provided for @dailySummaryDeliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Delivery time'**
  String get dailySummaryDeliveryTime;

  /// No description provided for @dailySummaryFullDigest.
  ///
  /// In en, this message translates to:
  /// **'Full digest'**
  String get dailySummaryFullDigest;

  /// No description provided for @dailySummaryQuotaOnly.
  ///
  /// In en, this message translates to:
  /// **'Quota only'**
  String get dailySummaryQuotaOnly;

  /// No description provided for @dailySummaryPreferredSide.
  ///
  /// In en, this message translates to:
  /// **'Preferred side: {side}'**
  String dailySummaryPreferredSide(String side);

  /// No description provided for @guideSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search guide...'**
  String get guideSearchHint;

  /// No description provided for @guideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Knowledge, features, and mindset.'**
  String get guideSubtitle;

  /// No description provided for @guideNoResults.
  ///
  /// In en, this message translates to:
  /// **'No articles found.'**
  String get guideNoResults;

  /// No description provided for @marketChartUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The market chart is not available yet.'**
  String get marketChartUnavailable;

  /// No description provided for @journalCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'The journal could not be checked.'**
  String get journalCheckFailed;

  /// No description provided for @alertStatusLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Alert status could not be loaded.'**
  String get alertStatusLoadFailed;

  /// No description provided for @alertNeedsNotificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Enable notification permission so price alerts can work.'**
  String get alertNeedsNotificationPermission;

  /// No description provided for @alertEnableFailed.
  ///
  /// In en, this message translates to:
  /// **'The alert could not be enabled. Make sure notifications are on and the instrument has a live price feed.'**
  String get alertEnableFailed;

  /// No description provided for @alertDisableFailed.
  ///
  /// In en, this message translates to:
  /// **'The alert could not be disabled. Try again shortly.'**
  String get alertDisableFailed;

  /// No description provided for @fundamentalDriftNone.
  ///
  /// In en, this message translates to:
  /// **'The latest fundamentals still support every original source.'**
  String get fundamentalDriftNone;

  /// No description provided for @fundamentalDriftSome.
  ///
  /// In en, this message translates to:
  /// **'{missing} of {total} original sources are no longer in the latest window.'**
  String fundamentalDriftSome(int missing, int total);

  /// No description provided for @outcomePendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Awaiting result'**
  String get outcomePendingLabel;

  /// No description provided for @outcomePendingBody.
  ///
  /// In en, this message translates to:
  /// **'The market is still running and the system is evaluating whether the TP or SL level was touched.'**
  String get outcomePendingBody;

  /// No description provided for @outcomeTp1Label.
  ///
  /// In en, this message translates to:
  /// **'TP1 Reached'**
  String get outcomeTp1Label;

  /// No description provided for @outcomeTp1Body.
  ///
  /// In en, this message translates to:
  /// **'Price reached the first profit target from the analysis scenario.'**
  String get outcomeTp1Body;

  /// No description provided for @outcomeTp2Label.
  ///
  /// In en, this message translates to:
  /// **'TP2 Reached'**
  String get outcomeTp2Label;

  /// No description provided for @outcomeTp2Body.
  ///
  /// In en, this message translates to:
  /// **'Price reached the second profit target from the analysis scenario.'**
  String get outcomeTp2Body;

  /// No description provided for @outcomeSlLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop Loss Hit'**
  String get outcomeSlLabel;

  /// No description provided for @outcomeSlBody.
  ///
  /// In en, this message translates to:
  /// **'Price reached the risk limit first. This is why a Stop Loss matters in every setup.'**
  String get outcomeSlBody;

  /// No description provided for @outcomeExpiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get outcomeExpiredLabel;

  /// No description provided for @outcomeExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'The analysis window ended without a main target confirmed.'**
  String get outcomeExpiredBody;

  /// No description provided for @outcomeInvalidatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Analysis Invalidated'**
  String get outcomeInvalidatedLabel;

  /// No description provided for @outcomeInvalidatedBody.
  ///
  /// In en, this message translates to:
  /// **'The setup no longer matches the original analysis structure.'**
  String get outcomeInvalidatedBody;

  /// No description provided for @outcomeUnknownLabel.
  ///
  /// In en, this message translates to:
  /// **'Status not available'**
  String get outcomeUnknownLabel;

  /// No description provided for @outcomeUnknownBody.
  ///
  /// In en, this message translates to:
  /// **'The outcome cannot be evaluated yet.'**
  String get outcomeUnknownBody;

  /// No description provided for @whyNotHigherConfidence.
  ///
  /// In en, this message translates to:
  /// **'Why isn\'t confidence higher?'**
  String get whyNotHigherConfidence;

  /// No description provided for @citedSources.
  ///
  /// In en, this message translates to:
  /// **'Cited sources'**
  String get citedSources;

  /// No description provided for @awaitConfirmationNotice.
  ///
  /// In en, this message translates to:
  /// **'Wait for confirmation — the AI does not recommend Buy or Sell right now.'**
  String get awaitConfirmationNotice;

  /// No description provided for @instrumentRulesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Instrument rules are not available.'**
  String get instrumentRulesUnavailable;

  /// No description provided for @tradingRulesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Trading rules could not be loaded.'**
  String get tradingRulesLoadFailed;

  /// No description provided for @tradingRulesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Trading rules are not available.'**
  String get tradingRulesUnavailable;

  /// No description provided for @adaptivePlanIntro.
  ///
  /// In en, this message translates to:
  /// **'Turn the Standard Plan into a position size that fits your funds and loss limit.'**
  String get adaptivePlanIntro;

  /// No description provided for @adaptivePlanDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This calculator does not change AI levels and does not send orders. Enter free funds after deducting margin used by other positions.'**
  String get adaptivePlanDisclaimer;

  /// No description provided for @availableTradingFunds.
  ///
  /// In en, this message translates to:
  /// **'Available trading funds'**
  String get availableTradingFunds;

  /// No description provided for @maxLossLimit.
  ///
  /// In en, this message translates to:
  /// **'Maximum loss limit'**
  String get maxLossLimit;

  /// No description provided for @buildPositionPlan.
  ///
  /// In en, this message translates to:
  /// **'Build position plan'**
  String get buildPositionPlan;

  /// No description provided for @notRecommended.
  ///
  /// In en, this message translates to:
  /// **'Not recommended'**
  String get notRecommended;

  /// No description provided for @adaptivePlanFootnote.
  ///
  /// In en, this message translates to:
  /// **'Day trading only. Estimates exclude spread, slippage, fees, VAT, rollover, and broker auto-liquidation.'**
  String get adaptivePlanFootnote;

  /// No description provided for @lossToSl.
  ///
  /// In en, this message translates to:
  /// **'Loss to SL'**
  String get lossToSl;

  /// No description provided for @entryZone.
  ///
  /// In en, this message translates to:
  /// **'Entry zone'**
  String get entryZone;

  /// No description provided for @primaryScenario.
  ///
  /// In en, this message translates to:
  /// **'Primary scenario'**
  String get primaryScenario;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
