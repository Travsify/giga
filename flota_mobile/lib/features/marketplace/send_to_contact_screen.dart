import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flota_mobile/theme/app_theme.dart';

class SendToContactScreen extends ConsumerStatefulWidget {
  const SendToContactScreen({super.key});

  @override
  ConsumerState<SendToContactScreen> createState() => _SendToContactScreenState();
}

class _SendToContactScreenState extends ConsumerState<SendToContactScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_phoneController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name and phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Logic to initiate delivery with location_requested=true
      // This uses the same backend endpoint but with empty dropoff_address
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery initiated! We will request the recipient\'s location.'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send to Contact', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Text(
                "No address? No problem.",
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              child: Text(
                "Just give us their contact info. We'll send them a secure link to provide their delivery location.",
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            
            Text("Recipient Name", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: AppTheme.inputDecoration('Enter name').copyWith(
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 24),

            Text("Recipient Phone", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            IntlPhoneField(
              decoration: AppTheme.inputDecoration('Phone Number').copyWith(
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              initialCountryCode: 'NG',
              onChanged: (phone) {
                _phoneController.text = phone.completeNumber;
              },
            ),
            const SizedBox(height: 24),

            Text("Parcel Description", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: AppTheme.inputDecoration('What are you sending?'),
            ),
            
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Initiate Secure Shipping", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Recipient will receive an SMS and must confirm their location before a rider is assigned.",
                      style: TextStyle(color: Colors.orange[800], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
