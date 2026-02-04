import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/features/profile/profile_provider.dart';
import 'document_upload_screen.dart';

class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;
    final rider = user?['rider'];

    final status = rider?['verification_status'] ?? 'pending';
    final hasLicense = rider?['driver_license_path'] != null;
    final hasRegistration = rider?['vehicle_registration_path'] != null;
    final isPlateVerified = rider?['vehicle_verified'] == true;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Trust & Verification', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(status),
            const SizedBox(height: 32),
            Text('REQUIRED DOCUMENTS', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDocTile(
              context,
              'Driver License',
              'Valid state-issued driving permit',
              Icons.badge_outlined,
              hasLicense ? 'Submitted' : 'Required',
              hasLicense,
              () => _uploadDoc(context, 'driver_license'),
            ),
            const SizedBox(height: 12),
            _buildDocTile(
              context,
              'Vehicle Registration',
              'Proof of ownership (V5C or logbook)',
              Icons.description_outlined,
              hasRegistration ? 'Submitted' : 'Required',
              hasRegistration,
              () => _uploadDoc(context, 'vehicle_registration'),
            ),
            const SizedBox(height: 32),
            Text('VEHICLE VERIFICATION', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
             _buildDocTile(
              context,
              'Plate Number Check',
              'Verification via national database',
              Icons.numbers_outlined,
              isPlateVerified ? 'Verified' : 'Pending Check',
              isPlateVerified,
              () {
                // If not verified, we could show a plate input dialog
              },
              showChevron: !isPlateVerified,
            ),
            const SizedBox(height: 48),
            if (status == 'pending' || status == 'rejected')
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Upload all required documents to begin accepting delivery requests.',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
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

  void _uploadDoc(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentUploadScreen(documentType: type),
      ),
    );
  }

  Widget _buildStatusHeader(String status) {
    Color color = Colors.orange;
    String text = 'Pending Verification';
    IconData icon = Icons.pending_rounded;

    if (status == 'submitted') {
      color = AppTheme.primaryBlue;
      text = 'Under Review';
      icon = Icons.hourglass_top_rounded;
    } else if (status == 'verified') {
      color = AppTheme.successGreen;
      text = 'Fully Verified';
      icon = Icons.verified_rounded;
    } else if (status == 'rejected') {
      color = AppTheme.primaryRed;
      text = 'Verification Failed';
      icon = Icons.error_outline_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 16),
          Text(text.toUpperCase(), style: GoogleFonts.outfit(color: color, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(
            status == 'submitted' 
              ? 'Our team is currently reviewing your documents. This usually takes 24-48 hours.'
              : 'Keep your documents updated to maintain your Giga Partner status.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDocTile(BuildContext context, String title, String subtitle, IconData icon, String statusText, bool isDone, VoidCallback onTap, {bool showChevron = true}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderBlue),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (isDone ? AppTheme.successGreen : AppTheme.primaryBlue).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: isDone ? AppTheme.successGreen : AppTheme.primaryBlue),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(statusText, style: TextStyle(color: isDone ? AppTheme.successGreen : Colors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
            if (showChevron) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
