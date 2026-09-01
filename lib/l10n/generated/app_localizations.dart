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

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

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
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loginDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your market analysis.'**
  String get loginDescription;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'name@email.com'**
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
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

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
  /// **'Register'**
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

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

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
