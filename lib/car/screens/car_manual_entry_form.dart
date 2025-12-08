import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../models/car.dart';
import '../services/car_repository.dart';

class CarManualEntryFormScreen extends StatefulWidget {
  const CarManualEntryFormScreen({super.key, this.entry});

  final CarTelemetryEntry? entry;

  bool get isEditing => entry != null;

  @override
  State<CarManualEntryFormScreen> createState() =>
      _CarManualEntryFormScreenState();
}

class _CarManualEntryFormScreenState
    extends State<CarManualEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _meetingKeyController =
      TextEditingController();
  final TextEditingController _sessionKeyController =
      TextEditingController();
  final TextEditingController _driverNumberController =
      TextEditingController();
  final TextEditingController _speedController = TextEditingController();
  final TextEditingController _throttleController =
      TextEditingController();
  final TextEditingController _rpmController = TextEditingController();
  final TextEditingController _offsetController =
      TextEditingController(text: '0');

  bool _submitting = false;
  int _selectedBrake = 0;
  int _selectedGear = 1;
  int _selectedDrs = 0;

  static const List<int> _gearOptions = [0, 1, 2, 3, 4, 5, 6, 7, 8];
  static const List<int> _brakeOptions = [0, 100];
  static const List<Map<String, dynamic>> _drsOptions = [
    {'value': 0, 'label': '0 • DRS off'},
    {'value': 1, 'label': '1 • DRS off variant'},
    {'value': 2, 'label': '2 • Unknown'},
    {'value': 3, 'label': '3 • Unknown'},
    {'value': 8, 'label': '8 • Detected'},
    {'value': 9, 'label': '9 • Unknown'},
    {'value': 10, 'label': '10 • DRS on'},
    {'value': 12, 'label': '12 • DRS on'},
    {'value': 13, 'label': '13 • Unknown'},
    {'value': 14, 'label': '14 • DRS on'},
  ];

  @override
  void initState() {
    super.initState();
    _applyInitialEntry(widget.entry);
  }

  @override
  void dispose() {
    _meetingKeyController.dispose();
    _sessionKeyController.dispose();
    _driverNumberController.dispose();
    _speedController.dispose();
    _throttleController.dispose();
    _rpmController.dispose();
    _offsetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070B),
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Manual Entry' : 'Add Car Telemetry'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sync manual telemetry samples directly to SpeedView.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use the same numbers from the web admin (session key, driver number, etc).',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [

                    Expanded(
                      child: _buildNumberField(
                        controller: _meetingKeyController,
                        label: 'Meeting key',
                        hintText: 'e.g. 1105',
                        requiredField: false,
                        min: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumberField(
                        controller: _sessionKeyController,
                        label: 'Session key',
                        hintText: 'e.g. 9493',
                        min: 1,
                      ),
                    ),

                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        controller: _driverNumberController,
                        label: 'Driver number',
                        hintText: 'e.g. 44',
                        min: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumberField(
                        controller: _offsetController,
                        label: 'Session offset (s)',
                        hintText: '0',
                        min: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildNumberField(
                  controller: _speedController,
                  label: 'Speed (km/h)',
                  hintText: '0 - 450',
                  min: 0,
                  max: 450,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        controller: _throttleController,
                        label: 'Throttle (%)',
                        hintText: '0 - 100',
                        min: 0,
                        max: 100,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedBrake,
                        decoration: _fieldDecoration('Brake (%)'),
                        items: _brakeOptions
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: _submitting
                            ? null
                            : (value) =>
                                setState(() => _selectedBrake = value ?? 0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedGear,
                        decoration: _fieldDecoration('Gear'),
                        items: _gearOptions
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text('Gear $value'),
                              ),
                            )
                            .toList(),
                        onChanged: _submitting
                            ? null
                            : (value) =>
                                setState(() => _selectedGear = value ?? 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumberField(
                        controller: _rpmController,
                        label: 'RPM',
                        hintText: '0 - 20,000',
                        min: 0,
                        max: 20000,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedDrs,
                  decoration: _fieldDecoration('DRS Status'),
                  items: _drsOptions
                      .map(
                        (option) => DropdownMenuItem(
                          value: option['value'] as int,
                          child: Text(option['label'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (value) =>
                          setState(() => _selectedDrs = value ?? _selectedDrs),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.isEditing
                              ? 'Save changes'
                              : 'Add telemetry entry',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final meetingKey =
        _parseOptionalInt(_meetingKeyController.text.trim());
    final sessionKey =
        int.parse(_sessionKeyController.text.trim());
    final driverNumber =
        int.parse(_driverNumberController.text.trim());
    final speed = int.parse(_speedController.text.trim());
    final throttle = int.parse(_throttleController.text.trim());
    final rpm = int.parse(_rpmController.text.trim());
    final offset = int.parse(_offsetController.text.trim());

    setState(() => _submitting = true);

    final request = context.read<CookieRequest>();
    final repo = CarRepository(request);

    try {
      final entry = widget.entry == null
          ? await repo.createManualEntry(
              meetingKey: meetingKey,
              sessionKey: sessionKey,
              driverNumber: driverNumber,
              speed: speed,
              throttle: throttle,
              brake: _selectedBrake,
              nGear: _selectedGear,
              rpm: rpm,
              drs: _selectedDrs,
              sessionOffsetSeconds: offset,
            )
          : await repo.updateManualEntry(
              entryId: widget.entry!.id,
              meetingKey: meetingKey,
              sessionKey: sessionKey,
              driverNumber: driverNumber,
              speed: speed,
              throttle: throttle,
              brake: _selectedBrake,
              nGear: _selectedGear,
              rpm: rpm,
              drs: _selectedDrs,
              sessionOffsetSeconds: offset,
            );
      if (!mounted) return;
      Navigator.of(context).pop(entry);
    } on CarRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red[700],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create entry: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _applyInitialEntry(CarTelemetryEntry? entry) {
    if (entry == null) return;
    _meetingKeyController.text = entry.meetingKey?.toString() ?? '';
    _sessionKeyController.text = entry.sessionKey?.toString() ?? '';
    _driverNumberController.text = entry.driverNumber.toString();
    _speedController.text = entry.speed?.toString() ?? '';
    _throttleController.text = entry.throttle?.toString() ?? '';
    _rpmController.text = entry.rpm?.toString() ?? '';
    _offsetController.text =
        entry.sessionOffsetSeconds?.toString() ?? _offsetController.text;
    _selectedBrake = entry.brake ?? _selectedBrake;
    _selectedGear = entry.nGear ?? _selectedGear;
    _selectedDrs = entry.drs ?? _selectedDrs;
  }

  TextFormField _buildNumberField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int? min,
    int? max,
    bool requiredField = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_submitting,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: _fieldDecoration(label, hintText: hintText),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (!requiredField && trimmed.isEmpty) {
          return null;
        }
        if (trimmed.isEmpty) {
          return '$label is required';
        }
        final parsed = int.tryParse(trimmed);
        if (parsed == null) {
          return 'Enter a valid number';
        }
        if (min != null && parsed < min) {
          return 'Minimum value is $min';
        }
        if (max != null && parsed > max) {
          return 'Maximum value is $max';
        }
        return null;
      },
    );
  }

  InputDecoration _fieldDecoration(String label, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFF0F151E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x22FFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF4B47)),
      ),
    );
  }

  int? _parseOptionalInt(String value) {
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }
}
