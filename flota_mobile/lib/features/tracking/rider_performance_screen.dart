import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';

class RiderPerformanceScreen extends ConsumerWidget {
  const RiderPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Performance Insights', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPerformanceHeader(),
            const SizedBox(height: 24),
            _buildInsightGrid(),
            const SizedBox(height: 32),
            _buildChartPlaceholder(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderBlue),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryBlue,
            child: Icon(Icons.trending_up, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overall Rating', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('4.9', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _InsightCard(label: 'Acceptance', value: '98%', icon: Icons.check_circle_outline, color: AppTheme.successGreen),
        _InsightCard(label: 'Cancellation', value: '1.2%', icon: Icons.cancel_outlined, color: AppTheme.primaryRed),
        _InsightCard(label: 'On-Time', value: '95%', icon: Icons.timer_outlined, color: AppTheme.accentCyan),
        _InsightCard(label: 'Distance', value: '420 km', icon: Icons.route_outlined, color: AppTheme.primaryBlue),
      ],
    );
  }

  Widget _buildChartPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderBlue),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, color: AppTheme.borderBlue, size: 48),
            const SizedBox(height: 12),
            Text('Activity Analysis Coming Soon', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InsightCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
