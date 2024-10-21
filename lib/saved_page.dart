import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  _SavedPageState createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  List<String> savedProperties = [];

  @override
  void initState() {
    super.initState();
    _loadSavedProperties();
  }

  // Load saved properties from SharedPreferences
  Future<void> _loadSavedProperties() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedProperties = prefs.getStringList('savedProperties') ?? [];
    });
  }

  // Remove a property from saved list
  Future<void> _removeProperty(int index) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedProperties.removeAt(index);
    });
    await prefs.setStringList('savedProperties', savedProperties);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Properties', style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFFB46146),
      ),
      body: savedProperties.isEmpty
          ? const Center(
        child: Text(
          'No saved properties yet',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: savedProperties.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: Image.asset(
                savedProperties[index],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
              title: Text('Property ${index + 1}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Color(0xFFB46146)),
                onPressed: () {
                  _removeProperty(index); // Remove saved property
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Property removed')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
