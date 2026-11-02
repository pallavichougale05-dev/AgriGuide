import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';

// ============================================================
// DIARY ENTRY MODEL
// ============================================================

class DiaryEntry {
  final int id;
  final DateTime date;
  final String cropField;
  final String activity;
  final String notes;

  const DiaryEntry({
    required this.id,
    required this.date,
    required this.cropField,
    required this.activity,
    required this.notes,
  });

  factory DiaryEntry.fromApi(DiaryEntryModel model) {
    return DiaryEntry(
      id: model.id,
      date: model.date,
      cropField: model.cropField,
      activity: model.activity,
      notes: model.notes,
    );
  }
}

// ============================================================
// FARM DIARY SCREEN
// ============================================================

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

// ============================================================
// DIARY SCREEN STATE
// ============================================================

class _DiaryScreenState extends State<DiaryScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _activityHistoryKey = GlobalKey();
  final GlobalKey _sharedExperiencesKey = GlobalKey();

  Future<void> _scrollToSection(GlobalKey key) async {
    final BuildContext? targetContext = key.currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.03,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isMarathi =>
      Localizations.localeOf(context).languageCode == 'mr';

  // ----------------------------------------------------------
  // LANGUAGE OF THE LIST CURRENTLY ON SCREEN
  // ----------------------------------------------------------
  //
  // Remembers which language the shared experiences were last
  // requested in, so the list can be reloaded when the user
  // switches between English and Marathi.
  // ----------------------------------------------------------

  String? _loadedLang;

  // ----------------------------------------------------------
  // LOGIN STATE
  // ----------------------------------------------------------

  bool isLoggedIn = false;

  // ----------------------------------------------------------
  // LOADING STATE
  // ----------------------------------------------------------

  bool isLoading = false;

  // DIARY ENTRIES
  final List<DiaryEntry> entries = [];

  // Experiences shared by the currently logged-in farmer.
  final List<ExperienceModel> myExperiences = [];
  bool isLoadingExperiences = false;

  // INITIALIZATION

  @override
  void initState() {
    super.initState();

    restoreSession();
  }

  // LANGUAGE CHANGE

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final String lang =
        Localizations.localeOf(context).languageCode;

    if (isLoggedIn &&
        _loadedLang != null &&
        _loadedLang != lang) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Reload both lists using the newly selected language.
          loadDiaryEntries();
          loadMyExperiences();
        }
      });
    }
  }

  // RESTORE SESSION

  Future<void> restoreSession() async {
    try {
      final bool validSession =
          await ApiService.hasValidSession();

      if (!mounted) {
        return;
      }

      if (validSession) {
        setState(() {
          isLoggedIn = true;
        });

        await Future.wait([
          loadDiaryEntries(),
          loadMyExperiences(),
        ]);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoggedIn = false;
      });
    }
  }

  // OPEN LOGIN / REGISTER

  Future<void> openAuthentication() async {
    final bool? authenticated =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (authenticated == true) {
      setState(() {
        isLoggedIn = true;
      });

      await Future.wait([
        loadDiaryEntries(),
        loadMyExperiences(),
      ]);
    }
  }

  // ==========================================================
  // LOAD DIARY ENTRIES
  // ==========================================================

  Future<void> loadDiaryEntries() async {
    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final String lang =
          Localizations.localeOf(context).languageCode;

      final List<DiaryEntryModel> apiEntries =
          await ApiService.getDiaryEntries(lang: lang);

      if (!mounted) {
        return;
      }

      setState(() {
        entries
          ..clear()
          ..addAll(
            apiEntries.map(
              DiaryEntry.fromApi,
            ),
          );

        isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getFriendlyErrorMessage(error),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================================
  // LOAD MY SHARED EXPERIENCES
  // ==========================================================
  //
  // Requests the experiences in the language the app is
  // showing right now (lang=en or lang=mr).
  //
  // If the user switches language while a request is still
  // running, the late response is ignored so an old-language
  // list never replaces the new one.
  // ==========================================================

  Future<void> loadMyExperiences() async {
    if (!mounted || !isLoggedIn) return;

    final String lang =
        Localizations.localeOf(context).languageCode;

    _loadedLang = lang;

    setState(() {
      isLoadingExperiences = true;
    });

    try {
      final List<ExperienceModel> experiences =
          await ApiService.getMyExperiences(lang: lang);

      if (!mounted) return;

      // The language changed while this request was running.
      // A newer request is already loading the correct list.
      if (lang != _loadedLang) return;

      setState(() {
        myExperiences
          ..clear()
          ..addAll(experiences);
        isLoadingExperiences = false;
      });
    } catch (error) {
      if (!mounted) return;

      if (lang != _loadedLang) return;

      setState(() {
        isLoadingExperiences = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load your shared experiences: $error',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================================
  // REFRESH DIARY
  // ==========================================================

  Future<void> refreshDiary() async {
    if (!isLoggedIn) {
      return;
    }

    await loadDiaryEntries();
    await loadMyExperiences();
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  Future<void> logout() async {
    await ApiService.logout();

    if (!mounted) {
      return;
    }

    setState(() {
      isLoggedIn = false;
      _loadedLang = null;
      entries.clear();
      myExperiences.clear();
    });
  }

  // ==========================================================
  // ADD DIARY ENTRY
  // ==========================================================

  Future<void> showAddEntrySheet() async {
    if (!isLoggedIn) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (context) {
        return AddDiaryEntrySheet(
          onEntryAdded: (DiaryEntry newEntry) {
            if (!mounted) {
              return;
            }

            setState(() {
              entries.insert(
                0,
                newEntry,
              );
            });
          },
        );
      },
    );
  }

  // ==========================================================
  // DELETE MY SHARED EXPERIENCE
  // ==========================================================

  Future<void> confirmDeleteExperience(
    ExperienceModel experience,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          _isMarathi
              ? 'शेअर केलेला अनुभव हटवा ?'
              : 'Delete shared experience?',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          _isMarathi
              ? '"${experience.title}" हा अनुभव कायमचा हटवा?'
              : 'Are you sure you want to permanently delete '
                  '"${experience.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_cancelLabel()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD64A4A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_deleteLabel()),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ApiService.deleteExperience(experience.id);

      if (!mounted) return;

      setState(() {
        myExperiences.removeWhere((item) => item.id == experience.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isMarathi
                ? 'अनुभव यशस्वीरित्या हटवला.'
                : 'Experience deleted successfully.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF287B49),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final String message = error.toString();
      String friendlyMessage = _isMarathi ? 'अनुभव हटवता आला नाही.' : 'Unable to delete the experience.';
      if (message.contains('401')) {
        friendlyMessage = _isMarathi ? 'तुमचे सत्र संपले आहे. कृपया पुन्हा लॉग इन करा.' : 'Your session has expired. Please log in again.';
      } else if (message.contains('403')) {
        friendlyMessage = _isMarathi ? 'तुम्ही फक्त तुमचे स्वतःचे अनुभव हटवू शकता.' : 'You can delete only your own experiences.';
      } else if (message.contains('404')) {
        friendlyMessage = _isMarathi ? 'हा अनुभव आता उपलब्ध नाही.' : 'This experience no longer exists.';
      } else if (message.contains('SocketException')) {
        friendlyMessage = _isMarathi ? 'AgriGuide सर्व्हरशी कनेक्ट करता आले नाही.' : 'Unable to connect to the AgriGuide server.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB63E3E),
        ),
      );
    }
  }

  // ==========================================================
  // MY SHARED EXPERIENCES SECTION
  // ==========================================================

  Widget buildMySharedExperiences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _isMarathi
                    ? 'माझे सामायिक अनुभव'
                    : 'My Shared Experiences',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF26372A),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F2E1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                '${myExperiences.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A7D50),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (isLoadingExperiences)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: Color(0xFF168A52),
              ),
            ),
          )
        else if (myExperiences.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE0E8DD)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.forum_outlined,
                  size: 34,
                  color: Color(0xFF6B806D),
                ),
                const SizedBox(height: 8),
                Text(
                  _isMarathi
                      ? 'तुम्ही अद्याप कोणतेही अनुभव शेअर केलेले नाही.'
                      : 'You have not shared any experiences yet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF536057)),
                ),
              ],
            ),
          )
        else
          ...myExperiences.map(
            (experience) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 11),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE0E8DD)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A1E3A24),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    experience.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF26372A),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    experience.topic,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF43844D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    experience.content,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: Color(0xFF536057),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_isMarathi ? 'शेअर केले: ' : 'Shared: '}${formatDate(experience.createdAt)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF879188),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => confirmDeleteExperience(experience),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFD64A4A),
                      ),
                      label: Text(
                        _deleteLabel(),
                        style: const TextStyle(
                          color: Color(0xFFD64A4A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================================
  // MAIN BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return buildLoginScreen();
    }

    return buildDiaryScreen();
  }

  // ==========================================================
  // LOGIN SCREEN
  // ==========================================================

  Widget buildLoginScreen() {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF168A52),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.farmDiary,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ------------------------------------------------
                // LOCK ICON
                // ------------------------------------------------

                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F2E1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 47,
                    color: Color(0xFF3D8650),
                  ),
                ),

                const SizedBox(height: 22),

                // ------------------------------------------------
                // TITLE
                // ------------------------------------------------

                Text(
                  l10n.privateDiary,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF26372A),
                  ),
                ),

                const SizedBox(height: 9),

                // ------------------------------------------------
                // DESCRIPTION
                // ------------------------------------------------

                Text(
                  l10n.loginToUseDiary,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF707B73),
                  ),
                ),

                const SizedBox(height: 25),

                // ------------------------------------------------
                // PRIVACY INFORMATION CARD
                // ------------------------------------------------

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE1E7DF),
                    ),
                  ),
                  child: Column(
                    children: [
                      buildPrivacyPoint(
                        icon: Icons.history_rounded,
                        text: l10n.activityHistory,
                      ),

                      const SizedBox(height: 12),

                      buildPrivacyPoint(
                        icon: Icons.person_outline_rounded,
                        text: l10n.loginRequired,
                      ),

                      const SizedBox(height: 12),

                      buildPrivacyPoint(
                        icon: Icons.cloud_done_outlined,
                        text: l10n.saveActivity,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ------------------------------------------------
                // LOGIN BUTTON
                // ------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: openAuthentication,
                    icon: const Icon(
                      Icons.login_rounded,
                    ),
                    label: Text(
                      l10n.login,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF168A52),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  l10n.loginRequired,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF8A938B),
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
  // PRIVACY POINT
  // ==========================================================

  Widget buildPrivacyPoint({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF4E7),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            size: 19,
            color: const Color(0xFF43844D),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF536057),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // LOGGED-IN DIARY SCREEN
  // ==========================================================

  Widget buildDiaryScreen() {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F2),

      // --------------------------------------------------------
      // APP BAR
      // --------------------------------------------------------

      appBar: AppBar(
        backgroundColor: const Color(0xFF168A52),
        foregroundColor: Colors.white,
        elevation: 0,

        title: Text(
          l10n.myFarmDiary,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          // Refresh.
          IconButton(
            onPressed:
                isLoading ? null : refreshDiary,
            tooltip: _isMarathi ? 'रीफ्रेश' : 'Refresh',
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),

          // Logout.
          IconButton(
            onPressed: logout,
            tooltip: l10n.logout,
            icon: const Icon(
              Icons.logout_rounded,
            ),
          ),
        ],
      ),

      // --------------------------------------------------------
      // CONTENT
      // --------------------------------------------------------

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshDiary,
          color: const Color(0xFF168A52),
          child: ListView(
            controller: _scrollController,
            physics:
                const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              110,
            ),
            children: [
              // ------------------------------------------------
              // HEADER
              // ------------------------------------------------

              buildDiaryHeader(),

              const SizedBox(height: 14),

              // Quick navigation to the two My Farm sections.
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _scrollToSection(_activityHistoryKey),
                      icon: const Icon(Icons.agriculture_outlined, size: 18),
                      label: Text(_isMarathi ? 'क्रियाकलाप इतिहास' : 'Activity History'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF168A52),
                        side: const BorderSide(color: Color(0xFFB8D8BD)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _scrollToSection(_sharedExperiencesKey),
                      icon: const Icon(Icons.forum_outlined, size: 18),
                      label: Text(_isMarathi ? 'माझे अनुभव' : 'My Experiences'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF168A52),
                        side: const BorderSide(color: Color(0xFFB8D8BD)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ------------------------------------------------
              // HISTORY TITLE
              // ------------------------------------------------

              Row(
                key: _activityHistoryKey,
                children: [
                  Expanded(
                    child: Text(
                      l10n.activityHistory,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF26372A),
                      ),
                    ),
                  ),

                  // Number of real database records.
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFE7F2E1),
                      borderRadius:
                          BorderRadius.circular(11),
                    ),
                    child: Text(
                      '${entries.length} ${l10n.records}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4A7D50),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 13),

              // ------------------------------------------------
              // LOADING
              // ------------------------------------------------

              if (isLoading)
                buildLoadingDiary()

              // ------------------------------------------------
              // EMPTY
              // ------------------------------------------------

              else if (entries.isEmpty)
                buildEmptyDiary()

              // ------------------------------------------------
              // REAL DATABASE ENTRIES
              // ------------------------------------------------

              else
                ...entries.map(
                  (entry) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 11,
                      ),
                      child:
                          buildDiaryEntry(entry),
                    );
                  },
                ),

              const SizedBox(height: 28),

              Container(
                key: _sharedExperiencesKey,
                child: buildMySharedExperiences(),
              ),
            ],
          ),
        ),
      ),

      // --------------------------------------------------------
      // ADD ACTIVITY BUTTON
      // --------------------------------------------------------

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            isLoading ? null : showAddEntrySheet,
        backgroundColor:
            const Color(0xFF168A52),
        foregroundColor: Colors.white,

        icon: const Icon(
          Icons.add_rounded,
        ),

        label: Text(
          l10n.addActivity,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DIARY HEADER
  // ==========================================================

  Widget buildDiaryHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF7E4), Color(0xFFDCEFD5)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD7E8D2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A315B3A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 30,
              color: Color(0xFF3D8246),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.activityHistory,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF26372A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.recordFarmActivity,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: Color(0xFF667268),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_done_outlined,
                        size: 13,
                        color: Color(0xFF4B8052),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${entries.length} ${l10n.records}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4B8052),
                        ),
                      ),
                    ],
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
  // LOADING STATE
  // ==========================================================

  Widget buildLoadingDiary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 45,
        horizontal: 25,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE1E7DF),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF168A52),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            _isMarathi
                ? 'तुमच्या शेतीच्या नोंदी लोड होत आहेत...'
                : 'Loading your farm records...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF68736B),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DIARY ENTRY CARD
  // ==========================================================

  Widget buildDiaryEntry(
    DiaryEntry entry,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E9E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1E3A24),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onLongPress: () => confirmDeleteEntry(entry),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 10, 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEAF7E4), Color(0xFFDDEFD7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.agriculture_rounded,
                    size: 24,
                    color: Color(0xFF3F8548),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.cropField,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF25342A),
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 42,
                              minHeight: 42,
                            ),
                            iconSize: 21,
                            tooltip: _isMarathi ? 'अधिक पर्याय' : 'More options',
                            icon: const Icon(
                              Icons.more_horiz_rounded,
                              color: Color(0xFF758078),
                            ),
                            onSelected: (value) {
                              if (value == 'delete') {
                                confirmDeleteEntry(entry);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                      color: Color(0xFFD64A4A),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _deleteLabel(),
                                      style: const TextStyle(
                                        color: Color(0xFFD64A4A),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: Color(0xFF879188),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            formatDate(entry.date),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF879188),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5E6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          entry.activity,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF3F7D47),
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        entry.notes,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.45,
                          color: Color(0xFF68736B),
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
    );
  }

  // ==========================================================
  // DELETE DIARY ENTRY
  // ==========================================================

  Future<void> confirmDeleteEntry(DiaryEntry entry) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFD64A4A),
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _deleteConfirmationTitle(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF26372A),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            _deleteConfirmationMessage(entry),
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF68736B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                _cancelLabel(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD64A4A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _deleteLabel(),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await ApiService.deleteDiaryEntry(entry.id);

      if (!mounted) return;

      setState(() {
        entries.removeWhere((item) => item.id == entry.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(_deletedSuccessMessage())),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF287B49),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getFriendlyDeleteErrorMessage(error)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB63E3E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        ),
      );
    }
  }

  String _deleteLabel() {
    return Localizations.localeOf(context).languageCode == 'mr'
        ? 'हटवा'
        : 'Delete';
  }

  String _cancelLabel() {
    return Localizations.localeOf(context).languageCode == 'mr'
        ? 'रद्द करा'
        : 'Cancel';
  }

  String _deleteConfirmationTitle() {
    return Localizations.localeOf(context).languageCode == 'mr'
        ? 'क्रियाकलाप हटवायचा?'
        : 'Delete activity?';
  }

  String _deleteConfirmationMessage(DiaryEntry entry) {
    if (Localizations.localeOf(context).languageCode == 'mr') {
      return '"${entry.activity}" हा "${entry.cropField}" साठीचा '
          'नोंदवलेला क्रियाकलाप कायमचा हटवला जाईल.';
    }

    return 'This will permanently delete the "${entry.activity}" '
        'record for "${entry.cropField}".';
  }

  String _deletedSuccessMessage() {
    return Localizations.localeOf(context).languageCode == 'mr'
        ? 'क्रियाकलाप यशस्वीरित्या हटवला.'
        : 'Activity deleted successfully.';
  }

  String getFriendlyDeleteErrorMessage(Object error) {
    final String message = error.toString();

    if (message.contains('401')) {
      return 'Your session has expired. Please log in again.';
    }
    if (message.contains('403')) {
      return 'You are not authorized to delete this activity.';
    }
    if (message.contains('404')) {
      return 'This activity no longer exists.';
    }
    if (message.contains('SocketException')) {
      return 'Unable to connect to the AgriGuide server.';
    }
    return 'Unable to delete the farm activity.';
  }

  // ==========================================================
  // FORMAT DATE
  // ==========================================================

  String formatDate(DateTime date) {
    final bool isMarathi =
        Localizations.localeOf(context)
                .languageCode ==
            'mr';

    if (isMarathi) {
      const List<String> months = [
        'जाने',
        'फेब्रु',
        'मार्च',
        'एप्रि',
        'मे',
        'जून',
        'जुलै',
        'ऑग',
        'सप्टें',
        'ऑक्टो',
        'नोव्हें',
        'डिसें',
      ];

      return '${date.day} '
          '${months[date.month - 1]} '
          '${date.year}';
    }

    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  // ==========================================================
  // EMPTY DIARY
  // ==========================================================

  Widget buildEmptyDiary() {
    final l10n =
        AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE1E7DF),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.note_add_outlined,
            size: 43,
            color: Color(0xFF4A8950),
          ),

          const SizedBox(height: 11),

          Text(
            l10n.noActivities,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334238),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            l10n.recordFarmActivity,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.4,
              color: Color(0xFF788178),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR MESSAGE
  // ==========================================================

  String getFriendlyErrorMessage(
    Object error,
  ) {
    final String message =
        error.toString();

    if (message.contains('401')) {
      return 'Your session has expired. Please log in again.';
    }

    if (message.contains('403')) {
      return 'You are not authorized to access this diary.';
    }

    if (message.contains('SocketException')) {
      return 'Unable to connect to the AgriGuide server.';
    }

    return 'Unable to load your farm diary.';
  }
}

