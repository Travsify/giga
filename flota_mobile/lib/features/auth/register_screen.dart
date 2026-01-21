import 'package:flutter/material.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  String selectedRole = 'Customer';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Account', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              const Text('Join the most efficient logistics network.', style: TextStyle(color: AppTheme.slateBlue)),
              const SizedBox(height: 40),
              const Text('Select your role', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _RoleCard(
                    title: 'Customer',
                    icon: Icons.person_outline,
                    isSelected: selectedRole == 'Customer',
                    onTap: () => setState(() => selectedRole = 'Customer'),
                  ),
                  const SizedBox(width: 12),
                  _RoleCard(
                    title: 'Rider',
                    icon: Icons.motorcycle,
                    isSelected: selectedRole == 'Rider',
                    onTap: () => setState(() => selectedRole = 'Rider'),
                  ),
                  const SizedBox(width: 12),
                  _RoleCard(
                    title: 'Company',
                    icon: Icons.business,
                    isSelected: selectedRole == 'Company',
                    onTap: () => setState(() => selectedRole = 'Company'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const _FormInput(label: 'Full Name', icon: Icons.person_outline),
              const SizedBox(height: 20),
              const _FormInput(label: 'Email', icon: Icons.alternate_email),
              const SizedBox(height: 20),
              const _FormInput(label: 'Password', icon: Icons.lock_outline, isPassword: true),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => ref.read(authProvider.notifier).register('Test User', 'test@test.com', 'password', selectedRole).then((_) => context.go('/')),
                  child: isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text('By signing up, you agree to our ', style: TextStyle(color: AppTheme.slateBlue, fontSize: 12)),
                    InkWell(
                      onTap: () {},
                      child: const Text('Terms of Service', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({required this.title, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue : AppTheme.slateBlue.withOpacity(0.1),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.primaryBlue : AppTheme.slateBlue),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.slateBlue,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormInput extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPassword;

  const _FormInput({required this.label, required this.icon, this.isPassword = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.slateBlue, size: 20),
            hintText: 'Enter your $label',
            hintStyle: TextStyle(color: AppTheme.slateBlue.withOpacity(0.5)),
          ),
        ),
      ],
    );
  }
}
