import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';

// ============================================================
// SHARE EXPERIENCE SCREEN
//
// Fields:
// - Title
// - Crop / Topic
// - Experience
// - Photo (optional)
// On success: Navigator.pop(context, true)
// The Knowledge Hub then reloads and shows the new experience.

class ShareExperienceScreen extends StatefulWidget {
  const ShareExperienceScreen({super.key});

  @override
  State<ShareExperienceScreen> createState() =>
      _ShareExperienceScreenState();
}

class _ShareExperienceScreenState extends State<ShareExperienceScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController topicController = TextEditingController();
  final TextEditingController experienceController =
      TextEditingController();

  final ImagePicker picker = ImagePicker();

  File? photo;
  bool isSubmitting = false;
  String? errorMessage;

  @override
  void dispose() {
    titleController.dispose();
    topicController.dispose();
    experienceController.dispose();
    super.dispose();
  }

  // ==========================================================
  // PHOTO (OPTIONAL)

  Future<void> pickPhoto(ImageSource source) async {
    try {
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );

      if (picked == null || !mounted) {
        return;
      }

      setState(() {
        photo = File(picked.path);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage =
            'Could not open the camera or gallery. Please check app permissions.';
      });
    }
  }

  void choosePhotoSource() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: Color(0xFF168A52),
                ),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFF168A52),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  pickPhoto(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // SUBMIT -> FastAPI -> database

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    if (isSubmitting) {
      return;
    }

    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {
      await ApiService.shareExperience(
        title: titleController.text,
        topic: topicController.text,
        content: experienceController.text,
        photo: photo,
      );

      if (!mounted) {
        return;
      }

      // Back to Knowledge Hub.
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  String friendlyError(Object error) {
    final String message =
        error.toString().replaceFirst('Exception: ', '');

    if (message.contains('SocketException') ||
        message.contains('ClientException') ||
        message.contains('Connection refused') ||
        message.contains('Failed host lookup')) {
      return 'Unable to connect to AgriGuide server. '
          'Please check your internet connection.';
    }

    if (message.contains('TimeoutException')) {
      return 'The request took too long. Please try again.';
    }

    return message;
  }

  // ==========================================================
  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF168A52),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Share Experience',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tell other farmers what you learned. '
                  'Everyone using AgriGuide can read your experience.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF748078),
                  ),
                ),
                const SizedBox(height: 18),

                if (errorMessage != null) ...[
                  buildErrorBox(errorMessage!),
                  const SizedBox(height: 16),
                ],

                // TITLE
                buildField(
                  controller: titleController,
                  label: 'Title',
                  hint: 'e.g. How I controlled leaf spot on tomato',
                  icon: Icons.title_rounded,
                  maxLength: 120,
                  validator: (value) {
                    final String text = value?.trim() ?? '';

                    if (text.length < 3) {
                      return 'Please enter a title (at least 3 characters).';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // CROP / TOPIC
                buildField(
                  controller: topicController,
                  label: 'Crop / Topic',
                  hint: 'e.g. Tomato, Drip irrigation',
                  icon: Icons.eco_outlined,
                  maxLength: 80,
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) {
                      return 'Please enter the crop or topic.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // EXPERIENCE
                buildField(
                  controller: experienceController,
                  label: 'Your Experience',
                  hint: 'Write what you did and what happened',
                  icon: Icons.edit_note_rounded,
                  maxLength: 5000,
                  minLines: 6,
                  maxLines: 12,
                  textInputAction: TextInputAction.newline,
                  validator: (value) {
                    final String text = value?.trim() ?? '';

                    if (text.length < 20) {
                      return 'Please write a little more (at least 20 characters).';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // PHOTO (OPTIONAL)
                const Text(
                  'Photo (optional)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F5F55),
                  ),
                ),
                const SizedBox(height: 8),

                if (photo != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Image.file(
                      photo!,
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting ? null : choosePhotoSource,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: Text(
                          photo == null ? 'Add Photo' : 'Change Photo',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF168A52),
                          side: const BorderSide(color: Color(0xFF168A52)),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    if (photo != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Remove photo',
                        onPressed: isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  photo = null;
                                });
                              },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFF718077),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 24),

                // SUBMIT
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF168A52),
                      disabledBackgroundColor: const Color(0xFF9BBEAA),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded),
                              SizedBox(width: 9),
                              Text(
                                'Submit Experience',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ERROR BOX (same style as the login screen)

  Widget buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0C8C2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Color(0xFFC65345),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: Color(0xFF9B4035),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FORM FIELD (same style as the login screen)

  Widget buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int? maxLength,
    int minLines = 1,
    int maxLines = 1,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextFormField(
      controller: controller,
      validator: validator,
      maxLength: maxLength,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: textInputAction,
      keyboardType: maxLines > 1 ? TextInputType.multiline : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: Icon(icon, color: const Color(0xFF4B8650)),
        filled: true,
        fillColor: const Color(0xFFFAFBF8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border(const Color(0xFFE0E5DC)),
        enabledBorder: border(const Color(0xFFE0E5DC)),
        focusedBorder: border(const Color(0xFF4B8D4D), 1.5),
        errorBorder: border(const Color(0xFFD46A5C)),
        focusedErrorBorder: border(const Color(0xFFD46A5C), 1.5),
      ),
    );
  }
}
