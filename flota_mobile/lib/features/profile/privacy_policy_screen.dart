import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/settings_service.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    final privacyUrl = settings.get<String>('privacy_url', '');

    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giga Privacy Policy',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: ${DateTime.now().year}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),

            if (privacyUrl.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.privacy_tip_outlined, size: 48, color: Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      'View Full Privacy Policy',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For the most up-to-date policy, please view it on our website.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _launchUrl(privacyUrl),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Open Privacy Policy'),
                    ),
                  ],
                ),
              ),
              
            if (privacyUrl.isNotEmpty) const SizedBox(height: 24),

            _buildSection(
              '1. Introduction',
              'Giga Logistics is committed to protecting your privacy. This policy explains how we collect, use, and safeguard your personal information when you use our super-app services in the UK.',
            ),
            _buildSection(
              '2. Data We Collect',
              '• Identity Data: Name, email, and verified UK phone number.\n• Location Data: GPS coordinates to facilitate precise delivery and ULEZ scanning.\n• Financial Data: Payment method tokens (processed securely via Stripe).',
            ),
            _buildSection(
              '3. How We Use Your Data',
              'We use your data to provide logistics services, notify you of delivery status, calculate carbon savings, and ensure compliance with ULEZ regulations.',
            ),
            _buildSection(
              '4. Data Retention',
              'We retain your personal data only for as long as necessary to fulfill the purposes we collected it for, including for the purposes of satisfying any legal, accounting, or reporting requirements.',
            ),
            _buildSection(
              '5. Your Rights',
              'Under the UK GDPR, you have the right to access, rectify, or erase your personal data. You can manage most of your data directly through the Giga Profile screen.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© ${DateTime.now().year} Giga Logistics UK. All rights reserved.',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    );
  }
}
