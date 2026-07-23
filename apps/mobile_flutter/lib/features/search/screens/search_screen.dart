import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/search_controller.dart';
import '../models/search_result_model.dart';
import '../repositories/search_repository.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  static const routeName = '/search';

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _input = TextEditingController();
  Timer? _debounce;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _input.dispose();
    _debounce?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      context.read<YohPalSearchController>().runSearch(
            userId: user.uid,
            value: value,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final controller = context.watch<YohPalSearchController>();
    final repo = context.read<SearchRepository>();

    if (user == null) {
      return const Scaffold(
          body: Center(child: Text('Please sign in')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        title: const Text('Search YohPal'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Videos'),
            Tab(text: 'Creators'),
            Tab(text: 'Live'),
            Tab(text: 'Business'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              controller: _input,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search videos, creators, live, businesses...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _input.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.white54),
                        onPressed: () {
                          _input.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF101527),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (controller.query.isEmpty)
            _SearchSuggestions(
              repo: repo,
              userId: user.uid,
              onSelect: (q) {
                _input.text = q;
                _onSearchChanged(q);
              },
            )
          else if (controller.loading)
            const Expanded(
                child: Center(child: CircularProgressIndicator()))
          else if (controller.error != null)
            Expanded(
              child: Center(
                child: Text(
                  controller.error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            )
          else
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _ResultsList(
                      results: controller.results['videos'] ?? []),
                  _ResultsList(
                      results: controller.results['creators'] ?? []),
                  _ResultsList(
                      results: controller.results['live'] ?? []),
                  _ResultsList(
                      results: controller.results['businesses'] ?? []),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  final SearchRepository repo;
  final String userId;
  final void Function(String query) onSelect;

  const _SearchSuggestions({
    required this.repo,
    required this.userId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text('Recent Searches',
              style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 12),
          StreamBuilder<List<String>>(
            stream: repo.watchRecentSearches(userId),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Text(
                  'No recent searches yet',
                  style: TextStyle(color: Colors.white54),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 4,
                children: items
                    .map((q) => ActionChip(
                          label: Text(q,
                              style: const TextStyle(
                                  color: Colors.white70)),
                          backgroundColor: const Color(0xFF101527),
                          onPressed: () => onSelect(q),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Trending',
              style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 12),
          StreamBuilder<List<String>>(
            stream: repo.watchTrendingSearches(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Text(
                  'Trending searches will appear here',
                  style: TextStyle(color: Colors.white54),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 4,
                children: items
                    .map((q) => ActionChip(
                          label: Text(q,
                              style: const TextStyle(
                                  color: Colors.white70)),
                          backgroundColor: const Color(0xFF101527),
                          onPressed: () => onSelect(q),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<SearchResultModel> results;

  const _ResultsList({required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No results found',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          leading: result.imageUrl.isEmpty
              ? CircleAvatar(
                  backgroundColor: const Color(0xFF101527),
                  child: Text(
                    result.type[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              : CircleAvatar(
                  backgroundImage: NetworkImage(result.imageUrl),
                  backgroundColor: const Color(0xFF101527),
                ),
          title: Text(
            result.title,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            result.subtitle,
            style: const TextStyle(color: Colors.white54),
          ),
          trailing: result.type == 'live'
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('LIVE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                )
              : null,
          onTap: () => _openResult(context, result),
        );
      },
    );
  }

  void _openResult(BuildContext context, SearchResultModel result) {
    if (result.type == 'video') {
      Navigator.pushNamed(context, '/creator-profile',
          arguments: result.raw['ownerId'] ?? result.id);
      return;
    }
    if (result.type == 'creator') {
      Navigator.pushNamed(context, '/creator-profile',
          arguments: result.id);
      return;
    }
    if (result.type == 'live') {
      Navigator.pushNamed(context, '/live-viewer', arguments: result.id);
      return;
    }
    if (result.type == 'business') {
      Navigator.pushNamed(context, '/business-profile',
          arguments: result.id);
      return;
    }
  }
}
