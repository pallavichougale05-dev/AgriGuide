import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

import 'auth_screen.dart';

// ============================================================
// KNOWLEDGE HUB
// The Knowledge Hub now loads its educational articles from the
// FastAPI backend instead of using hard-coded demo posts.
// The existing green visual style, search, category filtering,
// article details and login-required sharing flow are preserved.

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

// ============================================================
// KNOWLEDGE HUB STATE
class _KnowledgeScreenState extends State<KnowledgeScreen> {
  // Search field used to filter articles locally.
  final TextEditingController searchController =
      TextEditingController();

  // Articles returned by FastAPI.
  List<KnowledgeArticle> articles = [];

  // Loading/error state for the API request.
  bool isLoading = true;
  String? errorMessage;

  // 0 means All. The remaining indexes are generated from the
  // categories returned by the backend.
  int selectedCategory = 0;

  // ==========================================================
  // INITIAL LOAD

  @override
  void initState() {
    super.initState();
    loadKnowledgeArticles();
  }

  // ==========================================================
  // LOAD ARTICLES FROM FASTAPI
  // ApiService already knows how to call:
  // GET /knowledge/articles
  // We keep the network call outside the build method so the
  // request is not repeated every time Flutter rebuilds the UI.

  Future<void> loadKnowledgeArticles() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final List<KnowledgeArticle> result =
          await ApiService.getKnowledgeArticles();

      if (!mounted) {
        return;
      }

