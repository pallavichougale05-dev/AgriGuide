import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

class CropScreen extends StatefulWidget {
  const CropScreen({super.key});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

// ERROR TYPES

enum CropErrorType {
  emptyFields,
  invalidNumbers,
  noResults,
  networkError,
}

// CROP SCREEN STATE

class _CropScreenState extends State<CropScreen> {
  // INPUT CONTROLLERS

  final TextEditingController nitrogenController =
      TextEditingController();

  final TextEditingController phosphorusController =
      TextEditingController();

  final TextEditingController potassiumController =
      TextEditingController();

  final TextEditingController temperatureController =
      TextEditingController();

  final TextEditingController humidityController =
      TextEditingController();

  final TextEditingController phController =
      TextEditingController();

  final TextEditingController rainfallController =
      TextEditingController();

  // API / UI STATE

  List<CropRecommendation> recommendations = [];
  bool isLoading = false;
  CropErrorType? errorType;

  // CLEAN UP

  @override
  void dispose() {
    nitrogenController.dispose();
    phosphorusController.dispose();
    potassiumController.dispose();
    temperatureController.dispose();
    humidityController.dispose();
    phController.dispose();
    rainfallController.dispose();

    super.dispose();
  }

  // ERROR MESSAGE

  String _getErrorMessage(
    AppLocalizations l10n,
  ) {
    switch (errorType) {
      case CropErrorType.emptyFields:
        return l10n.fillFarmConditions;

      case CropErrorType.invalidNumbers:
        return l10n.invalidNumbers;

      case CropErrorType.noResults:
        return l10n.noCropRecommendations;

      case CropErrorType.networkError:
        return l10n.unableCropRecommendations;

      case null:
        return '';
    }
  }

  // GET TOP 5 RECOMMENDATIONS

  Future<void> getRecommendations() async {
    // Prevent duplicate requests.
    if (isLoading) {
      return;
    }

    // VALIDATE EMPTY FIELDS

    if (!_validateFields()) {
      return;
    }

    // PARSE VALUES

    final double? nitrogen =
        double.tryParse(nitrogenController.text.trim());

    final double? phosphorus =
        double.tryParse(phosphorusController.text.trim());

    final double? potassium =
        double.tryParse(potassiumController.text.trim());

    final double? temperature =
        double.tryParse(temperatureController.text.trim());

    final double? humidity =
        double.tryParse(humidityController.text.trim());

    final double? ph =
        double.tryParse(phController.text.trim());

    final double? rainfall =
        double.tryParse(rainfallController.text.trim());

    // NUMERIC VALIDATION

    if (nitrogen == null ||
        phosphorus == null ||
        potassium == null ||
        temperature == null ||
        humidity == null ||
        ph == null ||
        rainfall == null) {
      setState(() {
        recommendations = [];
        errorType = CropErrorType.invalidNumbers;
      });

      return;
    }

    // START LOADING

    setState(() {
      recommendations = [];
      errorType = null;
      isLoading = true;
    });

    try {
      // CALL BACKEND
      // ApiService handles the actual HTTP request.

      final List<CropRecommendation> result =
          await ApiService.recommendCrops(
        nitrogen: nitrogen,
        phosphorus: phosphorus,
        potassium: potassium,
        temperature: temperature,
        humidity: humidity,
        ph: ph,
        rainfall: rainfall,
      );

      if (!mounted) {
        return;
      }

      // EMPTY RESULT

      if (result.isEmpty) {
        setState(() {
          recommendations = [];
          errorType = CropErrorType.noResults;
          isLoading = false;
        });

        return;
      }

      // STORE RESULT

      setState(() {
        recommendations = result;
        errorType = null;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      // Do not expose technical API exceptions to the farmer.
      setState(() {
        recommendations = [];
        errorType = CropErrorType.networkError;
        isLoading = false;
      });
    }
  }

  // SAFE POTASSIUM VALUE
  // This helper keeps the call readable while still allowing
  // normal decimal input.

  String kPotassiumText() {
    return potassiumController.text.trim();
  }

  // INPUT VALIDATION

  bool _validateFields() {
    final List<TextEditingController> fields = [
      nitrogenController,
      phosphorusController,
      potassiumController,
      temperatureController,
      humidityController,
      phController,
      rainfallController,
    ];

    for (final field in fields) {
      if (field.text.trim().isEmpty) {
        setState(() {
          errorType = CropErrorType.emptyFields;
        });

        return false;
      }
    }

    return true;
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n =
        AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F2),

     // APP BAR
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F2),
        foregroundColor: const Color(0xFF20352A),
        elevation: 0,

        title: Text(
          l10n.cropRecommendation,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(
              right: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F1DD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Color(0xFF3E8744),
              size: 22,
            ),
          ),
        ],
      ),

