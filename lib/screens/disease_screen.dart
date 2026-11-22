import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

class DiseaseScreen extends StatefulWidget {
  const DiseaseScreen({super.key});

  @override
  State<DiseaseScreen> createState() => _DiseaseScreenState();
}

class _DiseaseScreenState extends State<DiseaseScreen> {
  final ImagePicker imagePicker = ImagePicker();

  bool isPickingImage = false;
  bool isLoading = false;

  File? selectedImage;

  String? detectedDisease;
  String? detectedCrop;
  String? affectedPart;

  bool isHealthy = false;
  bool isPestResult = false;

  String? symptoms;
  String? causes;
  String? fertilizer;
  String? management;
  String? reviewNote;
  String? sprayNote;

  String? solution;
  String? errorMessage;

  // BILINGUAL HARDCODED TEXT
  String bilingual(String english, String marathi) {
    final language = Localizations.localeOf(context).languageCode;
    return language == 'mr' ? marathi : english;
  }

  // RESET RESULT
  void clearResult() {
    detectedDisease = null;
    detectedCrop = null;
    affectedPart = null;

    isHealthy = false;
    isPestResult = false;

    symptoms = null;
    causes = null;
    fertilizer = null;
    management = null;
    reviewNote = null;
    sprayNote = null;

    solution = null;
  }

