import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/settings_service.dart';

class TermsConditionsScreen extends ConsumerWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    final termsUrl = settings.get<String>('terms_url', '');

    return Scaffold(
      appBar: AppBar(
        title: Text('Terms & Conditions', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giga Service Terms',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: ${DateTime.now().year}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),
            
            if (termsUrl.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.description_outlined, size: 48, color: AppTheme.primaryBlue),
                    const SizedBox(height: 16),
                    Text(
                      'View Full Terms Online',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For the most up-to-date terms, please view them on our website.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _launchUrl(termsUrl),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Open Terms & Conditions'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Below is a summary of our standard terms:',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              
            if (termsUrl.isNotEmpty) const SizedBox(height: 24),

            _buildSection(
              '1. Acceptance of Terms',
              'By accessing or using the Giga super-app, you agree to be bound by these Terms and Conditions and our Privacy Policy. If you do not agree, please do not use our services.',
            ),
            _buildSection(
              '2. Giga+ Subscription',
              'Giga+ is a premium subscription service priced at £39.99 per month. Subscriptions are billed in advance and are non-refundable. You may cancel your membership at any time via the support channel.',
            ),
            _buildSection(
              '3. Delivery Services',
              'Giga facilitates logistics between users and independent riders. While we strive for excellence, we are not liable for delays caused by traffic, weather, or incorrect address information provided by the user.',
            ),
            _buildSection(
              '4. Prohibited Items',
              'Users are prohibited from using Giga to transport illegal substances, hazardous materials, or dangerous goods as defined by UK law.',
            ),
            _buildSection(
              '5. Limitation of Liability',
              'To the maximum extent permitted by law, Giga Logistics shall not be liable for any indirect, incidental, or consequential damages resulting from the use of our platform.',
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
