import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddTestScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;

  AddTestScreen({required this.hospitalId, required this.hospitalName});

  @override
  _AddTestScreenState createState() => _AddTestScreenState();
}

class _AddTestScreenState extends State<AddTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  String _testName = '';
  String _room = '';

  Future<void> _addTest() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        // 1. Add test to the testsavailable table
        await _supabase.from('testsavailable').insert({
          'name': _testName,
          'room': _room,
        });

        // 2. Update the hospital's testavailable column
        final hospitalResponse = await _supabase
            .from('hospital')
            .select('testavailable')
            .eq('hospitalIdd', widget.hospitalId)
            .single();

        List<String> currentTests =
            List<String>.from(hospitalResponse['testavailable'] ?? []);
        currentTests.add(_testName);

        await _supabase
            .from('hospital')
            .update({'testavailable': currentTests}).eq(
                'hospitalIdd', widget.hospitalId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test added successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding test: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Test to ${widget.hospitalName}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Test Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a test name';
                    }
                    return null;
                  },
                  onSaved: (value) => _testName = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Room',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a room';
                    }
                    return null;
                  },
                  onSaved: (value) => _room = value!,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _addTest,
                  child: Text(
                    'Add Test',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
