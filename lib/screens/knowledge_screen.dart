import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

import 'auth_screen.dart';
import 'share_experience_screen.dart';

String? _lastLanguageCode;

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

// KNOWLEDGE HUB STATE
class _KnowledgeScreenState extends State<KnowledgeScreen> {
  final TextEditingController searchController = TextEditingController();

  int? currentUserId;
  List<ExperienceModel> experiences = [];
  bool isLoadingExperiences = true;
  String? experiencesError;

  @override
  void initState() {
    super.initState();
    loadExperiences();
    loadCurrentUser();
  }


  @override
void didChangeDependencies() {
  super.didChangeDependencies();

  final languageCode = Localizations.localeOf(context).languageCode;

  if (_lastLanguageCode != languageCode) {
    _lastLanguageCode = languageCode;

    // Reload experiences using the newly selected language.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        loadExperiences();
      }
    });
  }
}

  Future<void> loadCurrentUser() async {
    final user = await ApiService.getSavedUser();
    if (!mounted) return;

    setState(() {
      currentUserId = user?.id;
    });
  }

  // LOAD EXPERIENCES FROM FASTAPI
  // GET /knowledge/experiences (public - no login needed)

  Future<void> loadExperiences() async {
    setState(() {
      isLoadingExperiences = true;
      experiencesError = null;
    });

    try {
      final String languageCode =
    Localizations.localeOf(context).languageCode;

final List<ExperienceModel> result =
    await ApiService.getExperiences(lang: languageCode);

      if (!mounted) {
        return;
      }

      setState(() {
        experiences = result;
        isLoadingExperiences = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoadingExperiences = false;
        experiencesError =
            error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ==========================================================
  // FILTERED EXPERIENCES (search only)

  List<ExperienceModel> get filteredExperiences {
    final String query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return experiences;
    }

    return experiences
        .where(
          (item) =>
              item.title.toLowerCase().contains(query) ||
              item.topic.toLowerCase().contains(query) ||
              item.content.toLowerCase().contains(query) ||
              item.authorName.toLowerCase().contains(query),
        )
        .toList();
  }

  // ==========================================================
  // SHARE EXPERIENCE FLOW
  //
  // Farmer taps "Share Experience"
  //      -> Is the farmer logged in?
  //           Yes -> open the form
  //           No  -> login sheet -> AuthScreen -> form

  Future<void> startShareFlow() async {
    final l10n = AppLocalizations.of(context)!;

    // Is the farmer logged in? hasValidSession() checks the saved
    // JWT with the backend (GET /auth/me) and clears it if expired.
    final bool loggedIn = await ApiService.hasValidSession();

    if (!mounted) {
      return;
    }

    if (loggedIn) {
      await openShareForm();
      return;
    }

    // Not logged in -> explain, then Login / Register.
    final bool? wantsLogin = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return LoginRequiredSheet(message: l10n.loginToShareExperience);
      },
    );

    if (wantsLogin != true || !mounted) {
      return;
    }

    // AuthScreen pops with true after a successful login/registration.
    final bool? authenticated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthScreen(),
      ),
    );

    if (authenticated == true && mounted) {
      // Successful login -> the Share Experience form opens.
      await openShareForm();
    }
  }

  Future<void> openShareForm() async {
    final bool? shared = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ShareExperienceScreen(),
      ),
    );

    if (shared != true || !mounted) {
      return;
    }

    // Back in the Knowledge Hub: show the new experience.
    setState(() {
      searchController.clear();
    });

    await loadCurrentUser();
    await loadExperiences();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF168A52),
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Your experience has been shared. Other farmers can now read it.',
        ),
      ),
    );
  }

  // ==========================================================
  // OPEN EXPERIENCE (any user can read it)
  void openExperience(ExperienceModel experience) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExperienceDetailScreen(experience: experience),
      ),
    );
  }

  Future<void> deleteExperience(ExperienceModel experience) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete experience?'),
      content: Text(
        'Are you sure you want to delete "${experience.title}"? '
        'This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true || !mounted) return;

  try {
    await ApiService.deleteExperience(experience.id);

    if (!mounted) return;

    setState(() {
      experiences.removeWhere((item) => item.id == experience.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Experience deleted successfully.'),
      ),
    );
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.toString().replaceFirst('Exception: ', ''),
        ),
      ),
    );
  }
}

  // ==========================================================
  // DISPOSE
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // MAIN BUILD
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF168A52),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.knowledgeHub,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.search,
            onPressed: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: l10n.tryAgain,
            onPressed: isLoadingExperiences ? null : loadExperiences,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildCommunityHeader(),
                    const SizedBox(height: 17),
                    buildSearchField(),
                    const SizedBox(height: 20),
                    if (isLoadingExperiences)
                      buildLoadingState('Loading shared experiences...')
                    else if (experiencesError != null)
                      buildErrorState(
                        'Unable to load experiences',
                        experiencesError,
                        loadExperiences,
                      )
                    else
                      buildExperienceContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: startShareFlow,
        backgroundColor: const Color(0xFF168A52),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.edit_rounded),
        label: Text(
          l10n.shareExperience,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  // ==========================================================
  // FARMER COMMUNITY HEADER

  Widget buildCommunityHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8F3DF),
            Color(0xFFF2F7ED),
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFD8E7D1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 31,
              color: Color(0xFF438C47),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.community,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF29372D),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.knowledgeSubtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
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

  // ==========================================================
  // SEARCH FIELD

  Widget buildSearchField() {
    final l10n = AppLocalizations.of(context)!;

    return TextField(
      controller: searchController,
      onChanged: (_) {
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: l10n.searchPosts,
        hintStyle: const TextStyle(
          fontSize: 11,
          color: Color(0xFF929A93),
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: Color(0xFF5B8065),
        ),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFFE0E6DE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFFE0E6DE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFF4A8A50),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // EXPERIENCE CONTENT

  Widget buildExperienceContent() {
    final List<ExperienceModel> visible = filteredExperiences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Farmer Experiences',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF26372A),
                ),
              ),
            ),
            Text(
              '${visible.length}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7C867E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          buildNoExperiencesState()
        else
          ...visible.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: buildExperienceCard(item),
            ),
          ),
      ],
    );
  }

  // ==========================================================
  // EXPERIENCE CARD

  Widget buildExperienceCard(ExperienceModel item) {
    return GestureDetector(
      onTap: () => openExperience(item),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE1E7DF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE7F2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.forum_rounded,
                    size: 22,
                    color: Color(0xFF438C47),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.authorName.isEmpty ? 'Farmer' : item.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7D877F),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3DF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.topic,
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4B7F53),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF27382D),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                height: 1.4,
                color: Color(0xFF6D786F),
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Icon(
                  item.photoUrl != null
                      ? Icons.photo_outlined
                      : Icons.schedule_rounded,
                  size: 18,
                  color: const Color(0xFF68756C),
                ),
                const SizedBox(width: 5),
                Text(
                  formatDate(item.createdAt),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF68756C),
                  ),
                ),
                const Spacer(),
                if (currentUserId != null &&
                    item.userId == currentUserId)
                  IconButton(
                    tooltip: 'Delete experience',
                    onPressed: () => deleteExperience(item),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 22,
                    ),
                  ),

                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Color(0xFF7C877F),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // LOADING STATE

  Widget buildLoadingState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E7DF)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF68756C),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR STATE

  Widget buildErrorState(
    String title,
    String? message,
    VoidCallback onRetry,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E7DF)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 42,
            color: Color(0xFF7B877E),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF344238),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message ?? l10n.tryAgain,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.4,
              color: Color(0xFF7C867E),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.tryAgain),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF168A52),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // NO EXPERIENCES STATE

  Widget buildNoExperiencesState() {
    final bool searching = searchController.text.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E7DF)),
      ),
      child: Column(
        children: [
          Icon(
            searching ? Icons.search_off_rounded : Icons.forum_outlined,
            size: 42,
            color: const Color(0xFF7B877E),
          ),
          const SizedBox(height: 10),
          Text(
            searching
                ? 'No experiences found'
                : 'No experiences shared yet',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF344238),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            searching
                ? 'Try a different word.'
                : 'Be the first farmer to share what you learned.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF7C867E),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SMALL HELPER

String formatDate(DateTime date) {
  final DateTime local = date.toLocal();
  final String month = local.month.toString().padLeft(2, '0');
  final String day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

// ============================================================
// EXPERIENCE DETAILS SCREEN
// Any user (logged in or not) can read a shared experience.

class ExperienceDetailScreen extends StatelessWidget {
  final ExperienceModel experience;

  const ExperienceDetailScreen({
    super.key,
    required this.experience,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String? photoUrl = experience.photoUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF168A52),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.knowledgeHub,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crop / topic.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3DF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                experience.topic,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4B7F53),
                ),
              ),
            ),
            const SizedBox(height: 11),

            // Title.
            Text(
              experience.title,
              style: const TextStyle(
                fontSize: 23,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: Color(0xFF25362A),
              ),
            ),
            const SizedBox(height: 8),

            // Author and date.
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: Color(0xFF68756C),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    experience.authorName.isEmpty
                        ? 'Farmer'
                        : experience.authorName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF68756C),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: Color(0xFF68756C),
                ),
                const SizedBox(width: 5),
                Text(
                  formatDate(experience.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF68756C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Photo (optional).
            if (photoUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  photoUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) {
                      return child;
                    }

                    return Container(
                      height: 200,
                      color: Colors.white,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      color: Colors.white,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 36,
                        color: Color(0xFF7B877E),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Full experience.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE1E7DF)),
              ),
              child: Text(
                experience.content,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.55,
                  color: Color(0xFF59675E),
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LOGIN REQUIRED BOTTOM SHEET
//
// Only asks the question. It returns:
//   true  -> the farmer wants to log in / register
//   false -> the farmer wants to continue without logging in
//
// The Knowledge Hub then opens AuthScreen and, after a
// successful login, the Share Experience form.

class LoginRequiredSheet extends StatelessWidget {
  final String message;

  const LoginRequiredSheet({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD9DED9),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3DF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 30,
              color: Color(0xFF438C47),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.loginRequired,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF29372D),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: Color(0xFF737D75),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF168A52),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                l10n.login,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text(
              l10n.continueButton,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF617067),
              ),
            ),
          ),
        ],
      ),
    );
  }
}