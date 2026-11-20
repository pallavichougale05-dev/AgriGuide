import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

// ============================================================
// CROP RECOMMENDATION SCREEN
// ============================================================
//
// Flow for the farmer:
//   1. Choose the farm location (the server uses the last 12 months
//      of weather there, so nobody has to type temperature or rain).
//   2. Enter the soil values: N, P, K and pH.
//   3. Tap the button -> 5 suitable crops, best match first,
//      each with the varieties grown for that crop.
//
// The model score is NOT shown. The crops are simply listed in order,
// and the first one is marked "Best match".
// ============================================================

class CropScreen extends StatefulWidget {
  const CropScreen({super.key});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

enum CropErrorType {
  noLocation,
  noResults,
  networkError,
}

// One soil input: its limits and its usual range in the model's data.
class _SoilField {
  final TextEditingController controller;
  final String suffix;
  final IconData icon;
  final double hardMin; // below / above this the server refuses the value
  final double hardMax;
  final double usualMin; // range the model was trained on
  final double usualMax;
  final String hint;

  const _SoilField({
    required this.controller,
    required this.suffix,
    required this.icon,
    required this.hardMin,
    required this.hardMax,
    required this.usualMin,
    required this.usualMax,
    required this.hint,
  });
}

class _CropScreenState extends State<CropScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ScrollController scrollController = ScrollController();
  final GlobalKey resultsKey = GlobalKey();

  // Soil input controllers
  final TextEditingController nitrogenController = TextEditingController();
  final TextEditingController phosphorusController = TextEditingController();
  final TextEditingController potassiumController = TextEditingController();
  final TextEditingController phController = TextEditingController();

  // Location search
  final TextEditingController locationController = TextEditingController();

  LocationSearchResult? selectedLocation;
  List<LocationSearchResult> locationResults = [];
  bool isSearchingLocation = false;
  bool searchedLocationOnce = false;

  // API / UI state
  List<CropRecommendation> recommendations = [];
  bool isLoading = false;
  bool valuesOutsideUsualRange = false;
  CropErrorType? errorType;

  // ----------------------------------------------------------
  // SOIL FIELD SETTINGS
  // Usual ranges come from the data the model was trained on.

  late final _SoilField nitrogenField = _SoilField(
    controller: nitrogenController,
    suffix: 'N',
    icon: Icons.science_outlined,
    hardMin: 0,
    hardMax: 500,
    usualMin: 8,
    usualMax: 200,
    hint: '70',
  );

  late final _SoilField phosphorusField = _SoilField(
    controller: phosphorusController,
    suffix: 'P',
    icon: Icons.science_outlined,
    hardMin: 0,
    hardMax: 500,
    usualMin: 5,
    usualMax: 80,
    hint: '40',
  );

  late final _SoilField potassiumField = _SoilField(
    controller: potassiumController,
    suffix: 'K',
    icon: Icons.science_outlined,
    hardMin: 0,
    hardMax: 500,
    usualMin: 5,
    usualMax: 130,
    hint: '42',
  );

  late final _SoilField phField = _SoilField(
    controller: phController,
    suffix: 'pH',
    icon: Icons.grass_outlined,
    hardMin: 0,
    hardMax: 14,
    usualMin: 4.5,
    usualMax: 8.5,
    hint: '6.7',
  );

