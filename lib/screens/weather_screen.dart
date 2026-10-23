import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';


// ============================================================
// FARM WEATHER SCREEN
// ============================================================
//
// PURPOSE:
//
// Shows weather information for the farmer's selected location.
//
// LOCATION OPTIONS:
//
// 1. GPS
//    Phone location
//       ↓
//    Latitude + Longitude
//       ↓
//    FastAPI
//       ↓
//    Weather
//
// 2. MANUAL SEARCH
//    Farmer types a location
//       ↓
//    FastAPI location search
//       ↓
//    Location results
//       ↓
//    Farmer selects location
//       ↓
//    Latitude + Longitude
//       ↓
//    FastAPI
//       ↓
//    Weather
//
// LOCALIZATION:
//
// The screen supports:
// English
// Marathi
//
// UI labels come from AppLocalizations.
//
// Dynamic weather conditions and farm advice are also
// translated according to the selected language.
//
// ============================================================


class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  // Creates the mutable state for the Weather screen.
  //
  // Weather and location can change while the screen is open.
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}


// ============================================================
// WEATHER SCREEN STATE
// ============================================================

class _WeatherScreenState extends State<WeatherScreen> {

  // ----------------------------------------------------------
  // WEATHER DATA
  // ----------------------------------------------------------

  // Stores the weather returned by FastAPI.
  WeatherData? weatherData;


  // ----------------------------------------------------------
  // LOCATION
  // ----------------------------------------------------------

  // Default latitude.
  //
  // Kolhapur is used when the screen first opens.
  double selectedLatitude = 16.70;

  // Default longitude.
  double selectedLongitude = 74.24;

  // Text displayed to the farmer.
  String selectedLocationName = 'Kolhapur, Maharashtra';


  // ----------------------------------------------------------
  // LOADING / ERROR
  // ----------------------------------------------------------

  // True while weather is being fetched.
  bool isLoading = true;

  // Error message shown when something fails.
  String? errorMessage;


  // ==========================================================
  // INITIAL LOAD
  // ==========================================================

  @override
  void initState() {
    super.initState();

    // Loads weather for the default location when
    // the screen first opens.
    loadWeather();
  }


  // ==========================================================
  // LOAD WEATHER
  // ==========================================================

  Future<void> loadWeather() async {

    // --------------------------------------------------------
    // SHOW LOADING STATE
    // --------------------------------------------------------

    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }


