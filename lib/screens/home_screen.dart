import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import 'crop_screen.dart';
import 'disease_screen.dart';
import 'weather_screen.dart';
import 'chatbot_screen.dart';
import 'knowledge_screen.dart';
import 'diary_screen.dart';
import 'tools_screen.dart';

// ============================================================
// HOME SCREEN
// Main dashboard of AgriGuide.
//
// The Home screen provides:
// - Welcome section
// - Weather summary
// - Quick actions
// - Farming tip
// - Bottom navigation
//
// IMPORTANT:
//
// All user-visible text that has a translation is now read
// from AppLocalizations.
//
// This means English ↔ Marathi can update the Home UI.
// ============================================================


class HomeScreen extends StatefulWidget {

  // ----------------------------------------------------------
  // LANGUAGE CHANGE CALLBACK
  // ----------------------------------------------------------
  //
  // main.dart provides this function.
  // It changes the application's selected locale.
  //
  final void Function(Locale locale) onLanguageChanged;


  const HomeScreen({
    super.key,
    required this.onLanguageChanged,
  });


  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}


// ============================================================
// HOME SCREEN STATE
// ============================================================

class _HomeScreenState extends State<HomeScreen> {


  // ----------------------------------------------------------
  // BOTTOM NAVIGATION
  // ----------------------------------------------------------

  // Stores the currently selected navigation item.
  //
  // 0 = Home
  // 1 = Tools
  // 2 = Learn
  // 3 = Diary
  int selectedIndex = 0;


  // ==========================================================
  // OPEN SCREEN
  // ==========================================================

  void openScreen(
    Widget screen,
  ) {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }


  // ==========================================================
  // HANDLE BOTTOM NAVIGATION
  // ==========================================================

  void handleNavigation(
    int index,
  ) {

    // Home is already the current screen.
    if (index == 0) {

      setState(() {
        selectedIndex = 0;
      });

      return;
    }


    // Update selected navigation item.
    setState(() {
      selectedIndex = index;
    });


    // Open the selected screen.
    switch (index) {

      case 1:
        openScreen(
          const ToolsScreen(),
        );
        break;


      case 2:
        openScreen(
          const KnowledgeScreen(),
        );
        break;


      case 3:
        openScreen(
          const DiaryScreen(),
        );
        break;
    }
  }


  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    // --------------------------------------------------------
    // GET LOCALIZED STRINGS
    // --------------------------------------------------------
    //
    // AppLocalizations reads the currently selected language.
    //
    // English → English strings
    // Marathi → Marathi strings
    //
    final AppLocalizations l10n =
        AppLocalizations.of(context)!;


