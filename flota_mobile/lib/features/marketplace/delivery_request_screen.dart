import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/shared/map_picker_screen.dart';
import 'package:flota_mobile/features/marketplace/data/models/delivery_models.dart';
import 'package:flota_mobile/features/marketplace/delivery_provider.dart';
import 'package:flota_mobile/features/profile/profile_provider.dart';
import 'package:intl/intl.dart';

class DeliveryRequestScreen extends ConsumerStatefulWidget {
  final bool initiallyScheduled;
  const DeliveryRequestScreen({super.key, this.initiallyScheduled = false});

  @override
  ConsumerState<DeliveryRequestScreen> createState() => _DeliveryRequestScreenState();
}

class _DeliveryRequestScreenState extends ConsumerState<DeliveryRequestScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form State
  String selectedVehicle = 'Bike';
  String selectedTier = 'Standard';
  String selectedCategory = 'General';
  String selectedSize = 'Medium';
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _pickupPostcode = TextEditingController();
  final TextEditingController _dropoffPostcode = TextEditingController();
  LatLng? pickupLatLng;
  LatLng? dropoffLatLng;
  File? _parcelImage;
  final ImagePicker _picker = ImagePicker();
  
  bool isScheduled = false;
  DateTime? scheduledDate;
  TimeOfDay? scheduledTime;

  @override
  void initState() {
    super.initState();
    isScheduled = widget.initiallyScheduled;
    if (isScheduled) {
      scheduledDate = DateTime.now().add(const Duration(days: 1));
      scheduledTime = const TimeOfDay(hour: 10, minute: 0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _pickupPostcode.dispose();
    _dropoffPostcode.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _pickLocation(bool isPickup) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          title: isPickup ? 'Select Pickup' : 'Select Drop-off',
          initialPosition: isPickup ? pickupLatLng : dropoffLatLng,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isPickup) {
          _pickupController.text = result['address'];
          pickupLatLng = result['position'];
        } else {
          _dropoffController.text = result['address'];
          dropoffLatLng = result['position'];
        }
      });
      _updateEstimation();
    }
  }

  void _updateEstimation() {
    if (pickupLatLng != null && dropoffLatLng != null) {
      ref.read(deliveryProvider.notifier).estimateFare(
        DeliveryEstimationRequest(
          pickupLat: pickupLatLng!.latitude,
          pickupLng: pickupLatLng!.longitude,
          dropoffLat: dropoffLatLng!.latitude,
          dropoffLng: dropoffLatLng!.longitude,
          vehicleType: selectedVehicle,
          serviceTier: selectedTier,
          parcelCategory: selectedCategory,
          parcelSize: selectedSize,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() => _parcelImage = File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deliveryState = ref.watch(deliveryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _currentStep == 0 ? () => context.pop() : _prevStep,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
        ),
        title: Text(
          'Send Parcel',
          style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                'Step ${_currentStep + 1}/5',
                style: GoogleFonts.outfit(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / 5,
            backgroundColor: Colors.grey[100],
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentStep = idx),
              children: [
                _buildLocationStep(),
                _buildParcelSpecStep(),
                _buildSnapshotStep(),
                _buildPreferenceStep(),
                _buildReviewStep(),
              ],
            ),
          ),
          _buildBottomBar(deliveryState),
        ],
      ),
    );
  }

  // --- STEP 1: LOCATIONS ---
  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Where is it going?", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Enter postcodes for precision pricing.", style: GoogleFonts.outfit(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildPostcodeField('Pickup Postcode', _pickupPostcode, Icons.my_location, true),
          const SizedBox(height: 16),
          _buildPostcodeField('Drop-off Postcode', _dropoffPostcode, Icons.location_on, false),
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: () => _pickLocation(true),
            icon: const Icon(Icons.map_outlined),
            label: const Text("Select on map instead"),
          ),
        ],
      ),
    );
  }

  Widget _buildPostcodeField(String label, TextEditingController controller, IconData icon, bool isPickup) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: GoogleFonts.outfit(fontSize: 14, letterSpacing: 0, fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, color: isPickup ? AppTheme.primaryBlue : AppTheme.primaryRed),
          hintText: 'e.g. SW1A 1AA',
        ),
        onChanged: (val) {
          if (val.length >= 5) {
            // Mocking postcode lookup for LatLng
            setState(() {
              if (isPickup) pickupLatLng = const LatLng(51.5074, -0.1278);
              else dropoffLatLng = const LatLng(51.5007, -0.1246);
            });
            _updateEstimation();
          }
        },
      ),
    );
  }

  // --- STEP 2: PARCEL SPECS ---
  Widget _buildParcelSpecStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What are you moving?", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildSizeGrid(),
          const SizedBox(height: 32),
          Text("Category", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildCategoryPills(),
        ],
      ),
    );
  }

  Widget _buildSizeGrid() {
    final sizes = [
      {'label': 'Letter', 'icon': Icons.mail_outline, 'desc': 'Documents / Small Pouch'},
      {'label': 'Box', 'icon': Icons.inventory_2_outlined, 'desc': 'Shoebox / Small Parcel'},
      {'label': 'Medium', 'icon': Icons.luggage_outlined, 'desc': 'Suitcase / Large Box'},
      {'label': 'Large', 'icon': Icons.widgets_outlined, 'desc': 'Extra Large / Heavy'},
      {'label': 'Van Load', 'icon': Icons.local_shipping_outlined, 'desc': 'Furniture / Multiple Items'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sizes.length,
      itemBuilder: (context, idx) {
        final item = sizes[idx];
        final isSelected = selectedSize == item['label'];
        return GestureDetector(
          onTap: () {
            setState(() => selectedSize = item['label'] as String);
            _updateEstimation();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.grey[200]!, width: 2),
            ),
            child: Row(
              children: [
                Icon(item['icon'] as IconData, color: isSelected ? AppTheme.primaryBlue : Colors.grey),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(item['desc'] as String, style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primaryBlue),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryPills() {
    final categories = ['General', 'Fragile', 'Electronics', 'Grocery', 'Fashion'];
    return Wrap(
      spacing: 10,
      children: categories.map((cat) {
        final isSelected = selectedCategory == cat;
        return FilterChip(
          label: Text(cat),
          selected: isSelected,
          onSelected: (val) => setState(() => selectedCategory = cat),
          selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
          checkmarkColor: AppTheme.primaryBlue,
        );
      }).toList(),
    );
  }

  // --- STEP 3: SNAPSHOT ---
  Widget _buildSnapshotStep() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_enhance_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text("Snapshot Verification", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            "Take a quick photo of your parcel. This helps riders bring the right equipment and reduces price disputes.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
          const SizedBox(height: 48),
          if (_parcelImage != null)
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(_parcelImage!, height: 200, width: 200, fit: BoxFit.cover),
                ),
                Positioned(
                  top: -10,
                  right: -10,
                  child: GestureDetector(
                    onTap: () => setState(() => _parcelImage = null),
                    child: const CircleAvatar(backgroundColor: Colors.red, radius: 15, child: Icon(Icons.close, color: Colors.white, size: 15)),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text("Open Camera"),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
        ],
      ),
    );
  }

  // --- STEP 4: PREFERENCES ---
  Widget _buildPreferenceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Delivery Method", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildVehicleOption('Bike', 'Fastest for small items', Icons.motorcycle),
          _buildVehicleOption('Van', 'Best for bulky boxes', Icons.local_shipping),
          _buildVehicleOption('Truck', 'Pallets & Furniture', Icons.fire_truck),
          const SizedBox(height: 32),
          Text("Service Speed", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTierCard('Standard', '30-45 mins', AppTheme.primaryBlue, 'Standard'),
          _buildTierCard('Giga Expo', 'Instant (15-20 mins)', AppTheme.primaryRed, 'Expo'),
          
          const SizedBox(height: 32),
          Text("Timing", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Schedule for later"),
            value: isScheduled,
            activeColor: AppTheme.primaryBlue,
            onChanged: (val) => setState(() => isScheduled = val),
          ),
          if (isScheduled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null) setState(() => scheduledDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(scheduledDate != null ? DateFormat('MMM dd, yyyy').format(scheduledDate!) : "Select Date"),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: scheduledTime ?? const TimeOfDay(hour: 10, minute: 0));
                      if (time != null) setState(() => scheduledTime = time);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(scheduledTime != null ? scheduledTime!.format(context) : "Select Time"),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleOption(String label, String desc, IconData icon) {
    final isSelected = selectedVehicle == label;
    return GestureDetector(
      onTap: () {
        setState(() => selectedVehicle = label);
        _updateEstimation();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppTheme.primaryBlue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  Text(desc, style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(String label, String timing, Color color, String value) {
    final isSelected = selectedTier == value;
    return RadioListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(timing),
      value: value,
      groupValue: selectedTier,
      activeColor: color,
      onChanged: (val) {
        setState(() => selectedTier = val!);
        _updateEstimation();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // --- STEP 5: REVIEW ---
  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Confirm Booking", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildReviewItem("Pickup", _pickupController.text.isEmpty ? 'From Postcode' : _pickupController.text, Icons.my_location),
          _buildReviewItem("Drop-off", _dropoffController.text.isEmpty ? 'To Postcode' : _dropoffController.text, Icons.location_on),
          _buildReviewItem("Parcel", "$selectedSize ($selectedCategory)", Icons.inventory),
          _buildReviewItem("Vehicle", "$selectedVehicle ($selectedTier)", Icons.local_shipping),
          if (isScheduled)
            _buildReviewItem("Scheduled For", 
              "${DateFormat('MMM dd').format(scheduledDate!)} at ${scheduledTime!.format(context)}", 
              Icons.calendar_today
            ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Text("Safety First", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text("By clicking Book Now, you confirm the parcel contains no hazardous or illegal materials according to UK law.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String val, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomBar(DeliveryState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Total Estimate", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(
                state.estimation != null ? "${ref.watch(authProvider).currencySymbol}${state.estimation!.finalFare.toStringAsFixed(2)}" : "-",
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              if (_currentStep < 4) _nextStep();
              else {
                // Final confirm logic
                final req = DeliveryRequest(
                  pickupAddress: _pickupPostcode.text,
                  pickupLat: pickupLatLng?.latitude ?? 0,
                  pickupLng: pickupLatLng?.longitude ?? 0,
                  dropoffAddress: _dropoffPostcode.text,
                  dropoffLat: dropoffLatLng?.latitude ?? 0,
                  dropoffLng: dropoffLatLng?.longitude ?? 0,
                  vehicleType: selectedVehicle,
                  serviceTier: selectedTier,
                  parcelCategory: selectedCategory,
                  parcelSize: selectedSize,
                  fare: state.estimation?.finalFare ?? 0,
                  scheduledTime: isScheduled && scheduledDate != null && scheduledTime != null
                      ? DateTime(scheduledDate!.year, scheduledDate!.month, scheduledDate!.day, scheduledTime!.hour, scheduledTime!.minute)
                      : null,
                );
                context.push('/checkout', extra: req);
              }
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text(_currentStep == 4 ? "Pay Now" : "Continue", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
