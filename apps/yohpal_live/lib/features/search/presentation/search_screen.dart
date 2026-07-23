import 'package:flutter/material.dart';
import '../../../core/auth/yohpal_auth_service.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../application/search_controller.dart' as yohpal_search;
import '../data/search_repository.dart';
import '../domain/search_result.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late final yohpal_search.SearchController _controller;
  late final TabController _tabController;
  final _searchFieldCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final env = AppEnvironmentConfig.fromDartDefines();
    final auth = YohPalAuthService();
    _controller = yohpal_search.SearchController(
      repository: SearchRepository(
        apiClient: ApiClient(
          baseUrl: env.apiBaseUrl,
          tokenProvider: auth.getIdToken,
        ),
      ),
    );

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _controller.setActiveTab(_tabController.index == 0 ? 'videos' : 'creators');
    });

    _controller.addListener(() {
      final tabIndex = _controller.activeTab == 'videos' ? 0 : 1;
      if (_tabController.index != tabIndex) {
        _tabController.animateTo(tabIndex);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    _searchFieldCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D0D1E),
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Explore YohPal',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(110),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildTabBar(),
                ],
              ),
            ),
          ),
        ),
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isSearching) {
              return _buildShimmerGrid();
            }

            if (_controller.failure != null) {
              return _buildErrorState();
            }

            if (_searchFieldCtrl.text.trim().length < 2) {
              return _buildRecentOrPlaceholderState();
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildVideoResults(),
                _buildCreatorResults(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: TextField(
        controller: _searchFieldCtrl,
        onChanged: _controller.onQueryChanged,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          suffixIcon: _searchFieldCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    _searchFieldCtrl.clear();
                    _controller.clear();
                    setState(() {});
                  },
                )
              : null,
          hintText: 'Search videos, tags, creators...',
          hintStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: const Color(0xFF6C63FF),
      indicatorWeight: 3,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white38,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
      tabs: const [
        Tab(text: 'Videos'),
        Tab(text: 'Creators'),
      ],
    );
  }

  Widget _buildVideoResults() {
    final videos = _controller.videoResults;
    if (videos.isEmpty) {
      return _buildEmptyState('No videos found', 'Try refining your query or keywords.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      itemBuilder: (context, idx) {
        final video = videos[idx];
        return _VideoResultTile(video: video);
      },
    );
  }

  Widget _buildCreatorResults() {
    final creators = _controller.creatorResults;
    if (creators.isEmpty) {
      return _buildEmptyState('No creators found', 'Search for their display name or username.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: creators.length,
      itemBuilder: (context, idx) {
        final creator = creators[idx];
        return _CreatorResultTile(creator: creator);
      },
    );
  }

  Widget _buildRecentOrPlaceholderState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.travel_explore,
                size: 64,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Search what you love',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Type to find trending videos and creators',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Search Failed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.failure?.message ?? 'A network error occurred.',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _controller.search(_searchFieldCtrl.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, idx) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 66,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 14,
                        width: 140,
                        color: Colors.white.withOpacity(0.04),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 80,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VideoResultTile extends StatelessWidget {
  const _VideoResultTile({required this.video});
  final VideoSearchResult video;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: Colors.white.withOpacity(0.04),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 110,
                height: 70,
                color: Colors.white10,
                child: video.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        video.thumbnailUrl,
                        fit: Cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.videocam, color: Colors.white30),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.videocam, color: Colors.white30),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.creatorName,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye_outlined, size: 12, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(
                        '${video.viewCount} views',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.schedule, size: 12, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(
                        '${video.duration.inMinutes}m',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorResultTile extends StatelessWidget {
  const _CreatorResultTile({required this.creator});
  final CreatorSearchResult creator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: Colors.white.withOpacity(0.04),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white10,
              backgroundImage: creator.avatarUrl.isNotEmpty
                  ? NetworkImage(creator.avatarUrl)
                  : null,
              child: creator.avatarUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white30)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        creator.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (creator.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 14, color: Colors.blueAccent),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${creator.username}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${creator.followerCount} followers',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white54),
              onPressed: () {
                // Navigate to creator profile
              },
            ),
          ],
        ),
      ),
    );
  }
}

const Cover = BoxFit.cover;
