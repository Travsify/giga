import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/api_client.dart';

class TeamManagementScreen extends ConsumerStatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  ConsumerState<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends ConsumerState<TeamManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _members = [];
  List<dynamic> _invitations = [];

  @override
  void initState() {
    super.initState();
    _fetchTeam();
  }

  Future<void> _fetchTeam() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.get('business/team');
      setState(() {
        _members = response.data['members'] ?? [];
        _invitations = response.data['invitations'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch team: $e')));
      }
    }
  }

  void _showInviteModal() {
    final emailController = TextEditingController();
    String selectedRole = 'Member';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
            top: 40,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invite Team Member',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Grow your business by adding collaborators.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'colleague@business.com',
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
              Text('Assign Role', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _roleChoice(
                    label: 'Admin',
                    isSelected: selectedRole == 'Admin',
                    onTap: () => setModalState(() => selectedRole = 'Admin'),
                  ),
                  const SizedBox(width: 12),
                  _roleChoice(
                    label: 'Member',
                    isSelected: selectedRole == 'Member',
                    onTap: () => setModalState(() => selectedRole = 'Member'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    if (email.isEmpty) return;
                    
                    Navigator.pop(context);
                    _sendInvite(email, selectedRole);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Send Invitation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendInvite(String email, String role) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('business/invite', data: {
        'email': email,
        'role': role,
      });
      _fetchTeam();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation sent!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to invite: $e')));
      }
    }
  }

  Widget _roleChoice({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Team Management', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchTeam,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildSectionHeader('Current Members', _members.length.toString()),
                  const SizedBox(height: 16),
                  ..._members.map((m) => _MemberCard(member: m)),
                  if (_members.isEmpty) const _EmptyState(text: 'No members added yet.'),
                  
                  const SizedBox(height: 40),
                  
                  _buildSectionHeader('Pending Invitations', _invitations.length.toString()),
                  const SizedBox(height: 16),
                  ..._invitations.map((i) => _InviteCard(invite: i)),
                  if (_invitations.isEmpty) const _EmptyState(text: 'No pending invitations.'),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteModal,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Invite Member', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String count) {
    return Row(
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(count, style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  final dynamic member;
  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
            child: Text(member['name'][0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(member['email'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
            child: Text(member['role'] ?? 'Member', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final dynamic invite;
  const _InviteCard({required this.invite});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_outline_rounded, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invite['email'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black54)),
                Text('Role: ${invite['role']}', style: const TextStyle(fontSize: 12, color: Colors.black38)),
              ],
            ),
          ),
          const Text('PENDING', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(text, style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic)),
      ),
    );
  }
}
