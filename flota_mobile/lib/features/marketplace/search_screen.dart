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

    // Generic Address Search (Mock)
    if (query.length > 3) {
        setState(() {
          _results = [
            '📍 123 Main St, Lagos',
            '📍 Big Ben, London',
            '📍 Previous: 55 Mole St',
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
            hintText: 'Search address or location...',
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
