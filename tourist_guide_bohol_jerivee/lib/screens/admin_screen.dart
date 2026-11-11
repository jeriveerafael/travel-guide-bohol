import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/destination.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({
    super.key,
    required this.destinations,
    required this.onSaveDestination,
    required this.onDeleteDestination,
    required this.apiConnected,
    required this.onSignOut,
    required this.onLoadOverview,
    required this.onLoadUsers,
    required this.onLoadActivities,
  });

  final List<Destination> destinations;
  final ValueChanged<Destination> onSaveDestination;
  final ValueChanged<Destination> onDeleteDestination;
  final bool apiConnected;
  final VoidCallback onSignOut;
  final Future<Map<String, dynamic>> Function() onLoadOverview;
  final Future<Map<String, dynamic>> Function({required int page, required String query}) onLoadUsers;
  final Future<Map<String, dynamic>> Function({required int page, required String query}) onLoadActivities;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _userSearch = TextEditingController();
  final TextEditingController _activitySearch = TextEditingController();

  Map<String, dynamic> _overview = {};
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _activities = [];
  Map<String, dynamic> _usersPagination = {'page': 1, 'pages': 1, 'total': 0};
  Map<String, dynamic> _activitiesPagination = {'page': 1, 'pages': 1, 'total': 0};
  bool _loading = true;
  String? _loadError;
  int _section = 0;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  @override
  void dispose() {
    _userSearch.dispose();
    _activitySearch.dispose();
    super.dispose();
  }

  int _asInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

  List<Map<String, dynamic>> _mapRows(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Map<String, dynamic> _mapObject(dynamic value) => value is Map
      ? Map<String, dynamic>.from(value)
      : <String, dynamic>{};

  Future<void> _refreshAll() async {
    if (!widget.apiConnected) {
      if (mounted) setState(() {
        _loading = false;
        _loadError = 'Connect the PHP/MySQL API before loading administrator records.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final overviewResponse = await widget.onLoadOverview();
      final usersResponse = await widget.onLoadUsers(page: 1, query: _userSearch.text.trim());
      final activitiesResponse = await widget.onLoadActivities(page: 1, query: _activitySearch.text.trim());
      if (!mounted) return;
      setState(() {
        _overview = _mapObject(overviewResponse['data']);
        _users = _mapRows(usersResponse['data']);
        _activities = _mapRows(activitiesResponse['data']);
        _usersPagination = _mapObject(usersResponse['pagination']);
        _activitiesPagination = _mapObject(activitiesResponse['pagination']);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _loadUsers({int page = 1}) async {
    setState(() => _loading = true);
    try {
      final response = await widget.onLoadUsers(page: page, query: _userSearch.text.trim());
      if (!mounted) return;
      setState(() {
        _users = _mapRows(response['data']);
        _usersPagination = _mapObject(response['pagination']);
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _loadActivities({int page = 1}) async {
    setState(() => _loading = true);
    try {
      final response = await widget.onLoadActivities(page: page, query: _activitySearch.text.trim());
      if (!mounted) return;
      setState(() {
        _activities = _mapRows(response['data']);
        _activitiesPagination = _mapObject(response['pagination']);
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _showDestinationForm(BuildContext context, {Destination? existing}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: existing?.name ?? '');
    final municipality = TextEditingController(text: existing?.municipality ?? '');
    final description = TextEditingController(text: existing?.description ?? '');
    final imageUrl = TextEditingController(text: existing?.imageUrl ?? '');
    final latitude = TextEditingController(text: existing?.latitude.toString() ?? '9.78');
    final longitude = TextEditingController(text: existing?.longitude.toString() ?? '124.08');
    final fee = TextEditingController(text: existing?.entranceFee ?? 'Verify current rates locally');
    final hours = TextEditingController(text: existing?.operatingHours ?? 'Check current visitor schedule');
    final tips = TextEditingController(text: existing?.tips ?? '');
    final contact = TextEditingController(text: existing?.contactInfo ?? '');
    final activities = TextEditingController(text: existing?.activities ?? '');
    final stays = TextEditingController(text: existing?.accommodations ?? '');
    var category = existing?.category ?? 'Nature & Adventure';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add destination' : 'Edit destination'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _FormField(controller: name, label: 'Destination name'),
                  _FormField(controller: municipality, label: 'Municipality / city'),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories.where((item) => item != 'All').map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                    onChanged: (value) => setDialogState(() => category = value ?? category),
                  ),
                  const SizedBox(height: 12),
                  _FormField(controller: description, label: 'Description', maxLines: 3),
                  _FormField(controller: imageUrl, label: 'Image URL (optional)', requiredField: false),
                  Row(children: [
                    Expanded(child: _FormField(controller: latitude, label: 'Latitude', keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _FormField(controller: longitude, label: 'Longitude', keyboardType: TextInputType.number)),
                  ]),
                  _FormField(controller: fee, label: 'Entrance fee information'),
                  _FormField(controller: hours, label: 'Operating hours'),
                  _FormField(controller: tips, label: 'Travel tips', maxLines: 2),
                  _FormField(controller: contact, label: 'Contact information', maxLines: 2),
                  _FormField(controller: activities, label: 'Activities / things to do', maxLines: 2),
                  _FormField(controller: stays, label: 'Accommodations / where to stay', maxLines: 2),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final lat = double.tryParse(latitude.text.trim());
                final lng = double.tryParse(longitude.text.trim());
                if (!formKey.currentState!.validate() || lat == null || lng == null || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid coordinates between latitude -90 to 90 and longitude -180 to 180.')));
                  return;
                }
                final result = Destination(
                  id: existing?.id ?? 'custom-${DateTime.now().microsecondsSinceEpoch}',
                  name: name.text.trim(),
                  municipality: municipality.text.trim(),
                  category: category,
                  description: description.text.trim(),
                  imageUrl: imageUrl.text.trim(),
                  latitude: lat,
                  longitude: lng,
                  entranceFee: fee.text.trim().isEmpty ? 'Check with the destination' : fee.text.trim(),
                  operatingHours: hours.text.trim().isEmpty ? 'Check before visiting' : hours.text.trim(),
                  tips: tips.text.trim(),
                  contactInfo: contact.text.trim(),
                  activities: activities.text.trim(),
                  accommodations: stays.text.trim(),
                  isCustom: true,
                );
                widget.onSaveDestination(result);
                Navigator.pop(dialogContext);
              },
              child: const Text('Save destination'),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    municipality.dispose();
    description.dispose();
    imageUrl.dispose();
    latitude.dispose();
    longitude.dispose();
    fee.dispose();
    hours.dispose();
    tips.dispose();
    contact.dispose();
    activities.dispose();
    stays.dispose();
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return 'Not yet';
    final parsed = DateTime.tryParse(value.toString().replaceFirst(' ', 'T'));
    if (parsed == null) return value.toString();
    final local = parsed.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = (local.hour % 12 == 0 ? 12 : local.hour % 12).toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.year}-$month-$day $hour:$minute $period';
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case 'account_registered': return Icons.person_add_alt_1;
      case 'login': return Icons.login;
      case 'logout': return Icons.logout;
      case 'destination_search': return Icons.search;
      case 'destination_view': return Icons.visibility_outlined;
      case 'favorite_added': return Icons.favorite;
      case 'favorite_removed': return Icons.favorite_border;
      case 'offline_destination_saved': return Icons.download_done;
      case 'offline_destination_removed': return Icons.download_for_offline_outlined;
      case 'destination_visited': return Icons.place;
      case 'itinerary_saved': return Icons.bookmark_added;
      case 'itinerary_removed': return Icons.bookmark_remove_outlined;
      case 'map_opened': return Icons.map_outlined;
      default: return Icons.history;
    }
  }

  String _eventLabel(String type) {
    return type.split('_').map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
  }

  Widget _metric(String label, dynamic value, IconData icon, Color tint) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(children: [
          CircleAvatar(backgroundColor: tint.withValues(alpha: 0.12), child: Icon(icon, color: tint)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${value ?? 0}', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600)),
          ])),
        ]),
      ),
    );
  }

  Widget _sectionButton(String title, int index, IconData icon) {
    final selected = _section == index;
    return ChoiceChip(
      avatar: Icon(icon, size: 17, color: selected ? Colors.white : const Color(0xFF087E8B)),
      label: Text(title),
      selected: selected,
      selectedColor: const Color(0xFF087E8B),
      labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xFF23434A), fontWeight: FontWeight.w700),
      onSelected: (_) => setState(() => _section = index),
    );
  }

  Widget _buildUsers() {
    final total = _asInt(_usersPagination['total']);
    final page = _asInt(_usersPagination['page']).clamp(1, 999999).toInt();
    final pages = _asInt(_usersPagination['pages']).clamp(1, 999999).toInt();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Registered users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Text('$total registered account(s). Passwords and authentication tokens are never displayed.', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12)),
      const SizedBox(height: 12),
      TextField(
        controller: _userSearch,
        onSubmitted: (_) => _loadUsers(page: 1),
        decoration: InputDecoration(
          hintText: 'Search name, email, or role',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () => _loadUsers(page: 1)),
        ),
      ),
      const SizedBox(height: 12),
      if (_users.isEmpty)
        const _EmptyAdminState(icon: Icons.people_outline, text: 'No users found.')
      else
        ..._users.map((user) {
          final role = user['role']?.toString() ?? 'user';
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE7F3F0),
                child: Text((user['fullName']?.toString().isNotEmpty ?? false) ? user['fullName'].toString()[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFF087E8B), fontWeight: FontWeight.w800)),
              ),
              title: Text('${user['fullName']?.toString() ?? 'Unknown user'}  (#${user['id'] ?? '-'})', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${user['email'] ?? ''}\nJoined: ${_formatDate(user['createdAt'])}\nLast login: ${_formatDate(user['lastLoginAt'])}\nLast activity: ${_formatDate(user['lastActivityAt'])}\nActivities: ${user['activityCount'] ?? 0}', style: const TextStyle(height: 1.45, fontSize: 12)),
              ),
              isThreeLine: true,
              trailing: Chip(
                label: Text(role.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                backgroundColor: role == 'admin' ? const Color(0xFFFFF0D4) : const Color(0xFFEAF2FA),
              ),
            ),
          );
        }),
      _PaginationBar(page: page, pages: pages, onPrevious: page > 1 ? () => _loadUsers(page: page - 1) : null, onNext: page < pages ? () => _loadUsers(page: page + 1) : null),
    ]);
  }

  Widget _buildActivities() {
    final total = _asInt(_activitiesPagination['total']);
    final page = _asInt(_activitiesPagination['page']).clamp(1, 999999).toInt();
    final pages = _asInt(_activitiesPagination['pages']).clamp(1, 999999).toInt();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('User activity history', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Text('$total recorded activity event(s), newest first.', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12)),
      const SizedBox(height: 12),
      TextField(
        controller: _activitySearch,
        onSubmitted: (_) => _loadActivities(page: 1),
        decoration: InputDecoration(
          hintText: 'Search user, email, activity, or description',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () => _loadActivities(page: 1)),
        ),
      ),
      const SizedBox(height: 12),
      if (_activities.isEmpty)
        const _EmptyAdminState(icon: Icons.history, text: 'No activity has been recorded yet. User actions will appear here after the new SQL table is installed.')
      else
        ..._activities.map((activity) {
          final type = activity['eventType']?.toString() ?? '';
          return Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: const Color(0xFFE7F3F0), child: Icon(_eventIcon(type), color: const Color(0xFF087E8B))),
              title: Text(activity['fullName']?.toString() ?? 'Unknown user', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${activity['email'] ?? ''}\n${activity['description'] ?? _eventLabel(type)}\n${_formatDate(activity['createdAt'])}', style: const TextStyle(height: 1.45, fontSize: 12)),
              ),
              isThreeLine: true,
              trailing: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(_eventLabel(type), textAlign: TextAlign.end, style: const TextStyle(fontSize: 10, color: Color(0xFF087E8B), fontWeight: FontWeight.w800)),
              ),
            ),
          );
        }),
      _PaginationBar(page: page, pages: pages, onPrevious: page > 1 ? () => _loadActivities(page: page - 1) : null, onNext: page < pages ? () => _loadActivities(page: page + 1) : null),
    ]);
  }

  Widget _buildDestinations(BuildContext context) {
    final customDestinations = widget.destinations.where((item) => item.isCustom).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Destination catalogue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
        FilledButton.icon(onPressed: () => _showDestinationForm(context), icon: const Icon(Icons.add), label: const Text('Add destination')),
      ]),
      const SizedBox(height: 10),
      ...widget.destinations.map((destination) => Card(
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Color(0xFFE7F3F0), child: Icon(Icons.place, color: Color(0xFF087E8B))),
          title: Text(destination.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          subtitle: Text('${destination.municipality} · ${destination.category}'),
          trailing: Wrap(children: [
            if (!destination.isCustom)
              const Padding(padding: EdgeInsets.only(right: 4), child: Center(child: Text('Sample', style: TextStyle(fontSize: 10, color: Colors.blueGrey)))),
            IconButton(tooltip: 'Edit', onPressed: () => _showDestinationForm(context, existing: destination), icon: const Icon(Icons.edit_outlined)),
            IconButton(tooltip: 'Delete', onPressed: () => widget.onDeleteDestination(destination), icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
          ]),
        ),
      )),
      if (customDestinations.isEmpty) const SizedBox.shrink(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
      children: [
        Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Admin dashboard', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
            SizedBox(height: 5),
            Text('Monitor registered users and their activity, and manage tourism content.'),
          ])),
          Wrap(spacing: 8, children: [
            IconButton.filledTonal(tooltip: 'Refresh dashboard', onPressed: _refreshAll, icon: const Icon(Icons.refresh)),
            OutlinedButton.icon(onPressed: widget.onSignOut, icon: const Icon(Icons.logout), label: const Text('Sign out')),
          ]),
        ]),
        const SizedBox(height: 17),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFFFF5DE), borderRadius: BorderRadius.circular(15)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(widget.apiConnected ? Icons.verified_user_outlined : Icons.warning_amber_rounded, color: const Color(0xFF9A6B17)),
            const SizedBox(width: 9),
            Expanded(child: Text(
              widget.apiConnected
                  ? 'PHP/MySQL API connected. User information and activity history are loaded from MySQL. Passwords and authentication tokens are never displayed.'
                  : 'PHP/MySQL API is not connected. Start Apache and MySQL in XAMPP.',
              style: const TextStyle(color: Color(0xFF684B18), fontSize: 12, height: 1.5),
            )),
          ]),
        ),
        const SizedBox(height: 16),
        if (_loading) const LinearProgressIndicator(),
        if (_loadError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: const Color(0xFFFFEEEE), borderRadius: BorderRadius.circular(12)),
            child: Text('Could not load administrator data. ${_loadError!}\nIf this is an existing database, import backend/sql/admin_activity_upgrade.sql in phpMyAdmin.', style: const TextStyle(color: Color(0xFF8B2525), fontSize: 12, height: 1.5)),
          ),
        ],
        LayoutBuilder(builder: (context, constraints) {
          final count = constraints.maxWidth > 850 ? 3 : 2;
          return GridView.count(
            crossAxisCount: count,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: count == 3 ? 2.25 : 1.9,
            children: [
              _metric('Registered users', _overview['totalUsers'], Icons.people_alt_outlined, const Color(0xFF087E8B)),
              _metric('Activities recorded', _overview['totalActivities'], Icons.history, const Color(0xFF7A5AB5)),
              _metric('Destinations', _overview['totalDestinations'] ?? widget.destinations.length, Icons.place_outlined, const Color(0xFF3E8754)),
              _metric('Administrators', _overview['adminUsers'], Icons.admin_panel_settings_outlined, const Color(0xFFB27B27)),
              _metric('Active users (30 days)', _overview['activeUsers30Days'], Icons.person_search_outlined, const Color(0xFF3976B8)),
              _metric('Activities today', _overview['todayActivities'], Icons.today_outlined, const Color(0xFFBD6A43)),
            ],
          );
        }),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _sectionButton('Overview', 0, Icons.dashboard_outlined),
          _sectionButton('All users', 1, Icons.people_outline),
          _sectionButton('User activities', 2, Icons.history),
          _sectionButton('Destinations', 3, Icons.place_outlined),
        ]),
        const SizedBox(height: 16),
        if (_section == 0) ...[
          const Text('Recent user activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (_activities.isEmpty)
            const _EmptyAdminState(icon: Icons.history, text: 'No user activities yet. After users sign in and use the website, their actions will be listed here.')
          else
            ..._activities.take(8).map((activity) => Card(
              child: ListTile(
                dense: true,
                leading: Icon(_eventIcon(activity['eventType']?.toString() ?? ''), color: const Color(0xFF087E8B)),
                title: Text('${activity['fullName'] ?? 'Unknown user'} — ${activity['description'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: Text('${activity['email'] ?? ''} · ${_formatDate(activity['createdAt'])}', style: const TextStyle(fontSize: 11)),
              ),
            )),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => setState(() => _section = 2), child: const Text('View all activities'))),
          const SizedBox(height: 10),
          const Text('Recently registered users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ..._users.take(5).map((user) => Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline, color: Color(0xFF087E8B)),
              title: Text(user['fullName']?.toString() ?? 'Unknown user'),
              subtitle: Text('${user['email'] ?? ''} · ${user['role'] ?? 'user'}'),
              trailing: Text('Activities: ${user['activityCount'] ?? 0}', style: const TextStyle(fontSize: 11)),
            ),
          )),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => setState(() => _section = 1), child: const Text('View all users'))),
        ] else if (_section == 1) ...[
          _buildUsers(),
        ] else if (_section == 2) ...[
          _buildActivities(),
        ] else ...[
          _buildDestinations(context),
        ],
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.page, required this.pages, required this.onPrevious, required this.onNext});
  final int page;
  final int pages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          OutlinedButton.icon(onPressed: onPrevious, icon: const Icon(Icons.chevron_left), label: const Text('Previous')),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('Page $page of $pages', style: const TextStyle(fontWeight: FontWeight.w700))),
          OutlinedButton.icon(onPressed: onNext, icon: const Icon(Icons.chevron_right), label: const Text('Next')),
        ]),
      );
}

class _EmptyAdminState extends StatelessWidget {
  const _EmptyAdminState({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFFF4F8F7), borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Icon(icon, size: 34, color: Colors.blueGrey),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
        ]),
      );
}

class _FormField extends StatelessWidget {
  const _FormField({required this.controller, required this.label, this.maxLines = 1, this.keyboardType, this.requiredField = true});
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool requiredField;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(labelText: label),
          validator: (value) => requiredField && (value == null || value.trim().isEmpty) ? 'This field is required' : null,
        ),
      );
}
