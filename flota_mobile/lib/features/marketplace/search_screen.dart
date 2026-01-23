import 'package:flutter/material.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _results = [];

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    // Regex for UK Postcode
    final postcodeRegex = RegExp(r'^([A-Z]{1,2}[0-9][A-Z0-9]? [0-9][ABD-HJLNP-UW-Z]{2})$', caseSensitive: false);

    if (postcodeRegex.hasMatch(query)) {
        setState(() {
          _results = [
            'Looking up ${query.toUpperCase()}...',
            '📍 Camden High Street, London',
            '📍 10 Downing Street',
          ];
        });
        return;
    }
    
    // Normal Search Logic
    setState(() {
      _results = [
        'Delivery to Camden',
        'Pickup from Soho',
        'Express Parcel #1234',
        'Locker Dropoff',
      ].where((element) => element.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search for deliveries, locations...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          onChanged: _onSearch,
        ),
        backgroundColor: AppTheme.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                   const SizedBox(height: 10),
                   Text('Start typing to search', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(_results[index]),
                  onTap: () {
                    // Handle selection
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected: ${_results[index]}')),
                    );
                  },
                );
              },
            ),
    );
  }
}