    return Scaffold(

      backgroundColor:
          const Color(
        0xFFF7F8F2,
      ),


      // ======================================================
      // MAIN CONTENT
      // ======================================================

      body:
          SafeArea(

        child:
            SingleChildScrollView(

          physics:
              const BouncingScrollPhysics(),

          padding:
              const EdgeInsets.fromLTRB(
            18,
            14,
            18,
            20,
          ),


          child:
              Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // ------------------------------------------------
              // HEADER
              // ------------------------------------------------

              buildHeader(
                l10n,
              ),


              const SizedBox(
                height:
                    25,
              ),


              // ------------------------------------------------
              // WELCOME
              // ------------------------------------------------

              buildWelcomeSection(
                l10n,
              ),


              const SizedBox(
                height:
                    20,
              ),


              // ------------------------------------------------
              // WEATHER SUMMARY
              // ------------------------------------------------

              buildWeatherSummary(
                l10n,
              ),


              const SizedBox(
                height:
                    24,
              ),


              // ------------------------------------------------
              // QUICK ACTIONS
              // ------------------------------------------------

              buildQuickActions(
                l10n,
              ),


              const SizedBox(
                height:
                    22,
              ),


              // ------------------------------------------------
              // FARMING TIP
              // ------------------------------------------------

              buildFarmingTip(
                l10n,
              ),


              const SizedBox(
                height:
                    12,
              ),
            ],
          ),
        ),
      ),


      // ======================================================
      // BOTTOM NAVIGATION
      // ======================================================

      bottomNavigationBar:
          buildBottomNavigation(
        l10n,
      ),
    );
  }


  // ==========================================================
  // HEADER
  // ==========================================================

  Widget buildHeader(
    AppLocalizations l10n,
  ) {

    return Row(

      children: [

        // ------------------------------------------------------
        // AGRIGUIDE LOGO
        // ------------------------------------------------------

        Container(

          width:
              44,

          height:
              44,

          decoration:
              BoxDecoration(

            color:
                const Color(
              0xFFE5F1DD,
            ),

            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),


          child:
              const Icon(

            Icons.eco_rounded,

            color:
                Color(
              0xFF3E8744,
            ),

            size:
                27,
          ),
        ),


        const SizedBox(
          width:
              11,
        ),


        // ------------------------------------------------------
        // APPLICATION IDENTITY
        // ------------------------------------------------------

        const Expanded(

          child:
              Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(

                'AgriGuide',

                style:
                    TextStyle(

                  fontSize:
                      21,

                  fontWeight:
                      FontWeight.w800,

                  color:
                      Color(
                    0xFF20352A,
                  ),
                ),
              ),


              Text(

                'Smart Farming Assistance',

                style:
                    TextStyle(

                  fontSize:
                      10,

                  color:
                      Color(
                    0xFF7B837C,
                  ),
                ),
              ),
            ],
          ),
        ),


        // ------------------------------------------------------
        // LANGUAGE SELECTOR
        // ------------------------------------------------------

        buildLanguageButton(
          l10n,
        ),
      ],
    );
  }


  // ==========================================================
  // LANGUAGE BUTTON
  // ==========================================================

  Widget buildLanguageButton(
    AppLocalizations l10n,
  ) {

    return Container(

      width:
          44,

      height:
          44,


      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          14,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFE3E6DE,
          ),
        ),
      ),


      child:
          PopupMenuButton<String>(

        tooltip:
            l10n.language,

        padding:
            EdgeInsets.zero,


        icon:
            const Icon(

          Icons.language_rounded,

          color:
              Color(
            0xFF304033,
          ),

          size:
              24,
        ),


        // ------------------------------------------------------
        // CHANGE LANGUAGE
        // ------------------------------------------------------

        onSelected:
            (String language) {

          if (language == 'en') {

            widget.onLanguageChanged(
              const Locale('en'),
            );
          }


          if (language == 'mr') {

            widget.onLanguageChanged(
              const Locale('mr'),
            );
          }
        },


        // LANGUAGE OPTIONS
        itemBuilder:
            (BuildContext context) {

          return [

            PopupMenuItem<String>(

              value:
                  'en',

              child:
                  Row(

                children: [

                  const Text(
                    '🇬🇧',
                  ),

                  const SizedBox(
                    width:
                        10,
                  ),

                  Text(
                    l10n.english,
                  ),
                ],
              ),
            ),


            PopupMenuItem<String>(

              value:
                  'mr',

              child:
                  Row(

                children: [

                  const Text(
                    '🇮🇳',
                  ),

                  const SizedBox(
                    width:
                        10,
                  ),

                  Text(
                    l10n.marathi,
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
  }


  // ==========================================================
  // WELCOME SECTION
  // ==========================================================

  Widget buildWelcomeSection(
    AppLocalizations l10n,
  ) {

    return Row(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        // ------------------------------------------------------
        // GREETING
        // ------------------------------------------------------

        Expanded(

          child:
              Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [



              const SizedBox(
                height:
                    3,
              ),


              Text(

                '${l10n.farmer} 👋',

                style:
                    TextStyle(

                  fontSize:
                      30,

                  fontWeight:
                      FontWeight.w800,

                  color:
                      Color(
                    0xFF20352A,
                  ),
                ),
              ),


              const SizedBox(
                height:
                    8,
              ),


              Text(

                l10n.homeWelcome,

                style:
                    const TextStyle(

                  fontSize:
                      13,

                  color:
                      Color(
                    0xFF7A837B,
                  ),
                ),
              ),
            ],
          ),
        ),


        const SizedBox(
          width:
              10,
        ),


        // DECORATIVE FARM ILLUSTRATION

        Container(

          width:
              82,

          height:
              82,

          decoration:
              BoxDecoration(

            color:
                const Color(
              0xFFE3F0D8,
            ),

            borderRadius:
                BorderRadius.circular(
              28,
            ),
          ),


          child:
              Stack(

            alignment:
                Alignment.center,

            children: [

              // Decorative sun.
              Positioned(

                top:
                    12,

                right:
                    12,

                child:
                    Container(

                  width:
                      20,

                  height:
                      20,

                  decoration:
                      const BoxDecoration(

                    color:
                        Color(
                      0xFFF4D36D,
                    ),

                    shape:
                        BoxShape.circle,
                  ),
                ),
              ),


              // Leaf.
              const Icon(

                Icons.eco_rounded,

                size:
                    48,

                color:
                    Color(
                  0xFF4C914B,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  // ==========================================================
  // WEATHER SUMMARY
  // ==========================================================
  //
  // NOTE:
  // This is currently a dashboard summary.
  // The dedicated Weather screen contains the real live
  // weather data from the backend.
  //
  // We are only translating the labels here.
  // ==========================================================

  Widget buildWeatherSummary(
    AppLocalizations l10n,
  ) {

    return GestureDetector(

      onTap: () {

        openScreen(
          const WeatherScreen(),
        );
      },


      child:
          Container(

        width:
            double.infinity,

        padding:
            const EdgeInsets.all(
          18,
        ),


        decoration:
            BoxDecoration(

          color:
              const Color(
            0xFFE5F0D9,
          ),

          borderRadius:
              BorderRadius.circular(
            23,
          ),
        ),


        child:
            Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                const Icon(

                  Icons.cloud_rounded,

                  color:
                      Color(
                    0xFF4B7D61,
                  ),

                  size:
                      21,
                ),


                const SizedBox(
                  width:
                      7,
                ),


                Text(

                  l10n.farmWeather,

                  style:
                      const TextStyle(

                    fontSize:
                        15,

                    fontWeight:
                        FontWeight.w800,

                    color:
                        Color(
                      0xFF31523A,
                    ),
                  ),
                ),


                const Spacer(),


                const Icon(

                  Icons.arrow_forward_rounded,

                  color:
                      Color(
                    0xFF62806A,
                  ),

                  size:
                      20,
                ),
              ],
            ),


            const SizedBox(
              height:
                  14,
            ),


            Row(

              children: [

                const Text(

                  '28°',

                  style:
                      TextStyle(

                    fontSize:
                        38,

                    fontWeight:
                        FontWeight.w800,

                    color:
                        Color(
                      0xFF253A2B,
                    ),
                  ),
                ),


                const SizedBox(
                  width:
                      12,
                ),


                Expanded(

                  child:
                      Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(

                        l10n.partlyCloudy,

                        style:
                            TextStyle(

                          fontSize:
                              13,

                          fontWeight:
                              FontWeight.w700,

                          color:
                              Color(
                            0xFF536557,
                          ),
                        ),
                      ),


                      SizedBox(
                        height:
                            2,
                      ),


                      Text(

                        'Good conditions today',

                        style:
                            TextStyle(

                          fontSize:
                              10,

                          color:
                              Color(
                            0xFF7B857C,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),


                buildWeatherMetric(

                  icon:
                      Icons.water_drop_outlined,

                  value:
                      '62%',

                  label:
                      l10n.humidityLabel,
                ),


                const SizedBox(
                  width:
                      16,
                ),


                buildWeatherMetric(

                  icon:
                      Icons.air_rounded,

                  value:
                      '12',

                  label:
                      l10n.windLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  // ==========================================================
  // WEATHER METRIC
  // ==========================================================

  Widget buildWeatherMetric({

    required IconData icon,

    required String value,

    required String label,
  }) {

    return Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Icon(

          icon,

          size:
              18,

          color:
              const Color(
            0xFF57916B,
          ),
        ),


        const SizedBox(
          height:
              3,
        ),


        Text(

          value,

          style:
              const TextStyle(

            fontSize:
                12,

            fontWeight:
                FontWeight.w800,

            color:
                Color(
              0xFF334335,
            ),
          ),
        ),


        Text(

          label,

          style:
              const TextStyle(

            fontSize:
                9,

            color:
                Color(
              0xFF778078,
            ),
          ),
        ),
      ],
    );
  }


  // ==========================================================
  // QUICK ACTIONS
  // ==========================================================

  Widget buildQuickActions(
    AppLocalizations l10n,
  ) {

    return Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Text(

          l10n.quickActions,

          style:
              const TextStyle(

            fontSize:
                20,

            fontWeight:
                FontWeight.w800,

            color:
                Color(
              0xFF26372A,
            ),
          ),
        ),


        const SizedBox(
          height:
              12,
        ),


        // ----------------------------------------------------
        // ROW 1
        // ----------------------------------------------------

        Row(

          children: [

            Expanded(

              child:
                  buildActionCard(

                title:
                    l10n.cropRecommendation,

                subtitle:
                    l10n.cropRecommendationSubtitle,

                icon:
                    Icons.eco_rounded,

                iconColor:
                    const Color(
                  0xFF438C47,
                ),

                backgroundColor:
                    const Color(
                  0xFFE8F3DF,
                ),

                screen:
                    const CropScreen(),
              ),
            ),


            const SizedBox(
              width:
                  12,
            ),


            Expanded(

              child:
                  buildActionCard(

                title: l10n.diseaseDetection,

                subtitle:
                    l10n.diseaseDetectionSubtitle,

                icon:
                    Icons.health_and_safety_rounded,

                iconColor:
                    const Color(
                  0xFF4C8147,
                ),

                backgroundColor:
                    const Color(
                  0xFFF2EBDD,
                ),

                screen:
                    const DiseaseScreen(),
              ),
            ),
          ],
        ),


        const SizedBox(
          height:
              12,
        ),


        // ----------------------------------------------------
        // ROW 2
        // ----------------------------------------------------

        Row(

          children: [

            Expanded(

              child:
                  buildActionCard(

                title:
                    l10n.farmWeather,

                subtitle:
                    l10n.farmWeatherSubtitle,

                icon:
                    Icons.cloud_rounded,

                iconColor:
                    const Color(
                  0xFF4C808A,
                ),

                backgroundColor:
                    const Color(
                  0xFFE2EFF0,
                ),

                screen:
                    const WeatherScreen(),
              ),
            ),


            const SizedBox(
              width:
                  12,
            ),


            Expanded(

              child:
                  buildActionCard(

                title: l10n.agriAssistant,

                subtitle:
                    l10n.agriAssistantSubtitle,

                icon:
                    Icons.smart_toy_rounded,

                iconColor:
                    const Color(
                  0xFF7561A7,
                ),

                backgroundColor:
                    const Color(
                  0xFFEEE9F7,
                ),

                screen:
                    const ChatbotScreen(),
              ),
            ),
          ],
        ),
      ],
    );
  }


  // ==========================================================
  // QUICK ACTION CARD
  // ==========================================================

  Widget buildActionCard({

    required String title,

    required String subtitle,

    required IconData icon,

    required Color iconColor,

    required Color backgroundColor,

    required Widget screen,
  }) {

    return GestureDetector(

      onTap: () {

        openScreen(
          screen,
        );
      },


      child:
          Container(

        height:
            126,

        padding:
            const EdgeInsets.all(
          15,
        ),


        decoration:
            BoxDecoration(

          color:
              backgroundColor,

          borderRadius:
              BorderRadius.circular(
            21,
          ),


          boxShadow: [

            BoxShadow(

              color:
                  Colors.black.withValues(
                alpha:
                    0.04,
              ),

              blurRadius:
                  8,

              offset:
                  const Offset(
                0,
                3,
              ),
            ),
          ],
        ),


        child:
            Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ------------------------------------------------
            // ICON
            // ------------------------------------------------

            Container(

              width:
                  43,

              height:
                  43,

              decoration:
                  BoxDecoration(

                color:
                    Colors.white.withValues(
                  alpha:
                      0.55,
                ),

                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),


              child:
                  Icon(

                icon,

                color:
                    iconColor,

                size:
                    25,
              ),
            ),


            const Spacer(),


            // ------------------------------------------------
            // TITLE
            // ------------------------------------------------

            Text(

              title,

              maxLines:
                  1,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(

                fontSize:
                    15,

                fontWeight:
                    FontWeight.w800,

                color:
                    Color(
                  0xFF29372D,
                ),
              ),
            ),


            const SizedBox(
              height:
                  3,
            ),


            // ------------------------------------------------
            // SUBTITLE
            // ------------------------------------------------

            Text(

              subtitle,

              maxLines:
                  1,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(

                fontSize:
                    10.5,

                color:
                    Color(
                  0xFF788178,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ==========================================================
  // FARMING TIP
  // ==========================================================

  Widget buildFarmingTip(
    AppLocalizations l10n,
  ) {

    return Container(

      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        17,
      ),


      decoration:
          BoxDecoration(

        color:
            const Color(
          0xFF24573A,
        ),

        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),


      child:
          Row(

        children: [

          // --------------------------------------------------
          // TIP ICON
          // --------------------------------------------------

          Container(

            width:
                47,

            height:
                47,

            decoration:
                BoxDecoration(

              color:
                  const Color(
                0xFF39714D,
              ),

              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),


            child:
                const Icon(

              Icons.tips_and_updates_rounded,

              color:
                  Color(
                0xFFF2D46B,
              ),

              size:
                  26,
            ),
          ),


          const SizedBox(
            width:
                13,
          ),


          // TIP INFORMATION
          Expanded(

            child:
                Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(

                  l10n.farmingTip,

                  style:
                      const TextStyle(

                    fontSize:
                        15,

                    fontWeight:
                        FontWeight.w800,

                    color:
                        Colors.white,
                  ),
                ),


                const SizedBox(
                  height:
                      4,
                ),


                Text(

                  l10n.farmingTipText,

                  maxLines:
                      2,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      TextStyle(

                    fontSize:
                        11,

                    height:
                        1.3,

                    color:
                        Color(
                      0xFFD5E1D7,
                    ),
                  ),
                ),
              ],
            ),
          ),


          const Icon(

            Icons.arrow_forward_rounded,

            color:
                Color(
              0xFFD5E1D7,
            ),

            size:
                21,
          ),
        ],
      ),
    );
  }

  // BOTTOM NAVIGATION

  Widget buildBottomNavigation(
    AppLocalizations l10n,
  ) {

    return Container(
      decoration:
          const BoxDecoration(
        color:
            Colors.white,
        border:
            Border(
          top:
              BorderSide(
            color:
                Color(
              0xFFE4E6DF,
            ),
          ),
        ),
      ),


      child:
          SafeArea(
        child:
            Padding(
          padding:
              const EdgeInsets.fromLTRB(
            8,
            8,
            8,
            8,
          ),


          child:
              Row(

            mainAxisAlignment:
                MainAxisAlignment.spaceAround,

            children: [

              // HOME
              buildNavigationItem(
                index:
                    0,
                icon:
                    Icons.home_rounded,

                label:
                    l10n.home,
              ),

              // TOOLS
              buildNavigationItem(
                index:
                    1,
                icon:
                    Icons.grid_view_rounded,
                label:
                    l10n.tools,
              ),

              // LEARN
              buildNavigationItem(
                index:
                    2,
                icon:
                    Icons.menu_book_rounded,
                label: l10n.knowledgeHub,
              ),


              // DIARY
              buildNavigationItem(
                index:
                    3,
                icon:
                    Icons.edit_note_rounded,
                label: l10n.farmDiary,
              ),
            ],
          ),
        ),
      ),
    );
  }


  // NAVIGATION ITEM

  Widget buildNavigationItem({

    required int index,

    required IconData icon,

    required String label,
  }) {

    final bool isSelected =
        selectedIndex == index;


    return GestureDetector(

      onTap: () {

        handleNavigation(
          index,
        );
      },


      child:
          SizedBox(

        width:
            72,

        child:
            Column(

          mainAxisSize:
              MainAxisSize.min,

          children: [

            Icon(

              icon,

              size:
                  22,

              color:
                  isSelected

                      ? const Color(
                          0xFF347844,
                        )

                      : const Color(
                          0xFF808780,
                        ),
            ),


            const SizedBox(
              height:
                  4,
            ),


            Text(

              label,

              maxLines:
                  1,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  TextStyle(

                fontSize:
                    10,

                fontWeight:
                    isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,

                color:
                    isSelected

                        ? const Color(
                            0xFF347844,
                          )

                        : const Color(
                            0xFF808780,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}