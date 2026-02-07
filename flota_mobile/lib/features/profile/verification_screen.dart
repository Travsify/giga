import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/features/profile/profile_provider.dart';
import 'package:flota_mobile/features/profile/domain/verification_requirements.dart';
import 'document_upload_screen.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  String? _selectedCountry;
  String? _selectedIdentityDoc; // For NG: 'nin' or 'intl_passport'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rider = ref.read(profileProvider).user?['rider'];
      if (rider != null) {
        setState(() {
          _selectedCountry = rider['country'];
          _selectedIdentityDoc = rider['identity_doc_type'];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;
    final rider = user?['rider'];
    final status = rider?['verification_status'] ?? 'pending';

    // Use rider's country if set, else use selected
    final country = _selectedCountry ?? rider?['country'];

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

            // Country Selector
            if (country == null) ...[
              Text('SELECT YOUR COUNTRY', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildCountrySelector(),
              const SizedBox(height: 32),
            ] else ...[
              _buildCountryBadge(country),
              const SizedBox(height: 24),
              Text('REQUIRED DOCUMENTS', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildDocumentList(country, rider),
            ],

            const SizedBox(height: 48),
            if (status == 'pending' || status == 'rejected')
              _buildInfoBanner(),
            if (status == 'rejected' && rider?['rejection_reason'] != null)
              _buildRejectionDetails(rider!),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionDetails(Map<String, dynamic> rider) {
    final errors = rider['verification_errors'] as Map<String, dynamic>? ?? {};
    if (errors.isEmpty && rider['rejection_reason'] == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.primaryRed),
              const SizedBox(width: 8),
              Text('REJECTION DETAILS', style: GoogleFonts.outfit(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 12),
          Text(rider['rejection_reason'] ?? 'One or more of your documents could not be verified.', style: const TextStyle(color: Colors.white, fontSize: 14)),
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            ...errors.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppTheme.primaryRed, fontSize: 16, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: '${e.key.replaceAll('_', ' ').toUpperCase()}: ', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                          TextSpan(text: e.value.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildCountrySelector() {
    return Column(
      children: VerificationRequirements.supportedCountries.map((c) {
        final isSelected = _selectedCountry == c['code'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => setState(() => _selectedCountry = c['code']),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue.withOpacity(0.15) : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppTheme.primaryBlue : AppTheme.borderBlue, width: isSelected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Text(c['flag']!, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(c['name']!, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ),
                  if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primaryBlue),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCountryBadge(String country) {
    final countryData = VerificationRequirements.supportedCountries.firstWhere((c) => c['code'] == country, orElse: () => {'flag': '🌍', 'name': country});
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(countryData['flag']!, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(countryData['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDocumentList(String country, Map<String, dynamic>? rider) {
    final docs = VerificationRequirements.getForCountry(country);
    final List<Widget> widgets = [];

    // Group choice docs
    final identityDocs = docs.where((d) => d.choiceGroupId == 'identity').toList();
    final otherDocs = docs.where((d) => d.choiceGroupId == null).toList();

    // Identity choice group (for Nigeria)
    if (identityDocs.isNotEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Choose one for identity verification:', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
        ),
      );
      widgets.add(_buildChoiceGroup(identityDocs, rider));
      widgets.add(const SizedBox(height: 24));
    }

    // Other required/optional docs
    for (final doc in otherDocs) {
      widgets.add(_buildDocTile(doc, rider));
      widgets.add(const SizedBox(height: 12));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _buildChoiceGroup(List<VerificationDoc> docs, Map<String, dynamic>? rider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderBlue),
      ),
      child: Column(
        children: docs.map((doc) {
          final isSelected = _selectedIdentityDoc == doc.id;
          final isSubmitted = _isDocSubmitted(doc.id, rider);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: InkWell(
              onTap: () {
                setState(() => _selectedIdentityDoc = doc.id);
                _uploadDoc(context, doc.id);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.transparent),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: doc.id,
                      groupValue: _selectedIdentityDoc,
                      onChanged: (v) {
                        setState(() => _selectedIdentityDoc = v);
                        _uploadDoc(context, doc.id);
                      },
                      activeColor: AppTheme.primaryBlue,
                    ),
                    Icon(doc.icon, color: isSubmitted ? AppTheme.successGreen : AppTheme.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(doc.description, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (isSubmitted) const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 20),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDocTile(VerificationDoc doc, Map<String, dynamic>? rider) {
    final isSubmitted = _isDocSubmitted(doc.id, rider);
    final isOptional = doc.status == DocStatus.optional;
    final errors = rider?['verification_errors'] as Map<String, dynamic>? ?? {};
    final hasError = errors.containsKey(doc.id);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasError ? AppTheme.primaryRed : AppTheme.borderBlue),
      ),
      child: ListTile(
        onTap: () => _uploadDoc(context, doc.id),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (hasError ? AppTheme.primaryRed : (isSubmitted ? AppTheme.successGreen : AppTheme.primaryBlue)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(doc.icon, color: hasError ? AppTheme.primaryRed : (isSubmitted ? AppTheme.successGreen : AppTheme.primaryBlue)),
        ),
        title: Row(
          children: [
            Text(doc.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            if (isOptional) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: const Text('Optional', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        subtitle: Text(hasError ? errors[doc.id].toString() : doc.description, style: TextStyle(color: hasError ? AppTheme.primaryRed.withOpacity(0.8) : AppTheme.textSecondary, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasError ? 'Fix' : (isSubmitted ? 'Submitted' : (isOptional ? 'Add' : 'Required')),
              style: TextStyle(color: hasError ? AppTheme.primaryRed : (isSubmitted ? AppTheme.successGreen : (isOptional ? AppTheme.textSecondary : Colors.orange)), fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: hasError ? AppTheme.primaryRed : AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  bool _isDocSubmitted(String docId, Map<String, dynamic>? rider) {
    if (rider == null) return false;
    final pathKey = _getPathKey(docId);
    return rider[pathKey] != null && rider[pathKey].toString().isNotEmpty;
  }

  String _getPathKey(String docId) {
    switch (docId) {
      case 'nin': return 'nin_path';
      case 'intl_passport': return 'intl_passport_path';
      case 'driver_license': return 'driver_license_path';
      case 'dvla_license': return 'dvla_license_path';
      case 'passport': return 'passport_path';
      case 'passport_photo': return 'passport_photo_path';
      case 'brp': return 'brp_path';
      case 'selfie_id': return 'selfie_id_path';
      case 'vehicle_front': return 'vehicle_front_path';
      case 'vehicle_side': return 'vehicle_side_path';
      case 'vehicle_interior': return 'vehicle_interior_path';
      default: return '${docId}_path';
    }
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

  Widget _buildInfoBanner() {
    return Container(
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
    );
  }
}
