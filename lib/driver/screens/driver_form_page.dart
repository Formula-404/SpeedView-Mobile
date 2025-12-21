import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../models/driver.dart';

class DriverFormPage extends StatefulWidget {
  final Driver? existing;

  const DriverFormPage({super.key, this.existing});

  bool get isEdit => existing != null;

  @override
  State<DriverFormPage> createState() => _DriverFormPageState();
}

class _DriverFormPageState extends State<DriverFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _numberController;
  late TextEditingController _fullNameController;
  late TextEditingController _broadcastController;
  late TextEditingController _countryController;
  late TextEditingController _headshotController;

  bool _isSaving = false;

  // ===== Teams state =====
  bool _isTeamsLoading = true;
  String? _teamsError;
  List<String> _teamOptions = <String>[];
  Set<String> _selectedTeams = <String>{};

  String? _teamEndpointUsed; // buat debug ringan

  static const _baseUrl = 'https://helven-marcia-speedview.pbp.cs.ui.ac.id';

  // Coba beberapa kandidat endpoint (karena root include Django bisa /team/ atau /teams/)
  static const List<String> _teamEndpointCandidates = <String>[
    '$_baseUrl/team/api/mobile/',
    '$_baseUrl/team/api/mobile',
    '$_baseUrl/team/api/',
    '$_baseUrl/team/api',
    '$_baseUrl/teams/api/mobile/',
    '$_baseUrl/teams/api/mobile',
    '$_baseUrl/teams/api/',
    '$_baseUrl/teams/api',
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.existing;

    _numberController = TextEditingController(
      text: d != null ? d.driverNumber.toString() : '',
    );
    _fullNameController = TextEditingController(text: d?.fullName ?? '');
    _broadcastController = TextEditingController(text: d?.broadcastName ?? '');
    _countryController = TextEditingController(text: d?.countryCode ?? '');
    _headshotController = TextEditingController(text: d?.headshotUrl ?? '');

    _selectedTeams = Set<String>.from(d?.teams ?? const <String>[]);

    Future.microtask(_loadTeams);
  }

  @override
  void dispose() {
    _numberController.dispose();
    _fullNameController.dispose();
    _broadcastController.dispose();
    _countryController.dispose();
    _headshotController.dispose();
    super.dispose();
  }

  // ===================== TEAMS: robust fetch + robust parse =====================

  List<dynamic>? _extractListFromResponse(dynamic response) {
    // Terima:
    // - List langsung
    // - Map { data: [...] }
    // - Map { data: { data: [...] } }
    // - Map { results/teams: [...] }
    if (response is List) return response;

    if (response is Map) {
      dynamic data = response['data'] ?? response['results'] ?? response['teams'];

      if (data is List) return data;

      // kalau terbungkus lagi
      if (data is Map) {
        final inner = data['data'] ?? data['results'] ?? data['teams'];
        if (inner is List) return inner;
      }
    }
    return null;
  }

  List<String> _normalizeTeamNames(List<dynamic> rawList) {
    final names = <String>[];

    for (final item in rawList) {
      if (item is Map) {
        final tn = item['team_name'] ?? item['name'] ?? item['pk'] ?? item['id'];
        if (tn != null) names.add(tn.toString());
      } else if (item != null) {
        names.add(item.toString());
      }
    }

    final cleaned = names
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return cleaned;
  }

  Future<void> _loadTeams() async {
    if (!mounted) return;

    setState(() {
      _isTeamsLoading = true;
      _teamsError = null;
      _teamOptions = <String>[];
      _teamEndpointUsed = null;
    });

    final request = context.read<CookieRequest>();

    String? lastHint;

    for (final url in _teamEndpointCandidates) {
      try {
        final response = await request.get(url);

        final list = _extractListFromResponse(response);
        if (list == null) {
          // simpan hint untuk debugging
          if (response is Map) {
            lastHint = 'Got Map keys: ${response.keys.toList()}';
          } else {
            lastHint = 'Got response type: ${response.runtimeType}';
          }
          continue;
        }

        final cleaned = _normalizeTeamNames(list);
        if (!mounted) return;

        setState(() {
          _teamOptions = cleaned;
          _isTeamsLoading = false;
          _teamsError = cleaned.isEmpty ? 'No team data available.' : null;
          _teamEndpointUsed = url;
        });

        return; // sukses, stop loop
      } catch (e) {
        lastHint = 'Error from $url: $e';
        // coba kandidat berikutnya
      }
    }

    if (!mounted) return;
    setState(() {
      _isTeamsLoading = false;
      _teamsError = 'Failed to load teams. ${lastHint ?? ''}'.trim();
    });
  }

  Future<void> _openTeamPicker() async {
    if (_isTeamsLoading) return;

    if (_teamOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_teamsError ?? 'No team data available.'),
          backgroundColor: Colors.red[800],
        ),
      );
      return;
    }

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        final temp = Set<String>.from(_selectedTeams);
        String query = '';

        return StatefulBuilder(
          builder: (context, setLocal) {
            final filtered = _teamOptions
                .where((t) => t.toLowerCase().contains(query.toLowerCase()))
                .toList();

            return AlertDialog(
              backgroundColor: const Color(0xFF0D1117),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: const Text(
                'Select Team(s)',
                style: TextStyle(
                  color: Color(0xFFE6EDF3),
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 440,
                child: Column(
                  children: [
                    TextField(
                      style: const TextStyle(color: Color(0xFFE6EDF3)),
                      decoration: InputDecoration(
                        hintText: 'Search team…',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF111827),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                      onChanged: (v) => setLocal(() => query = v),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '${temp.length} selected',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setLocal(() {
                              temp.clear();
                              temp.addAll(filtered);
                            });
                          },
                          child: const Text('Select filtered'),
                        ),
                        TextButton(
                          onPressed: () => setLocal(temp.clear),
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Scrollbar(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final name = filtered[i];
                            final selected = temp.contains(name);
                            return CheckboxListTile(
                              dense: true,
                              value: selected,
                              onChanged: (val) {
                                setLocal(() {
                                  if (val == true) {
                                    temp.add(name);
                                  } else {
                                    temp.remove(name);
                                  }
                                });
                              },
                              activeColor: Colors.red[700],
                              checkColor: Colors.white,
                              title: Text(
                                name,
                                style: const TextStyle(
                                  color: Color(0xFFE6EDF3),
                                  fontSize: 14,
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, temp),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (result == null) return;

    setState(() => _selectedTeams = result);
  }

  // ===================== Save (Create / Update) =====================
  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final request = context.read<CookieRequest>();
    final isEdit = widget.isEdit;

    final number = isEdit
        ? widget.existing!.driverNumber
        : (int.tryParse(_numberController.text.trim()) ?? 0);

    final country = _countryController.text.trim().toUpperCase();

    final Map<String, dynamic> body = {
      'driver_number': number,
      'full_name': _fullNameController.text.trim(),
      'broadcast_name': _broadcastController.text.trim(),
      'country_code': country,
      'headshot_url': _headshotController.text.trim(),
      'teams': _selectedTeams.toList(), // list of team_name (PK team)
    };

    try {
      final String url = isEdit
          ? "$_baseUrl/driver/api/mobile/${widget.existing!.driverNumber}/update/"
          : "$_baseUrl/driver/api/mobile/create/";

      final response = await request.postJson(url, jsonEncode(body));

      if (response is Map && response['ok'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Driver updated successfully' : 'Driver created successfully'),
            backgroundColor: Colors.green[700],
          ),
        );
        Navigator.pop(context, true);
        return;
      }

      String msg = 'Validation failed. Please check your input.';
      if (response is Map) {
        if (response['error'] != null) {
          msg = response['error'].toString();
        } else if (response['field_errors'] is Map) {
          final fe = response['field_errors'] as Map;
          if (fe.isNotEmpty) {
            final firstKey = fe.keys.first;
            final firstVal = fe[firstKey];
            msg = '$firstKey: $firstVal';
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red[800]),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save driver: $e'),
          backgroundColor: Colors.red[800],
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEdit;

    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: const Color(0xFF161B22),
        appBar: AppBar(
          title: Text(
            isEdit ? 'Edit Driver' : 'Add Driver',
            style: const TextStyle(
              color: Color(0xFFE6EDF3),
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: const Color(0xFF161B22),
          iconTheme: const IconThemeData(color: Color(0xFFE6EDF3)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionCard(
                  title: 'Driver Info',
                  subtitle: isEdit
                      ? 'Update driver details. Driver Number is locked.'
                      : 'Create a new driver entry.',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _numberController,
                              label: 'Driver Number',
                              hint: 'e.g. 44',
                              keyboardType: TextInputType.number,
                              enabled: !isEdit,
                              validator: (v) {
                                if (isEdit) return null;
                                if (v == null || v.trim().isEmpty) return 'Driver number is required';
                                final n = int.tryParse(v.trim());
                                if (n == null || n <= 0) return 'Input must be a positive number';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _countryController,
                              label: 'Country Code',
                              hint: 'GBR',
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 3,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                if (v.trim().length != 3) return 'Use 3 letters (e.g. GBR)';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _fullNameController,
                        label: 'Full Name',
                        hint: 'Lewis Hamilton',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Full name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _broadcastController,
                        label: 'Broadcast Name',
                        hint: 'LEWIS H.',
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _headshotController,
                        label: 'Headshot URL',
                        hint: 'https://…/headshot.jpg',
                        keyboardType: TextInputType.url,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final uri = Uri.tryParse(v.trim());
                          final ok = uri != null &&
                              (uri.scheme == 'http' || uri.scheme == 'https') &&
                              uri.host.isNotEmpty;
                          if (!ok) return 'Please input a valid URL (http/https)';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  title: 'Teams',
                  subtitle: _teamEndpointUsed == null
                      ? 'Optional. You can assign multiple teams.'
                      : 'Loaded from: ${_teamEndpointUsed!}',
                  trailing: _isTeamsLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                        )
                      : IconButton(
                          tooltip: 'Reload teams',
                          onPressed: _loadTeams,
                          icon: const Icon(Icons.refresh, color: Colors.white70),
                        ),
                  child: _buildTeamsField(),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isEdit ? 'Save Changes' : 'Create Driver',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamsField() {
    if (_teamsError != null && _teamOptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _teamsError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: _loadTeams,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final selectedSorted = _selectedTeams.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final unknownSelected = selectedSorted.where((t) => !_teamOptions.contains(t)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _openTeamPicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedTeams.isEmpty ? 'Tap to select team(s)' : '${_selectedTeams.length} team(s) selected',
                    style: TextStyle(
                      color: _selectedTeams.isEmpty ? Colors.white54 : const Color(0xFFE6EDF3),
                      fontSize: 14,
                      fontWeight: _selectedTeams.isEmpty ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white54),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_selectedTeams.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in selectedSorted)
                Chip(
                  label: Text(
                    t,
                    style: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 12),
                  ),
                  backgroundColor: const Color(0xFF111827),
                  side: const BorderSide(color: Colors.white24),
                  deleteIconColor: Colors.white60,
                  onDeleted: () => setState(() => _selectedTeams.remove(t)),
                ),
            ],
          )
        else
          const Text(
            'Tip: you can select multiple teams. This is optional.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        if (unknownSelected.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Note: some selected teams are not in the latest option list (old data).',
            style: TextStyle(color: Colors.amberAccent, fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFE6EDF3),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    int? maxLength,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: TextStyle(
        color: enabled ? const Color(0xFFE6EDF3) : Colors.white54,
      ),
      keyboardType: keyboardType,
      validator: validator,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
        counterStyle: const TextStyle(color: Colors.white54, fontSize: 10),
        filled: true,
        fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
