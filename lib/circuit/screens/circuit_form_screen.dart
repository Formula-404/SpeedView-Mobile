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
  
  // Controllers
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
    final url = isEdit 
        ? 'http://127.0.0.1:8000/circuit/api/${widget.circuit!.id}/update/'
        : 'http://127.0.0.1:8000/circuit/api/create/';

    // Data Map
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
      final response = await request.post(url, data);

      if (context.mounted) {
         Navigator.pop(context, true);
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isEdit ? "Circuit updated" : "Circuit created"), backgroundColor: Colors.green),
         );
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
    const cardColor = Color(0xFF0F151F);
    final isEdit = widget.circuit != null;

    return Scaffold(
      backgroundColor: const Color(0xFF05070B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isEdit ? 'Edit Circuit' : 'Add Circuit', style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
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
              _buildSectionTitle('Basic Info'),
              _buildTextField('Circuit Name', _nameController, true),
              _buildTextField('Map Image URL', _mapUrlController, false, isUrl: true),
              Row(
                children: [
                  Expanded(child: _buildTextField('Location', _locationController, true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Country', _countryController, true)),
                ],
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Technical Specs'),
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
                  Expanded(child: _buildTextField('Length (km)', _lengthController, true, isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Turns', _turnsController, true, isNumber: true)),
                ],
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('History'),
              _buildTextField('Grands Prix Names', _gpController, true),
              _buildTextField('Seasons', _seasonsController, true),
              _buildTextField('GP Held (Count)', _gpHeldController, true, isNumber: true),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFB4D46),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isEdit ? 'Update Circuit' : 'Create Circuit',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool required, {bool isNumber = false, bool isUrl = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: isNumber ? TextInputType.number : (isUrl ? TextInputType.url : TextInputType.text),
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'Required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF0F151F),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFB4D46))),
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
        ),
      ),
    );
  }
}