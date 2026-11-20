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
// One green, one amber accent, soft neutrals. Text colours are
// dark enough to read outdoors.
class _C {
  static const Color background = Color(0xFFFAFAF7);
  static const Color surface = Colors.white;
  static const Color ink = Color(0xFF1C2B20);
  static const Color muted = Color(0xFF5C6B5E);
  static const Color line = Color(0xFFE4E7DE);
  static const Color green = Color(0xFF1F6F43);
  static const Color greenDark = Color(0xFF14311F);
  static const Color greenTint = Color(0xFFE4F0E1);
  static const Color amber = Color(0xFFB8792E);
  static const Color amberTint = Color(0xFFF6E9D6);
  static const Color teal = Color(0xFF2F7080);
  static const Color tealTint = Color(0xFFDDEDEF);
}

class HomeScreen extends StatefulWidget {
  // Language change callback (provided by main.dart).
  final void Function(Locale locale) onLanguageChanged;

  const HomeScreen({
    super.key,
    required this.onLanguageChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0 = Home, 1 = Tools, 2 = Learn, 3 = Diary
  int selectedIndex = 0;

  // Season guide shows a short version first; tap to see all.
  bool seasonExpanded = false;

  bool get _isMarathi =>
      Localizations.localeOf(context).languageCode == 'mr';

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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(l10n),
              const SizedBox(height: 24),
              buildWelcomeSection(l10n),
              const SizedBox(height: 22),
              buildQuickActions(l10n),
              const SizedBox(height: 24),
              buildSeasonGuideCard(),
              const SizedBox(height: 18),
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
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _C.green,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.eco_rounded,
            color: Colors.white,
            size: 27,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AgriGuide',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _C.greenDark,
                ),
              ),
              Text(
                _isMarathi
                    ? 'स्मार्ट शेती सहाय्य'
                    : 'Smart Farming Assistance',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: _C.muted,
                ),
              ),
            ],
          ),
        ),
        buildLanguageButton(l10n),
      ],
    );
  }

  // LANGUAGE BUTTON (globe + current language code)

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
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language_rounded,
              size: 20,
              color: _C.green,
            ),
            const SizedBox(width: 6),
            Text(
              code,
              style: const TextStyle(
                fontSize: 14,
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
            fontSize: 30,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: _C.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.homeWelcome,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: _C.muted,
          ),
        ),
      ],
    );
  }

  // QUICK ACTIONS (2 x 2, equal height)

  Widget buildQuickActions(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: const TextStyle(
            fontSize: 20,
            height: 1.3,
            fontWeight: FontWeight.w800,
            color: _C.greenDark,
          ),
        ),
        const SizedBox(height: 12),
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
                  iconColor: _C.amber,
                  tint: _C.amberTint,
                  screen: const DiseaseScreen(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: buildActionCard(
                  title: l10n.farmWeather,
                  subtitle: l10n.farmWeatherSubtitle,
                  icon: Icons.cloud_rounded,
                  iconColor: _C.teal,
                  tint: _C.tealTint,
                  screen: const WeatherScreen(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildActionCard(
                  title: l10n.agriAssistant,
                  subtitle: l10n.agriAssistantSubtitle,
                  icon: Icons.smart_toy_rounded,
                  iconColor: _C.greenDark,
                  tint: _C.greenTint,
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
  // White card, tinted icon tile, title and subtitle that wrap.

  Widget buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color tint,
    required Widget screen,
  }) {
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => openScreen(screen),
          child: Container(
            constraints: const BoxConstraints(minHeight: 136),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: _C.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: _C.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // SEASON GUIDE CARD (offline, English + Marathi)
  // Short version by default: season, progress, first few crops.
  // Tap the header to see every crop, the note and the footer.

  Widget buildSeasonGuideCard() {
    final String lang = Localizations.localeOf(context).languageCode;
    final bool mr = lang == 'mr';
    final SeasonSnapshot season = SeasonGuide.snapshot(DateTime.now(), lang);

    final double progress =
        (season.monthInSeason / season.seasonLength).clamp(0.0, 1.0).toDouble();
    final int percent = (progress * 100).round();

    Widget cropChip(String text, {bool soft = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: soft ? _C.background : _C.greenTint,
          borderRadius: BorderRadius.circular(20),
          border: soft ? Border.all(color: _C.line) : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: soft ? _C.muted : _C.greenDark,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    Widget cropSection({
      required String title,
      required List<String> crops,
      required IconData icon,
    }) {
      const int shortCount = 4;
      final bool cut = !seasonExpanded && crops.length > shortCount;
      final List<String> shown =
          cut ? crops.take(shortCount).toList() : crops;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _C.green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _C.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (crops.isEmpty)
            Text(
              mr
                  ? 'या महिन्यासाठी माहिती उपलब्ध नाही'
                  : 'No crops listed for this month',
              style: const TextStyle(color: _C.muted, fontSize: 12.5),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                ...shown.map((crop) => cropChip(crop)),
                if (cut)
                  cropChip('+${crops.length - shortCount}', soft: true),
              ],
            ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER (tap to expand)
          Semantics(
            button: true,
            label: seasonExpanded
                ? (mr ? 'तपशील लपवा' : 'Hide details')
                : (mr ? 'तपशील पहा' : 'Show details'),
            child: InkWell(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              onTap: () {
                setState(() {
                  seasonExpanded = !seasonExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _C.greenTint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: _C.green,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mr ? 'हंगाम मार्गदर्शक' : 'Season Guide',
                            style: const TextStyle(
                              color: _C.green,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            season.seasonName,
                            style: const TextStyle(
                              color: _C.ink,
                              fontSize: 19,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${season.range}  •  ${season.monthName}',
                            style: const TextStyle(
                              color: _C.muted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Icon(
                        seasonExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: _C.muted,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // PROGRESS + CROPS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        season.progressLabel,
                        style: const TextStyle(
                          color: _C.muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        color: _C.green,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: _C.greenTint,
                    valueColor: const AlwaysStoppedAnimation<Color>(_C.green),
                  ),
                ),
                const SizedBox(height: 18),
                cropSection(
                  title: season.sowLabel,
                  crops: season.sow,
                  icon: Icons.grass_rounded,
                ),
                const SizedBox(height: 16),
                cropSection(
                  title: season.harvestLabel,
                  crops: season.harvest,
                  icon: Icons.agriculture_rounded,
                ),
                if (seasonExpanded) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _C.amberTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: _C.amber,
                          size: 21,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            season.note,
                            style: const TextStyle(
                              color: _C.ink,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    season.footer,
                    style: const TextStyle(
                      color: _C.muted,
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FARMING TIP

  Widget buildFarmingTip(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.amberTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.tips_and_updates_rounded,
              color: _C.amber,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.farmingTip,
                  style: const TextStyle(
                    fontSize: 15.5,
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
                    fontSize: 13.5,
                    height: 1.45,
                    color: _C.ink,
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
      decoration: const BoxDecoration(
        color: _C.surface,
        border: Border(top: BorderSide(color: _C.line)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
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
  // Equal width tabs. The label shrinks to fit if it is long.

  Widget buildNavigationItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = selectedIndex == index;
    final Color color = isSelected ? _C.green : _C.muted;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => handleNavigation(index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? _C.greenTint : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 24, color: color),
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
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}