      // CONTENT

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // HERO CARD

              buildHeroCard(l10n),
              const SizedBox(
                height: 20,
              ),

              // FARM CONDITIONS HEADER

              Text(
                l10n.farmConditions,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF26372A),
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                l10n.farmConditionsSubtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF788178),
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // INPUTS

              buildInputGrid(l10n),
              const SizedBox(
                height: 16,
              ),

              // ERROR

              if (errorType != null)
                buildErrorCard(l10n),
              if (errorType != null)
                const SizedBox(
                  height: 16,
                ),

              // RECOMMENDATIONS

              if (recommendations.isNotEmpty)
                buildRecommendations(l10n),

              if (recommendations.isNotEmpty)
                const SizedBox(
                  height: 18,
                ),

              // MAIN ACTION

              buildRecommendationButton(l10n),
              const SizedBox(
                height: 10,
              ),

              // Small privacy / data note.
              Center(
                child: Text(
                  l10n.weatherDataNote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF89918A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // HERO CARD

  Widget buildHeroCard(
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE7F3DE),
            Color(0xFFDDEDD6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD1E3C9),
        ),
      ),
      child: Row(
        children: [
          // ICON

          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.72,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Color(0xFF438C47),
              size: 31,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          // TEXT

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.cropIntroTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF29372D),
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  l10n.cropIntroSubtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: Color(0xFF68756A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // INPUT GRID
  // Uses two columns on normal phone-sized screens.
  // This significantly reduces scrolling compared with the
  // original seven full-width fields.

  Widget buildInputGrid(
    AppLocalizations l10n,
  ) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool twoColumns =
            constraints.maxWidth >= 340;

        final double fieldWidth = twoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        final List<Widget> fields = [
          buildInputField(
            controller: nitrogenController,
            label: l10n.nitrogen,
            hint: 'e.g. 90',
            suffix: 'N',
            icon: Icons.science_outlined,
          ),
          buildInputField(
            controller: phosphorusController,
            label: l10n.phosphorus,
            hint: 'e.g. 42',
            suffix: 'P',
            icon: Icons.science_outlined,
          ),
          buildInputField(
            controller: potassiumController,
            label: l10n.potassium,
            hint: 'e.g. 43',
            suffix: 'K',
            icon: Icons.science_outlined,
          ),
          buildInputField(
            controller: temperatureController,
            label: l10n.temperature,
            hint: 'e.g. 25.5',
            suffix: '°C',
            icon: Icons.thermostat_outlined,
          ),
          buildInputField(
            controller: humidityController,
            label: l10n.humidity,
            hint: 'e.g. 80',
            suffix: '%',
            icon: Icons.water_drop_outlined,
          ),
          buildInputField(
            controller: phController,
            label: l10n.soilPh,
            hint: 'e.g. 6.5',
            suffix: 'pH',
            icon: Icons.grass_outlined,
          ),
          buildInputField(
            controller: rainfallController,
            label: l10n.rainfall,
            hint: 'e.g. 200',
            suffix: 'mm',
            icon: Icons.water_rounded,
          ),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final field in fields)
              SizedBox(
                width: fieldWidth,
                child: field,
              ),
          ],
        );
      },
    );
  }

  // INPUT FIELD

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      textInputAction: TextInputAction.next,

      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,

        // Field icon.
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF4B8650),
          size: 20,
        ),

        // Field title.
        labelText: label,

        // Example value.
        hintText: hint,

        // Unit.
        suffixText: suffix,

        labelStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFF68736A),
        ),

        hintStyle: const TextStyle(
          fontSize: 11,
          color: Color(0xFFAFB6B0),
        ),

        suffixStyle: const TextStyle(
          fontSize: 11,
          color: Color(0xFF758075),
          fontWeight: FontWeight.w700,
        ),

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFFE0E5DC),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFF4B8D4D),
            width: 1.6,
          ),
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
        ),
      ),
    );
  }

  // ERROR CARD

  Widget buildErrorCard(
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFF2CECE),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB84C4C),
            size: 21,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              _getErrorMessage(l10n),
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: Color(0xFF8E4141),
              ),
            ),
          ),

          const SizedBox(
            width: 4,
          ),

          GestureDetector(
            onTap: () {
              setState(() {
                errorType = null;
              });
            },
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: Color(0xFF9D5A5A),
            ),
          ),
        ],
      ),
    );
  }

  // RECOMMENDATIONS SECTION

  Widget buildRecommendations(
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.top5Recommendations,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF26372A),
                ),
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F2E1),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                '${recommendations.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF438C47),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 5,
        ),

        Text(
          l10n.recommendationVarietyInfo,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF788178),
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        for (int index = 0;
            index < recommendations.length;
            index++) ...[
          buildRecommendationCard(
            recommendation:
                recommendations[index],
            rank: index + 1,
            l10n: l10n,
          ),

          if (index !=
              recommendations.length - 1)
            const SizedBox(
              height: 11,
            ),
        ],
      ],
    );
  }

  // RECOMMENDATION CARD

  Widget buildRecommendationCard({
    required CropRecommendation recommendation,
    required int rank,
    required AppLocalizations l10n,
  }) {
    final bool isTop = rank == 1;

    // Keep the progress indicator between 0 and 1.
    final double progress =
        (recommendation.score / 100)
            .clamp(0.0, 1.0);

    return AnimatedContainer(
      duration:
          const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(21),
        border: Border.all(
          color: isTop
              ? const Color(0xFFBBD8BB)
              : const Color(0xFFE2E7DE),
          width: isTop ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isTop ? 0.055 : 0.03,
            ),
            blurRadius: isTop ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [

          // TOP ROW

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // Rank badge.
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isTop
                      ? const Color(0xFFE4F1DE)
                      : const Color(0xFFF2F5F0),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                    color: isTop
                        ? const Color(0xFF3E8744)
                        : const Color(0xFF68736A),
                  ),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              // Crop + variety.
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.crop,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF29372D),
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons.eco_outlined,
                          size: 15,
                          color:
                              Color(0xFF4A8C4C),
                        ),

                        const SizedBox(
                          width: 5,
                        ),

                        Expanded(
                          child: Text(
                            '${l10n.variety}: '
                            '${recommendation.variety}',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Color(0xFF667269),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              // Match percentage.
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    '${recommendation.score.toStringAsFixed(0)}%',
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Color(0xFF3E8744),
                    ),
                  ),

                  Text(
                    l10n.match,
                    style:
                        const TextStyle(
                      fontSize: 9,
                      color:
                          Color(0xFF8A938A),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          // MATCH PROGRESS

          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor:
                  const Color(0xFFEDF1EA),
              valueColor:
                  const AlwaysStoppedAnimation<
                      Color>(
                Color(0xFF69A76D),
              ),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // INFO STRIP

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF4F8F1),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                  color: Color(0xFF4A8E50),
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    l10n.suitableCropInfo,
                    style: const TextStyle(
                      fontSize: 10.5,
                      height: 1.3,
                      color:
                          Color(0xFF637065),
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

  // PRIMARY BUTTON

  Widget buildRecommendationButton(
    AppLocalizations l10n,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed:
            isLoading
                ? null
                : getRecommendations,

        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF3D8B47),
          foregroundColor: Colors.white,

          disabledBackgroundColor:
              const Color(0xFFA8BCA9),

          elevation: 0,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
        ),

        child: AnimatedSwitcher(
          duration:
              const Duration(milliseconds: 180),

          child: isLoading
              ? Row(
                  key: const ValueKey(
                    'loading',
                  ),
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Text(
                      l10n.loading,
                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey(
                    'button',
                  ),
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 19,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Text(
                      l10n.getTop5Recommendations,
                      style:
                          const TextStyle(
                        fontSize: 14.5,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}