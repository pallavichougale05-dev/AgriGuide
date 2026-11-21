
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'auth_screen.dart';
import 'share_experience_screen.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<ExperienceModel> _experiences = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedTopic = 'All';

  String _currentLanguageCode = '';
  int _requestVersion = 0;

  bool get _isMarathi =>
      Localizations.localeOf(context).languageCode == 'mr';

  String tr(String english, String marathi) =>
      _isMarathi ? marathi : english;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final language = Localizations.localeOf(context).languageCode;
    final normalizedLanguage = language == 'mr' ? 'mr' : 'en';

    if (_currentLanguageCode != normalizedLanguage) {
      _currentLanguageCode = normalizedLanguage;
      loadExperiences(normalizedLanguage);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> loadExperiences([String? language]) async {
    final requestedLanguage =
        language ?? (_isMarathi ? 'mr' : 'en');
    final requestId = ++_requestVersion;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await ApiService.getExperiences(
        lang: requestedLanguage,
      );

      if (!mounted || requestId != _requestVersion) return;

      setState(() {
        _experiences = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestVersion) return;

      setState(() {
        _isLoading = false;
        _errorMessage = tr(
          'Unable to load community posts. Please try again.',
          'समुदायातील पोस्ट लोड करता आल्या नाहीत. पुन्हा प्रयत्न करा.',
        );
      });
    }
  }

  List<String> get _topics {
    final topics = _experiences
        .map((item) => item.topic.trim())
        .where((topic) => topic.isNotEmpty)
        .toSet()
        .toList();

    topics.sort();

    return [
      tr('All', 'सर्व'),
      ...topics,
    ];
  }

  List<ExperienceModel> get _filteredExperiences {
    final query = _searchQuery.toLowerCase().trim();

    return _experiences.where((item) {
      final matchesTopic = _selectedTopic == 'All' ||
          _selectedTopic == 'सर्व' ||
          item.topic == _selectedTopic;

      final searchableText = [
        item.title,
        item.topic,
        item.content,
        item.authorName,
      ].join(' ').toLowerCase();

      final matchesSearch =
          query.isEmpty || searchableText.contains(query);

      return matchesTopic && matchesSearch;
    }).toList();
  }

  Future<void> _openShareExperience() async {
    try {
      final isLoggedIn = await ApiService.hasValidSession();

      if (!mounted) return;

      if (!isLoggedIn) {
        _showLoginRequiredSheet();
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ShareExperienceScreen(),
        ),
      );

      if (!mounted) return;
      await loadExperiences();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'Something went wrong. Please try again.',
              'काहीतरी चूक झाली. पुन्हा प्रयत्न करा.',
            ),
          ),
        ),
      );
    }
  }

  void _showLoginRequiredSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF247A43),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tr('Login required', 'लॉगिन आवश्यक आहे'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF183B2A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr(
                    'Please log in to share your farming experience with the community.',
                    'समुदायासोबत तुमचा शेतीचा अनुभव शेअर करण्यासाठी कृपया लॉगिन करा.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF247A43),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
  Navigator.pop(sheetContext);

  final loginResult = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => const AuthScreen(),
    ),
  );

  debugPrint('LOGIN RESULT: $loginResult');

  if (!mounted) return;

  if (loginResult == true) {
    debugPrint('Opening Share Experience Form');

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ShareExperienceScreen(),
      ),
    );

    if (!mounted) return;

    await loadExperiences();
  }
},
                    child: Text(
                      tr('Login / Register', 'लॉगिन / नोंदणी'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(
                    tr('Maybe later', 'नंतर'),
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openExperience(ExperienceModel experience) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExperienceDetailScreen(
          experience: experience,
        ),
      ),
    );
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value.toString());

    if (date == null) return '';

    final localDate = date.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDate);

    if (difference.inMinutes < 1) {
      return tr('Just now', 'आत्ताच');
    }

    if (difference.inHours < 1) {
      return tr(
        '${difference.inMinutes} min ago',
        '${difference.inMinutes} मिनिटांपूर्वी',
      );
    }

    if (difference.inDays < 1) {
      return tr(
        '${difference.inHours} hours ago',
        '${difference.inHours} तासांपूर्वी',
      );
    }

    if (difference.inDays < 7) {
      return tr(
        '${difference.inDays} days ago',
        '${difference.inDays} दिवसांपूर्वी',
      );
    }

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredExperiences;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF247A43),
          onRefresh: () => loadExperiences(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              SliverToBoxAdapter(
                child: _buildCommunityBanner(),
              ),
              SliverToBoxAdapter(
                child: _buildSearchField(),
              ),
              SliverToBoxAdapter(
                child: _buildTopicFilters(),
              ),
              SliverToBoxAdapter(
                child: _buildSectionHeader(filtered.length),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF247A43),
                    ),
                  ),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildErrorState(),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildExperienceCard(
                            filtered[index],
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F1E5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.groups_2_rounded,
              color: Color(0xFF247A43),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Farming Knowledge', 'शेतीविषयक माहिती'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF183B2A),
                  ),
                ),
                
              ],
            ),
          ),
          IconButton(
            tooltip: tr('Refresh', 'रिफ्रेश'),
            onPressed: () => loadExperiences(),
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF247A43),
              size: 25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1F7540),
            Color(0xFF3B9658),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -18,
            child: Icon(
              Icons.agriculture_rounded,
              size: 112,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tr('FARMER COMMUNITY', 'शेतकरी समुदाय'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            
              const SizedBox(height: 9),
              SizedBox(
                width: 250,
                child: Text(
                  tr(
                    'Discover practical knowledge shared by fellow farmers.',
                    'इतर शेतकऱ्यांनी शेअर केलेले उपयुक्त अनुभव जाणून घ्या.',
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              InkWell(
                onTap: _openShareExperience,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_rounded,
                        size: 15,
                        color: Color(0xFF247A43),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        tr('Share your Experience', 'तुमचा अनुभव शेअर करा'),
                        style: const TextStyle(
                          color: Color(0xFF247A43),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE6EBE5)),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          decoration: InputDecoration(
            hintText: tr(
              'Search experiences, topics...',
              'अनुभव किंवा विषय शोधा...',
            ),
            hintStyle: const TextStyle(
              color: Colors.black38,
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF247A43),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicFilters() {
    final topics = _topics;

    if (topics.length <= 1) {
      return const SizedBox(height: 8);
    }

    if (!topics.contains(_selectedTopic)) {
      _selectedTopic = topics.first;
    }

    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: topics.length,
        // ignore: unnecessary_underscores
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final topic = topics[index];
          final selected = topic == _selectedTopic;

          return ChoiceChip(
            label: Text(topic),
            selected: selected,
            onSelected: (_) {
              setState(() => _selectedTopic = topic);
            },
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFF247A43),
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.black54,
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
            ),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF247A43)
                  : const Color(0xFFE2E8E1),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tr('Community posts', 'समुदायातील पोस्ट'),
              style: const TextStyle(
                color: Color(0xFF183B2A),
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
          Text(
            '$count ${tr('posts', 'पोस्ट') }',
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard(ExperienceModel experience) {
    final photoUrl = experience.photoUrl?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openExperience(experience),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE9EDE8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE6F2E8),
                    child: Text(
                      experience.authorName.trim().isNotEmpty
                          ? experience.authorName.trim()[0].toUpperCase()
                          : 'F',
                      style: const TextStyle(
                        color: Color(0xFF247A43),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          experience.authorName.trim().isNotEmpty
                              ? experience.authorName
                              : tr('Farmer', 'शेतकरी'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF26372C),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatDate(experience.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (experience.topic.trim().isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4EB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          experience.topic,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF247A43),
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                experience.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF203A2A),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                experience.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.55,
                  color: Colors.black54,
                ),
              ),
              if (hasPhoto) ...[
                const SizedBox(height: 13),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    photoUrl,
                    width: double.infinity,
                    height: 175,
                    fit: BoxFit.cover,
                    // ignore: unnecessary_underscores
                    errorBuilder: (_, __, ___) {
                      return Container(
                        height: 100,
                        color: const Color(0xFFF0F3EF),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.black38,
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 13),
              const Divider(height: 1, color: Color(0xFFEEF0EC)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    size: 16,
                    color: Color(0xFF247A43),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tr('Read experience', 'अनुभव वाचा'),
                    style: const TextStyle(
                      color: Color(0xFF247A43),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 17,
                    color: Color(0xFF247A43),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 76,
              width: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F2E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 36,
                color: Color(0xFF247A43),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? tr('No matching posts found', 'जुळणाऱ्या पोस्ट सापडल्या नाहीत')
                  : tr('No experiences yet', 'अजून अनुभव उपलब्ध नाहीत'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF183B2A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? tr(
                      'Try another keyword or topic.',
                      'दुसरा शब्द किंवा विषय शोधून पाहा.',
                    )
                  : tr(
                      'Be the first to share a farming experience.',
                      'शेतीचा अनुभव शेअर करणारे पहिले शेतकरी बना.',
                    ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Colors.black38,
            ),
            const SizedBox(height: 14),
            Text(
              _errorMessage ?? tr('Something went wrong', 'काहीतरी चूक झाली'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => loadExperiences(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(tr('Try again', 'पुन्हा प्रयत्न करा')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF247A43),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExperienceDetailScreen extends StatelessWidget {
  final ExperienceModel experience;

  const ExperienceDetailScreen({
    super.key,
    required this.experience,
  });

  bool _isMarathi(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'mr';

  String _tr(BuildContext context, String english, String marathi) =>
      _isMarathi(context) ? marathi : english;

  @override
  Widget build(BuildContext context) {
    final photoUrl = experience.photoUrl?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F3),
        foregroundColor: const Color(0xFF183B2A),
        elevation: 0,
        title: Text(
          _tr(context, 'Farmer Experience', 'शेतकऱ्याचा अनुभव'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE9EDE8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (experience.topic.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4EB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    experience.topic,
                    style: const TextStyle(
                      color: Color(0xFF247A43),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                experience.title,
                style: const TextStyle(
                  color: Color(0xFF183B2A),
                  fontSize: 22,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: Color(0xFF247A43),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      experience.authorName.trim().isNotEmpty
                          ? experience.authorName
                          : _tr(context, 'Farmer', 'शेतकरी'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (hasPhoto) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    photoUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // ignore: unnecessary_underscores
                    errorBuilder: (_, __, ___) {
                      return Container(
                        height: 150,
                        color: const Color(0xFFF0F3EF),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 35,
                          color: Colors.black38,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                experience.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.8,
                  color: Color(0xFF35463A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
