import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../models/circuit_model.dart';

class CircuitFormScreen extends StatefulWidget {
  final Circuit? circuit;

  const CircuitFormScreen({super.key, this.circuit});

  @override
  State<CircuitFormScreen> createState() => _CircuitFormScreenState();
}

class _CircuitFormScreenState extends State<CircuitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _mapUrlController = TextEditingController();
  final _locationController = TextEditingController();
  final _countryController = TextEditingController();
  final _lengthController = TextEditingController();
  final _turnsController = TextEditingController();
  final _gpController = TextEditingController();
  final _seasonsController = TextEditingController();
  final _gpHeldController = TextEditingController();

  String _circuitType = 'RACE';
  String _direction = 'CW';

  @override
  void initState() {
    super.initState();
    if (widget.circuit != null) {
      final c = widget.circuit!;
      _nameController.text = c.name;
      _mapUrlController.text = c.mapImageUrl ?? '';
      _locationController.text = c.location;
      _countryController.text = c.country;
      _lengthController.text = c.lengthKm.toString();
      _turnsController.text = c.turns.toString();
      _gpController.text = c.grandsPrix;
      _seasonsController.text = c.seasons;
      _gpHeldController.text = c.grandsPrixHeld.toString();
      _circuitType = c.circuitType;
      _direction = c.direction;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final request = context.read<CookieRequest>();
    final isEdit = widget.circuit != null;
    
    final baseUrl = "https://helven-marcia-speedview.pbp.cs.ui.ac.id"; 
    final url = isEdit 
        ? '$baseUrl/circuit/api/${widget.circuit!.id}/update/'
        : '$baseUrl/circuit/api/create/';

    final Map<String, dynamic> data = {
      'name': _nameController.text,
      'map_image_url': _mapUrlController.text,
      'location': _locationController.text,
      'country': _countryController.text,
      'circuit_type': _circuitType,
      'direction': _direction,
      'length_km': _lengthController.text,
      'turns': _turnsController.text,
      'grands_prix': _gpController.text,
      'seasons': _seasonsController.text,
      'grands_prix_held': _gpHeldController.text,
    };

    try {
      final response = await request.postJson(url, jsonEncode(data));
      if (context.mounted) {
         if (response['ok'] == true) {
             Navigator.pop(context, true);
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response['message'] ?? "Success"), backgroundColor: Colors.green),
             );
         } else {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response['error'] ?? "Failed"), backgroundColor: Colors.red),
             );
         }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.circuit != null ? 'Edit Circuit' : 'Add Circuit', style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField('Circuit Name', _nameController, true, hint: 'e.g. Adelaide Street Circuit'),
              _buildTextField('Map Image URL', _mapUrlController, false, isUrl: true, hint: 'https://...'),
              
              Row(
                children: [
                  Expanded(child: _buildTextField('Location', _locationController, true, hint: 'e.g. Adelaide')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Country', _countryController, true, hint: 'e.g. Australia')),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      'Type', 
                      _circuitType, 
                      ['RACE', 'STREET', 'ROAD'], 
                      (val) => setState(() => _circuitType = val!)
                    )
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      'Direction', 
                      _direction, 
                      ['CW', 'ACW'], 
                      (val) => setState(() => _direction = val!)
                    )
                  ),
                ],
              ),
              
              Row(
                children: [
                  Expanded(child: _buildTextField('Length (km)', _lengthController, true, isNumber: true, hint: 'e.g. 3.780')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Turns', _turnsController, true, isNumber: true, hint: 'e.g. 16')),
                ],
              ),

              _buildTextField('Grands Prix Names', _gpController, true, hint: 'e.g. Australian Grand Prix'),
              _buildTextField('Seasons', _seasonsController, true, hint: 'e.g. 1985–1995'),
              _buildTextField('GP Held (Count)', _gpHeldController, true, isNumber: true, hint: 'e.g. 11'),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFB4D46),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  widget.circuit != null ? 'Update Circuit' : 'Create Circuit',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    bool required, 
    {bool isNumber = false, bool isUrl = false, String? hint}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: isNumber ? TextInputType.number : (isUrl ? TextInputType.url : TextInputType.text),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return '$label is required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13), 
          filled: true,
          fillColor: const Color(0xFF0F151F),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFB4D46))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        dropdownColor: const Color(0xFF161B22),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF0F151F),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}