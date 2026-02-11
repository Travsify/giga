import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:flota_mobile/features/marketplace/delivery_provider.dart';
import 'package:flota_mobile/features/marketplace/data/models/delivery_models.dart';
import 'package:flota_mobile/core/location_service.dart';
import 'package:flota_mobile/core/api_config.dart';

// ──────────────── Errand Category Model ────────────────
class ErrandCategory {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> prompts;

  const ErrandCategory({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.prompts = const [],
  });
}

const _errandCategories = [
  ErrandCategory(
    name: 'Shopping',
    subtitle: 'Buy items for me',
    icon: Icons.shopping_cart_rounded,
    color: Color(0xFF6366F1),
    prompts: ['Buy groceries from the nearest supermarket', 'Pick up items from the market'],
  ),
  ErrandCategory(
    name: 'Pickup & Drop',
    subtitle: 'Collect & deliver',
    icon: Icons.swap_horiz_rounded,
    color: Color(0xFF0EA5E9),
    prompts: ['Collect a parcel from this address', 'Drop off documents at the office'],
  ),
  ErrandCategory(
    name: 'Food Run',
    subtitle: 'Get me food',
    icon: Icons.fastfood_rounded,
    color: Color(0xFFFF6B35),
    prompts: ['Buy lunch from the nearest restaurant', 'Get me jollof rice and chicken from Mama Put'],
  ),
  ErrandCategory(
    name: 'Pharmacy',
    subtitle: 'Collect medication',
    icon: Icons.local_pharmacy_rounded,
    color: Color(0xFF10B981),
    prompts: ['Pick up my prescription from the pharmacy', 'Buy Paracetamol and first-aid kit'],
  ),
  ErrandCategory(
    name: 'Queue & Pay',
    subtitle: 'Stand in line for me',
    icon: Icons.people_alt_rounded,
    color: Color(0xFFF59E0B),
    prompts: ['Pay my electricity bill at the office', 'Queue at the bank to make a deposit'],
  ),
  ErrandCategory(
    name: 'Custom',
    subtitle: 'Anything else',
    icon: Icons.edit_note_rounded,
    color: Color(0xFF8B5CF6),
    prompts: ['I need someone to help me with...'],
  ),
];

// ──────────────── Shopping List Item ────────────────
class ShoppingItem {
  String name;
  int quantity;
  ShoppingItem({required this.name, this.quantity = 1});
}

// ──────────────── Main Screen ────────────────
class ErrandScreen extends ConsumerStatefulWidget {
  const ErrandScreen({super.key});

  @override
  ConsumerState<ErrandScreen> createState() => _ErrandScreenState();
}

