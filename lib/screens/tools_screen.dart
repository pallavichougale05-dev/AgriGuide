import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import 'crop_screen.dart';
import 'disease_screen.dart';
import 'weather_screen.dart';
import 'chatbot_screen.dart';
import 'knowledge_screen.dart';
import 'diary_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  void openScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n =
        AppLocalizations.of(context)!;

    final bool isMarathi =
        Localizations.localeOf(context).languageCode == 'mr';

    // Updated display names.
    // Existing screens, APIs and database identifiers remain unchanged.

    final String cropName = isMarathi
        ? 'पीक शिफारस'
        : 'Crop Recommendation';

    final String diseaseName = isMarathi
        ? 'रोग ओळख आणि उपाय'
        : 'Disease Detection & Solution';

    final String weatherName = isMarathi
        ? 'शेती हवामान'
        : 'Farm Weather';

    final String assistantName = isMarathi
        ? 'शेती सहाय्यक'
        : 'Farming Assistant';

    final String knowledgeName = isMarathi
        ? 'शेतीविषयक ज्ञान'
        : 'Farming Knowledge';

    final String farmName = isMarathi
        ? 'माझी शेती'
        : 'My Farm';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F2),

      // APP BAR
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F2),
        foregroundColor: const Color(0xFF20352A),
        elevation: 0,
        title: Text(
          l10n.tools,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: Color(0xFF20352A),
          ),
        ),
        actions: [
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F1DD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Color(0xFF3E8744),
              size: 23,
            ),
          ),
        ],
      ),

      // PAGE CONTENT
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            18,
            2,
            18,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.farmingTools,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7A847C),
                ),
              ),

              const SizedBox(height: 24),

              // RECOMMEND
              buildSectionTitle(l10n.recommend),

              const SizedBox(height: 10),

              buildToolCard(
                context: context,
                title: cropName,
                subtitle: l10n.cropRecommendationSubtitle,
                icon: Icons.eco_rounded,
                iconColor: const Color(0xFF438C47),
                iconBackground: const Color(0xFFE6F2DF),
                screen: const CropScreen(),
              ),

              const SizedBox(height: 20),

              // PROTECT
              buildSectionTitle(l10n.protect),

              const SizedBox(height: 10),

              buildToolCard(
                context: context,
                title: diseaseName,
                subtitle: l10n.diseaseDetectionSubtitle,
                icon: Icons.health_and_safety_rounded,
                iconColor: const Color(0xFF4C8147),
                iconBackground: const Color(0xFFF2EBDD),
                screen: const DiseaseScreen(),
              ),

              const SizedBox(height: 20),

              // PLAN
              buildSectionTitle(l10n.plan),

              const SizedBox(height: 10),

              buildToolCard(
                context: context,
                title: weatherName,
                subtitle: l10n.farmWeatherSubtitle,
                icon: Icons.cloud_rounded,
                iconColor: const Color(0xFF4C808A),
                iconBackground: const Color(0xFFE2EFF0),
                screen: const WeatherScreen(),
              ),

              const SizedBox(height: 20),

              // ASSIST
              buildSectionTitle(l10n.assist),

              const SizedBox(height: 10),

              buildToolCard(
                context: context,
                title: assistantName,
                subtitle: l10n.agriAssistantSubtitle,
                icon: Icons.smart_toy_rounded,
                iconColor: const Color(0xFF7561A7),
                iconBackground: const Color(0xFFEEE9F7),
                screen: const ChatbotScreen(),
              ),

              const SizedBox(height: 20),

              // KNOWLEDGE AND RECORDS
              buildSectionTitle(l10n.knowledgeAndRecords),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: buildCompactToolCard(
                      context: context,
                      title: knowledgeName,
                      subtitle: l10n.knowledgeHubSubtitle,
                      icon: Icons.menu_book_rounded,
                      iconColor: const Color(0xFF4A8052),
                      backgroundColor: const Color(0xFFE8F1E7),
                      screen: const KnowledgeScreen(),
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: buildCompactToolCard(
                      context: context,
                      title: farmName,
                      subtitle: l10n.farmDiarySubtitle,
                      icon: Icons.edit_note_rounded,
                      iconColor: const Color(0xFF80684E),
                      backgroundColor: const Color(0xFFF2ECE2),
                      screen: const DiaryScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SECTION TITLE
  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: Color(0xFF7A847C),
      ),
    );
  }

  // MAIN TOOL CARD
  Widget buildToolCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required Widget screen,
  }) {
    return GestureDetector(
      onTap: () {
        openScreen(context, screen);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE2E7DE),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 9,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // TOOL ICON
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),

            const SizedBox(width: 14),

            // TOOL INFORMATION
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF29372D),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      height: 1.3,
                      color: Color(0xFF788178),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ARROW
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF8A928B),
            ),
          ],
        ),
      ),
    );
  }

  // COMPACT TOOL CARD
  Widget buildCompactToolCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Widget screen,
  }) {
    return GestureDetector(
      onTap: () {
        openScreen(context, screen);
      },
      child: Container(
        height: 145,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE2E7DE),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ICON
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),

            const Spacer(),

            // TITLE
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF29372D),
              ),
            ),

            const SizedBox(height: 3),

            // SUBTITLE AND ARROW
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      height: 1.2,
                      color: Color(0xFF7A847C),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Color(0xFF7D877F),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}