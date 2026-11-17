import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

class CropScreen extends StatefulWidget {
  const CropScreen({super.key});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

enum CropErrorType {
  emptyFields,
  invalidNumbers,
  noResults,
  networkError,
}

class _CropScreenState extends State<CropScreen> {
  // Soil input controllers
  final TextEditingController nitrogenController =
      TextEditingController();
  final TextEditingController phosphorusController =
      TextEditingController();
  final TextEditingController potassiumController =
      TextEditingController();
  final TextEditingController phController =
      TextEditingController();

  // Location search
  final TextEditingController locationController =
      TextEditingController();

  LocationSearchResult? selectedLocation;
  List<LocationSearchResult> locationResults = [];
  bool isSearchingLocation = false;

  // API / UI state
  List<CropRecommendation> recommendations = [];
  bool isLoading = false;
  CropErrorType? errorType;

  bool get isMarathi =>
      Localizations.localeOf(context).languageCode == 'mr';

  String get locationLabel =>
      isMarathi ? 'शेताचे ठिकाण' : 'Farm Location';

  String get locationHint =>
      isMarathi ? 'गाव किंवा शहर शोधा' : 'Search village or city';

  String get searchLabel =>
      isMarathi ? 'शोधा' : 'Search';

  String get selectLocationMessage =>
      isMarathi
          ? 'शिफारसी मिळवण्यापूर्वी शेताचे ठिकाण निवडा.'
          : 'Select your farm location before requesting recommendations.';

  String get locationSearchError =>
      isMarathi
          ? 'ठिकाण शोधता आले नाही. पुन्हा प्रयत्न करा.'
          : 'Could not search locations. Please try again.';

  @override
  void dispose() {
    nitrogenController.dispose();
    phosphorusController.dispose();
    potassiumController.dispose();
    phController.dispose();
    locationController.dispose();
    super.dispose();
  }

  // ERROR MESSAGE

  String _getErrorMessage(AppLocalizations l10n) {
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

  // LOCATION SEARCH

  Future<void> searchFarmLocations() async {
    final query = locationController.text.trim();

    if (query.length < 2) {
      setState(() {
        locationResults = [];
      });
      return;
    }

    setState(() {
      isSearchingLocation = true;
      locationResults = [];
    });

    try {
      final results = await ApiService.searchCropLocations(query);
      if (!mounted) return;

      setState(() {
        locationResults = results;
        isSearchingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        locationResults = [];
        isSearchingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locationSearchError)),
      );
    }
  }

  void selectFarmLocation(LocationSearchResult location) {
    setState(() {
      selectedLocation = location;
      locationController.text = location.displayName;
      locationResults = [];
      errorType = null;
    });
  }

  // LOCATION FIELD