  // PICK IMAGE
  Future<void> pickImage(ImageSource source) async {
    if (isPickingImage || isLoading) return;

    setState(() {
      isPickingImage = true;
      errorMessage = null;
    });

    try {
      final XFile? pickedFile = await imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      if (!mounted) return;

      setState(() {
        selectedImage = File(pickedFile.path);
        clearResult();
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;

      setState(() {
        errorMessage = l10n.unableSelectImage;
      });
    } finally {
      if (mounted) {
        setState(() {
          isPickingImage = false;
        });
      }
    }
  }

  // IMAGE SOURCE BOTTOM SHEET
  void showImageSourceOptions() {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9DED9),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.chooseImageSource,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF26372A),
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                buildSourceOption(
                  icon: Icons.camera_alt_outlined,
                  title: l10n.takePhoto,
                  subtitle: l10n.takePhotoSubtitle,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 11),
                buildSourceOption(
                  icon: Icons.photo_library_outlined,
                  title: l10n.chooseFromGallery,
                  subtitle: l10n.gallerySubtitle,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // IMAGE SOURCE OPTION
  Widget buildSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isPickingImage || isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8F3),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE0E8DC),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F1DF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF438C47),
                size: 24,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF344238),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7A847C),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF89928B),
            ),
          ],
        ),
      ),
    );
  }

  // REMOVE IMAGE
  void removeImage() {
    if (isLoading) return;

    setState(() {
      selectedImage = null;
      clearResult();
      errorMessage = null;
    });
  }

  // DISEASE DETECTION API
  Future<void> detectDisease() async {
    final l10n = AppLocalizations.of(context)!;

    if (selectedImage == null) {
      setState(() {
        errorMessage = l10n.selectCropImageFirst;
      });
      return;
    }

    setState(() {
      isLoading = true;
      clearResult();
      errorMessage = null;
    });

    try {
      final String lang =
          Localizations.localeOf(context).languageCode;

      final DiseaseDetectionResponse response =
          await ApiService.detectDisease(
        selectedImage!,
        lang: lang,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;

        if (!response.success) {
          errorMessage = response.message.isNotEmpty
              ? response.message
              : bilingual(
                  'Disease detection could not process the image.',
                  'प्रतिमा तपासता आली नाही. कृपया पुन्हा प्रयत्न करा.',
                );
          return;
        }

        detectedCrop = response.crop;
        detectedDisease = response.disease;
        affectedPart = response.part;

        isHealthy = response.isHealthy;
        isPestResult = response.isPest;

        symptoms = response.symptoms;
        causes = response.causes;
        fertilizer = response.fertilizer;
        management = response.management;
        reviewNote = response.reviewNote;
        sprayNote = response.sprayNote;

        // Confidence and alternatives are intentionally
        // not displayed in this screen.

        solution = [
          symptoms,
          causes,
          fertilizer,
          management,
          sprayNote,
          reviewNote,
        ].where(
          (value) => value != null && value.trim().isNotEmpty,
        ).join('\n\n');

        if (detectedDisease == null ||
            detectedDisease!.trim().isEmpty) {
          errorMessage = bilingual(
            'The server returned no disease prediction.',
            'सर्व्हरकडून रोगाची माहिती मिळाली नाही.',
          );
          clearResult();
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = bilingual(
          'Unable to connect to the disease detection service.\n'
          'Please make sure the backend is running and try again.',
          'रोग ओळखणी सेवेशी जोडता आले नाही.\n'
          'बॅकएंड सुरू असल्याची खात्री करून पुन्हा प्रयत्न करा.',
        );
      });

      debugPrint('Disease detection error: $error');
    }
  }

  // MAIN BUILD
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8F2),
        foregroundColor: const Color(0xFF20352A),
        elevation: 0,
        title: Text(
          l10n.diseaseDetection,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 5, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildIntroCard(),
            const SizedBox(height: 25),

            sectionHeading(
              l10n.uploadCropImage,
              l10n.uploadCropImageSubtitle,
            ),

            const SizedBox(height: 15),
            buildImagePreview(),
            const SizedBox(height: 13),
            buildImageButtons(),

            const SizedBox(height: 20),

            if (errorMessage != null) ...[
              buildMessageCard(),
              const SizedBox(height: 16),
            ],

            buildDetectButton(),

            const SizedBox(height: 25),

            if (detectedDisease != null) ...[
              sectionHeading(
                bilingual('Detection report', 'रोग ओळख अहवाल'),
                bilingual(
                  'Results from your uploaded leaf image',
                  'तुम्ही अपलोड केलेल्या पानाच्या प्रतिमेचा निकाल',
                ),
              ),
              const SizedBox(height: 13),
              buildDiseaseResult(),
              if (solution != null && solution!.isNotEmpty) ...[
                const SizedBox(height: 16),
                buildSolutionCard(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // SECTION HEADING
  Widget sectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF26372A),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.5,
            color: Color(0xFF788178),
          ),
        ),
      ],
    );
  }

  // INTRO CARD
  Widget buildIntroCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE5F2DF),
            Color(0xFFF3F8EF),
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFD7E8D0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.spa_outlined,
              color: Color(0xFF438C47),
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.diseaseIntroTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF28412D),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  l10n.diseaseIntroSubtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: Color(0xFF627065),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // IMAGE PREVIEW
  Widget buildImagePreview() {
    final l10n = AppLocalizations.of(context)!;

    if (selectedImage == null) {
      return Container(
        width: double.infinity,
        height: 245,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4ED),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFD7E1D3),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                size: 36,
                color: Color(0xFF6C846F),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              l10n.noImageSelected,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF405046),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Text(
                l10n.imageHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  height: 1.5,
                  color: Color(0xFF7C857E),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 290,
            color: const Color(0xFFECEFEA),
            child: Image.file(
              selectedImage!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 45,
                    color: Color(0xFF879087),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                onTap: isLoading ? null : removeImage,
                borderRadius: BorderRadius.circular(13),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 15,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    bilingual('Image selected', 'प्रतिमा निवडली'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CAMERA AND GALLERY BUTTONS
  Widget buildImageButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isPickingImage || isLoading
                ? null
                : () => pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined, size: 19),
            label: Text(l10n.camera),
            style: imageButtonStyle(),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isPickingImage || isLoading
                ? null
                : () => pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined, size: 19),
            label: Text(l10n.gallery),
            style: imageButtonStyle(),
          ),
        ),
      ],
    );
  }

  ButtonStyle imageButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF438C47),
      disabledForegroundColor: const Color(0xFF9BA59C),
      side: const BorderSide(
        color: Color(0xFFBFD5BA),
      ),
      minimumSize: const Size(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      textStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  // ERROR MESSAGE
  Widget buildMessageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E9),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFF0D9B8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFB67629),
            size: 23,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              errorMessage ?? '',
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.5,
                color: Color(0xFF765A35),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // DETECT BUTTON
  Widget buildDetectButton() {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isLoading || isPickingImage
            ? null
            : detectDisease,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF438C47),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB8C7B9),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Text(
                    l10n.loading,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.health_and_safety_outlined,
                    size: 21,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    l10n.detectDisease,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // DETAIL ROW
  Widget buildDetailRow(String label, String? value) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF66A466),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF738075),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF34483A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // DISEASE RESULT CARD
  Widget buildDiseaseResult() {
    final resultTitle = isHealthy
        ? bilingual('Healthy', 'निरोगी')
        : (detectedDisease ?? bilingual('Unknown', 'अज्ञात'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFDCE8D8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F2E1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: Color(0xFF438C47),
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bilingual('Detection result', 'ओळखण्याचा निकाल'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF26372A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bilingual(
                        'Analysis completed',
                        'विश्लेषण पूर्ण झाले',
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF788178),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF438C47),
                size: 25,
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7ED),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: const Color(0xFFDCEBD6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bilingual('Detected condition', 'आढळलेला रोग'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF738075),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  resultTitle,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF345139),
                  ),
                ),
                if (isHealthy) ...[
                  const SizedBox(height: 7),
                  Text(
                    bilingual(
                      'No disease was detected.',
                      'कोणताही रोग आढळला नाही.',
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF526456),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 19),

          Text(
            bilingual('Crop information', 'पिकाची माहिती'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF34483A),
            ),
          ),

          const SizedBox(height: 14),

          buildDetailRow(
            bilingual('Crop', 'पीक'),
            detectedCrop,
          ),

          buildDetailRow(
            bilingual('Affected part', 'प्रभावित भाग'),
            affectedPart,
          ),

          if (isPestResult)
            buildDetailRow(
              bilingual('Classification', 'वर्गीकरण'),
              bilingual('Insect pest', 'कीड'),
            ),
        ],
      ),
    );
  }

  // SOLUTION CARD
  Widget buildSolutionCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7EB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD5E7CF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF4D8D4F),
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.suggestedSolution,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF304A34),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bilingual(
                        'Recommended guidance',
                        'शिफारस केलेले मार्गदर्शन',
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF738075),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          buildDetailRow(
            bilingual('Symptoms', 'लक्षणे'),
            symptoms,
          ),

          buildDetailRow(
            bilingual('Possible causes', 'संभाव्य कारणे'),
            causes,
          ),

          buildDetailRow(
            bilingual('Fertilizer recommendation', 'खताची शिफारस'),
            fertilizer,
          ),

          buildDetailRow(
            bilingual('Management', 'व्यवस्थापन'),
            management,
          ),

          buildDetailRow(
            bilingual('Spray guidance', 'फवारणी मार्गदर्शन'),
            sprayNote,
          ),

          buildDetailRow(
            bilingual('Expert review note', 'तज्ज्ञांच्या पुनरावलोकनाची सूचना'),
            reviewNote,
          ),
        ],
      ),
    );
  }
}