      setState(() {
        articles = result;
        isLoading = false;
        selectedCategory = 0;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  // ==========================================================
  // CATEGORY VALUES

  List<String> get categoryValues {
    final Set<String> uniqueCategories = articles
        .map((article) => article.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet();

    final List<String> values = ['all'];
    values.addAll(uniqueCategories);
    return values;
  }

  // ==========================================================
  // FILTERED ARTICLES
  // Filtering happens locally after the backend data has been
  // loaded. This makes search and category changes immediate.

  List<KnowledgeArticle> get filteredArticles {
    Iterable<KnowledgeArticle> result = articles;

    final List<String> categories = categoryValues;

    // Category filter.
    if (selectedCategory > 0 && selectedCategory < categories.length) {
      final String selected = categories[selectedCategory].toLowerCase();

      result = result.where(
        (article) => article.category.toLowerCase() == selected,
      );
    }

    // Search filter.
    final String query = searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where(
        (article) =>
            article.title.toLowerCase().contains(query) ||
            article.summary.toLowerCase().contains(query) ||
            article.content.toLowerCase().contains(query) ||
            article.category.toLowerCase().contains(query),
      );
    }
    return result.toList();
  }

  // ==========================================================
  // LOCALIZED CATEGORY NAME
  // Backend categories currently include values such as:
  // Soil, Water Management, Crop Management, Crop Protection, Weather and Farm Management.
  // We map categories that already have localization keys to the
  // existing translated labels. Unknown categories are shown
  // exactly as returned by the backend.

  String localizedCategory(
    BuildContext context,
    String category,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final String key = category.trim().toLowerCase();

    switch (key) {
      case 'soil':
        return l10n.soilCategory;

      case 'crop management':
        return l10n.cropCategory;

      case 'crop protection':
        return l10n.diseaseCategory;

      case 'water management':
        return l10n.irrigationCategory;

      case 'weather':
        return l10n.weather;

      default:
        return category;
    }
  }

  // ==========================================================
  // CATEGORY DISPLAY LIST

  List<String> localizedCategories(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<String> values = categoryValues;

    return values.asMap().entries.map((entry) {
      if (entry.key == 0) {
        return l10n.all;
      }

      return localizedCategory(context, entry.value);
    }).toList();
  }

  // ==========================================================
  // LOGIN REQUIRED
  // Reading Knowledge Hub content is public.
  // Sharing an experience still requires login according to the existing product rule.

  Future<void> requireLogin(String message) async {
  final wantsLogin = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return LoginRequiredSheet(message: message);
    },
  );

  if (wantsLogin != true || !mounted) return;

  final loggedIn = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => const AuthScreen(),
    ),
  );

  if (loggedIn == true && mounted) {
    // Open the Share Experience form here.
  }
}

  // ==========================================================
  // OPEN ARTICLE
  void openArticle(KnowledgeArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KnowledgeArticleScreen(article: article),
      ),
    );
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
    final List<String> categories = localizedCategories(context);

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
            onPressed: isLoading ? null : loadKnowledgeArticles,
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
                    const SizedBox(height: 13),
                    buildCategoryFilter(categories),
                    const SizedBox(height: 20),
                    if (isLoading)
                      buildLoadingState()
                    else if (errorMessage != null)
                      buildErrorState()
                    else
                      buildArticleContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          requireLogin(l10n.loginToShareExperience);
        },
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
  // COMMUNITY / KNOWLEDGE HEADER

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
  // CATEGORY FILTER

  Widget buildCategoryFilter(List<String> categories) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final bool selected = selectedCategory == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF168A52)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF168A52)
                      : const Color(0xFFE0E6DE),
                ),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : const Color(0xFF5E6961),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // ARTICLE CONTENT

  Widget buildArticleContent() {
    final l10n = AppLocalizations.of(context)!;
    final List<KnowledgeArticle> visibleArticles = filteredArticles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.knowledgeHub,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF26372A),
                ),
              ),
            ),
            Text(
              '${visibleArticles.length}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7C867E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visibleArticles.isEmpty)
          buildNoArticlesState()
        else
          ...visibleArticles.map(
            (article) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: buildArticleCard(article),
            ),
          ),
      ],
    );
  }

  // ==========================================================
  // ARTICLE CARD

  Widget buildArticleCard(KnowledgeArticle article) {
    return GestureDetector(
      onTap: () => openArticle(article),
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
                    Icons.menu_book_rounded,
                    size: 24,
                    color: Color(0xFF438C47),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    localizedCategory(context, article.category),
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
                    localizedCategory(context, article.category),
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
              article.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF27382D),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              article.summary,
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
                const Icon(
                  Icons.article_outlined,
                  size: 18,
                  color: Color(0xFF68756C),
                ),
                const SizedBox(width: 5),
                Text(
                  'Article ${article.id}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF68756C),
                  ),
                ),
                const Spacer(),
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

  // ==========================================================
  // LOADING STATE

  Widget buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E7DF)),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(height: 14),
          Text(
            'Loading knowledge articles...',
            textAlign: TextAlign.center,
            style: TextStyle(
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

  Widget buildErrorState() {
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
            'Unable to load Knowledge Hub',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF344238),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            errorMessage ?? l10n.tryAgain,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.4,
              color: Color(0xFF7C867E),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: loadKnowledgeArticles,
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
  // NO ARTICLES STATE

  Widget buildNoArticlesState() {
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
            Icons.search_off_rounded,
            size: 42,
            color: Color(0xFF7B877E),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.noPostsFound,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF344238),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            l10n.tryAgain,
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
// KNOWLEDGE ARTICLE DETAILS SCREEN

class KnowledgeArticleScreen extends StatelessWidget {
  final KnowledgeArticle article;

  const KnowledgeArticleScreen({
    super.key,
    required this.article,
  });

  // ==========================================================
  // LOCALIZED CATEGORY

  String localizedCategory(
    BuildContext context,
    String category,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final String key = category.trim().toLowerCase();

    switch (key) {
      case 'soil':
        return l10n.soilCategory;
      case 'crop management':
        return l10n.cropCategory;
      case 'crop protection':
        return l10n.diseaseCategory;
      case 'water management':
        return l10n.irrigationCategory;
      case 'weather':
        return l10n.weather;
      default:
        return category;
    }
  }

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
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article category.
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
                localizedCategory(context, article.category),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4B7F53),
                ),
              ),
            ),
            const SizedBox(height: 11),


            // Article title.
            Text(
              article.title,
              style: const TextStyle(
                fontSize: 23,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: Color(0xFF25362A),
              ),
            ),
            const SizedBox(height: 14),

            // Article summary.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE1E7DF)),
              ),
              child: Text(
                article.summary,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.55,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF59675E),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Complete article content.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE1E7DF)),
              ),
              child: Text(
                article.content,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.55,
                  color: Color(0xFF59675E),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Backend article identifier is useful during testing
            // and can be removed later if it is not needed in the production UI.
            Center(
              child: Text(
                'Article ID: ${article.id}',
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF8A938D),
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
// Sharing an experience remains protected by the existing
// login-required flow.


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
            onPressed: () async {
              Navigator.pop(context); // Close the login-required sheet

              final loggedIn = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AuthScreen(),
                ),
              );

              if (loggedIn == true && context.mounted) {
                // Open the Share Experience form here.
              }
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
              Navigator.pop(context, true);
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