  Widget buildLocationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locationLabel,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF526354),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: locationController,
                textInputAction: TextInputAction.search,
                onChanged: (_) {
                  setState(() {
                    selectedLocation = null;
                    locationResults = [];
                  });
                },
                onSubmitted: (_) => searchFarmLocations(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: locationHint,
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF4B8650),
                  ),
                  suffixIcon: selectedLocation != null
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF438C47),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFE0E5DC),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF4B8D4D),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isSearchingLocation
                    ? null
                    : searchFarmLocations,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D8B47),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: isSearchingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(searchLabel),
              ),
            ),
          ],
        ),

        if (locationResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE0E5DC),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: locationResults.length,
              // ignore: unnecessary_underscores
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
              ),
              itemBuilder: (context, index) {
                final location = locationResults[index];

                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF4B8650),
                  ),
                  title: Text(
                    location.displayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => selectFarmLocation(location),
                );
              },
            ),
          ),
        ],

        if (selectedLocation != null) ...[
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 15,
                color: Color(0xFF438C47),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  isMarathi
                      ? 'शेताचे ठिकाण निवडले आहे'
                      : 'Farm location selected',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF438C47),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // VALIDATION

  bool _validateFields() {
    final fields = [
      nitrogenController,
      phosphorusController,
      potassiumController,
      phController,
    ];

    for (final field in fields) {
      if (field.text.trim().isEmpty) {
        setState(() {
          errorType = CropErrorType.emptyFields;
        });
        return false;
      }
    }

    if (selectedLocation == null) {
      setState(() {
        errorType = CropErrorType.emptyFields;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(selectLocationMessage)),
      );

      return false;
    }

    return true;
  }

  // GET TOP 5 RECOMMENDATIONS

  Future<void> getRecommendations() async {
    if (isLoading) return;

    if (!_validateFields()) return;

    final double? nitrogen =
        double.tryParse(nitrogenController.text.trim());

    final double? phosphorus =
        double.tryParse(phosphorusController.text.trim());

    final double? potassium =
        double.tryParse(potassiumController.text.trim());

    final double? ph =
        double.tryParse(phController.text.trim());

    if (nitrogen == null ||
        phosphorus == null ||
        potassium == null ||
        ph == null) {
      setState(() {
        recommendations = [];
        errorType = CropErrorType.invalidNumbers;
      });
      return;
    }

    final location = selectedLocation!;

    setState(() {
      recommendations = [];
      errorType = null;
      isLoading = true;
    });

    try {
      final result = await ApiService.recommendCrops(
        nitrogen: nitrogen,
        phosphorus: phosphorus,
        potassium: potassium,
        ph: ph,
        latitude: location.latitude,
        longitude: location.longitude,
      );

      if (!mounted) return;

      setState(() {
        recommendations = result;
        errorType = result.isEmpty
            ? CropErrorType.noResults
            : null;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        recommendations = [];
        errorType = CropErrorType.networkError;
        isLoading = false;
      });
    }
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n =
        AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F2),
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
            margin: const EdgeInsets.only(right: 14),
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeroCard(l10n),
              const SizedBox(height: 20),

              Text(
                l10n.farmConditions,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF26372A),
                ),
              ),
              const SizedBox(height: 5),

              Text(
                l10n.farmConditionsSubtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF788178),
                ),
              ),
              const SizedBox(height: 14),

              buildInputGrid(l10n),
              const SizedBox(height: 18),

              buildLocationSelector(),
              const SizedBox(height: 16),

              if (errorType != null) ...[
                buildErrorCard(l10n),
                const SizedBox(height: 16),
              ],

              if (recommendations.isNotEmpty) ...[
                buildRecommendations(l10n),
                const SizedBox(height: 18),
              ],

              buildRecommendationButton(l10n),
              const SizedBox(height: 10),

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

  Widget buildHeroCard(AppLocalizations l10n) {
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
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Color(0xFF438C47),
              size: 31,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 5),
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

  // SOIL INPUT GRID

  Widget buildInputGrid(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool twoColumns = constraints.maxWidth >= 340;
        final double fieldWidth = twoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        final fields = [
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
            controller: phController,
            label: l10n.soilPh,
            hint: 'e.g. 6.5',
            suffix: 'pH',
            icon: Icons.grass_outlined,
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
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF4B8650),
          size: 20,
        ),
        labelText: label,
        hintText: hint,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFFE0E5DC),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFF4B8D4D),
            width: 1.6,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
        ),
      ),
    );
  }

  // ERROR CARD

  Widget buildErrorCard(AppLocalizations l10n) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB84C4C),
            size: 21,
          ),
          const SizedBox(width: 10),
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

  Widget buildRecommendations(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F2E1),
                borderRadius: BorderRadius.circular(20),
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
        const SizedBox(height: 5),
        Text(
          l10n.recommendationVarietyInfo,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF788178),
          ),
        ),
        const SizedBox(height: 12),
        for (int index = 0; index < recommendations.length; index++) ...[
          buildRecommendationCard(
            recommendation: recommendations[index],
            rank: index + 1,
            l10n: l10n,
          ),
          if (index != recommendations.length - 1)
            const SizedBox(height: 11),
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

    // Backend score is between 0 and 1.
    final double progress =
        recommendation.score.clamp(0.0, 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    fontWeight: FontWeight.w800,
                    color: isTop
                        ? const Color(0xFF3E8744)
                        : const Color(0xFF68736A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.crop,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF29372D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.eco_outlined,
                          size: 15,
                          color: Color(0xFF4A8C4C),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${l10n.variety}: ${recommendation.varieties.join(', ')}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF667269),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${recommendation.percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3E8744),
                    ),
                  ),
                  Text(
                    l10n.match,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF8A938A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFEDF1EA),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF69A76D),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // PRIMARY BUTTON

  Widget buildRecommendationButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : getRecommendations,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3D8B47),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFA8BCA9),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? Row(
                  key: const ValueKey('loading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.loading,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('button'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.getTop5Recommendations,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