  @override
  void dispose() {
    nitrogenController.dispose();
    phosphorusController.dispose();
    potassiumController.dispose();
    phController.dispose();
    locationController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // ==========================================================
  // SMALL HELPERS

  // Accepts both 6.5 and 6,5 (some keyboards type a comma).
  double? parseNumber(String text) {
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  String formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  String? validateSoilValue(
    AppLocalizations l10n,
    String? text,
    _SoilField field,
  ) {
    final String value = text?.trim() ?? '';

    if (value.isEmpty) {
      return l10n.cropEnterValue;
    }

    final double? number = parseNumber(value);

    if (number == null) {
      return l10n.invalidNumbers;
    }

    if (number < field.hardMin || number > field.hardMax) {
      return l10n.cropValueRange(
        formatNumber(field.hardMin),
        formatNumber(field.hardMax),
      );
    }

    return null;
  }

  bool isOutsideUsualRange(_SoilField field) {
    final double? number = parseNumber(field.controller.text);

    if (number == null) {
      return false;
    }

    return number < field.usualMin || number > field.usualMax;
  }

  // ==========================================================
  // ERROR MESSAGE

  String _getErrorMessage(AppLocalizations l10n) {
    switch (errorType) {
      case CropErrorType.noLocation:
        return l10n.cropSelectLocation;
      case CropErrorType.noResults:
        return l10n.noCropRecommendations;
      case CropErrorType.networkError:
        return l10n.unableCropRecommendations;
      case null:
        return '';
    }
  }

  // ==========================================================
  // LOCATION SEARCH

  Future<void> searchFarmLocations() async {
    final String query = locationController.text.trim();

    if (query.length < 2) {
      setState(() {
        locationResults = [];
        searchedLocationOnce = false;
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isSearchingLocation = true;
      locationResults = [];
    });

    try {
      final results = await ApiService.searchCropLocations(query);
      if (!mounted) return;

      setState(() {
        locationResults = results;
        searchedLocationOnce = true;
        isSearchingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        locationResults = [];
        isSearchingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.cropLocationSearchError,
          ),
        ),
      );
    }
  }

  void selectFarmLocation(LocationSearchResult location) {
    FocusScope.of(context).unfocus();

    setState(() {
      selectedLocation = location;
      locationController.text = location.displayName;
      locationResults = [];
      searchedLocationOnce = false;
      errorType = null;
    });
  }

  // ==========================================================
  // GET TOP 5 RECOMMENDATIONS

  Future<void> getRecommendations() async {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    // 1) Location first: it decides the climate used by the model.
    if (selectedLocation == null) {
      setState(() {
        errorType = CropErrorType.noLocation;
      });
      return;
    }

    // 2) Soil values.
    if (!formKey.currentState!.validate()) {
      return;
    }

    final double nitrogen = parseNumber(nitrogenController.text)!;
    final double phosphorus = parseNumber(phosphorusController.text)!;
    final double potassium = parseNumber(potassiumController.text)!;
    final double ph = parseNumber(phController.text)!;

    final bool outside = isOutsideUsualRange(nitrogenField) ||
        isOutsideUsualRange(phosphorusField) ||
        isOutsideUsualRange(potassiumField) ||
        isOutsideUsualRange(phField);

    final LocationSearchResult location = selectedLocation!;

    setState(() {
      recommendations = [];
      errorType = null;
      valuesOutsideUsualRange = outside;
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
        errorType = result.isEmpty ? CropErrorType.noResults : null;
        isLoading = false;
      });

      scrollToResults();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        recommendations = [];
        errorType = CropErrorType.networkError;
        isLoading = false;
      });
    }
  }

  // After the answer arrives, bring the results into view.
  void scrollToResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? target = resultsKey.currentContext;

      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          alignment: 0.02,
        );
      }
    });
  }

  // ==========================================================
  // BUILD

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

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
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildIntroBanner(l10n),
                  const SizedBox(height: 18),

                  // STEP 1: LOCATION
                  buildSectionCard(
                    step: '1',
                    title: l10n.cropStepLocationTitle,
                    help: l10n.cropStepLocationHelp,
                    child: buildLocationSelector(l10n),
                  ),
                  const SizedBox(height: 14),

                  // STEP 2: SOIL
                  buildSectionCard(
                    step: '2',
                    title: l10n.cropStepSoilTitle,
                    help: l10n.cropStepSoilHelp,
                    child: buildSoilGrid(l10n),
                  ),
                  const SizedBox(height: 18),

                  buildRecommendationButton(l10n),

                  if (isLoading) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        l10n.cropFindingCrops,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF68756A),
                        ),
                      ),
                    ),
                  ],

                  if (errorType != null) ...[
                    const SizedBox(height: 16),
                    buildErrorCard(l10n),
                  ],

                  if (recommendations.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    buildRecommendations(l10n),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // INTRO BANNER (plain, no decoration)

  Widget buildIntroBanner(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F1DE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.eco_rounded,
            color: Color(0xFF3E8744),
            size: 30,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.cropIntroTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF29372D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.cropIntroSubtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: Color(0xFF59675C),
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
  // SECTION CARD (numbered step)

  Widget buildSectionCard({
    required String step,
    required String title,
    required String help,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E8DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF3D8B47),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  step,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF26372A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            help,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: Color(0xFF788178),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ==========================================================
  // LOCATION FIELD

  Widget buildLocationSelector(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    searchedLocationOnce = false;
                  });
                },
                onSubmitted: (_) => searchFarmLocations(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFFAFBF8),
                  labelText: l10n.cropLocationLabel,
                  hintText: l10n.cropLocationHint,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF68736A),
                  ),
                  hintStyle: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFAFB6B0),
                  ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isSearchingLocation ? null : searchFarmLocations,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D8B47),
                  foregroundColor: Colors.white,
                  elevation: 0,
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
                    : Text(l10n.cropSearch),
              ),
            ),
          ],
        ),

        // Search results
        if (locationResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E5DC)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: locationResults.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
              ),
              itemBuilder: (context, index) {
                final LocationSearchResult location = locationResults[index];

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

        // Nothing found
        if (searchedLocationOnce &&
            locationResults.isEmpty &&
            selectedLocation == null &&
            !isSearchingLocation) ...[
          const SizedBox(height: 8),
          Text(
            l10n.cropNoPlaceFound,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF8E4141),
            ),
          ),
        ],

        // Confirmation
        if (selectedLocation != null) ...[
          const SizedBox(height: 8),
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
                  l10n.cropLocationSelected,
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

  // ==========================================================
  // SOIL INPUT GRID

  Widget buildSoilGrid(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool twoColumns = constraints.maxWidth >= 300;
        final double fieldWidth = twoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        final List<Widget> fields = [
          buildSoilInput(l10n, nitrogenField, l10n.nitrogen, false),
          buildSoilInput(l10n, phosphorusField, l10n.phosphorus, false),
          buildSoilInput(l10n, potassiumField, l10n.potassium, false),
          buildSoilInput(l10n, phField, l10n.soilPh, true),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            for (final Widget field in fields)
              SizedBox(width: fieldWidth, child: field),
          ],
        );
      },
    );
  }

  Widget buildSoilInput(
    AppLocalizations l10n,
    _SoilField field,
    String label,
    bool isLast,
  ) {
    return TextFormField(
      controller: field.controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      validator: (value) => validateSoilValue(l10n, value, field),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFFAFBF8),
        prefixIcon: Icon(
          field.icon,
          color: const Color(0xFF4B8650),
          size: 20,
        ),
        labelText: label,
        hintText: field.hint,
        suffixText: field.suffix,
        // Shows the usual range under the box, e.g. "Usual range: 8 - 200".
        helperText: l10n.cropUsualRange(
          formatNumber(field.usualMin),
          formatNumber(field.usualMax),
        ),
        helperStyle: const TextStyle(
          fontSize: 10,
          color: Color(0xFF8A938A),
        ),
        errorMaxLines: 2,
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
          borderSide: const BorderSide(color: Color(0xFFE0E5DC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFF4B8D4D),
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFFD46A5C)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFFD46A5C),
            width: 1.6,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
        ),
      ),
    );
  }

  // ==========================================================
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
        child: isLoading
            ? Row(
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
            : Text(
                l10n.getTop5Recommendations,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  // ==========================================================
  // ERROR CARD

  Widget buildErrorCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFF2CECE)),
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

  // ==========================================================
  // RESULTS

  Widget buildRecommendations(AppLocalizations l10n) {
    return Column(
      key: resultsKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.top5Recommendations,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: Color(0xFF26372A),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          l10n.cropResultsSubtitle,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.4,
            color: Color(0xFF788178),
          ),
        ),
        const SizedBox(height: 14),

        for (int index = 0; index < recommendations.length; index++) ...[
          buildCropCard(
            l10n: l10n,
            recommendation: recommendations[index],
            rank: index + 1,
          ),
          if (index != recommendations.length - 1)
            const SizedBox(height: 11),
        ],

        const SizedBox(height: 16),

        // Soil values far from what the model was trained on.
        if (valuesOutsideUsualRange) ...[
          buildNoteBox(
            icon: Icons.info_outline_rounded,
            text: l10n.cropOutOfRangeNote,
            background: const Color(0xFFFFF6E5),
            border: const Color(0xFFF0DDB0),
            color: const Color(0xFF7A5B12),
          ),
          const SizedBox(height: 10),
        ],

        buildNoteBox(
          icon: Icons.cloud_outlined,
          text: l10n.cropClimateNote,
          background: const Color(0xFFEFF5EA),
          border: const Color(0xFFDCE8D4),
          color: const Color(0xFF4B6B52),
        ),
        const SizedBox(height: 10),
        buildNoteBox(
          icon: Icons.verified_user_outlined,
          text: l10n.cropPrototypeNote,
          background: const Color(0xFFEFF5EA),
          border: const Color(0xFFDCE8D4),
          color: const Color(0xFF4B6B52),
        ),
      ],
    );
  }

  Widget buildNoteBox({
    required IconData icon,
    required String text,
    required Color background,
    required Color border,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ONE CROP CARD
  // Rank, crop name, and the varieties grown for it.
  // The first card is marked "Best match". No score is shown.

  Widget buildCropCard({
    required AppLocalizations l10n,
    required CropRecommendation recommendation,
    required int rank,
  }) {
    final bool isTop = rank == 1;
    const int maxChips = 4;

    final List<String> varieties = recommendation.varieties;
    final List<String> shown = varieties.take(maxChips).toList();
    final int hidden = varieties.length - shown.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTop ? const Color(0xFFA9CFA9) : const Color(0xFFE2E7DE),
          width: isTop ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isTop
                      ? const Color(0xFF3D8B47)
                      : const Color(0xFFEFF3EC),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isTop ? Colors.white : const Color(0xFF68736A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation.crop,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF29372D),
                  ),
                ),
              ),
              if (isTop)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F1DE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.cropBestMatch,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3E8744),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            l10n.cropVarietiesGrown,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF788178),
            ),
          ),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            Text(
              l10n.cropNoVarieties,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF8A938A),
              ),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final String variety in shown) buildVarietyChip(variety),
                if (hidden > 0)
                  buildVarietyChip(
                    l10n.cropMoreVarieties(hidden),
                    muted: true,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget buildVarietyChip(String text, {bool muted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFF2F4F0) : const Color(0xFFF0F6EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: muted ? const Color(0xFFE2E6DE) : const Color(0xFFDDE9D6),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: muted ? const Color(0xFF7C867E) : const Color(0xFF3F5E45),
        ),
      ),
    );
  }
}