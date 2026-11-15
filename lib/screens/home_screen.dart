import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import 'crop_screen.dart';
import 'disease_screen.dart';
import 'weather_screen.dart';
import 'chatbot_screen.dart';
import 'knowledge_screen.dart';
import 'diary_screen.dart';
import 'tools_screen.dart';
import 'season_guide.dart';


// DESIGN TOKENS
class _C {
  static const Color background = Color(0xFFF6F7F2);
  static const Color ink = Color(0xFF1B2A20);
  static const Color grey = Color(0xFF6E7A70);
  static const Color greyLight = Color(0xFF9AA39B);
  static const Color line = Color(0xFFE5E9DF);
  static const Color green = Color(0xFF2F7A4B);
  static const Color greenDark = Color(0xFF1E5236);
  static const Color greenDeep = Color(0xFF164029);
  static const Color greenTint = Color(0xFFE3EFDB);
  static const Color gold = Color(0xFFF2C94C);
}

class HomeScreen extends StatefulWidget {

  // LANGUAGE CHANGE CALLBACK (provided by main.dart)
  final void Function(Locale locale) onLanguageChanged;

  const HomeScreen({
    super.key,
    required this.onLanguageChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// HOME SCREEN STATE

class _HomeScreenState extends State<HomeScreen> {
  // 0 = Home, 1 = Tools, 2 = Learn, 3 = Diary
  int selectedIndex = 0;

  // OPEN SCREEN
  
  void openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) {
      if (mounted && selectedIndex != 0) {
        setState(() {
          selectedIndex = 0;
        });
      }
    });
  }

  // HANDLE BOTTOM NAVIGATION