    try {

      // ------------------------------------------------------
      // SEND SELECTED COORDINATES TO APISERVICE
      // ------------------------------------------------------
      //
      // ApiService sends:
      //
      // GET /weather/current
      //
      // with latitude and longitude.
      // ------------------------------------------------------

      final WeatherData data = await ApiService.getWeather(
        latitude: selectedLatitude,
        longitude: selectedLongitude,
      );


      // ------------------------------------------------------
      // PREVENT UPDATING CLOSED SCREEN
      // ------------------------------------------------------

      if (!mounted) {
        return;
      }


      // ------------------------------------------------------
      // SAVE WEATHER DATA
      // ------------------------------------------------------

      setState(() {
        weatherData = data;
        isLoading = false;
        errorMessage = null;
      });

    } catch (error) {

      // ------------------------------------------------------
      // PREVENT UPDATING CLOSED SCREEN
      // ------------------------------------------------------

      if (!mounted) {
        return;
      }


      // ------------------------------------------------------
      // USER-FRIENDLY ERROR
      // ------------------------------------------------------

      final l10n = AppLocalizations.of(context)!;

      setState(() {
        isLoading = false;
        errorMessage =
            '${l10n.weatherUnavailable}\n${l10n.checkInternet}';
      });
    }
  }


  // ==========================================================
  // GET CURRENT GPS LOCATION
  // ==========================================================

  Future<void> useCurrentLocation() async {

    final l10n = AppLocalizations.of(context)!;

    try {

      // ------------------------------------------------------
      // CHECK LOCATION SERVICE
      // ------------------------------------------------------

      // Checks whether GPS/location services are enabled.
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();


      if (!serviceEnabled) {

        if (!mounted) {
          return;
        }

        showLocationMessage(
          l10n.locationPermissionRequired,
        );

        return;
      }


      // ------------------------------------------------------
      // CHECK PERMISSION
      // ------------------------------------------------------

      final LocationPermission permission =
          await Geolocator.checkPermission();

      LocationPermission currentPermission = permission;


      // ------------------------------------------------------
      // ASK FOR PERMISSION
      // ------------------------------------------------------

      if (currentPermission == LocationPermission.denied) {

        currentPermission =
            await Geolocator.requestPermission();
      }


      // ------------------------------------------------------
      // PERMISSION DENIED
      // ------------------------------------------------------

      if (currentPermission == LocationPermission.denied) {

        if (!mounted) {
          return;
        }

        showLocationMessage(
          l10n.locationPermissionRequired,
        );

        return;
      }


      // ------------------------------------------------------
      // PERMANENTLY DENIED
      // ------------------------------------------------------

      if (currentPermission ==
          LocationPermission.deniedForever) {

        if (!mounted) {
          return;
        }

        showLocationPermissionSettingsMessage();

        return;
      }


      // ------------------------------------------------------
      // GET GPS POSITION
      // ------------------------------------------------------

      // High accuracy gives better coordinates for weather.
      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,

          // The GPS does not need continuous updates.
          distanceFilter: 100,
        ),
      );


      // ------------------------------------------------------
      // SAVE LOCATION
      // ------------------------------------------------------

      if (!mounted) {
        return;
      }


      setState(() {

        // Save GPS latitude.
        selectedLatitude = position.latitude;

        // Save GPS longitude.
        selectedLongitude = position.longitude;

        // Display GPS label.
        selectedLocationName = l10n.currentLocation;

        // Clear previous error.
        errorMessage = null;
      });


      // ------------------------------------------------------
      // LOAD WEATHER FOR GPS LOCATION
      // ------------------------------------------------------

      await loadWeather();

    } catch (error) {

      if (!mounted) {
        return;
      }


      // ------------------------------------------------------
      // USER-FRIENDLY LOCATION ERROR
      // ------------------------------------------------------

      setState(() {
        errorMessage = l10n.unableGetLocation;
      });


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.unableGetLocation,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  // ==========================================================
  // LOCATION SEARCH
  // ==========================================================

  void openLocationSearch() {

    showModalBottomSheet<void>(
      context: context,

      // Allows sheet to move above keyboard.
      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (context) {

        return LocationSearchSheet(
          onLocationSelected:
              (LocationSearchResult result) async {

            // Close search sheet.
            Navigator.pop(context);


            if (!mounted) {
              return;
            }


            // ------------------------------------------------
            // SAVE SELECTED LOCATION
            // ------------------------------------------------

            setState(() {

              selectedLatitude = result.latitude;

              selectedLongitude = result.longitude;

              selectedLocationName = result.displayName;

              errorMessage = null;
            });


            // ------------------------------------------------
            // LOAD WEATHER FOR SELECTED LOCATION
            // ------------------------------------------------

            await loadWeather();
          },
        );
      },
    );
  }


  // ==========================================================
  // LOCATION MESSAGE
  // ==========================================================

  void showLocationMessage(
    String message,
  ) {

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  // ==========================================================
  // OPEN APP LOCATION SETTINGS
  // ==========================================================

  void showLocationPermissionSettingsMessage() {

    final l10n = AppLocalizations.of(context)!;

    showDialog<void>(
      context: context,

      builder: (context) {

        return AlertDialog(

          title: Text(
            l10n.locationPermissionRequired,
          ),

          content: Text(
            l10n.locationPermissionRequired,
          ),

          actions: [

            // ------------------------------------------------
            // CLOSE DIALOG
            // ------------------------------------------------

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: Text(
                l10n.cancel,
              ),
            ),


            // ------------------------------------------------
            // OPEN APP SETTINGS
            // ------------------------------------------------

            TextButton(
              onPressed: () async {

                Navigator.pop(context);

                await Geolocator.openAppSettings();
              },

              child: Text(
                l10n.openSettings,
              ),
            ),
          ],
        );
      },
    );
  }


  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(

      backgroundColor:
          const Color(0xFFF7F8F2),


      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(

        backgroundColor:
            const Color(0xFF168A52),

        foregroundColor:
            Colors.white,

        elevation: 0,

        title: Text(

          l10n.farmWeather,

          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [

          // --------------------------------------------------
          // REFRESH BUTTON
          // --------------------------------------------------

          IconButton(

            onPressed:
                isLoading
                    ? null
                    : loadWeather,

            tooltip:
                l10n.refreshWeather,

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),


      // ======================================================
      // BODY
      // ======================================================

      body:
          SafeArea(
        child:
            buildBody(),
      ),
    );
  }


  // ==========================================================
  // BODY STATE
  // ==========================================================

  Widget buildBody() {

    // --------------------------------------------------------
    // LOADING STATE
    // --------------------------------------------------------

    if (isLoading) {
      return buildLoadingState();
    }


    // --------------------------------------------------------
    // ERROR STATE
    // --------------------------------------------------------

    if (errorMessage != null) {
      return buildErrorState();
    }


    // --------------------------------------------------------
    // SAFETY FALLBACK
    // --------------------------------------------------------

    if (weatherData == null) {
      return buildErrorState();
    }


    // --------------------------------------------------------
    // NORMAL WEATHER UI
    // --------------------------------------------------------

    return buildWeatherContent();
  }


  // ==========================================================
  // LOADING STATE
  // ==========================================================

  Widget buildLoadingState() {

    final l10n = AppLocalizations.of(context)!;

    return Center(

      child:
          Column(

        mainAxisSize:
            MainAxisSize.min,

        children: [

          const CircularProgressIndicator(
            color:
                Color(0xFF3D8B47),
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            l10n.loadingFarmWeather,

            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF707B73),
            ),
          ),
        ],
      ),
    );
  }


  // ==========================================================
  // ERROR STATE
  // ==========================================================

  Widget buildErrorState() {

    final l10n = AppLocalizations.of(context)!;

    return Center(

      child:
          Padding(

        padding:
            const EdgeInsets.all(24),

        child:
            Column(

          mainAxisSize:
              MainAxisSize.min,

          children: [

            Container(

              width: 70,

              height: 70,

              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFFFCEBEB),
                shape:
                    BoxShape.circle,
              ),

              child:
                  const Icon(
                Icons.cloud_off_rounded,
                size: 34,
                color:
                    Color(0xFFB65B5B),
              ),
            ),


            const SizedBox(
              height: 14,
            ),


            Text(

              l10n.weatherUnavailable,

              style:
                  const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
                color:
                    Color(0xFF344238),
              ),
            ),


            const SizedBox(
              height: 6,
            ),


            Text(

              errorMessage ??
                  l10n.somethingWentWrong,

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                fontSize: 11,
                height: 1.4,
                color:
                    Color(0xFF788178),
              ),
            ),


            const SizedBox(
              height: 17,
            ),


            ElevatedButton.icon(

              onPressed:
                  isLoading
                      ? null
                      : loadWeather,

              icon:
                  const Icon(
                Icons.refresh_rounded,
              ),

              label:
                  Text(
                l10n.tryAgain,
              ),

              style:
                  ElevatedButton.styleFrom(

                backgroundColor:
                    const Color(0xFF168A52),

                foregroundColor:
                    Colors.white,

                elevation: 0,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ==========================================================
  // COMPLETE WEATHER CONTENT
  // ==========================================================

  Widget buildWeatherContent() {

    final CurrentWeather current =
        weatherData!.current;


    return RefreshIndicator(

      // Pull down to refresh weather.
      onRefresh:
          loadWeather,

      color:
          const Color(0xFF3D8B47),


      child:
          SingleChildScrollView(

        physics:
            const AlwaysScrollableScrollPhysics(
          parent:
              BouncingScrollPhysics(),
        ),

        padding:
            const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          28,
        ),

        child:
            Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ------------------------------------------------
            // LOCATION CARD
            // ------------------------------------------------

            buildLocationCard(),


            const SizedBox(
              height: 16,
            ),


            // ------------------------------------------------
            // CURRENT WEATHER
            // ------------------------------------------------

            buildCurrentWeatherCard(
              current,
            ),


            const SizedBox(
              height: 20,
            ),


            // ------------------------------------------------
            // WEATHER STATISTICS
            // ------------------------------------------------

            buildWeatherStats(
              current,
            ),


            const SizedBox(
              height: 22,
            ),


            Text(

              AppLocalizations.of(context)!
                  .fiveDayForecast,

              style:
                  const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
                color:
                    Color(0xFF25362A),
              ),
            ),


            const SizedBox(
              height: 12,
            ),


            // ------------------------------------------------
            // FORECAST
            // ------------------------------------------------

            buildForecastList(),


            const SizedBox(
              height: 20,
            ),


            // ------------------------------------------------
            // FARM ADVICE
            // ------------------------------------------------

            buildFarmAdvice(
              current,
            ),


            const SizedBox(
              height: 16,
            ),


            buildDataNote(),
          ],
        ),
      ),
    );
  }


  // ==========================================================
  // LOCATION CARD
  // ==========================================================

  Widget buildLocationCard() {

    final l10n = AppLocalizations.of(context)!;

    return Container(

      width:
          double.infinity,

      padding:
          const EdgeInsets.all(14),


      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        border:
            Border.all(
          color:
              const Color(0xFFE0E6DD),
        ),
      ),


      child:
          Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // --------------------------------------------------
          // SELECTED LOCATION
          // --------------------------------------------------

          Row(

            children: [

              Container(

                width: 42,

                height: 42,

                decoration:
                    BoxDecoration(

                  color:
                      const Color(0xFFE7F3E3),

                  borderRadius:
                      BorderRadius.circular(13),
                ),

                child:
                    const Icon(
                  Icons.location_on_rounded,

                  color:
                      Color(0xFF3F8748),

                  size: 22,
                ),
              ),


              const SizedBox(
                width: 10,
              ),


              Expanded(

                child:
                    Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(

                      l10n.farmLocation,

                      style:
                          const TextStyle(
                        fontSize: 9.5,
                        color:
                            Color(0xFF7B857C),
                      ),
                    ),


                    const SizedBox(
                      height: 3,
                    ),


                    Text(

                      selectedLocationName,

                      maxLines: 2,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF344239),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),


          const SizedBox(
            height: 13,
          ),


          // --------------------------------------------------
          // LOCATION ACTIONS
          // --------------------------------------------------

          Row(

            children: [

              Expanded(

                child:
                    OutlinedButton.icon(

                  onPressed:
                      isLoading
                          ? null
                          : useCurrentLocation,

                  icon:
                      const Icon(
                    Icons.my_location_rounded,
                    size: 18,
                  ),

                  label:
                      Text(
                    l10n.useCurrentLocation,
                  ),

                  style:
                      OutlinedButton.styleFrom(

                    foregroundColor:
                        const Color(0xFF327A45),

                    side:
                        const BorderSide(
                      color:
                          Color(0xFF327A45),
                    ),

                    minimumSize:
                        const Size(
                      0,
                      46,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),


              const SizedBox(
                width: 9,
              ),


              Expanded(

                child:
                    ElevatedButton.icon(

                  onPressed:
                      isLoading
                          ? null
                          : openLocationSearch,

                  icon:
                      const Icon(
                    Icons.search_rounded,
                    size: 18,
                  ),

                  label:
                      Text(
                    l10n.search,
                  ),

                  style:
                      ElevatedButton.styleFrom(

                    backgroundColor:
                        const Color(0xFF168A52),

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    minimumSize:
                        const Size(
                      0,
                      46,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // ==========================================================
  // CURRENT WEATHER CARD
  // ==========================================================

  Widget buildCurrentWeatherCard(
    CurrentWeather current,
  ) {

    final l10n = AppLocalizations.of(context)!;

    return Container(

      width:
          double.infinity,

      padding:
          const EdgeInsets.all(20),


      decoration:
          BoxDecoration(

        color:
            const Color(0xFF246C4A),

        borderRadius:
            BorderRadius.circular(24),
      ),


      child:
          Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(

            l10n.weatherCurrent,

            style:
                const TextStyle(
              fontSize: 13,
              color:
                  Color(0xFFD8E5DB),
            ),
          ),


          const SizedBox(
            height: 11,
          ),


          Row(

            children: [

              // ------------------------------------------------
              // WEATHER ICON
              // ------------------------------------------------

              Container(

                width: 70,

                height: 70,

                decoration:
                    BoxDecoration(

                  color:
                      const Color(0xFF3A7D5B),

                  borderRadius:
                      BorderRadius.circular(21),
                ),

                child:
                    Icon(

                  weatherIcon(
                    current.weatherCode,
                  ),

                  size: 42,

                  color:
                      const Color(0xFFE5EEE7),
                ),
              ),


              const SizedBox(
                width: 15,
              ),


              Expanded(

                child:
                    Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    // ------------------------------------------------
                    // TEMPERATURE
                    // ------------------------------------------------

                    Row(

                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Text(

                          current.temperature
                              .toStringAsFixed(1),

                          style:
                              const TextStyle(

                            fontSize: 43,

                            height: 0.95,

                            fontWeight:
                                FontWeight.w800,

                            color:
                                Colors.white,
                          ),
                        ),


                        const Text(

                          '°C',

                          style:
                              TextStyle(

                            fontSize: 17,

                            fontWeight:
                                FontWeight.w700,

                            color:
                                Color(0xFFD8E5DB),
                          ),
                        ),
                      ],
                    ),


                    const SizedBox(
                      height: 6,
                    ),


                    Text(

                      localizedWeatherCondition(
                        current.weatherCode,
                      ),

                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),


          const SizedBox(
            height: 17,
          ),


          // ------------------------------------------------
          // QUICK WEATHER ADVICE
          // ------------------------------------------------

          Container(

            width:
                double.infinity,

            padding:
                const EdgeInsets.all(12),


            decoration:
                BoxDecoration(

              color:
                  const Color(0xFF347955),

              borderRadius:
                  BorderRadius.circular(14),
            ),


            child:
                Row(

              children: [

                const Icon(

                  Icons.agriculture_rounded,

                  size: 18,

                  color:
                      Color(0xFFF2D46B),
                ),


                const SizedBox(
                  width: 8,
                ),


                Expanded(

                  child:
                      Text(

                    weatherAdvice(
                      current.weatherCode,
                    ),

                    style:
                        const TextStyle(
                      fontSize: 10.5,
                      height: 1.35,
                      color:
                          Color(0xFFE0E9E2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ==========================================================
  // WEATHER STATISTICS
  // ==========================================================

  Widget buildWeatherStats(
  CurrentWeather current,
  ) {

    final l10n = AppLocalizations.of(context)!;

    return Row(

      children: [

        Expanded(

          child:
              buildWeatherStat(

            icon:
                Icons.water_drop_outlined,

            value:
                '${current.humidity.toStringAsFixed(0)}%',

            label:
                l10n.humidity,
          ),
        ),


        const SizedBox(
          width: 9,
        ),


        Expanded(

          child:
              buildWeatherStat(

            icon:
                Icons.air_rounded,

            value:
                current.windSpeed
                    .toStringAsFixed(1),

            label:
                l10n.windLabel,
          ),
        ),


        const SizedBox(
          width: 9,
        ),


        Expanded(

          child:
              buildWeatherStat(

            icon:
                Icons.water_outlined,

            value:
                current.rainfall
                    .toStringAsFixed(1),

            label:
                l10n.rainLabel,
          ),
        ),
      ],
    );
  }


  // ==========================================================
  // WEATHER STAT CARD
  // ==========================================================

  Widget buildWeatherStat({

    required IconData icon,

    required String value,

    required String label,
  }) {

    return Container(

      padding:
          const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 13,
      ),


      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(17),

        border:
            Border.all(
          color:
              const Color(0xFFE2E7DF),
        ),
      ),


      child:
          Column(

        children: [

          Icon(

            icon,

            size: 21,

            color:
                const Color(0xFF3F8750),
          ),


          const SizedBox(
            height: 6,
          ),


          Text(

            value,

            style:
                const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF344239),
            ),
          ),


          const SizedBox(
            height: 3,
          ),


          Text(

            label,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              fontSize: 8,
              color:
                  Color(0xFF7A847C),
            ),
          ),
        ],
      ),
    );
  }


  // ==========================================================
  // FORECAST LIST
  // ==========================================================

  Widget buildForecastList() {

    // Gets the real forecast returned by FastAPI.
    final List<WeatherForecast> forecast =
        weatherData!.forecast;


    return Column(

      children:
          forecast.map(
        (day) {

          return Padding(

            padding:
                const EdgeInsets.only(
              bottom: 9,
            ),

            child:
                buildForecastCard(
              day,
            ),
          );
        },
      ).toList(),
    );
  }


  // ==========================================================
  // FORECAST CARD
  // ==========================================================

  Widget buildForecastCard(
    WeatherForecast day,
  ) {

    //final l10n = AppLocalizations.of(context)!;

    return Container(

      width:
          double.infinity,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 13,
      ),


      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(17),

        border:
            Border.all(
          color:
              const Color(0xFFE2E7DF),
        ),
      ),


      child:
          Row(

        children: [

          // --------------------------------------------------
          // WEATHER ICON
          // --------------------------------------------------

          Container(

            width: 43,

            height: 43,

            decoration:
                BoxDecoration(

              color:
                  const Color(0xFFEAF3E5),

              borderRadius:
                  BorderRadius.circular(13),
            ),

            child:
                Icon(

              weatherIcon(
                day.weatherCode,
              ),

              size: 22,

              color:
                  const Color(0xFF4B8D4D),
            ),
          ),


          const SizedBox(
            width: 11,
          ),


          // --------------------------------------------------
          // DATE + CONDITION
          // --------------------------------------------------

          Expanded(

            child:
                Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(

                  readableDate(
                    day.date,
                  ),

                  style:
                      const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF344238),
                  ),
                ),


                const SizedBox(
                  height: 3,
                ),


                Text(

                  localizedWeatherCondition(
                    day.weatherCode,
                  ),

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    fontSize: 9.5,
                    color:
                        Color(0xFF7B857C),
                  ),
                ),
              ],
            ),
          ),


          // --------------------------------------------------
          // RAIN PROBABILITY + TEMPERATURE
          // --------------------------------------------------

          Column(

            crossAxisAlignment:
                CrossAxisAlignment.end,

            children: [

              Row(

                children: [

                  const Icon(

                    Icons.water_drop_outlined,

                    size: 14,

                    color:
                        Color(0xFF4D8C9C),
                  ),


                  const SizedBox(
                    width: 3,
                  ),


                  Text(

                    '${day.rainProbability.toStringAsFixed(0)}%',

                    style:
                        const TextStyle(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          Color(0xFF4D8C9C),
                    ),
                  ),
                ],
              ),


              const SizedBox(
                height: 4,
              ),


              Text(

                '${day.maxTemperature.toStringAsFixed(0)}° / '
                '${day.minTemperature.toStringAsFixed(0)}°',

                style:
                    const TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(0xFF59655C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // ==========================================================
  // FARM ADVICE
  // ==========================================================

  Widget buildFarmAdvice(
    CurrentWeather current,
  ) {

    final l10n = AppLocalizations.of(context)!;

    return Container(

      width:
          double.infinity,

      padding:
          const EdgeInsets.all(17),


      decoration:
          BoxDecoration(

        color:
            const Color(0xFFE8F3DF),

        borderRadius:
            BorderRadius.circular(20),
      ),


      child:
          Row(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Container(

            width: 44,

            height: 44,

            decoration:
                BoxDecoration(

              color:
                  Colors.white.withValues(
                alpha: 0.65,
              ),

              borderRadius:
                  BorderRadius.circular(14),
            ),

            child:
                const Icon(

              Icons.agriculture_rounded,

              size: 23,

              color:
                  Color(0xFF438C47),
            ),
          ),


          const SizedBox(
            width: 11,
          ),


          Expanded(

            child:
                Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(

                  l10n.farmActivityAdvice,

                  style:
                      const TextStyle(
                    fontSize: 13.5,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF304336),
                  ),
                ),


                const SizedBox(
                  height: 5,
                ),


                Text(

                  weatherActivityAdvice(
                    current,
                  ),

                  style:
                      const TextStyle(
                    fontSize: 10.5,
                    height: 1.45,
                    color:
                        Color(0xFF607064),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ==========================================================
  // DATA NOTE
  // ==========================================================

  Widget buildDataNote() {

    final l10n = AppLocalizations.of(context)!;

    return Center(

      child:
          Text(

        l10n.weatherDataNote,

        textAlign:
            TextAlign.center,

        style:
            const TextStyle(
          fontSize: 9.5,
          color:
              Color(0xFF8A928C),
        ),
      ),
    );
  }


  // ==========================================================
  // WEATHER ICON
  // ==========================================================

  IconData weatherIcon(
    int code,
  ) {

    // Clear sky.
    if (code == 0) {
      return Icons.wb_sunny_rounded;
    }


    // Mainly clear.
    if (code == 1) {
      return Icons.wb_sunny_outlined;
    }


    // Partly cloudy.
    if (code == 2) {
      return Icons.wb_cloudy_rounded;
    }


    // Overcast.
    if (code == 3) {
      return Icons.cloud_rounded;
    }


    // Fog.
    if (code == 45 || code == 48) {
      return Icons.foggy;
    }


    // Drizzle.
    if (code >= 51 && code <= 57) {
      return Icons.grain_rounded;
    }


    // Rain.
    if (code >= 61 && code <= 67) {
      return Icons.water_drop_rounded;
    }


    // Snow.
    if (code >= 71 && code <= 77) {
      return Icons.ac_unit_rounded;
    }


    // Rain showers.
    if (code >= 80 && code <= 82) {
      return Icons.umbrella_rounded;
    }


    // Thunderstorm.
    if (code >= 95) {
      return Icons.thunderstorm_rounded;
    }


    return Icons.cloud_rounded;
  }


  // ==========================================================
  // LOCALIZED WEATHER CONDITION
  // ==========================================================
  //
  // The backend weather condition may be returned in English.
  //
  // Instead of displaying:
  //
  // "Mainly Clear"
  //
  // directly from the backend, we use the weather code and
  // translate the condition here.
  //
  // This ensures the condition changes when the app language
  // changes.
  //
  // ==========================================================

  String localizedWeatherCondition(
    int code,
  ) {

    final l10n = AppLocalizations.of(context)!;

    final bool isMarathi =
        Localizations.localeOf(context).languageCode == 'mr';


    // ----------------------------------------------------------
    // CLEAR SKY
    // ----------------------------------------------------------

    if (code == 0) {
      return isMarathi
          ? 'स्वच्छ आकाश'
          : 'Clear Sky';
    }


    // ----------------------------------------------------------
    // MAINLY CLEAR
    // ----------------------------------------------------------

    if (code == 1) {
      return isMarathi
          ? 'मुख्यतः स्वच्छ'
          : 'Mainly Clear';
    }


    // ----------------------------------------------------------
    // PARTLY CLOUDY
    // ----------------------------------------------------------

    if (code == 2) {
      return l10n.partlyCloudy;
    }


    // ----------------------------------------------------------
    // OVERCAST
    // ----------------------------------------------------------

    if (code == 3) {
      return isMarathi
          ? 'ढगाळ'
          : 'Overcast';
    }


    // ----------------------------------------------------------
    // FOG
    // ----------------------------------------------------------

    if (code == 45 || code == 48) {
      return isMarathi
          ? 'धुके'
          : 'Fog';
    }


    // ----------------------------------------------------------
    // DRIZZLE
    // ----------------------------------------------------------

    if (code >= 51 && code <= 57) {
      return isMarathi
          ? 'रिमझिम पाऊस'
          : 'Drizzle';
    }


    // ----------------------------------------------------------
    // RAIN
    // ----------------------------------------------------------

    if (code >= 61 && code <= 67) {
      return isMarathi
          ? 'पाऊस'
          : 'Rain';
    }


    // ----------------------------------------------------------
    // SNOW
    // ----------------------------------------------------------

    if (code >= 71 && code <= 77) {
      return isMarathi
          ? 'हिमवृष्टी'
          : 'Snow';
    }


    // ----------------------------------------------------------
    // RAIN SHOWERS
    // ----------------------------------------------------------

    if (code >= 80 && code <= 82) {
      return isMarathi
          ? 'पावसाच्या सरी'
          : 'Rain Showers';
    }


    // ----------------------------------------------------------
    // THUNDERSTORM
    // ----------------------------------------------------------

    if (code >= 95) {
      return isMarathi
          ? 'मेघगर्जनेसह पाऊस'
          : 'Thunderstorm';
    }


    return isMarathi
        ? 'हवामानाची माहिती'
        : 'Weather Conditions';
  }


  // ==========================================================
  // QUICK WEATHER ADVICE
  // ==========================================================

  String weatherAdvice(
    int code,
  ) {

    final bool isMarathi =
        Localizations.localeOf(context).languageCode == 'mr';


    // ----------------------------------------------------------
    // CLEAR WEATHER
    // ----------------------------------------------------------

    if (code == 0 || code == 1) {

      return isMarathi
          ? 'आज हवामान स्वच्छ आहे. जमिनीतील ओलावा तपासत नियमित शेतीची कामे सुरू ठेवा.'
          : 'Clear conditions today. Continue normal farm activities while monitoring soil moisture.';
    }


    // ----------------------------------------------------------
    // CLOUDY WEATHER
    // ----------------------------------------------------------

    if (code == 2 || code == 3) {

      return isMarathi
          ? 'आज आकाश ढगाळ आहे. नियमित शेतीची कामे सुरू ठेवा आणि हवामानातील बदलांवर लक्ष ठेवा.'
          : 'Cloudy conditions today. Continue routine farm work and monitor changes in weather.';
    }


    // ----------------------------------------------------------
    // RAIN / DRIZZLE
    // ----------------------------------------------------------

    if (code >= 51 && code <= 67) {

      return isMarathi
          ? 'पाऊस किंवा रिमझिम पाऊस सुरू आहे. सिंचनाचे नियोजन करण्यापूर्वी पावसाचे प्रमाण तपासा.'
          : 'Rain or drizzle is present. Consider rainfall before scheduling irrigation.';
    }


    // ----------------------------------------------------------
    // RAIN SHOWERS
    // ----------------------------------------------------------

    if (code >= 80 && code <= 82) {

      return isMarathi
          ? 'पावसाच्या सरी येण्याची शक्यता आहे. हवामानातील बदल लक्षात घेऊन शेतातील कामांचे नियोजन करा.'
          : 'Rain showers are possible. Plan field activities around changing conditions.';
    }


    // ----------------------------------------------------------
    // THUNDERSTORM
    // ----------------------------------------------------------

    if (code >= 95) {

      return isMarathi
          ? 'मेघगर्जनेसह वादळी हवामानाची शक्यता आहे. वादळाच्या वेळी अनावश्यक बाहेरील शेतीची कामे टाळा.'
          : 'Thunderstorm conditions are possible. Avoid unnecessary outdoor field work during storms.';
    }


    return isMarathi
        ? 'स्थानिक शेती हवामानाच्या परिस्थितीवर लक्ष ठेवा.'
        : 'Continue monitoring local farm weather conditions.';
  }


  // ==========================================================
  // FARM ACTIVITY ADVICE
  // ==========================================================

  String weatherActivityAdvice(
    CurrentWeather current,
  ) {

    final bool isMarathi =
        Localizations.localeOf(context).languageCode == 'mr';


    // ----------------------------------------------------------
    // HIGH RAINFALL
    // ----------------------------------------------------------

    if (current.rainfall > 5) {

      return isMarathi
          ? 'अलीकडील पावसाचे प्रमाण जास्त आहे. अधिक सिंचन करण्यापूर्वी जमिनीतील ओलावा तपासा.'
          : 'Recent rainfall is significant. Check soil moisture before adding more irrigation.';
    }


    // ----------------------------------------------------------
    // HIGH HUMIDITY
    // ----------------------------------------------------------

    if (current.humidity > 85) {

      return isMarathi
          ? 'हवेतील आर्द्रता जास्त आहे. रोग वाढण्यास अनुकूल परिस्थितीसाठी पिकांचे बारकाईने निरीक्षण करा.'
          : 'Humidity is high. Monitor crops closely for conditions that may encourage disease development.';
    }


    // ----------------------------------------------------------
    // STRONG WIND
    // ----------------------------------------------------------

    if (current.windSpeed > 25) {

      return isMarathi
          ? 'वाऱ्याचा वेग तुलनेने जास्त आहे. फवारणी आणि इतर खुल्या शेतातील कामे काळजीपूर्वक करा.'
          : 'Wind speed is relatively high. Take care with spraying and other exposed field activities.';
    }


    return isMarathi
        ? 'सध्याचे हवामान नियमित शेतीच्या कामांसाठी योग्य दिसत आहे. शेतातील परिस्थितीवर लक्ष ठेवा.'
        : 'Current conditions appear suitable for routine farm activities. Continue monitoring the field.';
  }


  // ==========================================================
  // READABLE DATE
  // ==========================================================

  String readableDate(
    String date,
  ) {

    final List<String> parts =
        date.split('-');


    if (parts.length != 3) {
      return date;
    }


    final bool isMarathi =
        Localizations.localeOf(context).languageCode == 'mr';


    // ----------------------------------------------------------
    // MONTH NAMES
    // ----------------------------------------------------------

    final List<String> englishMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];


    final List<String> marathiMonths = [
      'जाने',
      'फेब्रु',
      'मार्च',
      'एप्रि',
      'मे',
      'जून',
      'जुलै',
      'ऑग',
      'सप्टें',
      'ऑक्टो',
      'नोव्हें',
      'डिसें',
    ];


    final int month =
        int.tryParse(parts[1]) ?? 1;


    // Protect against invalid month values.
    if (month < 1 || month > 12) {
      return date;
    }


    final String monthName =
        isMarathi
            ? marathiMonths[month - 1]
            : englishMonths[month - 1];


    return '${parts[2]} '
        '$monthName '
        '${parts[0]}';
  }
}


// ============================================================
// LOCATION SEARCH SHEET
// ============================================================
//
// This is the manual-location search interface.
//
// Search text
//     ↓
// FastAPI /weather/search
//     ↓
// Location results
//     ↓
// Farmer selects one
//
// ============================================================

class LocationSearchSheet extends StatefulWidget {

  // Sends the selected location back to WeatherScreen.
  final void Function(
    LocationSearchResult result,
  ) onLocationSelected;


  const LocationSearchSheet({
    super.key,
    required this.onLocationSelected,
  });


  @override
  State<LocationSearchSheet> createState() =>
      _LocationSearchSheetState();
}


// ============================================================
// LOCATION SEARCH STATE
// ============================================================

class _LocationSearchSheetState
    extends State<LocationSearchSheet> {

  // Reads the farmer's search text.
  final TextEditingController searchController =
      TextEditingController();


  // Stores location results returned by FastAPI.
  List<LocationSearchResult> results = [];


  // Shows loading while location search is running.
  bool isSearching = false;


  // Error shown when location search fails.
  String? errorMessage;


  @override
  void dispose() {

    // Releases the search controller.
    searchController.dispose();

    super.dispose();
  }


  // ==========================================================
  // SEARCH LOCATION
  // ==========================================================

  Future<void> searchLocation() async {

    final l10n = AppLocalizations.of(context)!;

    // Gets the text entered by the farmer.
    final String query =
        searchController.text.trim();


    // Empty searches are not sent to the backend.
    if (query.isEmpty) {

      setState(() {
        errorMessage =
            l10n.locationNotFound;
        results = [];
      });

      return;
    }


    // --------------------------------------------------------
    // START LOADING
    // --------------------------------------------------------

    setState(() {
      isSearching = true;
      errorMessage = null;
      results = [];
    });


    try {

      // ------------------------------------------------------
      // CALL FASTAPI LOCATION SEARCH
      // ------------------------------------------------------

      final List<LocationSearchResult>
          locations =
          await ApiService.searchLocations(
        query,
      );


      if (!mounted) {
        return;
      }


      // ------------------------------------------------------
      // SAVE RESULTS
      // ------------------------------------------------------

      setState(() {
        results = locations;
        isSearching = false;
      });


      // ------------------------------------------------------
      // NO RESULTS
      // ------------------------------------------------------

      if (locations.isEmpty) {

        setState(() {
          errorMessage =
              l10n.locationNotFound;
        });
      }

    } catch (error) {

      if (!mounted) {
        return;
      }


      // ------------------------------------------------------
      // USER-FRIENDLY SEARCH ERROR
      // ------------------------------------------------------

      setState(() {
        isSearching = false;

        errorMessage =
            '${l10n.unableSearchLocation}\n'
            '${l10n.checkInternet}';

        results = [];
      });
    }
  }


  // ==========================================================
  // BUILD SEARCH SHEET
  // ==========================================================

  @override
  Widget build(BuildContext context) {

    final l10n = AppLocalizations.of(context)!;

    return Container(

      // Keeps the sheet above the keyboard.
      padding:
          EdgeInsets.fromLTRB(
        18,
        12,
        18,
        MediaQuery.of(context)
                .viewInsets
                .bottom +
            18,
      ),


      decoration:
          const BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(25),
        ),
      ),


      child:
          SafeArea(

        child:
            Column(

          mainAxisSize:
              MainAxisSize.min,

          children: [

            // ------------------------------------------------
            // DRAG HANDLE
            // ------------------------------------------------

            Container(

              width: 38,

              height: 4,

              decoration:
                  BoxDecoration(

                color:
                    const Color(0xFFD9DED9),

                borderRadius:
                    BorderRadius.circular(4),
              ),
            ),


            const SizedBox(
              height: 18,
            ),


            // ------------------------------------------------
            // HEADER
            // ------------------------------------------------

            Align(

              alignment:
                  Alignment.centerLeft,

              child:
                  Text(

                l10n.searchLocation,

                style:
                    const TextStyle(

                  fontSize: 20,

                  fontWeight:
                      FontWeight.w800,

                  color:
                      Color(0xFF29372D),
                ),
              ),
            ),


            const SizedBox(
              height: 5,
            ),


            Align(

              alignment:
                  Alignment.centerLeft,

              child:
                  Text(

                l10n.searchLocationSubtitle,

                style:
                    const TextStyle(

                  fontSize: 10.5,

                  color:
                      Color(0xFF7A847C),
                ),
              ),
            ),


            const SizedBox(
              height: 15,
            ),


            // ------------------------------------------------
            // SEARCH FIELD
            // ------------------------------------------------

            TextField(

              controller:
                  searchController,

              autofocus:
                  true,

              textInputAction:
                  TextInputAction.search,

              onSubmitted:
                  (_) => searchLocation(),

              decoration:
                  InputDecoration(

                hintText:
                    'e.g. Sangli, Pune, Kolhapur',

                hintStyle:
                    const TextStyle(

                  fontSize: 11,

                  color:
                      Color(0xFF929A93),
                ),


                prefixIcon:
                    const Icon(

                  Icons.search_rounded,

                  color:
                      Color(0xFF4A8751),
                ),


                suffixIcon:
                    IconButton(

                  // Starts search.
                  onPressed:
                      isSearching
                          ? null
                          : searchLocation,

                  icon:

                      isSearching

                          ? const SizedBox(

                              width: 19,

                              height: 19,

                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            )

                          : const Icon(
                              Icons.arrow_forward_rounded,
                            ),
                ),


                filled:
                    true,

                fillColor:
                    const Color(0xFFF7F9F5),


                border:
                    OutlineInputBorder(

                  borderRadius:
                      BorderRadius.circular(17),

                  borderSide:
                      const BorderSide(
                    color:
                        Color(0xFFE0E6DE),
                  ),
                ),


                enabledBorder:
                    OutlineInputBorder(

                  borderRadius:
                      BorderRadius.circular(17),

                  borderSide:
                      const BorderSide(
                    color:
                        Color(0xFFE0E6DE),
                  ),
                ),


                focusedBorder:
                    OutlineInputBorder(

                  borderRadius:
                      BorderRadius.circular(17),

                  borderSide:
                      const BorderSide(
                    color:
                        Color(0xFF4A8A50),
                    width: 1.5,
                  ),
                ),
              ),
            ),


            const SizedBox(
              height: 14,
            ),


            // ------------------------------------------------
            // ERROR
            // ------------------------------------------------

            if (errorMessage != null)

              Container(

                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(12),


                decoration:
                    BoxDecoration(

                  color:
                      const Color(0xFFFFF4E5),

                  borderRadius:
                      BorderRadius.circular(13),
                ),


                child:
                    Text(

                  errorMessage!,

                  style:
                      const TextStyle(

                    fontSize: 10.5,

                    color:
                        Color(0xFF815E2F),
                  ),
                ),
              ),


            if (errorMessage != null)

              const SizedBox(
                height: 10,
              ),


            // ------------------------------------------------
            // SEARCH RESULTS
            // ------------------------------------------------

            if (results.isNotEmpty)

              Flexible(

                child:
                    ListView.separated(

                  shrinkWrap:
                      true,

                  itemCount:
                      results.length,

                  separatorBuilder:
                      (_, _) =>
                          const SizedBox(
                    height: 8,
                  ),

                  itemBuilder:
                      (context, index) {

                    final LocationSearchResult
                        result =
                        results[index];


                    return buildLocationResult(
                      result,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }


  // ==========================================================
  // LOCATION RESULT CARD
  // ==========================================================

  Widget buildLocationResult(
    LocationSearchResult result,
  ) {

    return InkWell(

      // Selects this location.
      onTap: () {

        widget.onLocationSelected(
          result,
        );
      },


      borderRadius:
          BorderRadius.circular(16),


      child:
          Container(

        padding:
            const EdgeInsets.all(13),


        decoration:
            BoxDecoration(

          color:
              const Color(0xFFF8FAF7),

          borderRadius:
              BorderRadius.circular(16),

          border:
              Border.all(
            color:
                const Color(0xFFE1E7DF),
          ),
        ),


        child:
            Row(

          children: [

            // ------------------------------------------------
            // LOCATION ICON
            // ------------------------------------------------

            Container(

              width: 43,

              height: 43,

              decoration:
                  BoxDecoration(

                color:
                    const Color(0xFFE6F2E1),

                borderRadius:
                    BorderRadius.circular(13),
              ),

              child:
                  const Icon(

                Icons.location_on_outlined,

                size: 22,

                color:
                    Color(0xFF438C47),
              ),
            ),


            const SizedBox(
              width: 11,
            ),


            // ------------------------------------------------
            // LOCATION NAME
            // ------------------------------------------------

            Expanded(

              child:
                  Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(

                    result.name,

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(

                      fontSize: 13,

                      fontWeight:
                          FontWeight.w800,

                      color:
                          Color(0xFF344238),
                    ),
                  ),


                  const SizedBox(
                    height: 3,
                  ),


                  Text(

                    result.secondaryName,

                    maxLines: 2,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(

                      fontSize: 9.5,

                      height: 1.3,

                      color:
                          Color(0xFF7A847C),
                    ),
                  ),
                ],
              ),
            ),


            const Icon(

              Icons.chevron_right_rounded,

              color:
                  Color(0xFF8A938B),
            ),
          ],
        ),
      ),
    );
  }
}