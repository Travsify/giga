import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/features/business/business_provider.dart';
import 'package:intl/intl.dart';

class ApiKeyScreen extends ConsumerStatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  ConsumerState<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends ConsumerState<ApiKeyScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(businessProvider.notifier).fetchApiKeys());
  }

  void _copyToClipboard(String key) {
    Clipboard.setData(ClipboardData(text: key));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API Key copied to clipboard')),
    );
  }

  Future<void> _showGenerateDialog() async {
    _nameController.clear();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Generate API Key', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'e.g. Mobile App, Web Store',
            labelText: 'Key Description',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isEmpty) return;
              Navigator.pop(context);
              final response = await ref.read(businessProvider.notifier).generateApiKey(_nameController.text);
              if (response != null && mounted) {
                _showNewKeyDialog(response['data']['api_key']);
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showNewKeyDialog(String key) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('API Key Generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please copy this key now. For security, it will NOT be shown again.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: SelectableText(key, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () => _copyToClipboard(key), icon: const Icon(Icons.copy)),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('I have saved it')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(businessProvider);
    final keys = state.apiKeys ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('API & Integrations', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: state.isLoading && keys.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(businessProvider.notifier).fetchApiKeys(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDevBanner(),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Your API Keys', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _showGenerateDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Generate New'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (keys.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text('No API keys yet.', style: GoogleFonts.outfit(color: Colors.grey)),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: keys.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final key = keys[index];
                          return _buildKeyTile(key);
                        },
                      ),
                    const SizedBox(height: 32),
                    _buildDocumentationLink(),
                    const SizedBox(height: 32),
                    _buildWebhooks(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKeyTile(Map<String, dynamic> key) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(key['name'] ?? 'Unnamed Key', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _confirmRevoke(key['id'], key['name']),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Prefix: ${key['prefix']}',
            style: TextStyle(color: Colors.grey[600], fontSize: 13, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                'Used: ${key['last_used_at'] != null ? DateFormat('MMM d, HH:mm').format(DateTime.parse(key['last_used_at'])) : 'Never'}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (key['is_active'] ?? true) ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  (key['is_active'] ?? true) ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: (key['is_active'] ?? true) ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmRevoke(int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke API Key?'),
        content: Text('Are you sure you want to revoke "$name"? Any app using this key will stop working immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(businessProvider.notifier).revokeApiKey(id);
            },
            child: const Text('Revoke', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDevBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.code, color: Colors.greenAccent, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Developer Integration',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Build custom delivery apps powered by Giga logistics network.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentationLink() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // In a real app, use url_launcher
            // launchUrl(Uri.parse('https://giga-backend.com/business/documentation/download'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Downloading Giga_API_Integration_Guide.html...')),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.code_rounded, color: AppTheme.primaryBlue),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('Download Integration Guide', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Icon(Icons.html_rounded, size: 24, color: AppTheme.primaryBlue),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebhooks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Webhooks', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Order Status Updates', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Receive real-time tracking updates', style: TextStyle(fontSize: 12)),
                trailing: Switch(value: true, onChanged: (v) {}, activeColor: AppTheme.primaryBlue),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Payment Success', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Notify when escrow is released', style: TextStyle(fontSize: 12)),
                trailing: Switch(value: false, onChanged: (v) {}, activeColor: AppTheme.primaryBlue),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
