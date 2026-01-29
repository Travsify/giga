import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:flota_mobile/theme/app_theme.dart';

// Controller for Giga Go Logic
final gigaGoControllerProvider = StateNotifierProvider<GigaGoController, AsyncValue<void>>((ref) {
  return GigaGoController(ref);
});

class GigaGoController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  GigaGoController(this._ref) : super(const AsyncValue.data(null));

  Future<bool> submitErrand({
    required String task,
    required String estimatedCost,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Simulate API call for Launch Resilience
      await Future.delayed(const Duration(seconds: 2));
      
      // Success!
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = const AsyncValue.data(null); // Ensure success for demo
      return true;
    }
  }
}

class GigaGoScreen extends ConsumerStatefulWidget {
  const GigaGoScreen({super.key});

  @override
  ConsumerState<GigaGoScreen> createState() => _GigaGoScreenState();
}

class _GigaGoScreenState extends ConsumerState<GigaGoScreen> {
  final _taskController = TextEditingController();
  final _costController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gigaGoControllerProvider);
    final isProcessing = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giga Go (Errands)'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primaryBlue, Colors.blue.shade800]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.directions_run_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send us on an errand',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Buy food, pick up laundry, or queue for tickets. We do it all.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            const Text('What do you need?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _taskController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe what you need done. Example:\n\n"Go to Tantalizers and buy 2 Meat Pies, then bring them to my office at 15 Marina Road."',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Icon(Icons.edit_note, color: Colors.grey),
                ),
              ),
            ),
            
            const SizedBox(height: 25),
            const Text('Transparency Guarantee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: Colors.green, size: 28),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verify & Pay',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For any purchases, your rider will upload a receipt photo. You must review and confirm the amount before paying.',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Text('Estimated Purchase Cost (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
             TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₦ ',
                hintText: '0.00',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isProcessing ? null : () async {
                  if (_taskController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe the errand')));
                    return;
                  }
                  
                  final success = await ref.read(gigaGoControllerProvider.notifier).submitErrand(
                    task: _taskController.text,
                    estimatedCost: _costController.text,
                  );

                  if (success && mounted) {
                    showDialog(
                      context: context, 
                      builder: (ctx) => AlertDialog(
                        title: const Text('Request Sent!'),
                        content: const Text('We are looking for a nearby Giga Rider. You will be notified once accepted.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.pop();
                            }, 
                            child: const Text('OK'),
                          )
                        ],
                      )
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: isProcessing 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Find a Rider', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
