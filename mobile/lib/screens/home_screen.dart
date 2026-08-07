import 'package:flutter/material.dart';
import '../models/template.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import 'editor_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import '../services/user_settings_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Template>> _templatesFuture;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  int _activeTabIndex = 0;
  int _highlightedNavIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void _onReturnToRoot() {
    if (mounted) {
      setState(() {
        _highlightedNavIndex = _activeTabIndex;
      });
      _loadTemplates();
    }
  }

  Widget _buildTabNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      observers: [NestedNavigatorObserver(_onReturnToRoot)],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => child,
        );
      },
    );
  }

  void _onCreateTapped() {
    setState(() {
      _highlightedNavIndex = 2;
    });
    _navigatorKeys[_activeTabIndex].currentState?.push(
      MaterialPageRoute(
        builder: (_) => EditorScreen(
          template: Template(
            id: 'new',
            title: 'New Design',
            status: 'draft',
            thumbnailUrl: '',
            width: 1080,
            height: 1080,
            background: Background(type: 'color', value: '#FFFFFF'),
            imageLayers: [],
            textLayers: [],
            shapeLayers: [],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _highlightedNavIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 2) {
            _onCreateTapped();
          } else {
            _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
            setState(() {
              _highlightedNavIndex = index;
              _activeTabIndex = index;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.darkBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.accentNeon : AppTheme.textGray,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppTheme.textGray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  void _loadTemplates() {
    setState(() {
      _templatesFuture = ApiService.fetchTemplates();
    });
  }

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.white;
    }
  }

  String _resolveImageUrl(String url) {
    // Use ApiService to resolve the image URL dynamically
    return ApiService.resolveImageUrl(url);
    return url;
  }

  List<Template> _filterTemplates(List<Template> templates) {
    return templates.where((template) {
      final matchesSearch = template.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          template.status.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final currentNavigator = _navigatorKeys[_activeTabIndex].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
          return false;
        } else {
          if (_activeTabIndex != 0) {
            setState(() {
              _activeTabIndex = 0;
              _highlightedNavIndex = 0;
            });
            return false;
          }
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightBackground,
        appBar: AppBar(
          title: Text(
            _activeTabIndex == 4
                ? 'Settings'
                : _activeTabIndex == 3
                    ? 'Profile'
                    : _activeTabIndex == 1
                        ? 'Browse'
                        : 'Hello, User',
            style: const TextStyle(fontSize: 24, letterSpacing: -0.5),
          ),
          centerTitle: false,
        ),
        body: Stack(
          children: [
            IndexedStack(
              index: _activeTabIndex,
              children: [
                _buildTabNavigator(0, _buildHomeTab()),
                _buildTabNavigator(1, _buildBrowseTab()), // Replaced Favorites with Browse
                _buildTabNavigator(2, Container()), // Create button
                _buildTabNavigator(3, const ProfileScreen()),
                _buildTabNavigator(4, const SettingsScreen()),
              ],
            ),
            
            // Floating Bottom Navigation Bar
            Positioned(
              bottom: 24,
              left: 12,
              right: 12,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, 'Home'),
                    _buildNavItem(1, Icons.search_rounded, 'Browse'),
                    _buildNavItem(2, Icons.add_circle_outline_rounded, 'Create'),
                    _buildNavItem(3, Icons.person_outline_rounded, 'Profile'),
                    _buildNavItem(4, Icons.settings_outlined, 'Settings'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create a\nBeautiful Tribute',
            style: TextStyle(
              fontSize: 28,
              height: 1.2,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _onCreateTapped,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Start from Scratch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9094CE),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search Memorial Templates...',
            hintStyle: const TextStyle(color: AppTheme.textLight),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textGray),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AppTheme.textGray),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                : const Icon(Icons.tune_rounded, color: AppTheme.textGray),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildHorizontalCarousel(String title, List<Template> templates) {
    if (templates.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () {
                  _navigatorKeys[1].currentState?.popUntil((route) => route.isFirst);
                  setState(() {
                    _activeTabIndex = 1;
                    _highlightedNavIndex = 1;
                  });
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return _buildTemplateCard(template, width: 150);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(Template template, {double? width, EdgeInsetsGeometry? margin}) {
    final isImageBg = template.background.type == 'image';
    final bgValue = template.background.value;

    return Container(
      width: width,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            _navigatorKeys[_activeTabIndex].currentState?.push(
              MaterialPageRoute(
                builder: (_) => EditorScreen(template: template),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isImageBg ? Colors.white : _parseHexColor(bgValue),
                        ),
                        child: isImageBg && bgValue.startsWith('http')
                            ? Image.network(
                                _resolveImageUrl(bgValue),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      color: AppTheme.textGray,
                                    ),
                                  );
                                },
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          UserSettingsService.instance.toggleFavorite(template.id);
                        },
                        child: ListenableBuilder(
                          listenable: UserSettingsService.instance,
                          builder: (context, _) {
                            final isFavorite = UserSettingsService.instance.favoriteTemplateIds.contains(template.id);
                            return Container(
                              padding: const EdgeInsets.all(6),
                              color: Colors.transparent,
                              child: Icon(
                                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFavorite ? Colors.redAccent : Colors.white,
                                size: 24,
                                shadows: [
                                  if (!isFavorite)
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 4,
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Template',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        _loadTemplates();
      },
      color: AppTheme.accentNeon,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          _buildHeroBanner(),
          _buildSearchBar(),
          FutureBuilder<List<Template>>(
            future: _templatesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.accentNeon)),
                );
              } else if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 64,
                        color: AppTheme.textGray,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Cannot Connect to Server',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Make sure your dashboard backend is running locally at port 5000 and click retry.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGray,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadTemplates,
                        child: const Text('Retry Connection'),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'No templates found on backend admin.',
                      style: TextStyle(color: AppTheme.textGray),
                    ),
                  ),
                );
              }

              final filteredList = _filterTemplates(snapshot.data!);

              if (filteredList.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'No matching templates found.',
                      style: TextStyle(color: AppTheme.textGray),
                    ),
                  ),
                );
              }

              final trending = filteredList.take(5).toList();
              final recent = filteredList.skip(5).toList();

              return Column(
                children: [
                  _buildHorizontalCarousel('Trending Designs', trending),
                  if (recent.isNotEmpty) _buildHorizontalCarousel('Recent Designs', recent),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
  Widget _buildBrowseTab() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _loadTemplates();
            },
            color: AppTheme.accentNeon,
            child: FutureBuilder<List<Template>>(
              future: _templatesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.accentNeon));
                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      const Center(
                        child: Text(
                          'No templates found.',
                          style: TextStyle(color: AppTheme.textGray),
                        ),
                      ),
                    ],
                  );
                }

                final filteredList = _filterTemplates(snapshot.data!);

                if (filteredList.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      const Center(
                        child: Text(
                          'No matching templates found.',
                          style: TextStyle(color: AppTheme.textGray),
                        ),
                      ),
                    ],
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final template = filteredList[index];
                    return _buildTemplateCard(template, margin: EdgeInsets.zero);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class NestedNavigatorObserver extends NavigatorObserver {
  final VoidCallback onReturnToRoot;

  NestedNavigatorObserver(this.onReturnToRoot);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null && previousRoute.isFirst) {
      onReturnToRoot();
    }
  }
}
