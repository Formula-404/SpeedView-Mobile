import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:speedview/user/constants.dart';

enum _ComparisonModule { team, driver, circuit }

class ComparisonCreateScreen extends StatefulWidget {
  const ComparisonCreateScreen({
    Key? key,
    this.apiBaseUrl = 'https://helven-marcia-speedview.pbp.cs.ui.ac.id',
  }) : super(key: key);

  final String apiBaseUrl;

  @override
  State<ComparisonCreateScreen> createState() =>
      _ComparisonCreateScreenState();
}

class _ComparisonCreateScreenState extends State<ComparisonCreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isPublic = false;
  _ComparisonModule _module = _ComparisonModule.team;

  bool _loadingOptions = false;
  String? _loadError;

  final List<_CreateOption> _options = [];
  List<_CreateOption> _filtered = [];
  final Set<String> _selectedIds = <String>{};

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _searchController.addListener(_applySearch);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String get _pickerTitle {
    switch (_module) {
      case _ComparisonModule.team:
        return 'Select Teams';
      case _ComparisonModule.driver:
        return 'Select Drivers';
      case _ComparisonModule.circuit:
        return 'Select Circuits';
    }
  }

  String get _moduleApiValue {
    switch (_module) {
      case _ComparisonModule.team:
        return 'team';
      case _ComparisonModule.driver:
        return 'driver';
      case _ComparisonModule.circuit:
        return 'circuit';
    }
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loadingOptions = true;
      _loadError = null;
      _options.clear();
      _filtered = [];
      _selectedIds.clear();
    });

    String path;
    switch (_module) {
      case _ComparisonModule.team:
        path = '/team/api/';
        break;
      case _ComparisonModule.driver:
        path = '/driver/api/';
        break;
      case _ComparisonModule.circuit:
        path = '/circuit/api/';
        break;
    }

    try {
      final uri = Uri.parse('${widget.apiBaseUrl}$path');
      final res = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );

      if (res.statusCode != 200) {
        throw Exception('Failed with status ${res.statusCode}');
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['ok'] != true) {
        throw Exception(body['error'] ?? 'Failed to load items');
      }

      final data = body['data'] as List<dynamic>? ?? [];

      for (final raw in data) {
        final m = raw as Map<String, dynamic>;
        switch (_module) {
          case _ComparisonModule.team:
            _options.add(
              _CreateOption(
                id: (m['team_name'] ?? '').toString(),
                name: (m['team_name'] ?? '').toString(),
                sub: (m['short_code'] ?? '').toString(),
                logoUrl: (m['team_logo_url'] ?? '').toString(),
              ),
            );
            break;
          case _ComparisonModule.driver:
            final driverNumber = (m['driver_number'] ?? '').toString();
            final fullName = (m['full_name'] ?? '').toString();
            final broadcastName = (m['broadcast_name'] ?? '').toString();
            final name = fullName.isNotEmpty
                ? fullName
                : (broadcastName.isNotEmpty
                    ? broadcastName
                    : '#$driverNumber');

            _options.add(
              _CreateOption(
                id: driverNumber,
                name: name,
                sub: (m['country_code'] ?? '').toString(),
                logoUrl: (m['headshot_url'] ?? '').toString(),
              ),
            );
            break;
          case _ComparisonModule.circuit:
            final id = (m['id'] ?? '').toString();
            final location = (m['location'] ?? '').toString();
            final country = (m['country'] ?? '').toString();
            final sub = [
              if (location.isNotEmpty) location,
              if (country.isNotEmpty) country,
            ].join(' • ');

            _options.add(
              _CreateOption(
                id: id,
                name: (m['name'] ?? '').toString(),
                sub: sub,
                logoUrl: (m['map_image_url'] ?? '').toString(),
              ),
            );
            break;
        }
      }

      _filtered = List<_CreateOption>.from(_options);
      _applySearch();
    } catch (e) {
      _loadError = e.toString();
    } finally {
      setState(() {
        _loadingOptions = false;
      });
    }
  }

  void _applySearch() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<_CreateOption>.from(_options);
      } else {
        _filtered = _options
            .where((o) =>
                o.name.toLowerCase().contains(q) ||
                o.sub.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length >= 4) return;
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _submitCreate() async {
    if (_selectedIds.length < 2 || _selectedIds.length > 4) {
      await _showErrorDialog(
        title: 'Invalid Selection',
        message: 'You must pick between 2 and 4 items to create a comparison.',
      );
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      await _showErrorDialog(
        title: 'Missing Title',
        message: 'Please enter a title for your comparison.',
      );
      return;
    }

    if (_submitting) return;
    setState(() {
      _submitting = true;
    });

    final request = context.read<CookieRequest>();
    final url = buildSpeedViewUrl('/comparison/api/mobile/create/');

    final payload = {
      'title': title,
      'module': _moduleApiValue,
      'items': _selectedIds.toList(),
      'is_public': _isPublic,
    };

    try {
      final response = await request.postJson(url, jsonEncode(payload));

      if (response['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comparison created.'),
            backgroundColor: Colors.green,
          ),
        );
        // Return to caller so list screen can refresh if desired.
        Navigator.of(context).pop(true);
      } else {
        final msg =
            (response['error'] ?? 'Failed to create comparison').toString();
        await _showErrorDialog(
          title: 'Create Failed',
          message: msg,
        );
      }
    } catch (e) {
      await _showErrorDialog(
        title: 'Create Failed',
        message: 'Error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _showErrorDialog({
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B0F14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Color(0xE6E6EDF3),
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFFE5E7EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0D1117);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Create Comparison',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose a module, set a title, and select 2–4 items to compare.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0x99E6EDF3),
                ),
              ),
              const SizedBox(height: 20),

              // Title card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'Title',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '*',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      maxLength: 100,
                      style: const TextStyle(
                        color: Color(0xFFE6EDF3),
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Enter comparison title...',
                        hintStyle: const TextStyle(
                          color: Color(0x66E6EDF3),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0D1117),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0x1AE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0x1AE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFEF4444),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Visibility card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Checkbox(
                      value: _isPublic,
                      activeColor: const Color(0xFFEF4444),
                      onChanged: (v) {
                        setState(() {
                          _isPublic = v ?? false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Make this comparison public',
                        style: TextStyle(
                          color: Color(0xE6E6EDF3),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Module selector
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Module',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ModuleButton(
                            label: 'Team',
                            selected: _module == _ComparisonModule.team,
                            onTap: () {
                              if (_module == _ComparisonModule.team) return;
                              setState(() {
                                _module = _ComparisonModule.team;
                              });
                              _loadOptions();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ModuleButton(
                            label: 'Driver',
                            selected: _module == _ComparisonModule.driver,
                            onTap: () {
                              if (_module == _ComparisonModule.driver) return;
                              setState(() {
                                _module = _ComparisonModule.driver;
                              });
                              _loadOptions();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ModuleButton(
                            label: 'Circuit',
                            selected: _module == _ComparisonModule.circuit,
                            onTap: () {
                              if (_module == _ComparisonModule.circuit) return;
                              setState(() {
                                _module = _ComparisonModule.circuit;
                              });
                              _loadOptions();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Picker card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Picker header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _pickerTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          'Pick 2–4',
                          style: TextStyle(
                            color: Color(0x99E6EDF3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search + count
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              color: Color(0xFFE6EDF3),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search…',
                              hintStyle: const TextStyle(
                                color: Color(0x66E6EDF3),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF0D1117),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 18,
                                color: Color(0x99E6EDF3),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0x1AE5E7EB),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0x1AE5E7EB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFEF4444),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_selectedIds.length} selected',
                          style: const TextStyle(
                            color: Color(0x99E6EDF3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // List / states
                    if (_loadingOptions)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_loadError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Failed to load items.\n$_loadError',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFF9CA3),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    else if (_filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No items found.',
                            style: TextStyle(
                              color: Color(0xB3E6EDF3),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 360,
                        child: ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final opt = _filtered[index];
                            final selected =
                                _selectedIds.contains(opt.id);
                            final maxedOut =
                                !selected && _selectedIds.length >= 4;

                            return Opacity(
                              opacity: maxedOut ? 0.5 : 1.0,
                              child: IgnorePointer(
                                ignoring: maxedOut,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _toggleSelect(opt.id),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: selected
                                            ? const Color(0xFFEF4444)
                                                .withOpacity(0.8)
                                            : Colors.white.withOpacity(0.12),
                                        width: selected ? 1.4 : 1.0,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: opt.logoUrl.isNotEmpty
                                              ? Image.network(
                                                  opt.logoUrl,
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.contain,
                                                  errorBuilder:
                                                      (_, __, ___) =>
                                                          _logoFallback(),
                                                )
                                              : _logoFallback(),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                opt.name,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Color(0xFFE6EDF3),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                opt.sub,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Color(0x99E6EDF3),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (selected)
                                          const Icon(
                                            Icons.check_circle,
                                            size: 18,
                                            color: Color(0xFFEF4444),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Footer buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            foregroundColor: const Color(0xE6E6EDF3),
                            backgroundColor:
                                Colors.white.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: _submitting ? null : _submitCreate,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFFEF4444),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Create',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
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

  static Widget _logoFallback() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 20,
        color: Colors.white70,
      ),
    );
  }
}

class _ModuleButton extends StatelessWidget {
  const _ModuleButton({
    Key? key,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final baseBorderRadius = BorderRadius.circular(999);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: baseBorderRadius,
        color: selected
            ? const Color(0xFFEF4444)
            : Colors.white.withOpacity(0.04),
        border: Border.all(
          color: selected
              ? const Color(0xFFEF4444)
              : Colors.white.withOpacity(0.12),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: baseBorderRadius,
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : const Color(0xCCE6EDF3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateOption {
  final String id;
  final String name;
  final String sub;
  final String logoUrl;

  _CreateOption({
    required this.id,
    required this.name,
    required this.sub,
    required this.logoUrl,
  });
}
