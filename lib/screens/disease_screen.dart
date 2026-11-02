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

  // IMAGE PICKER
  final ImagePicker imagePicker = ImagePicker();

  // Prevents multiple camera/gallery requests from being
  // opened at the same time.
  // This is useful because Android can throw an
  // "already_active" error if the picker is opened twice.
  bool isPickingImage = false;

  
  File? selectedImage;
  bool isLoading = false;

  // API RESULT
  
  String? detectedDisease;
  String? solution;

  // ERROR / STATUS MESSAGE
 
  String? errorMessage;

  // PICK IMAGE

  Future<void> pickImage(ImageSource source) async {
    // Prevent duplicate picker requests.
    if (isPickingImage) {
      return;
    }

    if (mounted) {
      setState(() {
        isPickingImage = true;
        errorMessage = null;
      });
    }

    try {
      // Open either the camera or gallery.
      // imageQuality: 85 slightly compresses the image.
      // This is useful because the future API upload will
      // contain the image and smaller images upload faster.

      final XFile? pickedFile = await imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      // User cancelled the picker.
      if (pickedFile == null) {
        return;
      }

      // Convert XFile into a normal Dart File.
      final File imageFile = File(pickedFile.path);

      if (!mounted) {
        return;
      }

      setState(() {
        selectedImage = imageFile;

        // A new image means an old prediction is no longer valid.
        detectedDisease = null;
        solution = null;
        errorMessage = null;
      });
    } catch (error) {
      // Do not expose the technical exception to the farmer.
      if (!mounted) {
        return;
      }

      final l10n = AppLocalizations.of(context)!;

      setState(() {
        errorMessage = l10n.unableSelectImage;
      });
    } finally {
      // finally always executes:
      // - if image selection succeeds
      // - if user cancels
      // - if an error occurs
      // Therefore the picker becomes available again.
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
            padding: const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              22,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // DRAG HANDLE

                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9DED9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                const SizedBox(height: 18),
                // TITLE

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

                const SizedBox(height: 15),

                // CAMERA OPTION

                buildSourceOption(
                  icon: Icons.camera_alt_outlined,
                  title: l10n.takePhoto,
                  subtitle: l10n.takePhotoSubtitle,
                  onTap: () {
                    Navigator.pop(sheetContext);

                    pickImage(ImageSource.camera);
                  },
                ),

                const SizedBox(height: 10),

                // GALLERY OPTION
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
      onTap: isPickingImage ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9F5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE1E7DF),
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F2E1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF438C47),
                size: 24,
              ),
            ),

            const SizedBox(width: 13),

            // Title + subtitle
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
                      fontSize: 10.5,
                      color: Color(0xFF7A847C),
                      height: 1.3,
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
    setState(() {
      selectedImage = null;
      detectedDisease = null;
      solution = null;
      errorMessage = null;
    });
  }
  

  Future<void> detectDisease() async {
    final l10n = AppLocalizations.of(context)!;

    // IMAGE REQUIRED

    if (selectedImage == null) {
      setState(() {
        errorMessage = l10n.selectCropImageFirst;
      });
      return;
    }

    // START LOADING

    setState(() {
      isLoading = true;
      detectedDisease = null;
      solution = null;
      errorMessage = null;
    });

    try {
      // SEND IMAGE TO FASTAPI
      // The ApiService method uses multipart/form-data because
      // we are uploading the actual image file.
      //
      // Current endpoint:
      // POST /disease/detect
      //
      // The current backend only confirms that the image was
      // received because the real ML model is not trained yet.

      final DiseaseDetectionResponse response =
          await ApiService.detectDisease(
        selectedImage!,
      );

      if (!mounted) {
        return;
      }

      // CURRENT MODEL STATUS
      // modelReady is currently false.
      // Therefore we do NOT display a fake disease name or
      // solution. When the real model is trained, this same
      // screen can display the actual prediction.

      setState(() {
        isLoading = false;

        if (response.success && !response.modelReady) {
          errorMessage = response.message;
        } else if (!response.success) {
          errorMessage = response.message.isNotEmpty
              ? response.message
              : 'Disease detection could not process the image.';
        }
      });
    } catch (error) {
      // API / NETWORK ERROR
      // Do not expose technical exceptions directly to the
      // farmer. Show a simple actionable message instead.

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage =
            'Unable to connect to the disease detection service.\n'
            'Please make sure the backend is running and try again.';
      });
    }
  }

  // MAIN BUILD

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F2),

      // APP BAR

      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F2),
        foregroundColor: const Color(0xFF20352A),
        elevation: 0,
        title: Text(
          l10n.diseaseDetection,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // BODY

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          4,
          18,
          28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INTRO CARD

            buildIntroCard(),

            const SizedBox(height: 22),

            // UPLOAD SECTION TITLE

            Text(
              l10n.uploadCropImage,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF26372A),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              l10n.uploadCropImageSubtitle,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF788178),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 14),

            // IMAGE PREVIEW
            buildImagePreview(),
            const SizedBox(height: 13),

            // CAMERA / GALLERY BUTTONS
            buildImageButtons(),
            const SizedBox(height: 18),

            // STATUS / ERROR MESSAGE
            if (errorMessage != null) ...[
              buildMessageCard(),
              const SizedBox(height: 16),
            ],

            // DETECT BUTTON
            buildDetectButton(),
            const SizedBox(height: 18),

            // REAL DISEASE RESULT
          

            if (detectedDisease != null)
              buildDiseaseResult(),

            if (detectedDisease != null && solution != null)
              const SizedBox(height: 14),

            if (solution != null)
              buildSolutionCard(),
          ],
        ),
      ),
    );
  }

  // INTRO CARD

  Widget buildIntroCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEAF5E5),
            Color(0xFFF3F8EF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD8E8D2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ICON

          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: Color(0xFF438C47),
              size: 31,
            ),
          ),

          const SizedBox(width: 14),

          // TEXT

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.diseaseIntroTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF28412D),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  l10n.diseaseIntroSubtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.45,
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

    // NO IMAGE
    if (selectedImage == null) {
      return Container(
        width: double.infinity,
        height: 245,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4EE),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: const Color(0xFFD8DED5),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.image_outlined,
                size: 34,
                color: Color(0xFF6C846F),
              ),
            ),

            const SizedBox(height: 14),

            Text(
              l10n.noImageSelected,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF405046),
              ),
            ),

            const SizedBox(height: 5),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Text(
                l10n.imageHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF7C857E),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // IMAGE SELECTED

    return ClipRRect(
      borderRadius: BorderRadius.circular(23),
      child: Stack(
        children: [
          // IMAGE

          Container(
            width: double.infinity,
            height: 300,
            color: const Color(0xFFECEFEA),
            child: Image.file(
              selectedImage!,
              fit: BoxFit.cover,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
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

          // TOP GRADIENT
          // Helps the remove button remain visible even on
          // bright images.

          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 85,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.32),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // REMOVE BUTTON

          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: isLoading ? null : removeImage,
                borderRadius: BorderRadius.circular(14),
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

          // IMAGE READY LABEL

          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
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
                    l10n.uploadCropImage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
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

  // CAMERA / GALLERY BUTTONS

  Widget buildImageButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        // CAMERA BUTTON

        Expanded(
          child: OutlinedButton.icon(
            onPressed: isPickingImage || isLoading
                ? null
                : () {
                    pickImage(ImageSource.camera);
                  },
            icon: const Icon(
              Icons.camera_alt_outlined,
              size: 20,
            ),
            label: Text(l10n.camera),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF438C47),
              disabledForegroundColor: const Color(0xFF9BA59C),
              side: const BorderSide(
                color: Color(0xFFBFD5BA),
              ),
              minimumSize: const Size(
                0,
                50,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),

        const SizedBox(width: 11),

        // GALLERY BUTTON

        Expanded(
          child: OutlinedButton.icon(
            onPressed: isPickingImage || isLoading
                ? null
                : () {
                    pickImage(ImageSource.gallery);
                  },
            icon: const Icon(
              Icons.photo_library_outlined,
              size: 20,
            ),
            label: Text(l10n.gallery),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF438C47),
              disabledForegroundColor: const Color(0xFF9BA59C),
              side: const BorderSide(
                color: Color(0xFFBFD5BA),
              ),
              minimumSize: const Size(
                0,
                50,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // STATUS / MESSAGE CARD

  Widget buildMessageCard() {
    final l10n = AppLocalizations.of(context)!;

    final bool isPendingMessage =
        errorMessage == l10n.diseaseBackendPending;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isPendingMessage
            ? const Color(0xFFEFF6E9)
            : const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPendingMessage
              ? const Color(0xFFD3E6CC)
              : const Color(0xFFF0D9B8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ICON
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isPendingMessage
                  ? const Color(0xFFDDEFD6)
                  : const Color(0xFFFFE7C8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPendingMessage
                  ? Icons.info_outline_rounded
                  : Icons.warning_amber_rounded,
              color: isPendingMessage
                  ? const Color(0xFF4C8B4F)
                  : const Color(0xFFB67629),
              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          // MESSAGE
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.5,
                color: isPendingMessage
                    ? const Color(0xFF4A624D)
                    : const Color(0xFF765A35),
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
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                detectDisease();
              },
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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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

  // DISEASE RESULT

  Widget buildDiseaseResult() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDCE5DA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RESULT HEADER

          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F2E1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF438C47),
                  size: 22,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  l10n.detectionResult,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E4033),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // DISEASE NAME

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8F3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              detectedDisease ?? '',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF345139),
              ),
            ),
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
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7EB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD5E7CF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // HEADER
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF4D8D4F),
                  size: 23,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  l10n.suggestedSolution,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF304A34),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // SOLUTION

          Text(
            solution ?? '',
            style: const TextStyle(
              fontSize: 12,
              height: 1.55,
              color: Color(0xFF526456),
            ),
          ),
        ],
      ),
    );
  }
}