  void handleNavigation(int index) {
    setState(() {
      selectedIndex = index;
    });

    if (index == 0) return;

    switch (index) {
      case 1:
        openScreen(const ToolsScreen());
        break;
      case 2:
        openScreen(const KnowledgeScreen());
        break;
      case 3:
        openScreen(const DiaryScreen());
        break;
    }
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _C.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(l10n),
              const SizedBox(height: 22),
              buildWelcomeSection(l10n),
              const SizedBox(height: 18),
              buildSeasonGuideCard(),
              const SizedBox(height: 26),
              buildQuickActions(l10n),
              const SizedBox(height: 22),
              buildFarmingTip(l10n),
            ],
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNavigation(l10n),
    );
  }

  // HEADER

  Widget buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        // LOGO
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_C.green, _C.greenDark],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.eco_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),

        const SizedBox(width: 11),

        // APP IDENTITY
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AgriGuide',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: _C.ink,
                ),
              ),
              Text(
                'Smart Farming Assistance',
                style: TextStyle(
                  fontSize: 11,
                  color: _C.grey,
                ),
              ),
            ],
          ),
        ),

        // LANGUAGE
        buildLanguageButton(l10n),
      ],
    );
  }

  // LANGUAGE BUTTON  (globe + current language code)

  Widget buildLanguageButton(AppLocalizations l10n) {
    final String code =
        Localizations.localeOf(context).languageCode.toUpperCase();

    return PopupMenuButton<String>(
      tooltip: l10n.language,
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      onSelected: (String language) {
        if (language == 'en') {
          widget.onLanguageChanged(const Locale('en'));
        }
        if (language == 'mr') {
          widget.onLanguageChanged(const Locale('mr'));
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            value: 'en',
            child: Row(
              children: [
                const Text('🇬🇧'),
                const SizedBox(width: 10),
                Text(l10n.english),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'mr',
            child: Row(
              children: [
                const Text('🇮🇳'),
                const SizedBox(width: 10),
                Text(l10n.marathi),
              ],
            ),
          ),
        ];
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language_rounded,
              size: 20,
              color: _C.greenDark,
            ),
            const SizedBox(width: 6),
            Text(
              code,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _C.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WELCOME SECTION

  Widget buildWelcomeSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.farmer} 👋',
          style: const TextStyle(
            fontSize: 32,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: _C.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.homeWelcome,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: _C.grey,
          ),
        ),
      ],
    );
  }

  // SEASON GUIDE CARD (offline, English + Marathi)

  Widget buildSeasonGuideCard() {
    final String lang = Localizations.localeOf(context).languageCode;
    final SeasonSnapshot season = SeasonGuide.snapshot(DateTime.now(), lang);

    Widget cropSection({
      required String title,
      required List<String> crops,
      required IconData icon,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color.fromARGB(255, 66, 216, 136), size: 14),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color.fromARGB(255, 165, 244, 202),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (crops.isEmpty)
            Text(
              lang == 'mr'
                  ? 'या महिन्यासाठी माहिती उपलब्ध नाही'
                  : 'No crops listed for this month',
              style: const TextStyle(color: _C.grey, fontSize: 12),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 5,
              children: crops.map((crop) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _C.greenTint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    crop,
                    style: const TextStyle(
                      color: _C.greenDark,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.green, _C.greenDeep],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow( color: _C.greenDark.withValues(alpha: 0.20),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  lang == 'mr' ? 'हंगाम मार्गदर्शक' : 'Season Guide',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.eco_rounded,
                color: Color(0xFFD3E6D8),
                size: 23,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            season.seasonName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${season.range}            •  ${season.monthName}',
            style: const TextStyle(
              color: Color(0xFFD3E6D8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                season.progressLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(season.monthInSeason / season.seasonLength * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: season.monthInSeason / season.seasonLength,
              minHeight: 8,
              backgroundColor: const Color.fromARGB(57, 238, 193, 193),
              valueColor: const AlwaysStoppedAnimation<Color>(_C.gold),
            ),
          ),
          const SizedBox(height: 21),
          cropSection(
            title: season.sowLabel,
            crops: season.sow,
            icon: Icons.grass_rounded,
          ),
          const SizedBox(height: 17),
          cropSection(
            title: season.harvestLabel,
            crops: season.harvest,
            icon: Icons.agriculture_rounded,
          ),
          const SizedBox(height: 19),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: _C.gold,
                  size: 21,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    season.note,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Text(
            season.footer,
            style: const TextStyle(
              color: Color(0xFFD3E6D8),
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // QUICK ACTIONS  (2 x 2, equal height)

  Widget buildQuickActions(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: const TextStyle(
            fontSize: 21,
            height: 1.3,
            fontWeight: FontWeight.w800,
            color: _C.ink,
          ),
        ),

        const SizedBox(height: 12),

        // ROW 1
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: buildActionCard(
                  title: l10n.cropRecommendation,
                  subtitle: l10n.cropRecommendationSubtitle,
                  icon: Icons.grass_rounded,
                  iconColor: _C.green,
                  tint: _C.greenTint,
                  screen: const CropScreen(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildActionCard(
                  title: l10n.diseaseDetection,
                  subtitle: l10n.diseaseDetectionSubtitle,
                  icon: Icons.health_and_safety_rounded,
                  iconColor: const Color(0xFFB5602F),
                  tint: const Color(0xFFF6E7D8),
                  screen: const DiseaseScreen(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ROW 2
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: buildActionCard(
                  title: l10n.farmWeather,
                  subtitle: l10n.farmWeatherSubtitle,
                  icon: Icons.cloud_rounded,
                  iconColor: const Color(0xFF2F7080),
                  tint: const Color(0xFFDDEDEF),
                  screen: const WeatherScreen(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildActionCard(
                  title: l10n.agriAssistant,
                  subtitle: l10n.agriAssistantSubtitle,
                  icon: Icons.smart_toy_rounded,
                  iconColor: const Color(0xFF6A56A8),
                  tint: const Color(0xFFECE6F7),
                  screen: const ChatbotScreen(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // QUICK ACTION CARD
  // White card, coloured icon tile, wrapping title/subtitle.

  Widget buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color tint,
    required Widget screen,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => openScreen(screen),
        child: Container(
          constraints: const BoxConstraints(minHeight: 150),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _C.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ICON + ARROW
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: _C.greyLight,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // TITLE (wraps to 2 lines)
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  color: _C.ink,
                ),
              ),

              const SizedBox(height: 4),

              // SUBTITLE
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: _C.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FARMING TIP

  Widget buildFarmingTip(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E1AE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 40,
            decoration: BoxDecoration(
              color: _C.gold.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.tips_and_updates_rounded,
              color: Color(0xFF9A6B00),
              size: 26,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.farmingTip,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: _C.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.farmingTipText,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFF5A5440),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // BOTTOM NAVIGATION

  Widget buildBottomNavigation(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          child: Row(
            children: [
              buildNavigationItem(
                index: 0,
                icon: Icons.home_rounded,
                label: l10n.home,
              ),
              buildNavigationItem(
                index: 1,
                icon: Icons.grid_view_rounded,
                label: l10n.tools,
              ),
              buildNavigationItem(
                index: 2,
                icon: Icons.menu_book_rounded,
                label: l10n.knowledgeHub,
              ),
              buildNavigationItem(
                index: 3,
                icon: Icons.edit_note_rounded,
                label: l10n.farmDiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NAVIGATION ITEM
  // Each tab gets equal width; label scales down to fit.

  Widget buildNavigationItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = selectedIndex == index;
    final Color color = isSelected ? _C.green : _C.greyLight;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => handleNavigation(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: isSelected ? 56 : 40,
              height: 30,
              decoration: BoxDecoration(
                color: isSelected ? _C.greenTint : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 23, color: color),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
