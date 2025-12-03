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
  static const _baseUrl = 'http://127.0.0.1:8000/driver/api/create/';

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _numberController =
        TextEditingController(text: d != null ? d.driverNumber.toString() : '');
    _fullNameController =
        TextEditingController(text: d?.fullName ?? '');
    _broadcastController =
        TextEditingController(text: d?.broadcastName ?? '');
    _countryController =
        TextEditingController(text: d?.countryCode ?? '');
    _headshotController =
        TextEditingController(text: d?.headshotUrl ?? '');
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final request = context.read<CookieRequest>();

    final body = Driver(
      driverNumber: int.tryParse(_numberController.text.trim()) ?? 0,
      fullName: _fullNameController.text.trim(),
      broadcastName: _broadcastController.text.trim(),
      countryCode: _countryController.text.trim(),
      headshotUrl: _headshotController.text.trim(),
      teams: const [],
    ).toJsonForCreateUpdate();

    try {
      late final Map<String, dynamic> response;

      if (widget.isEdit) {
        response = await request.postJson(
          "$_baseUrl/driver/api/${widget.existing!.driverNumber}/update/",
          jsonEncode(body),
        );
      } else {
        response = await request.postJson(
          "$_baseUrl/driver/api/create/",
          jsonEncode(body),
        );
      }

      if (response['ok'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isEdit
                    ? 'Driver updated successfully'
                    : 'Driver created successfully',
              ),
              backgroundColor: Colors.green[700],
            ),
          );
          Navigator.pop(context, true); // true → tandai bahwa data berubah
        }
      } else {
        final error = response['error'] ??
            'Validation failed. Please check your input.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: Colors.red[800],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save driver: $e'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEdit;

    return Scaffold(
      backgroundColor: const Color(0xFF161B22),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Driver' : 'Add Driver',
          style: const TextStyle(color: Color(0xFFE6EDF3)),
        ),
        backgroundColor: const Color(0xFF161B22),
        iconTheme: const IconThemeData(color: Color(0xFFE6EDF3)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _numberController,
                label: 'Driver Number',
                hint: 'e.g. 44',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Driver number is required';
                  }
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) {
                    return 'Please input a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _fullNameController,
                label: 'Full Name',
                hint: 'Lewis Hamilton',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _broadcastController,
                label: 'Broadcast Name',
                hint: 'LEWIS H.',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _countryController,
                label: 'Country Code',
                hint: 'GBR',
                textCapitalization: TextCapitalization.characters,
                maxLength: 3,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (v.trim().length != 3) {
                    return 'Use 3-letter code (e.g. GBR, IDN)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _headshotController,
                label: 'Headshot URL',
                hint: 'https://…/headshot.jpg',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Color(0xFFE6EDF3)),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
