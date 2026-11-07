import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoginMode = true;
  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  String? errorMessage;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void switchMode() {
    setState(() {
      isLoginMode = !isLoginMode;
      errorMessage = null;
    });

    formKey.currentState?.reset();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (isLoginMode) {
        await ApiService.login(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      } else {
        await ApiService.register(
          fullName: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _friendlyError(Object error) {
    final String message = error.toString();
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    if (message.contains('already registered') ||
        message.contains('already exists') ||
        message.contains('already taken')) {
      return l10n.accountAlreadyExists;
    }

    if (message.contains('Invalid email') ||
        message.contains('invalid email')) {
      return l10n.invalidEmail;
    }

    if (message.contains('Invalid credentials') ||
        message.contains('Incorrect email') ||
        message.contains('Incorrect password') ||
        message.contains('401')) {
      return l10n.incorrectCredentials;
    }

    if (message.contains('Connection refused') ||
        message.contains('Failed host lookup') ||
        message.contains('SocketException') ||
        message.contains('ClientException')) {
      return l10n.unableConnectServer;
    }

    return isLoginMode ? l10n.loginFailed : l10n.registrationFailed;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F2),
        foregroundColor: const Color(0xFF20352A),
        elevation: 0,
        title: const Text(
          'AgriGuide',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BRAND ICON
                  Center(
                    child: Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F1DD),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        size: 45,
                        color: Color(0xFF3E8744),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // TITLE
                  Center(
                    child: Text(
                      isLoginMode
                          ? l10n.welcomeBack
                          : l10n.createYourAccount,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF20352A),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // SUBTITLE
                  Center(
                    child: Text(
                      isLoginMode
                          ? l10n.loginSubtitle
                          : l10n.createAccountSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFF748078),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ERROR MESSAGE
                  if (errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EE),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFF0C8C2),
                        ),
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
                              errorMessage!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                height: 1.4,
                                color: Color(0xFF9B4035),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // FULL NAME - REGISTRATION ONLY
                  if (!isLoginMode) ...[
                    buildField(
                      controller: nameController,
                      label: l10n.fullName,
                      hint: l10n.enterFullName,
                      icon: Icons.person_outline_rounded,
                      validator: (value) {
                        final String text = value?.trim() ?? '';

                        if (text.isEmpty) {
                          return l10n.pleaseEnterFullName;
                        }

                        if (text.length < 2) {
                          return l10n.nameMinLength;
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  // EMAIL
                  buildField(
                    controller: emailController,
                    label: l10n.emailAddress,
                    hint: l10n.enterYourEmailAddress,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final String email = value?.trim() ?? '';

                      if (email.isEmpty) {
                        return l10n.pleaseEnterEmail;
                      }

                      final bool validEmail = RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(email);

                      if (!validEmail) {
                        return l10n.invalidEmail;
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  // PASSWORD
                  buildField(
                    controller: passwordController,
                    label: l10n.password,
                    hint: isLoginMode
                        ? l10n.enterPassword
                        : l10n.createPassword,
                    icon: Icons.lock_outline_rounded,
                    obscureText: obscurePassword,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF718077),
                      ),
                    ),
                    validator: (value) {
                      final String password = value ?? '';

                      if (password.isEmpty) {
                        return l10n.pleaseEnterPassword;
                      }

                      if (!isLoginMode && password.length < 8) {
                        return l10n.passwordMinLength;
                      }

                      return null;
                    },
                  ),

                  // CONFIRM PASSWORD - REGISTRATION ONLY
                  if (!isLoginMode) ...[
                    const SizedBox(height: 14),
                    buildField(
                      controller: confirmPasswordController,
                      label: l10n.confirmPassword,
                      hint: l10n.reenterPassword,
                      icon: Icons.lock_reset_outlined,
                      obscureText: obscureConfirmPassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscureConfirmPassword =
                                !obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFF718077),
                        ),
                      ),
                      validator: (value) {
                        final String confirm = value ?? '';

                        if (confirm.isEmpty) {
                          return l10n.pleaseConfirmPassword;
                        }

                        if (confirm != passwordController.text) {
                          return l10n.passwordsDoNotMatch;
                        }

                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 24),

                  // SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF168A52),
                        disabledBackgroundColor: const Color(0xFF9BBEAA),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isLoginMode
                                      ? Icons.login_rounded
                                      : Icons.person_add_alt_1_rounded,
                                ),
                                const SizedBox(width: 9),
                                Text(
                                  isLoginMode
                                      ? l10n.loginButton
                                      : l10n.createAccountButton,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // SWITCH LOGIN / REGISTER
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          isLoginMode
                              ? l10n.dontHaveAccount
                              : l10n.alreadyHaveAccount,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF737E76),
                          ),
                        ),
                        TextButton(
                          onPressed: isLoading ? null : switchMode,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                          ),
                          child: Text(
                            isLoginMode
                                ? l10n.register
                                : l10n.loginButton,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF168A52),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SECURITY NOTE
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 15,
                          color: Color(0xFF6E8B76),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            l10n.secureSessionNote,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF7E8981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // REUSABLE FORM FIELD
  Widget buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF4B8650),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFFAFBF8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFFE0E5DC),
          ),
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
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFFD46A5C),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFFD46A5C),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
