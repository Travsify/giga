import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/features/marketplace/home_widgets.dart'; // For HeroActionCard style if needed
import 'package:flota_mobile/features/delivery/data/locker_repository.dart';
import 'package:flota_mobile/features/marketplace/data/delivery_repository.dart'; // Creating provider here or using generic
import 'package:dio/dio.dart';
import 'package:flota_mobile/core/api_client.dart'; // Assume we have this
import 'package:flota_mobile/features/auth/auth_provider.dart';

// Provider for Inter-state Logic
final interStateControllerProvider = StateNotifierProvider<InterStateController, AsyncValue<Map<String, dynamic>?>>((ref) {
  return InterStateController(ref);
});

class InterStateController extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final Ref _ref;
  InterStateController(this._ref) : super(const AsyncValue.data(null));

  Future<void> getPrice({
    required String originState,
    required String destState,
    required String size,
  }) async {
    state = const AsyncValue.loading();
    try {
      final dio = _ref.read(apiClientProvider).dio;
      final response = await dio.get('/inter-state/price', queryParameters: {
        'origin_state': originState,
        'destination_state': destState,
        'size': size,
      });
      state = AsyncValue.data(response.data);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<bool> createWaybill({
    required Map<String, dynamic> data,
  }) async {
    state = const AsyncValue.loading();
    try {
      final dio = _ref.read(apiClientProvider).dio;
      await dio.post('/inter-state/waybill', data: data);
      state = const AsyncValue.data(null); // Reset or Keep success data?
      return true;
    } catch (e) {
      if (e is DioException) {
         // Simplify error for UI
         state = AsyncValue.error(e.response?.data['message'] ?? 'Failed to book', StackTrace.current);
      } else {
         state = AsyncValue.error(e, StackTrace.current);
      }
      return false;
    }
  }
}

class InterStateScreen extends ConsumerStatefulWidget {
  const InterStateScreen({super.key});

  @override
  ConsumerState<InterStateScreen> createState() => _InterStateScreenState();
}

class _InterStateScreenState extends ConsumerState<InterStateScreen> {
  // Mock States for MVP - Ideally fetched from API/config
  final List<String> _states = ['Lagos', 'Abuja', 'Rivers', 'Ibadan', 'Kano'];
  
  String? _originState;
  String? _destState;
  String _selectedSize = 'Small';
  
  // Locker Selection (Mock or API driven - simplifying to "Nearest" or Dropdown)
  // To keep it simple per User Instruction: Just Select State -> Show Price -> Book.
  // We can select specific lockers in a real advanced flow. For MVP, we pass dummy Locker IDs or assume user selects from a list.
  // Let's assume we fetch lockers for selected state.
  
  String? _originLockerId;
  String? _destLockerId; // In reality, user selects "Wuse Locker" which has ID 5
  
  // Hardcoded Locker IDs for Demo (matching seed data implied existence)
  // We need actual lockers in DB. 
  // Let's assume user picks a locker from a dropdown filtered by state.

  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final priceState = ref.watch(interStateControllerProvider);
    final currency = ref.watch(authProvider).currencySymbol;

    return Scaffold(
      appBar: AppBar(title: const Text('Inter-state Delivery')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Route Selection
            Text('Select Route', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'From (State)'),
                    value: _originState,
                    items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      setState(() => _originState = val);
                      _fetchPrice();
                    },
                  ),
                ),
                const SizedBox(width: 15),
                const Icon(Icons.arrow_forward),
                const SizedBox(width: 15),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'To (State)'),
                    value: _destState,
                    items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      setState(() => _destState = val);
                      _fetchPrice();
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 2. Size Selection
            Text('Package Size', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildSizeCard('Small', 'Phones, Docs', Icons.smartphone_rounded), 
                _buildSizeCard('Medium', 'Shoes, Laptop', Icons.laptop_mac_rounded),
                _buildSizeCard('Large', 'Microwave', Icons.microwave_rounded),
              ],
            ),

            const SizedBox(height: 20),

            // 3. Price Display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppTheme.primaryBlue),
              ),
              child: priceState.when(
                data: (data) {
                  if (data == null) return const Text('Select route to see price');
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estimated Cost', style: Theme.of(context).textTheme.bodyMedium),
                          Text(
                            '$currency${data['price']}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Duration', style: Theme.of(context).textTheme.bodyMedium),
                          const Text(
                            '2-3 Days', // Hardcoded or from API
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Route unavailable', style: TextStyle(color: Colors.red)),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 4. Details Form (Simplified)
            Text('Recipient Details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TextField(
              controller: _recipientNameCtrl,
              decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _recipientPhoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Item Description', prefixIcon: Icon(Icons.description)),
            ),
             const SizedBox(height: 10),
            TextField(
              controller: _valueCtrl,
              decoration: const InputDecoration(labelText: 'Item Value (for Insurance)', prefixIcon: Icon(Icons.monetization_on)),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 30),

            // 5. Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed, // Giga Red
                  foregroundColor: Colors.white,
                ),
                onPressed: _originState == null || _destState == null || priceState.hasError 
                    ? null 
                    : _submitBooking,
                child: priceState.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Book & Pay from Wallet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeCard(String size, String desc, IconData icon) {
    final isSelected = _selectedSize == size;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedSize = size);
          _fetchPrice();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryRed : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppTheme.primaryRed : Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(height: 5),
              Text(
                size,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  color: isSelected ? Colors.white70 : Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fetchPrice() {
    if (_originState != null && _destState != null) {
      ref.read(interStateControllerProvider.notifier).getPrice(
        originState: _originState!,
        destState: _destState!,
        size: _selectedSize,
      );
    }
  }

  Future<void> _submitBooking() async {
      // Mock Locker IDs for now (Assuming IDs 1 and 2 exist in DB)
      // In production, user would select lockers from a filtered list.
      final originId = '1'; 
      final destId = '2'; 
      
      final success = await ref.read(interStateControllerProvider.notifier).createWaybill(data: {
        'origin_state': _originState,
        'destination_state': _destState,
        'origin_locker_id': originId, 
        'destination_locker_id': destId,
        'size': _selectedSize,
        'recipient_name': _recipientNameCtrl.text,
        'recipient_phone': _recipientPhoneCtrl.text,
        'items_description': _descCtrl.text,
        'value': _valueCtrl.text,
      });

      if (success && mounted) {
        // Show Success Dialog
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Booking Successful!'),
            content: const Text('Your waybill has been generated. Please drop off your package at the designated locker.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Go back home
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
  }
}
