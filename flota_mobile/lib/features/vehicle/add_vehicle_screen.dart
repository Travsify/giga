import 'package:flota_mobile/features/vehicle/vehicle_service.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _yearController = TextEditingController();
  
  String _selectedType = 'bike';
  bool _isLoading = false;

  final List<String> _vehicleTypes = ['bike', 'car', 'van', 'truck'];

  @override
  void dispose() {
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'vehicle_type': _selectedType,
        'vehicle_plate_number': _plateController.text.trim(),
        'make': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'color': _colorController.text.trim(),
        'year': _yearController.text.trim(),
      };

      await ref.read(vehicleServiceProvider).addVehicle(data);
      if (mounted) {
         ref.refresh(vehiclesProvider); // Refresh list
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle added successfully!')));
         Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Add New Vehicle', style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              Text(
                'Vehicle Details',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Vehicle Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: AppTheme.surfaceColor,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: _inputDecoration('Vehicle Type'),
                items: _vehicleTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 16),

              // Plate Number
              TextFormField(
                controller: _plateController,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: _inputDecoration('Plate Number (e.g., ABJ-123-XY)'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Make
              TextFormField(
                controller: _makeController,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: _inputDecoration('Make (e.g., Toyota)'),
              ),
              const SizedBox(height: 16),

              // Model
              TextFormField(
                controller: _modelController,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: _inputDecoration('Model (e.g., Corolla)'),
              ),
              const SizedBox(height: 16),

              // Color
              TextFormField(
                controller: _colorController,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: _inputDecoration('Color'),
              ),
              const SizedBox(height: 16),

              // Year
              TextFormField(
                controller: _yearController,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: _inputDecoration('Year'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Add Vehicle', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: AppTheme.surfaceColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryBlue)),
    );
  }
}
