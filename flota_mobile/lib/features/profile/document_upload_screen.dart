import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flota_mobile/features/profile/profile_provider.dart';
import 'package:dio/dio.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:flota_mobile/core/api_client.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  final String documentType;

  const DocumentUploadScreen({super.key, required this.documentType});

  @override
  ConsumerState<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  File? _image;
  bool _isUploading = false;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _upload() async {
    if (_image == null) return;

    setState(() => _isUploading = true);
    final api = ref.read(apiClientProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final fileVal = File(_image!.path);
      if (!fileVal.existsSync()) {
         throw Exception("File not found at path: ${_image!.path}");
      }

      final formData = FormData.fromMap({
        'type': widget.documentType,
        'file': await MultipartFile.fromFile(fileVal.path, filename: 'document.jpg'),
      });

      final response = await api.dio.post('profile/vehicle-document', data: formData);

      if (response.data['status'] == 'success') {
        ref.read(profileProvider.notifier).refresh(); // Refresh profile to get new paths
        if (mounted) {
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Document uploaded successfully!'), backgroundColor: AppTheme.successGreen));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppTheme.primaryRed));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = strToTitle(widget.documentType);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Upload $title', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderBlue, style: BorderStyle.solid),
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 64, color: AppTheme.primaryBlue.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text('No Image Selected', style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            if (_image == null) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choose from Gallery'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _upload,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isUploading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SUBMIT DOCUMENT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _image = null),
                child: const Text('Retake Photo', style: TextStyle(color: AppTheme.primaryRed)),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String strToTitle(String s) {
    return s.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}