class _ErrandScreenState extends ConsumerState<ErrandScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 4;

  // Step 1: Category
  int _selectedCategoryIndex = -1;

  // Step 2: Instructions
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final List<ShoppingItem> _shoppingList = [];

  // Step 2: Location
  final TextEditingController _errandLocationController = TextEditingController();
  final TextEditingController _deliveryLocationController = TextEditingController();
  LatLng? _errandLatLng;
  LatLng? _deliveryLatLng;

  // Step 3: Budget & Urgency
  double _budget = 5000;
  String _urgency = 'Standard';
  String _vehicleType = 'Bike';
  bool _isScheduled = false;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;

  // General
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _instructionsController.dispose();
    _itemNameController.dispose();
    _errandLocationController.dispose();
    _deliveryLocationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: return _selectedCategoryIndex >= 0;
      case 1: return _instructionsController.text.trim().isNotEmpty && 
                     _errandLocationController.text.trim().isNotEmpty &&
                     _deliveryLocationController.text.trim().isNotEmpty;
      case 2: return _budget > 0;
      case 3: return true;
      default: return false;
    }
  }

  ErrandCategory? get _selectedCategory =>
      _selectedCategoryIndex >= 0 ? _errandCategories[_selectedCategoryIndex] : null;

  String get _currencySymbol => ref.read(authProvider).currencySymbol;
  bool get _isNG => ref.read(authProvider).countryCode == 'NG';

  double get _minBudget => _isNG ? 1000 : 5;
  double get _maxBudget => _isNG ? 100000 : 500;

  double get _estimatedFee {
    double base = _isNG ? 1500 : 8;
    if (_urgency == 'Express') base *= 1.5;
    if (_urgency == 'Scheduled') base *= 0.9;
    if (_vehicleType == 'Car') base *= 1.3;
    return base;
  }

  Future<void> _submitErrand() async {
    if (_errandLatLng == null || _deliveryLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select valid locations'), backgroundColor: AppTheme.primaryRed),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Build description with shopping list
      String description = _instructionsController.text.trim();
      if (_shoppingList.isNotEmpty) {
        description += '\n\n📋 Shopping List:\n';
        for (final item in _shoppingList) {
          description += '• ${item.name} × ${item.quantity}\n';
        }
      }
      description += '\n💰 Item Budget: $_currencySymbol${_budget.toStringAsFixed(0)}';

      DateTime? scheduled;
      if (_isScheduled && _scheduledDate != null && _scheduledTime != null) {
        scheduled = DateTime(
          _scheduledDate!.year, _scheduledDate!.month, _scheduledDate!.day,
          _scheduledTime!.hour, _scheduledTime!.minute,
        );
      }

      final request = DeliveryRequest(
        pickupAddress: _errandLocationController.text,
        pickupLat: _errandLatLng!.latitude,
        pickupLng: _errandLatLng!.longitude,
        dropoffAddress: _deliveryLocationController.text,
        dropoffLat: _deliveryLatLng!.latitude,
        dropoffLng: _deliveryLatLng!.longitude,
        vehicleType: _vehicleType,
        serviceTier: _urgency,
        fare: _estimatedFee + _budget,
        parcelCategory: _selectedCategory?.name ?? 'Custom',
        description: description,
        scheduledTime: scheduled,
        isErrand: true,
      );

      // Navigate to checkout
      if (mounted) context.push('/checkout', extra: request);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.primaryRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _useMyLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      final address = await LocationService.getAddressFromCoordinates(position.latitude, position.longitude);
      setState(() {
        _deliveryLocationController.text = address;
        _deliveryLatLng = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e'), backgroundColor: AppTheme.primaryRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _currentStep == 0 ? () => context.pop() : _prevStep,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
        ),
        title: Text(
          'Run Errand',
          style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Step ${_currentStep + 1}/$_totalSteps',
                  style: GoogleFonts.outfit(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            minHeight: 3,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentStep = idx),
              children: [
                _buildCategoryStep(),
                _buildInstructionsStep(),
                _buildBudgetStep(),
                _buildReviewStep(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ──────────────── Step 1: Category Grid ────────────────
  Widget _buildCategoryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What do you need done?',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Text('Pick the type of errand and we\'ll match you with a runner.',
                    style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.3,
            ),
            itemCount: _errandCategories.length,
            itemBuilder: (context, index) {
              final cat = _errandCategories[index];
              final isSelected = _selectedCategoryIndex == index;
              return FadeInUp(
                delay: Duration(milliseconds: 80 * index),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8)),
                      ] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : cat.color.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(cat.icon, color: isSelected ? AppTheme.primaryBlue : cat.color, size: 28),
                        ),
                        const SizedBox(height: 10),
                        Text(cat.name, style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isSelected ? AppTheme.primaryBlue : const Color(0xFF1E293B),
                        )),
                        Text(cat.subtitle, style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        )),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ──────────────── Step 2: Instructions ────────────────
  Widget _buildInstructionsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Instructions & Location',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                const SizedBox(height: 6),
                Text('Be as specific as possible — it helps your runner complete the errand faster.',
                    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Suggested prompts
          if (_selectedCategory != null && _selectedCategory!.prompts.isNotEmpty) ...[
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _selectedCategory!.prompts.length,
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => setState(() => _instructionsController.text = _selectedCategory!.prompts[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
                    ),
                    child: Text(
                      _selectedCategory!.prompts[i],
                      style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Instructions text area
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _instructionsController,
              maxLines: 4,
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'Describe what you need done...',
                hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Shopping List Builder
          if (_selectedCategory?.name == 'Shopping' || _selectedCategory?.name == 'Food Run' || _selectedCategory?.name == 'Pharmacy') ...[
            Row(
              children: [
                const Icon(Icons.checklist_rounded, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text('Shopping List', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF1E293B))),
                const Spacer(),
                Text('${_shoppingList.length} items', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _itemNameController,
                      style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'Add item (e.g., Rice, Bread)',
                        hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _addItem,
                  child: Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._shoppingList.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return FadeInLeft(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppTheme.primaryBlue, size: 18),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item.name, style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1E293B)))),
                      // Quantity controls
                      GestureDetector(
                        onTap: () => setState(() {
                          if (item.quantity > 1) item.quantity--;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.remove, size: 16, color: Color(0xFF64748B)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('${item.quantity}', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => item.quantity++),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.add, size: 16, color: AppTheme.primaryBlue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _shoppingList.removeAt(i)),
                        child: const Icon(Icons.close, size: 16, color: AppTheme.primaryRed),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Errand Location
          Text('Where should the runner go?', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF1E293B))),
          const SizedBox(height: 10),
          _buildLocationField(
            controller: _errandLocationController,
            hint: 'Shop, pharmacy, office address...',
            icon: Icons.storefront_rounded,
            iconColor: AppTheme.primaryBlue,
            onPicked: (lat, lng) => setState(() => _errandLatLng = LatLng(lat, lng)),
          ),
          const SizedBox(height: 16),

          // Delivery Location
          Row(
            children: [
              Text('Deliver to', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF1E293B))),
              const Spacer(),
              GestureDetector(
                onTap: _useMyLocation,
                child: Row(
                  children: [
                    const Icon(Icons.my_location_rounded, size: 14, color: Color(0xFF0EA5E9)),
                    const SizedBox(width: 4),
                    Text('Use my location', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF0EA5E9), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildLocationField(
            controller: _deliveryLocationController,
            hint: 'Your delivery address...',
            icon: Icons.home_rounded,
            iconColor: const Color(0xFF10B981),
            onPicked: (lat, lng) => setState(() => _deliveryLatLng = LatLng(lat, lng)),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required Function(double lat, double lng) onPicked,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          Expanded(
            child: GooglePlaceAutoCompleteTextField(
              textEditingController: controller,
              googleAPIKey: ApiConfig.googleMapsApiKey,
              inputDecoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              textStyle: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF0F172A)),
              debounceTime: 400,
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (prediction) {
                final lat = double.tryParse(prediction.lat ?? '');
                final lng = double.tryParse(prediction.lng ?? '');
                if (lat != null && lng != null) onPicked(lat, lng);
              },
              itemClick: (prediction) {
                controller.text = prediction.description ?? '';
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    final name = _itemNameController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        _shoppingList.add(ShoppingItem(name: name));
        _itemNameController.clear();
      });
    }
  }

  // ──────────────── Step 3: Budget & Urgency ────────────────
  Widget _buildBudgetStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Budget & Preferences',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                const SizedBox(height: 6),
                Text('Set a spending limit for items and choose urgency.',
                    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Budget Slider
          FadeInUp(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryBlue, size: 22),
                      const SizedBox(width: 10),
                      Text('Item Budget', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF1E293B))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_currencySymbol${_budget.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                  ),
                  Text('Maximum the runner can spend on items',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppTheme.primaryBlue,
                      inactiveTrackColor: AppTheme.primaryBlue.withOpacity(0.15),
                      thumbColor: AppTheme.primaryBlue,
                      overlayColor: AppTheme.primaryBlue.withOpacity(0.1),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: _budget.clamp(_minBudget, _maxBudget),
                      min: _minBudget,
                      max: _maxBudget,
                      divisions: 50,
                      onChanged: (v) => setState(() => _budget = v),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$_currencySymbol${_minBudget.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
                      Text('$_currencySymbol${_maxBudget.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Urgency Tiers
          Text('How urgent?', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF1E293B))),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildUrgencyCard('Express', '~30 min', Icons.flash_on_rounded, const Color(0xFFEF4444)),
              const SizedBox(width: 10),
              _buildUrgencyCard('Standard', '1–2 hrs', Icons.schedule_rounded, const Color(0xFF0EA5E9)),
              const SizedBox(width: 10),
              _buildUrgencyCard('Scheduled', 'Pick time', Icons.calendar_month_rounded, const Color(0xFF8B5CF6)),
            ],
          ),

          // Scheduled date/time
          if (_isScheduled) ...[
            const SizedBox(height: 16),
            FadeInUp(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) setState(() => _scheduledDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Text(
                              _scheduledDate != null
                                  ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                                  : 'Pick date',
                              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 10, minute: 0),
                        );
                        if (time != null) setState(() => _scheduledTime = time);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 18, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Text(
                              _scheduledTime != null
                                  ? _scheduledTime!.format(context)
                                  : 'Pick time',
                              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Vehicle Type
          Text('Runner vehicle', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF1E293B))),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildVehicleChip('Bike', Icons.two_wheeler_rounded),
              const SizedBox(width: 10),
              _buildVehicleChip('Car', Icons.directions_car_rounded),
              const SizedBox(width: 10),
              _buildVehicleChip('Van', Icons.airport_shuttle_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyCard(String label, String subtitle, IconData icon, Color color) {
    final isSelected = _urgency == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _urgency = label;
          _isScheduled = label == 'Scheduled';
          if (_isScheduled && _scheduledDate == null) {
            _scheduledDate = DateTime.now().add(const Duration(days: 1));
            _scheduledTime = const TimeOfDay(hour: 10, minute: 0);
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.08) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : const Color(0xFF94A3B8), size: 24),
              const SizedBox(height: 6),
              Text(label, style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600, fontSize: 12,
                color: isSelected ? color : const Color(0xFF64748B),
              )),
              Text(subtitle, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleChip(String label, IconData icon) {
    final isSelected = _vehicleType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _vehicleType = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue.withOpacity(0.08) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.primaryBlue : const Color(0xFF94A3B8), size: 22),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500,
                  color: isSelected ? AppTheme.primaryBlue : const Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────── Step 4: Review ────────────────
  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            child: Text('Review Your Errand',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          ),
          const SizedBox(height: 20),

          // Category badge
          FadeInUp(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(_selectedCategory?.icon ?? Icons.shopping_basket, color: AppTheme.primaryBlue, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedCategory?.name ?? 'Errand',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF0F172A))),
                          Text('$_urgency • $_vehicleType',
                              style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  if (_instructionsController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),
                    Text(_instructionsController.text.trim(),
                        style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E293B)),
                        maxLines: 4, overflow: TextOverflow.ellipsis),
                  ],
                  if (_shoppingList.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),
                    Text('📋 Shopping List (${_shoppingList.length} items)',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 6),
                    ..._shoppingList.take(5).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('  • ${item.name} × ${item.quantity}',
                          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B))),
                    )),
                    if (_shoppingList.length > 5)
                      Text('  ...and ${_shoppingList.length - 5} more',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8))),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Locations
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildReviewRow(Icons.storefront_rounded, 'Runner goes to', _errandLocationController.text, AppTheme.primaryBlue),
                  const Padding(
                    padding: EdgeInsets.only(left: 14),
                    child: Divider(height: 20, color: Color(0xFFE2E8F0)),
                  ),
                  _buildReviewRow(Icons.home_rounded, 'Delivers to you', _deliveryLocationController.text, const Color(0xFF10B981)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Price Breakdown
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildPriceRow('Runner Service Fee', '$_currencySymbol${_estimatedFee.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  _buildPriceRow('Item Budget (max)', '$_currencySymbol${_budget.toStringAsFixed(0)}'),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
                  _buildPriceRow(
                    'Estimated Total',
                    '$_currencySymbol${(_estimatedFee + _budget).toStringAsFixed(0)}',
                    isBold: true,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You\'ll only be charged for what the runner actually spends + service fee.',
                            style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isScheduled && _scheduledDate != null) ...[
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: Color(0xFF8B5CF6), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Scheduled: ${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year} at ${_scheduledTime?.format(context) ?? '10:00'}',
                      style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF7C3AED), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500])),
              Text(value.isNotEmpty ? value : 'Not set',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600],
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(amount, style: GoogleFonts.outfit(fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? Colors.black87)),
      ],
    );
  }

  // ──────────────── Bottom Navigation Bar ────────────────
  Widget _buildBottomBar() {
    final canProceed = _canProceed();
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: canProceed
              ? (isLastStep ? _submitErrand : _nextStep)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canProceed ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFF1F5F9),
            disabledForegroundColor: const Color(0xFF94A3B8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: canProceed ? 2 : 0,
          ),
          child: _isLoading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastStep ? 'Confirm & Publish' : 'Continue',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Icon(isLastStep ? Icons.check_circle_rounded : Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}
