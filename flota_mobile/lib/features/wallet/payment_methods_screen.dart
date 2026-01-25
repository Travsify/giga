import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:animate_do/animate_do.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, dynamic>> _methods = [
    {'type': 'visa', 'last4': '4242', 'expiry': '12/26', 'isDefault': true},
    {'type': 'mastercard', 'last4': '8888', 'expiry': '05/25', 'isDefault': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Payment Methods', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _methods.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final method = _methods[index];
                return FadeInRight(
                  delay: Duration(milliseconds: index * 100),
                  child: _CardTile(
                    method: method,
                    onSetDefault: () {
                      setState(() {
                        for (var m in _methods) {
                          m['isDefault'] = (m == method);
                        }
                      });
                    },
                    onDelete: () {
                      setState(() => _methods.removeAt(index));
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Adding new card via Stripe SetupIntent...')),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text('Add New Card', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final Map<String, dynamic> method;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const _CardTile({required this.method, required this.onSetDefault, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bool isDefault = method['isDefault'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDefault ? Border.all(color: AppTheme.primaryBlue, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              method['type'] == 'visa' ? Icons.credit_card : Icons.payment,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•••• •••• •••• ${method['last4']}',
                  style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Expires ${method['expiry']}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          if (isDefault)
            const Icon(Icons.check_circle, color: AppTheme.primaryBlue)
          else
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'default', child: Text('Set as Default')),
                const PopupMenuItem(value: 'delete', child: Text('Remove')),
              ],
              onSelected: (val) {
                if (val == 'default') onSetDefault();
                if (val == 'delete') onDelete();
              },
            ),
        ],
      ),
    );
  }
}