// ADD DIARY ENTRY SHEET

class AddDiaryEntrySheet
    extends StatefulWidget {
  final void Function(DiaryEntry entry)
      onEntryAdded;

  const AddDiaryEntrySheet({
    super.key,
    required this.onEntryAdded,
  });

  @override
  State<AddDiaryEntrySheet> createState() =>
      _AddDiaryEntrySheetState();
}

// ADD ENTRY STATE

class _AddDiaryEntrySheetState
    extends State<AddDiaryEntrySheet> {
  // FORM CONTROLLERS

  final TextEditingController
      cropController =
      TextEditingController();

  final TextEditingController
      activityController =
      TextEditingController();

  final TextEditingController
      notesController =
      TextEditingController();

  // SAVE STATE
  bool isSaving = false;

  // DISPOSE

  @override
  void dispose() {
    cropController.dispose();
    activityController.dispose();
    notesController.dispose();

    super.dispose();
  }

  // SAVE NEW ENTRY

  Future<void> saveEntry() async {
    final l10n =
        AppLocalizations.of(context)!;

    final String crop =
        cropController.text.trim();

    final String activity =
        activityController.text.trim();

    final String notes =
        notesController.text.trim();

    // VALIDATION

    if (crop.isEmpty ||
        activity.isEmpty ||
        notes.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            l10n.required,
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // START SAVING

    setState(() {
      isSaving = true;
    });

    try {
      // REAL API REQUEST      

      final DiaryEntryModel created =
          await ApiService.createDiaryEntry(
        date: DateTime.now(),
        cropField: crop,
        activity: activity,
        notes: notes,
      );

      if (!mounted) {
        return;
      }

      // CONVERT API MODEL TO UI MODEL

      final DiaryEntry newEntry =
          DiaryEntry.fromApi(
        created,
      );

      // SEND REAL DATABASE RECORD TO PARENT

      widget.onEntryAdded(
        newEntry,
      );

      // Close the bottom sheet.
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            getSaveErrorMessage(error),
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }
  }

  // SAVE ERROR

  String getSaveErrorMessage(
    Object error,
  ) {
    final String message =
        error.toString();

    if (message.contains('401')) {
      return 'Your session has expired. Please log in again.';
    }

    if (message.contains('403')) {
      return 'You are not authorized to save this activity.';
    }

    if (message.contains('SocketException')) {
      return 'Unable to connect to the AgriGuide server.';
    }

    return 'Unable to save the farm activity.';
  }

  // BUILD FORM

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.of(context)
                  .viewInsets
                  .bottom +
              18,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9DED8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // TITLE

              Text(
                l10n.addActivity,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF26372A),
                ),
              ),

              const SizedBox(height: 5),

              Text(
                l10n.recordFarmActivity,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF798279),
                ),
              ),

              const SizedBox(height: 18),

              // CROP / FIELD

              buildFormField(
                controller:
                    cropController,
                label:
                    l10n.cropOrField,
                hint:
                    l10n.enterCropOrField,
                icon:
                    Icons.eco_outlined,
              ),

              const SizedBox(height: 12),

              // ACTIVITY

              buildFormField(
                controller:
                    activityController,
                label:
                    l10n.activity,
                hint:
                    l10n.enterActivity,
                icon:
                    Icons.agriculture_outlined,
              ),

              const SizedBox(height: 12),

              // NOTES

              TextField(
                controller:
                    notesController,
                minLines: 4,
                maxLines: 6,
                enabled: !isSaving,
                decoration:
                    InputDecoration(
                  labelText:
                      l10n.notes,
                  hintText:
                      l10n.enterNotes,

                  prefixIcon:
                      const Padding(
                    padding:
                        EdgeInsets.only(
                      bottom: 55,
                    ),
                    child: Icon(
                      Icons
                          .notes_outlined,
                      color:
                          Color(
                        0xFF4B8650,
                      ),
                    ),
                  ),

                  filled: true,
                  fillColor:
                      const Color(
                    0xFFF9FAF7,
                  ),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      17,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(
                        0xFFE0E5DC,
                      ),
                    ),
                  ),

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      17,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(
                        0xFFE0E5DC,
                      ),
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      17,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(
                        0xFF4B8D4D,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // SAVE BUTTON

              SizedBox(
                width:
                    double.infinity,
                height: 52,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      isSaving
                          ? null
                          : saveEntry,

                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons
                              .save_outlined,
                        ),

                  label: Text(
                    isSaving
                        ? 'Saving...'
                        : l10n
                            .saveActivity,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF168A52,
                    ),
                    foregroundColor:
                        Colors.white,
                    disabledBackgroundColor:
                        const Color(
                      0xFF8BB59A,
                    ),
                    disabledForegroundColor:
                        Colors.white,
                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
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

  // FORM FIELD

  Widget buildFormField({
    required TextEditingController
        controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      enabled: !isSaving,
      decoration:
          InputDecoration(
        labelText: label,
        hintText: hint,

        prefixIcon: Icon(
          icon,
          color:
              const Color(
            0xFF4B8650,
          ),
        ),

        filled: true,
        fillColor:
            const Color(
          0xFFF9FAF7,
        ),

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            17,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(
              0xFFE0E5DC,
            ),
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            17,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(
              0xFFE0E5DC,
            ),
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            17,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(
              0xFF4B8D4D,
            ),
          ),
        ),
      ),
    );
  }
}