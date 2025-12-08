import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:speedview/user/constants.dart';
import '../models/team.dart';

class TeamFormScreen extends StatefulWidget {
  final Team? team;

  const TeamFormScreen({super.key, this.team});

  @override
  State<TeamFormScreen> createState() => _TeamFormScreenState();
}

class _TeamFormScreenState extends State<TeamFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _shortCodeController;
  late TextEditingController _logoController;
  late TextEditingController _teamColourController;
  late TextEditingController _teamColourSecondaryController;
  late TextEditingController _websiteController;
  late TextEditingController _wikiController;
  late TextEditingController _countryController;
  late TextEditingController _baseController;
  late TextEditingController _foundedYearController;
  late TextEditingController _constructorsController;
  late TextEditingController _driversController;
  late TextEditingController _pointsController;
  late TextEditingController _winsController;
  late TextEditingController _podiumsController;
  late TextEditingController _racesEnteredController;
  late TextEditingController _avgLapController;
  late TextEditingController _bestLapController;
  late TextEditingController _avgPitController;
  late TextEditingController _topSpeedController;
  late TextEditingController _lapsCompletedController;
  late TextEditingController _enginesController;
  late TextEditingController _descController;

  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.team;
    _nameController = TextEditingController(text: t?.teamName ?? '');
    _shortCodeController = TextEditingController(text: t?.shortCode ?? '');
    _logoController = TextEditingController(text: t?.teamLogoUrl ?? '');
    _teamColourController =
        TextEditingController(text: t?.teamColourHex.replaceAll('#', '') ?? '');
    _teamColourSecondaryController = TextEditingController(
        text: t?.teamColourSecondaryHex.replaceAll('#', '') ?? '');

    _websiteController = TextEditingController(text: t?.website ?? '');
    _wikiController = TextEditingController(text: t?.wikiUrl ?? '');
    _countryController = TextEditingController(text: t?.country ?? '');
    _baseController = TextEditingController(text: t?.base ?? '');
    _foundedYearController =
        TextEditingController(text: t?.foundedYear?.toString() ?? '');

    _constructorsController = TextEditingController(
        text: t?.constructorsChampionships.toString() ?? '0');
    _driversController =
        TextEditingController(text: t?.driversChampionships.toString() ?? '0');
    _pointsController =
        TextEditingController(text: t?.points.toString() ?? '0');
    _winsController =
        TextEditingController(text: t?.raceVictories.toString() ?? '0');
    _podiumsController =
        TextEditingController(text: t?.podiums.toString() ?? '0');
    _racesEnteredController =
        TextEditingController(text: t?.racesEntered.toString() ?? '0');

    _avgLapController =
        TextEditingController(text: t?.avgLapTimeMs?.toString() ?? '');
    _bestLapController =
        TextEditingController(text: t?.bestLapTimeMs?.toString() ?? '');
    _avgPitController =
        TextEditingController(text: t?.avgPitDurationMs?.toString() ?? '');
    _topSpeedController =
        TextEditingController(text: t?.topSpeedKph?.toString() ?? '');
    _lapsCompletedController =
        TextEditingController(text: t?.lapsCompleted.toString() ?? '0');

    _enginesController = TextEditingController(text: t?.engines ?? '');
    _descController = TextEditingController(text: t?.teamDescription ?? '');
    _isActive = t?.isActive ?? true;

    _logoController.addListener(() => setState(() {}));
    _teamColourController.addListener(() => setState(() {}));
    _teamColourSecondaryController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortCodeController.dispose();
    _logoController.dispose();
    _teamColourController.dispose();
    _teamColourSecondaryController.dispose();
    _websiteController.dispose();
    _wikiController.dispose();
    _countryController.dispose();
    _baseController.dispose();
    _foundedYearController.dispose();
    _constructorsController.dispose();
    _driversController.dispose();
    _pointsController.dispose();
    _winsController.dispose();
    _podiumsController.dispose();
    _racesEnteredController.dispose();
    _avgLapController.dispose();
    _bestLapController.dispose();
    _avgPitController.dispose();
    _topSpeedController.dispose();
    _lapsCompletedController.dispose();
    _enginesController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final request = context.read<CookieRequest>();
    final isEdit = widget.team != null;

    final url = isEdit
        ? buildSpeedViewUrl(
            '/team/api/mobile/${Uri.encodeComponent(widget.team!.teamName)}/edit/')
        : buildSpeedViewUrl('/team/api/mobile/create/');

    try {
      final body = {
        'team_name': _nameController.text.trim(),
        'short_code': _shortCodeController.text.trim(),
        'team_logo_url': _logoController.text.trim(),
        'team_colour': _teamColourController.text.trim(),
        'team_colour_secondary': _teamColourSecondaryController.text.trim(),
        'website': _websiteController.text.trim(),
        'wiki_url': _wikiController.text.trim(),
        'country': _countryController.text.trim(),
        'base': _baseController.text.trim(),
        'founded_year': int.tryParse(_foundedYearController.text.trim()) ?? 0,
        'constructors_championships':
            int.tryParse(_constructorsController.text.trim()) ?? 0,
        'drivers_championships':
            int.tryParse(_driversController.text.trim()) ?? 0,
        'points': int.tryParse(_pointsController.text.trim()) ?? 0,
        'race_victories': int.tryParse(_winsController.text.trim()) ?? 0,
        'podiums': int.tryParse(_podiumsController.text.trim()) ?? 0,
        'races_entered': int.tryParse(_racesEnteredController.text.trim()) ?? 0,
        'avg_lap_time_ms':
            double.tryParse(_avgLapController.text.trim()) ?? 0.0,
        'best_lap_time_ms': int.tryParse(_bestLapController.text.trim()) ?? 0,
        'avg_pit_duration_ms':
            double.tryParse(_avgPitController.text.trim()) ?? 0.0,
        'top_speed_kph':
            double.tryParse(_topSpeedController.text.trim()) ?? 0.0,
        'laps_completed':
            int.tryParse(_lapsCompletedController.text.trim()) ?? 0,
        'team_description': _descController.text.trim(),
        'engines': _enginesController.text.trim(),
        'is_active': _isActive,
      };

      final response = await request.postJson(url, jsonEncode(body));

      if (response['ok'] == true) {
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit
                ? 'Team updated successfully'
                : 'Team created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;

        // NEW: include field_errors if present
        final fieldErrors = response['field_errors'];
        String message = response['error'] ?? 'Failed to save team';

        if (fieldErrors is Map) {
          final buf = StringBuffer(message);
          buf.writeln();
          fieldErrors.forEach((field, errors) {
            buf.writeln('$field: $errors');
          });
          message = buf.toString();
        }

        _showError(message);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Network error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Color _parseColor(String s) {
    s = s.replaceAll('#', '').trim();
    if (s.length != 6) return Colors.transparent;
    return Color(int.parse('FF$s', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.team != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.pop(context),
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
                Text(
                  isEdit ? 'Edit Team' : 'Create Team',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Update team information, links, branding colors, and stats.',
                  style: TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),

                _buildLabel('Team Name', required: true),
                _buildTextField(_nameController, hint: 'Red Bull Racing'),
                const SizedBox(height: 6),
                const Text(
                  'Primary key; changing this renames the team.',
                  style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11),
                ),
                const SizedBox(height: 24),

                _buildLabel('Short Code'),
                _buildTextField(_shortCodeController, hint: 'RBR', maxLength: 3),
                const SizedBox(height: 24),

                _buildLabel('Team Logo URL'),
                _buildTextField(_logoController,
                    hint: 'https://example.com/logo.png'),
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: _logoController.text.isNotEmpty
                              ? Image.network(
                                  _logoController.text,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) =>
                                      const Icon(Icons.broken_image,
                                          color: Colors.white24, size: 40),
                                )
                              : const Icon(Icons.image,
                                  color: Colors.white24, size: 40),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Preview updates as you edit the URL.',
                          style: TextStyle(
                            color: Color(0x66FFFFFF),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildLabel('Branding Colors'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildColorSwatch(
                            _teamColourController,
                            "Primary",
                            true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildColorSwatch(
                            _teamColourSecondaryController,
                            "Secondary",
                            false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Country'),
                          _buildTextField(_countryController, hint: 'UK'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Base'),
                          _buildTextField(
                            _baseController,
                            hint: 'Milton Keynes',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildLabel('Founded Year'),
                _buildTextField(
                  _foundedYearController,
                  hint: '2005',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                _buildLabel('Website'),
                _buildTextField(
                  _websiteController,
                  hint: 'https://www.redbullracing.com',
                ),
                const SizedBox(height: 24),

                _buildLabel('Wikipedia URL'),
                _buildTextField(
                  _wikiController,
                  hint: 'https://en.wikipedia.org/wiki/Red_Bull_Racing',
                ),
                const SizedBox(height: 24),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.red,
                  title: const Text(
                    'Active Team',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 32),

                const Divider(color: Colors.white10),
                const SizedBox(height: 32),

                Text(
                  'Statistics',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatField(
                        'Constructors\'',
                        _constructorsController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatField(
                        'Drivers\'',
                        _driversController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatField(
                        'Points',
                        _pointsController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatField('Wins', _winsController),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatField('Podiums', _podiumsController),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildLabel('Races Entered'),
                _buildTextField(
                  _racesEnteredController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatField(
                        'Avg Lap (ms)',
                        _avgLapController,
                        isDouble: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatField(
                        'Best Lap (ms)',
                        _bestLapController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatField(
                        'Avg Pit (ms)',
                        _avgPitController,
                        isDouble: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatField(
                        'Top Speed (kph)',
                        _topSpeedController,
                        isDouble: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildLabel('Laps Completed'),
                _buildTextField(
                  _lapsCompletedController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                _buildLabel('Engines'),
                _buildTextField(
                  _enginesController,
                  hint: 'Honda, TAG Heuer...',
                  maxLines: 2,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Comma-separated engine supplier list.',
                  style: TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 24),

                _buildLabel('Description'),
                _buildTextField(_descController, maxLines: 4),
                const SizedBox(height: 48),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFFDC2626),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Color(0xFFE6EDF3),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    String? hint,
    int? maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: Colors.red,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        counterText: "",
      ),
      validator: (val) {
        if (hint == 'Required' && (val == null || val.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildColorSwatch(
      TextEditingController controller, String label, bool required) {
    Color c = _parseColor(controller.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(label, required: required),
                  _buildTextField(controller, hint: 'FF0000', maxLength: 6),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatField(String label, TextEditingController controller,
      {bool isDouble = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        _buildTextField(controller,
            keyboardType:
                TextInputType.numberWithOptions(decimal: isDouble)),
      ],
    );
  }
}
