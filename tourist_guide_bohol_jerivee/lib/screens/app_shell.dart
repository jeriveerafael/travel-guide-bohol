import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/destination.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/image_cache_service.dart';
import '../services/local_storage_service.dart';
import '../services/offline_cache.dart';
import '../widgets/offline_banner.dart';
import 'admin_screen.dart';
import 'auth_dialog.dart';
import 'destination_detail_sheet.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'itinerary_screen.dart';
import 'map_screen.dart';
import 'offline_screen.dart';
import 'saved_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  LocalStorageService? _storage;
  final ApiService _api = ApiService();
  bool _apiConnected = false;
  String? _authToken;
  Map<String, dynamic>? _currentUser;
  bool _isReady = false;
  int _selectedIndex = 0;
  String _searchQuery = '';
  Timer? _searchLogTimer;
  String _lastLoggedSearch = '';
  final ConnectivityService _connectivity = ConnectivityService();
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isOnline = true;

  late List<Destination> _destinations;
  Set<String> _favorites = <String>{};
  Set<String> _savedOffline = <String>{};
  Set<String> _visited = <String>{};
  Set<String> _savedItineraries = <String>{};

  @override
  void initState() {
    super.initState();
    _destinations = List<Destination>.of(sampleDestinations);
    _isOnline = _connectivity.isOnline;
    _initialize();
    _connectivitySubscription = _connectivity.changes.listen(_handleConnectivityChange);
  }

  Future<void> _handleConnectivityChange(bool online) async {
    if (!mounted) return;
    setState(() => _isOnline = online);
    if (online) {
      final refreshed = await _syncContent();
      if (refreshed && mounted) {
        _showMessage('Back online. Tourism information was refreshed.');
      }
    } else {
      _showMessage('You are offline. Showing cached guides and downloaded maps.');
    }
  }

  @override
  void dispose() {
    _searchLogTimer?.cancel();
    _connectivitySubscription?.cancel();
    _connectivity.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final storage = await LocalStorageService.create();
      List<Destination> destinations = List<Destination>.of(sampleDestinations);
      final custom = storage.readCustomDestinations();
      var apiConnected = false;

      // Offline-first: restore the last cached catalogue before trying the API
      // so the guide is usable without an internet connection.
      final cachedCatalogue = await OfflineCache.readCatalogue();
      if (cachedCatalogue.isNotEmpty) {
        destinations = _mergeCustom(cachedCatalogue, custom);
      }

      // Restore the cached account so a returning signed-in visitor can keep
      // using the website when the API cannot be reached.
      final savedToken = storage.readString('auth_token');
      Map<String, dynamic>? restoredUser;
      final cachedUser = storage.readString('auth_user');
      if (cachedUser != null && cachedUser.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedUser);
          if (decoded is Map) restoredUser = _normalizeUser(decoded);
        } catch (_) {
          restoredUser = null;
        }
      }

      try {
        final remote = await _api.fetchDestinations();
        apiConnected = true;
        if (remote.isNotEmpty) {
          destinations = remote;
          await OfflineCache.saveCatalogue(remote);
        }
      } catch (_) {
        if (cachedCatalogue.isEmpty) {
          destinations = _mergeCustom(List<Destination>.of(sampleDestinations), custom);
          // Keep something useful in the offline catalogue even when the API
          // has never been reachable from this browser.
          await OfflineCache.saveCatalogue(destinations);
        }
      }

      if (apiConnected && savedToken != null && savedToken.isNotEmpty) {
        try {
          final result = await _api.currentUser(savedToken);
          final rawUser = result['user'];
          if (rawUser is Map) restoredUser = _normalizeUser(rawUser);
          if (restoredUser == null) throw Exception('Invalid user session.');
          await storage.writeString('auth_token', savedToken);
          await storage.writeString('auth_user', jsonEncode(restoredUser));
          await storage.remove('admin_token'); // migrate the previous admin-only key
        } catch (_) {
          // Only a reachable API can reject a session. When the API is offline
          // the cached session is kept for offline browsing.
          await storage.remove('auth_token');
          await storage.remove('auth_user');
          await storage.remove('admin_token');
          restoredUser = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _storage = storage;
        _apiConnected = apiConnected;
        _authToken = restoredUser == null ? null : savedToken;
        _currentUser = restoredUser;
        _destinations = destinations;
        _favorites = storage.readSet('favorites');
        _savedOffline = storage.readSet('offline_destinations');
        _visited = storage.readSet('visited_destinations');
        _savedItineraries = storage.readSet('saved_itineraries');
        _isOnline = _connectivity.isOnline;
        _isReady = true;
      });

      if (!apiConnected && cachedCatalogue.isEmpty) {
        _showMessage('The PHP/MySQL API is offline and no offline copy is stored yet. Showing bundled sample tourism records.');
      } else if (!apiConnected) {
        _showMessage('You are offline. Showing the tourism information saved on this device.');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isReady = true);
      _showMessage('Local browser storage could not be initialized.');
    }
  }

  List<Destination> _mergeCustom(List<Destination> base, List<Destination> custom) {
    final ids = base.map((item) => item.id).toSet();
    return [...base, ...custom.where((item) => !ids.contains(item.id))];
  }

  /// Reloads destinations from the PHP API and refreshes the offline copy.
  /// Returns `false` when the API cannot be reached.
  Future<bool> _syncContent() async {
    try {
      final remote = await _api.fetchDestinations();
      if (remote.isEmpty) return false;
      await OfflineCache.saveCatalogue(remote);
      if (!mounted) return true;
      setState(() {
        _destinations = remote;
        _apiConnected = true;
        _isOnline = true;
      });
      return true;
    } catch (_) {
      if (mounted) setState(() => _apiConnected = false);
      return false;
    }
  }

  Map<String, dynamic>? _normalizeUser(Map user) {
    final role = user['role']?.toString();
    final email = user['email']?.toString();
    if (role == null || email == null) return null;
    return <String, dynamic>{
      'id': user['id'],
      'fullName': (user['fullName'] ?? user['full_name'] ?? 'Traveler').toString(),
      'email': email,
      'role': role,
    };
  }

  bool get _isAdmin => _currentUser?['role'] == 'admin';

  Future<void> _openAuth({bool startWithSignUp = false, bool openAdminAfter = false}) async {
    if (!_apiConnected) {
      _showMessage('The PHP/MySQL API is unavailable. Start Apache and MySQL in XAMPP, then check the API URL.');
      return;
    }
    if (_currentUser != null) {
      if (openAdminAfter) await _openAdmin();
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AuthDialog(api: _api, startWithSignUp: startWithSignUp),
    );
    if (result == null || !mounted) return;

    final authenticated = await _acceptAuthentication(result);
    if (!authenticated || !mounted) return;
    if (openAdminAfter && !_isAdmin) {
      _showMessage('Your account is registered as a traveler. Administrator access is not enabled.');
    } else if (openAdminAfter && _isAdmin) {
      setState(() => _selectedIndex = 5);
    } else {
      _showMessage(startWithSignUp ? 'Your account was created successfully.' : 'You are signed in.');
    }
  }

  Future<bool> _acceptAuthentication(Map<String, dynamic> result) async {
    final token = result['token']?.toString() ?? '';
    final rawUser = result['user'];
    final user = rawUser is Map ? _normalizeUser(rawUser) : null;
    if (token.isEmpty || user == null) {
      _showMessage('The server did not return a valid account session.');
      return false;
    }

    await _storage?.writeString('auth_token', token);
    await _storage?.writeString('auth_user', jsonEncode(user));
    await _storage?.remove('admin_token');
    if (!mounted) return false;
    setState(() {
      _authToken = token;
      _currentUser = user;
      _selectedIndex = 0;
    });
    return true;
  }

  Future<void> _openAdmin() async {
    if (!_apiConnected) {
      _showMessage('Start Apache and MySQL in XAMPP before opening the administrator dashboard.');
      return;
    }
    if (_currentUser == null) {
      await _openAuth(openAdminAfter: true);
      return;
    }
    if (!_isAdmin) {
      _showMessage('Administrator access is required for this page.');
      return;
    }
    setState(() => _selectedIndex = 5);
  }

  Future<void> _signOut() async {
    final token = _authToken;
    if (token != null) {
      try { await _api.logout(token); } catch (_) {}
    }
    await _storage?.remove('auth_token');
    await _storage?.remove('auth_user');
    await _storage?.remove('admin_token');
    if (!mounted) return;
    setState(() {
      _authToken = null;
      _currentUser = null;
      _selectedIndex = 0;
    });
    _showMessage('You have signed out.');
  }

  Future<void> _showProfile() async {
    final user = _currentUser;
    if (user == null) return;
    _recordActivity('profile_viewed', 'Viewed account profile', entityType: 'user', entityId: user['id']?.toString());
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Your account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['fullName']?.toString() ?? 'Traveler', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(user['email']?.toString() ?? ''),
            const SizedBox(height: 8),
            Chip(label: Text(_isAdmin ? 'Administrator' : 'Traveler account')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
          TextButton.icon(onPressed: () { Navigator.pop(dialogContext); _signOut(); }, icon: const Icon(Icons.logout), label: const Text('Sign out')),
        ],
      ),
    );
  }

  void _handleAccountAction(String action) {
    switch (action) {
      case 'login':
        _openAuth();
        break;
      case 'signup':
        _openAuth(startWithSignUp: true);
        break;
      case 'home':
        setState(() => _selectedIndex = 0);
        break;
      case 'profile':
        _showProfile();
        break;
      case 'admin':
        _openAdmin();
        break;
      case 'logout':
        _signOut();
        break;
    }
  }

  void _selectPage(int index) {
    // A second guard in addition to the build-level authentication gate.
    if (_currentUser == null) return;
    if (index == 5) {
      _openAdmin();
      return;
    }
    if (index == 6) {
      _openOffline();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _openOffline() {
    if (_currentUser == null) {
      _openAuth();
      return;
    }
    setState(() => _selectedIndex = 6);
  }

  void _recordActivity(
    String eventType,
    String description, {
    String? entityType,
    String? entityId,
    Map<String, dynamic> metadata = const {},
  }) {
    final token = _authToken;
    if (!_apiConnected || token == null || token.isEmpty) return;
    unawaited(_api.recordActivity(
      token: token,
      eventType: eventType,
      description: description,
      entityType: entityType,
      entityId: entityId,
      metadata: metadata,
    ).catchError((_) {}));
  }

  void _handleSearchChanged(String value) {
    _searchQuery = value;
    final query = value.trim();
    _searchLogTimer?.cancel();
    if (query.length < 2 || query == _lastLoggedSearch) return;
    _searchLogTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || query == _lastLoggedSearch) return;
      _lastLoggedSearch = query;
      _recordActivity(
        'destination_search',
        'Searched destinations for "$query"',
        entityType: 'destination_search',
        metadata: {'query': query},
      );
    });
  }

  Future<void> _persistSet(String key, Set<String> value) async {
    await _storage?.writeSet(key, value);
  }

  void _toggleFavorite(String id) {
    final adding = !_favorites.contains(id);
    setState(() {
      if (adding) {
        _favorites.add(id);
      } else {
        _favorites.remove(id);
      }
    });
    _persistSet('favorites', _favorites);
    final destination = _findDestination(id);
    _recordActivity(
      adding ? 'favorite_added' : 'favorite_removed',
      adding ? 'Added ${destination?.name ?? 'a destination'} to favorites' : 'Removed ${destination?.name ?? 'a destination'} from favorites',
      entityType: 'destination',
      entityId: id,
    );
  }

  void _toggleOffline(String id) {
    final saving = !_savedOffline.contains(id);
    setState(() {
      if (saving) {
        _savedOffline.add(id);
      } else {
        _savedOffline.remove(id);
      }
    });
    _persistSet('offline_destinations', _savedOffline);
    final destination = _findDestination(id);
    if (saving && destination != null) {
      // Cache the photo as well so the saved guide is still useful offline.
      unawaited(ImageCacheService.load(destination.imageUrl));
    }
    _recordActivity(
      saving ? 'offline_destination_saved' : 'offline_destination_removed',
      saving ? 'Saved ${destination?.name ?? 'a destination'} for offline viewing' : 'Removed ${destination?.name ?? 'a destination'} from offline saves',
      entityType: 'destination',
      entityId: id,
    );
    _showMessage(_savedOffline.contains(id)
        ? 'Destination saved to your offline guide.'
        : 'Destination removed from your offline guide.');
  }

  void _markVisited(String id) {
    final isNew = !_visited.contains(id);
    setState(() => _visited.add(id));
    _persistSet('visited_destinations', _visited);
    final destination = _findDestination(id);
    if (isNew) {
      _recordActivity('destination_visited', 'Marked ${destination?.name ?? 'a destination'} as visited', entityType: 'destination', entityId: id);
    }
    _showMessage('Destination added to your visited list.');
  }

  void _toggleItinerary(String id) {
    final saving = !_savedItineraries.contains(id);
    setState(() {
      if (saving) {
        _savedItineraries.add(id);
      } else {
        _savedItineraries.remove(id);
      }
    });
    _persistSet('saved_itineraries', _savedItineraries);
    _recordActivity(
      saving ? 'itinerary_saved' : 'itinerary_removed',
      saving ? 'Saved itinerary $id' : 'Removed saved itinerary $id',
      entityType: 'itinerary',
      entityId: id,
    );
  }

  Destination? _findDestination(String id) {
    for (final destination in _destinations) {
      if (destination.id == id) return destination;
    }
    return null;
  }

  Future<void> _openDestination(Destination destination) async {
    _recordActivity('destination_view', 'Viewed ${destination.name}', entityType: 'destination', entityId: destination.id);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.92,
        child: DestinationDetailSheet(
          destination: destination,
          isFavorite: _favorites.contains(destination.id),
          isSavedOffline: _savedOffline.contains(destination.id),
          onFavorite: () {
            _toggleFavorite(destination.id);
            Navigator.pop(sheetContext);
          },
          onSaveOffline: () {
            _toggleOffline(destination.id);
            Navigator.pop(sheetContext);
          },
          onVisited: () {
            _markVisited(destination.id);
            Navigator.pop(sheetContext);
          },
          onShowMap: () {
            _recordActivity('map_opened', 'Opened map for ${destination.name}', entityType: 'destination', entityId: destination.id);
            Navigator.pop(sheetContext);
            setState(() => _selectedIndex = 2);
          },
        ),
      ),
    );
  }

  Future<void> _saveDestination(Destination destination) async {
    if (_apiConnected) {
      final token = _authToken;
      if (token == null || !_isAdmin) {
        _showMessage('Sign in with an administrator account to manage destinations.');
        return;
      }
      final isUpdate = _destinations.any((item) => item.id == destination.id);
      try {
        await _api.saveDestination(destination, token: token, isUpdate: isUpdate);
        final refreshed = await _api.fetchDestinations();
        if (!mounted) return;
        setState(() => _destinations = refreshed);
        _showMessage('Destination saved to the MySQL database.');
      } catch (error) {
        _showMessage('Could not save destination: $error');
      }
      return;
    }

    setState(() {
      _destinations.removeWhere((item) => item.id == destination.id);
      _destinations.add(destination);
    });
    await _storage?.writeCustomDestinations(
      _destinations.where((item) => item.isCustom).toList(),
    );
    _showMessage('Demo destination saved in this browser only.');
  }

  Future<void> _deleteDestination(Destination destination) async {
    if (_apiConnected) {
      final token = _authToken;
      if (token == null || !_isAdmin) {
        _showMessage('Sign in with an administrator account to manage destinations.');
        return;
      }
      try {
        await _api.deleteDestination(destination.id, token: token);
        final refreshed = await _api.fetchDestinations();
        if (!mounted) return;
        setState(() {
          _destinations = refreshed;
          _favorites.remove(destination.id);
          _savedOffline.remove(destination.id);
          _visited.remove(destination.id);
        });
        await _persistSet('favorites', _favorites);
        await _persistSet('offline_destinations', _savedOffline);
        await _persistSet('visited_destinations', _visited);
        _showMessage('Destination deleted from the MySQL database.');
      } catch (error) {
        _showMessage('Could not delete destination: $error');
      }
      return;
    }

    setState(() {
      _destinations.removeWhere((item) => item.id == destination.id);
      _favorites.remove(destination.id);
      _savedOffline.remove(destination.id);
      _visited.remove(destination.id);
    });
    await _storage?.writeCustomDestinations(
      _destinations.where((item) => item.isCustom).toList(),
    );
    await _persistSet('favorites', _favorites);
    await _persistSet('offline_destinations', _savedOffline);
    await _persistSet('visited_destinations', _visited);
    _showMessage('Demo destination deleted from this browser.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return HomeScreen(
          destinations: _destinations,
          favorites: _favorites,
          onOpenDestination: _openDestination,
          onFavorite: _toggleFavorite,
          onSearch: (value) => setState(() {
            _searchQuery = value;
            _selectedIndex = 1;
          }),
          onExplore: () => setState(() => _selectedIndex = 1),
          onOpenItineraries: () => setState(() => _selectedIndex = 4),
        );
      case 1:
        return ExploreScreen(
          key: const ValueKey('explore-screen'),
          destinations: _destinations,
          favorites: _favorites,
          initialQuery: _searchQuery,
          onOpenDestination: _openDestination,
          onFavorite: _toggleFavorite,
          onQueryChanged: _handleSearchChanged,
        );
      case 2:
        return MapScreen(
          destinations: _destinations,
          onOpenDestination: _openDestination,
          isOnline: _isOnline,
        );
      case 3:
        return SavedScreen(
          destinations: _destinations,
          favorites: _favorites,
          savedOffline: _savedOffline,
          visited: _visited,
          onOpenDestination: _openDestination,
          onFavorite: _toggleFavorite,
          onSaveOffline: _toggleOffline,
          onOpenOfflineCenter: _openOffline,
        );
      case 4:
        return ItineraryScreen(
          destinations: _destinations,
          savedItineraries: _savedItineraries,
          onToggleSaved: _toggleItinerary,
          onOpenDestination: _openDestination,
        );
      case 5:
        return AdminScreen(
          destinations: _destinations,
          onSaveDestination: _saveDestination,
          onDeleteDestination: _deleteDestination,
          apiConnected: _apiConnected,
          onSignOut: _signOut,
          onLoadOverview: () => _api.adminOverview(token: _authToken ?? ''),
          onLoadUsers: ({required int page, required String query}) => _api.adminUsers(token: _authToken ?? '', page: page, query: query),
          onLoadActivities: ({required int page, required String query}) => _api.adminActivities(token: _authToken ?? '', page: page, query: query),
        );
      case 6:
        return OfflineScreen(
          destinations: _destinations,
          savedOffline: _savedOffline,
          isOnline: _isOnline,
          onOpenDestination: _openDestination,
          onRefresh: _syncContent,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  List<int> get _railIndices => [0, 1, 2, 3, 4, if (_isAdmin) 5, 6];

  int get _railSelectedIndex {
    final position = _railIndices.indexOf(_selectedIndex);
    return position < 0 ? 0 : position;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Login is mandatory: never build the public website or navigation until
    // the PHP API has validated an existing session or the user signs in.
    if (_currentUser == null) {
      return Scaffold(
        body: AuthDialog(
          key: const ValueKey('required-auth-screen'),
          api: _api,
          fullScreen: true,
          onAuthenticated: (result) async {
            await _acceptAuthentication(result);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: _selectedIndex >= 5
            ? IconButton(
                tooltip: 'Back to the website',
                onPressed: () => setState(() => _selectedIndex = 0),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        titleSpacing: _selectedIndex >= 5 ? 4 : 18,
        title: Row(children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(color: const Color(0xFF087E8B), borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.travel_explore, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('BOHOL EXPLORER', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
            Text('Tourist information & travel guide', style: TextStyle(fontSize: 9, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
          ]),
        ]),
        actions: [
          IconButton(
            tooltip: _isOnline ? 'Offline guide center' : 'Offline mode: open cached guide',
            onPressed: _openOffline,
            icon: Icon(
              _isOnline ? Icons.cloud_done_outlined : Icons.cloud_off,
              color: _isOnline ? null : const Color(0xFFB66A12),
            ),
          ),
          if (_currentUser == null && MediaQuery.sizeOf(context).width > 460) ...[
            TextButton(onPressed: () => _openAuth(), child: const Text('Sign in')),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: FilledButton.tonalIcon(
                onPressed: () => _openAuth(startWithSignUp: true),
                icon: const Icon(Icons.person_add_alt_1, size: 17),
                label: const Text('Sign up'),
              ),
            ),
          ] else if (_currentUser == null) ...[
            PopupMenuButton<String>(
              tooltip: 'Account',
              onSelected: _handleAccountAction,
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'login', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.login), title: Text('Sign in'))),
                PopupMenuItem(value: 'signup', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.person_add_alt_1), title: Text('Sign up'))),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.account_circle_outlined, size: 27),
              ),
            ),
          ] else ...[
            PopupMenuButton<String>(
              tooltip: 'Account options',
              onSelected: _handleAccountAction,
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'profile',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.account_circle_outlined),
                    title: Text(_currentUser?['fullName']?.toString() ?? 'My account'),
                    subtitle: Text(_currentUser?['email']?.toString() ?? ''),
                  ),
                ),
                if (_isAdmin) const PopupMenuItem(value: 'admin', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.admin_panel_settings_outlined), title: Text('Admin dashboard'))),
                if (_selectedIndex == 5) const PopupMenuItem(value: 'home', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.home_outlined), title: Text('Back to website'))),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'logout', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.logout), title: Text('Sign out'))),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const CircleAvatar(radius: 15, child: Icon(Icons.person, size: 17)),
                  const SizedBox(width: 7),
                  if (MediaQuery.sizeOf(context).width > 650)
                    Text(_currentUser?['fullName']?.toString() ?? 'Account', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Icon(Icons.arrow_drop_down),
                ]),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Column(children: [
        if (!_isOnline)
          OfflineBanner(
            onOpenOffline: _openOffline,
            onRetry: () async {
              final refreshed = await _syncContent();
              _showMessage(refreshed
                  ? 'Tourism information refreshed.'
                  : 'Still offline. Cached guides remain available.');
            },
          ),
        Expanded(
          child: !_isReady
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  if (!isWide) return _buildPage();
                  return Row(children: [
                    NavigationRail(
                      selectedIndex: _railSelectedIndex,
                      extended: constraints.maxWidth >= 1180,
                      onDestinationSelected: (position) => _selectPage(_railIndices[position]),
                      labelType: constraints.maxWidth >= 1180 ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                      destinations: [
                        const NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
                        const NavigationRailDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: Text('Explore')),
                        const NavigationRailDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: Text('Map')),
                        const NavigationRailDestination(icon: Icon(Icons.bookmarks_outlined), selectedIcon: Icon(Icons.bookmarks), label: Text('Saved')),
                        const NavigationRailDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: Text('Itineraries')),
                        if (_isAdmin) const NavigationRailDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings), label: Text('Admin')),
                        const NavigationRailDestination(icon: Icon(Icons.cloud_download_outlined), selectedIcon: Icon(Icons.cloud_download), label: Text('Offline')),
                      ],
                    ),
                    const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE8EEEE)),
                    Expanded(child: _buildPage()),
                  ]);
                }),
        ),
      ]),
      bottomNavigationBar: !_isReady
          ? null
          : LayoutBuilder(builder: (context, constraints) {
              if (MediaQuery.sizeOf(context).width >= 900) return const SizedBox.shrink();
              return NavigationBar(
                selectedIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
                onDestinationSelected: _selectPage,
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                  NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explore'),
                  NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
                  NavigationDestination(icon: Icon(Icons.bookmarks_outlined), selectedIcon: Icon(Icons.bookmarks), label: 'Saved'),
                  NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Plans'),
                ],
              );
            }),
    );
  }
}
