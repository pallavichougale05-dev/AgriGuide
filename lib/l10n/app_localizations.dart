import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('mr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AgriGuide'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'AgriGuide Home'**
  String get homeTitle;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to AgriGuide'**
  String get homeWelcome;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Smart farming assistance for your farm'**
  String get homeSubtitle;

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

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'Marathi'**
  String get marathi;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmer;

  /// No description provided for @farmWeather.
  ///
  /// In en, this message translates to:
  /// **'Farm Weather'**
  String get farmWeather;

  /// No description provided for @viewWeather.
  ///
  /// In en, this message translates to:
  /// **'View Weather Conditions'**
  String get viewWeather;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @weatherCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current Weather'**
  String get weatherCurrent;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @rain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get rain;

  /// No description provided for @rainfall.
  ///
  /// In en, this message translates to:
  /// **'Rainfall'**
  String get rainfall;

  /// No description provided for @humidityLabel.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidityLabel;

  /// No description provided for @windLabel.
  ///
  /// In en, this message translates to:
  /// **'km/h Wind'**
  String get windLabel;

  /// No description provided for @rainLabel.
  ///
  /// In en, this message translates to:
  /// **'mm Rain'**
  String get rainLabel;

  /// No description provided for @searchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search Location'**
  String get searchLocation;

  /// No description provided for @searchLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search for a city, town or district.'**
  String get searchLocationSubtitle;

  /// No description provided for @farmLocation.
  ///
  /// In en, this message translates to:
  /// **'Farm Location'**
  String get farmLocation;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @locationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Location Not Found'**
  String get locationNotFound;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get clearSearch;

  /// No description provided for @refreshWeather.
  ///
  /// In en, this message translates to:
  /// **'Refresh Weather'**
  String get refreshWeather;

  /// No description provided for @loadingFarmWeather.
  ///
  /// In en, this message translates to:
  /// **'Loading farm weather...'**
  String get loadingFarmWeather;

  /// No description provided for @weatherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Weather Unavailable'**
  String get weatherUnavailable;

  /// No description provided for @unableSearchLocation.
  ///
  /// In en, this message translates to:
  /// **'Unable to search for the location.'**
  String get unableSearchLocation;

  /// No description provided for @unableLoadWeather.
  ///
  /// In en, this message translates to:
  /// **'Unable to load weather information.'**
  String get unableLoadWeather;

  /// No description provided for @unableGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Unable to get your current location.'**
  String get unableGetLocation;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required.'**
  String get locationPermissionRequired;

  /// No description provided for @fiveDayForecast.
  ///
  /// In en, this message translates to:
  /// **'5-Day Forecast'**
  String get fiveDayForecast;

  /// No description provided for @farmActivityAdvice.
  ///
  /// In en, this message translates to:
  /// **'Farm Activity Advice'**
  String get farmActivityAdvice;

  /// No description provided for @weatherDataNote.
  ///
  /// In en, this message translates to:
  /// **'Weather data is fetched through the AgriGuide backend.'**
  String get weatherDataNote;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @cropRecommendationAction.
  ///
  /// In en, this message translates to:
  /// **'Crop Recommendation'**
  String get cropRecommendationAction;

  /// No description provided for @diseaseDetectionAction.
  ///
  /// In en, this message translates to:
  /// **'Disease Detection & Solution'**
  String get diseaseDetectionAction;

  /// No description provided for @agriAssistantAction.
  ///
  /// In en, this message translates to:
  /// **'Farming Assistant'**
  String get agriAssistantAction;

  /// No description provided for @farmingTip.
  ///
  /// In en, this message translates to:
  /// **'Farming Tip'**
  String get farmingTip;

  /// No description provided for @farmingTipText.
  ///
  /// In en, this message translates to:
  /// **'Watering crops early in the morning can reduce evaporation and improve water absorption.'**
  String get farmingTipText;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @farmingTools.
  ///
  /// In en, this message translates to:
  /// **'Farming Tools and Assistance'**
  String get farmingTools;

  /// No description provided for @recommend.
  ///
  /// In en, this message translates to:
  /// **'RECOMMEND'**
  String get recommend;

  /// No description provided for @protect.
  ///
  /// In en, this message translates to:
  /// **'PROTECT'**
  String get protect;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'PLAN'**
  String get plan;

  /// No description provided for @assist.
  ///
  /// In en, this message translates to:
  /// **'ASSIST'**
  String get assist;

  /// No description provided for @knowledgeAndRecords.
  ///
  /// In en, this message translates to:
  /// **'KNOWLEDGE & RECORDS'**
  String get knowledgeAndRecords;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @disease.
  ///
  /// In en, this message translates to:
  /// **'Disease'**
  String get disease;

  /// No description provided for @weatherForecast.
  ///
  /// In en, this message translates to:
  /// **'Weather Forecast'**
  String get weatherForecast;

  /// No description provided for @farmingQuestions.
  ///
  /// In en, this message translates to:
  /// **'Farming Questions'**
  String get farmingQuestions;

  /// No description provided for @knowledgeHub.
  ///
  /// In en, this message translates to:
  /// **'Farming Knowledge'**
  String get knowledgeHub;

  /// No description provided for @farmDiary.
  ///
  /// In en, this message translates to:
  /// **'My Farm'**
  String get farmDiary;

  /// No description provided for @cropRecommendationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find suitable crops and varieties'**
  String get cropRecommendationSubtitle;

  /// No description provided for @diseaseDetectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Detect crop problems and get guidance'**
  String get diseaseDetectionSubtitle;

  /// No description provided for @farmWeatherSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View weather and farm conditions'**
  String get farmWeatherSubtitle;

  /// No description provided for @agriAssistantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask questions about farming'**
  String get agriAssistantSubtitle;

  /// No description provided for @knowledgeHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get farming knowledge, experiences and guidance'**
  String get knowledgeHubSubtitle;

  /// No description provided for @farmDiarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep a record of your farm activities'**
  String get farmDiarySubtitle;

  /// No description provided for @cropIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Find the Best Fit for Your Farm'**
  String get cropIntroTitle;

  /// No description provided for @cropIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get your top 5 crop recommendations with suitable varieties.'**
  String get cropIntroSubtitle;

  /// No description provided for @farmConditions.
  ///
  /// In en, this message translates to:
  /// **'Farm Conditions'**
  String get farmConditions;

  /// No description provided for @farmConditionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the available soil and weather values.'**
  String get farmConditionsSubtitle;

  /// No description provided for @nitrogen.
  ///
  /// In en, this message translates to:
  /// **'Nitrogen'**
  String get nitrogen;

  /// No description provided for @phosphorus.
  ///
  /// In en, this message translates to:
  /// **'Phosphorus'**
  String get phosphorus;

  /// No description provided for @potassium.
  ///
  /// In en, this message translates to:
  /// **'Potassium'**
  String get potassium;

  /// No description provided for @soilPh.
  ///
  /// In en, this message translates to:
  /// **'Soil pH'**
  String get soilPh;

  /// No description provided for @nitrogenUnit.
  ///
  /// In en, this message translates to:
  /// **'kg/ha'**
  String get nitrogenUnit;

  /// No description provided for @phosphorusUnit.
  ///
  /// In en, this message translates to:
  /// **'kg/ha'**
  String get phosphorusUnit;

  /// No description provided for @potassiumUnit.
  ///
  /// In en, this message translates to:
  /// **'kg/ha'**
  String get potassiumUnit;

  /// No description provided for @temperatureUnit.
  ///
  /// In en, this message translates to:
  /// **'°C'**
  String get temperatureUnit;

  /// No description provided for @humidityUnit.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get humidityUnit;

  /// No description provided for @phUnit.
  ///
  /// In en, this message translates to:
  /// **'pH'**
  String get phUnit;

  /// No description provided for @rainfallUnit.
  ///
  /// In en, this message translates to:
  /// **'mm'**
  String get rainfallUnit;

  /// No description provided for @getTop5Recommendations.
  ///
  /// In en, this message translates to:
  /// **'Get Top 5 Recommendations'**
  String get getTop5Recommendations;

  /// No description provided for @top5Recommendations.
  ///
  /// In en, this message translates to:
  /// **'Top 5 Recommendations'**
  String get top5Recommendations;

  /// No description provided for @recommendationVarietyInfo.
  ///
  /// In en, this message translates to:
  /// **'Each recommendation includes a suitable variety.'**
  String get recommendationVarietyInfo;

  /// No description provided for @variety.
  ///
  /// In en, this message translates to:
  /// **'Variety'**
  String get variety;

  /// No description provided for @match.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get match;

  /// No description provided for @suitableCropInfo.
  ///
  /// In en, this message translates to:
  /// **'Suitable crop and variety based on the recommendation result.'**
  String get suitableCropInfo;

  /// No description provided for @fillFarmConditions.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all farm conditions.'**
  String get fillFarmConditions;

  /// No description provided for @invalidNumbers.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid numbers in all fields.'**
  String get invalidNumbers;

  /// No description provided for @noCropRecommendations.
  ///
  /// In en, this message translates to:
  /// **'No suitable crop recommendations were found. Please check the entered farm conditions.'**
  String get noCropRecommendations;

  /// No description provided for @unableCropRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Unable to get crop recommendations.\nPlease check your internet connection and try again.'**
  String get unableCropRecommendations;

  /// No description provided for @diseaseIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Identify Crop Problems Early'**
  String get diseaseIntroTitle;

  /// No description provided for @diseaseIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload an image of your crop to check for possible diseases and receive guidance.'**
  String get diseaseIntroSubtitle;

  /// No description provided for @uploadCropImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Crop Image'**
  String get uploadCropImage;

  /// No description provided for @uploadCropImageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use a clear image of the affected leaf or crop.'**
  String get uploadCropImageSubtitle;

  /// No description provided for @chooseImageSource.
  ///
  /// In en, this message translates to:
  /// **'Choose Image Source'**
  String get chooseImageSource;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get takePhoto;

  /// No description provided for @takePhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the camera to capture a crop image'**
  String get takePhotoSubtitle;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @gallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select an existing crop image'**
  String get gallerySubtitle;

  /// No description provided for @noImageSelected.
  ///
  /// In en, this message translates to:
  /// **'No Image Selected'**
  String get noImageSelected;

  /// No description provided for @imageHint.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or choose from gallery'**
  String get imageHint;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @detectDisease.
  ///
  /// In en, this message translates to:
  /// **'Detect Disease'**
  String get detectDisease;

  /// No description provided for @detectionResult.
  ///
  /// In en, this message translates to:
  /// **'Detection Result'**
  String get detectionResult;

  /// No description provided for @suggestedSolution.
  ///
  /// In en, this message translates to:
  /// **'Suggested Solution'**
  String get suggestedSolution;

  /// No description provided for @selectCropImageFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a crop image first.'**
  String get selectCropImageFirst;

  /// No description provided for @unableSelectImage.
  ///
  /// In en, this message translates to:
  /// **'Unable to select the image.\nPlease try Camera or Gallery again.'**
  String get unableSelectImage;

  /// No description provided for @diseaseBackendPending.
  ///
  /// In en, this message translates to:
  /// **'Disease detection is not connected yet.\nYour image is ready for the disease-analysis backend.'**
  String get diseaseBackendPending;

  /// No description provided for @diseaseBackendNote.
  ///
  /// In en, this message translates to:
  /// **'Disease analysis will be available after the detection backend is connected.'**
  String get diseaseBackendNote;

  /// No description provided for @assistantGreeting.
  ///
  /// In en, this message translates to:
  /// **'Namaste! I am Farming Assistant. Ask me about crops, soil, irrigation, pests, or farming practices.'**
  String get assistantGreeting;

  /// No description provided for @tryAsking.
  ///
  /// In en, this message translates to:
  /// **'Try Asking'**
  String get tryAsking;

  /// No description provided for @askAboutFarming.
  ///
  /// In en, this message translates to:
  /// **'Ask about farming...'**
  String get askAboutFarming;

  /// No description provided for @assistantThinking.
  ///
  /// In en, this message translates to:
  /// **'Farming Assistant is thinking...'**
  String get assistantThinking;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @askQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a Question'**
  String get askQuestion;

  /// No description provided for @clearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get clearChat;

  /// No description provided for @assistantError.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the assistant.'**
  String get assistantError;

  /// No description provided for @assistantWelcome.
  ///
  /// In en, this message translates to:
  /// **'Ask any question about farming.'**
  String get assistantWelcome;

  /// No description provided for @cropQuestions.
  ///
  /// In en, this message translates to:
  /// **'Crop Questions'**
  String get cropQuestions;

  /// No description provided for @soilQuestions.
  ///
  /// In en, this message translates to:
  /// **'Soil Questions'**
  String get soilQuestions;

  /// No description provided for @irrigationQuestions.
  ///
  /// In en, this message translates to:
  /// **'Irrigation Questions'**
  String get irrigationQuestions;

  /// No description provided for @pestQuestions.
  ///
  /// In en, this message translates to:
  /// **'Pest Questions'**
  String get pestQuestions;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Farmer Community'**
  String get community;

  /// No description provided for @knowledgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Farming Knowledge'**
  String get knowledgeTitle;

  /// No description provided for @knowledgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share real farming experiences, learn from other farmers, and discuss farming challenges.'**
  String get knowledgeSubtitle;

  /// No description provided for @searchPosts.
  ///
  /// In en, this message translates to:
  /// **'Search farmer experiences...'**
  String get searchPosts;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @cropCategory.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get cropCategory;

  /// No description provided for @diseaseCategory.
  ///
  /// In en, this message translates to:
  /// **'Disease'**
  String get diseaseCategory;

  /// No description provided for @irrigationCategory.
  ///
  /// In en, this message translates to:
  /// **'Irrigation'**
  String get irrigationCategory;

  /// No description provided for @soilCategory.
  ///
  /// In en, this message translates to:
  /// **'Soil'**
  String get soilCategory;

  /// No description provided for @harvestCategory.
  ///
  /// In en, this message translates to:
  /// **'Harvest'**
  String get harvestCategory;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @shareExperience.
  ///
  /// In en, this message translates to:
  /// **'Share Experience'**
  String get shareExperience;

  /// No description provided for @writePost.
  ///
  /// In en, this message translates to:
  /// **'Write a Post'**
  String get writePost;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @writeComment.
  ///
  /// In en, this message translates to:
  /// **'Write a Comment'**
  String get writeComment;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @liked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get liked;

  /// No description provided for @likes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likes;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @noPostsFound.
  ///
  /// In en, this message translates to:
  /// **'No experiences found'**
  String get noPostsFound;

  /// No description provided for @beFirstToComment.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment'**
  String get beFirstToComment;

  /// No description provided for @shareYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Share your farming experience'**
  String get shareYourExperience;

  /// No description provided for @postTitle.
  ///
  /// In en, this message translates to:
  /// **'Post Title'**
  String get postTitle;

  /// No description provided for @postDescription.
  ///
  /// In en, this message translates to:
  /// **'Write about your experience'**
  String get postDescription;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @publishPost.
  ///
  /// In en, this message translates to:
  /// **'Publish Post'**
  String get publishPost;

  /// No description provided for @postPublished.
  ///
  /// In en, this message translates to:
  /// **'Post Published'**
  String get postPublished;

  /// No description provided for @privateDiary.
  ///
  /// In en, this message translates to:
  /// **'Private Farm Diary'**
  String get privateDiary;

  /// No description provided for @myFarmDiary.
  ///
  /// In en, this message translates to:
  /// **'My Farm'**
  String get myFarmDiary;

  /// No description provided for @activityHistory.
  ///
  /// In en, this message translates to:
  /// **'Activity History'**
  String get activityHistory;

  /// No description provided for @addActivity.
  ///
  /// In en, this message translates to:
  /// **'Add Activity'**
  String get addActivity;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// No description provided for @recordFarmActivity.
  ///
  /// In en, this message translates to:
  /// **'Record Farm Activity'**
  String get recordFarmActivity;

  /// No description provided for @saveActivity.
  ///
  /// In en, this message translates to:
  /// **'Save Activity'**
  String get saveActivity;

  /// No description provided for @noActivities.
  ///
  /// In en, this message translates to:
  /// **'No activities recorded yet'**
  String get noActivities;

  /// No description provided for @activityDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get activityDate;

  /// No description provided for @cropOrField.
  ///
  /// In en, this message translates to:
  /// **'Crop / Field'**
  String get cropOrField;

  /// No description provided for @enterCropOrField.
  ///
  /// In en, this message translates to:
  /// **'Enter crop or field name'**
  String get enterCropOrField;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Farm Activity'**
  String get activity;

  /// No description provided for @enterActivity.
  ///
  /// In en, this message translates to:
  /// **'Enter farm activity'**
  String get enterActivity;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @enterNotes.
  ///
  /// In en, this message translates to:
  /// **'Enter additional notes'**
  String get enterNotes;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login / Register'**
  String get login;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get signIn;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Login Required'**
  String get loginRequired;

  /// No description provided for @loginToUseDiary.
  ///
  /// In en, this message translates to:
  /// **'Please log in to access your farm records.'**
  String get loginToUseDiary;

  /// No description provided for @loginToShareExperience.
  ///
  /// In en, this message translates to:
  /// **'Please log in to share your farming experience.'**
  String get loginToShareExperience;

  /// No description provided for @loginToLike.
  ///
  /// In en, this message translates to:
  /// **'Please log in to like this experience.'**
  String get loginToLike;

  /// No description provided for @loginToComment.
  ///
  /// In en, this message translates to:
  /// **'Please log in to comment on this experience.'**
  String get loginToComment;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

  /// No description provided for @diary.
  ///
  /// In en, this message translates to:
  /// **'My Farm'**
  String get diary;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get continueButton;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No Results Found'**
  String get noResults;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required fields.'**
  String get required;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get somethingWentWrong;

  /// No description provided for @checkInternet.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection.'**
  String get checkInternet;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get unknownError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cropRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Crop Recommendation'**
  String get cropRecommendation;

  /// No description provided for @diseaseDetection.
  ///
  /// In en, this message translates to:
  /// **'Disease Detection & Solution'**
  String get diseaseDetection;

  /// No description provided for @agriAssistant.
  ///
  /// In en, this message translates to:
  /// **'Farming Assistant'**
  String get agriAssistant;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @partlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly Cloudy'**
  String get partlyCloudy;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'mr': return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
