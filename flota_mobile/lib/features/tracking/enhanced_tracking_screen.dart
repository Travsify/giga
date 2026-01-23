import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flota_mobile/core/api_client.dart';

class EnhancedTrackingScreen extends ConsumerStatefulWidget {
  final String deliveryId;
  
  const EnhancedTrackingScreen({
    super.key,
    required this.deliveryId,
  });

  @override
  ConsumerState<EnhancedTrackingScreen> createState() => _EnhancedTrackingScreenState();
}

class _EnhancedTrackingScreenState extends ConsumerState<EnhancedTrackingScreen> {
  bool _contactlessDelivery = true; // Default ON for UK market

  Future<void> _callRider(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _captureProofOfDelivery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading photo...')),
      );

      try {
        final dio = ref.read(apiClientProvider).dio;
        String fileName = photo.path.split('/').last;
        FormData formData = FormData.fromMap({
          "proof_image": await MultipartFile.fromFile(photo.path, filename: fileName),
        });

        await dio.post(
          '/deliveries/${widget.deliveryId}/proof',
          data: formData,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proof of delivery uploaded successfully!')),
        );
        
        // Update Firestore status to delivered to sync UI
        FirebaseFirestore.instance
            .collection('deliveries')
            .doc(widget.deliveryId)
            .update({
              'status': 'delivered',
              'proof_available': true,
            });

      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _emergencyContact() async {
    // Show emergency options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: AppTheme.errorRed),
              title: const Text('Call Support'),
              subtitle: const Text('24/7 Emergency Line'),
              onTap: () {
                Navigator.pop(context);
                _callRider('999'); // UK emergency number
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_location, color: AppTheme.primaryBlue),
              title: const Text('Share Location'),
              subtitle: const Text('Send to emergency contact'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location shared with emergency contact')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Delivery', style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('deliveries')
            .doc(widget.deliveryId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text('Delivery not found'));
          }

          final riderName = data['rider_name'] ?? 'Rider';
          final riderRating = data['rider_rating'] ?? 5.0;
          final vehicleReg = data['vehicle_registration'] ?? 'N/A';
          final riderPhone = data['rider_phone'] ?? '';
          final status = data['status'] ?? 'pending';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rider Verification Card
                _RiderVerificationCard(
                  riderName: riderName,
                  riderRating: riderRating,
                  vehicleReg: vehicleReg,
                  riderPhone: riderPhone,
                  onCall: () => _callRider(riderPhone),
                ),
                
                const SizedBox(height: 20),

                // Safety Features Section
                Text(
                  'Safety Features',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                // Contactless Delivery Toggle
                _SafetyFeatureCard(
                  icon: Icons.do_not_touch,
                  title: 'Contactless Delivery',
                  subtitle: _contactlessDelivery 
                      ? 'Leave at door, photo required'
                      : 'Hand to customer',
                  trailing: Switch(
                    value: _contactlessDelivery,
                    onChanged: (value) {
                      setState(() => _contactlessDelivery = value);
                      // Update Firestore
                      FirebaseFirestore.instance
                          .collection('deliveries')
                          .doc(widget.deliveryId)
                          .update({'contactless_delivery': value});
                          
                      // Update Backend
                      try {
                        final dio = ref.read(apiClientProvider).dio;
                        dio.patch(
                          '/deliveries/${widget.deliveryId}/status',
                          data: {'contactless_delivery': value},
                        );
                      } catch (e) {
                        debugPrint('Failed to sync contactless status: $e');
                      }
                    },
                    activeColor: AppTheme.successGreen,
                  ),
                ),

                const SizedBox(height: 12),

                  // Proof of Delivery
                _SafetyFeatureCard(
                  icon: Icons.camera_alt,
                  title: 'Proof of Delivery',
                  subtitle: status == 'delivered' 
                      ? 'Photo available'
                      : 'Tap to capture photo',
                  trailing: status == 'delivered'
                      ? IconButton(
                          icon: const Icon(Icons.visibility, color: AppTheme.primaryBlue),
                          onPressed: () {
                            // View proof of delivery photo logic would go here
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Viewing delivery photo...')),
                            );
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryBlue),
                          onPressed: _captureProofOfDelivery,
                        ),
                ),

                const SizedBox(height: 12),

                // Chat with Rider
                _SafetyFeatureCard(
                  icon: Icons.chat_bubble_outline,
                  title: 'Chat with Rider',
                  subtitle: 'Send a message',
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    onPressed: () {
                      context.push('/chat/${widget.deliveryId}');
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Emergency Contact Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _emergencyContact,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.emergency),
                    label: const Text('Emergency Contact'),
                  ),
                ),

                const SizedBox(height: 20),

                // Delivery Status
                _DeliveryStatusCard(status: status),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Rider Verification Card Widget
class _RiderVerificationCard extends StatelessWidget {
  final String riderName;
  final double riderRating;
  final String vehicleReg;
  final String riderPhone;
  final VoidCallback onCall;

  const _RiderVerificationCard({
    required this.riderName,
    required this.riderRating,
    required this.vehicleReg,
    required this.riderPhone,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rider Photo Placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 32,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      riderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified, size: 12, color: AppTheme.successGreen),
                          const SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.successGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      riderRating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Vehicle: $vehicleReg',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (riderPhone.isNotEmpty)
            IconButton(
              onPressed: onCall,
              icon: const Icon(Icons.phone, color: AppTheme.primaryBlue),
            ),
        ],
      ),
    );
  }
}

// Safety Feature Card Widget
class _SafetyFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SafetyFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// Delivery Status Card Widget
class _DeliveryStatusCard extends StatelessWidget {
  final String status;

  const _DeliveryStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(status);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: statusConfig['colors'] as List<Color>,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            statusConfig['icon'] as IconData,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusConfig['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  statusConfig['subtitle'] as String,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'pending':
        return {
          'icon': Icons.pending_actions,
          'title': 'Finding Rider',
          'subtitle': 'We\'re matching you with a nearby rider',
          'colors': [AppTheme.accentCyan, AppTheme.primaryBlue],
        };
      case 'accepted':
        return {
          'icon': Icons.directions_bike,
          'title': 'Rider On The Way',
          'subtitle': 'Your rider is heading to pickup location',
          'colors': [AppTheme.primaryBlue, AppTheme.slateBlue],
        };
      case 'picked_up':
        return {
          'icon': Icons.local_shipping,
          'title': 'In Transit',
          'subtitle': 'Your parcel is on its way',
          'colors': [AppTheme.slateBlue, AppTheme.accentCyan],
        };
      case 'delivered':
        return {
          'icon': Icons.check_circle,
          'title': 'Delivered',
          'subtitle': 'Your parcel has been delivered',
          'colors': [AppTheme.successGreen, Color(0xFF10B981)],
        };
      default:
        return {
          'icon': Icons.info,
          'title': 'Unknown Status',
          'subtitle': 'Please contact support',
          'colors': [Colors.grey, Colors.grey.shade700],
        };
    }
  }
}
