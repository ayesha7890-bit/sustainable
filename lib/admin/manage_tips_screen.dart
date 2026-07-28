import 'package:flutter/material.dart';
import 'package:sustainable/database/database_helper.dart';

class ManageTipsScreen extends StatefulWidget {
  const ManageTipsScreen({super.key});

  @override
  State<ManageTipsScreen> createState() => _ManageTipsScreenState();
}

class _ManageTipsScreenState extends State<ManageTipsScreen> {
  // 🔥 SQLite Database se data store karne ke liye list
  List<Map<String, dynamic>> _tips = [];

  // Controllers to capture text from input fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTips(); // Screen load hote hi data database se aayega
  }

  // 📥 Database se pure travel/energy tips fetch karne ka function
  void _loadTips() async {
    final data = await DatabaseHelper.instance.fetchTravelTips();
    setState(() {
      _tips = data;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // 🗑️ Database se tip delete karne ka logic
  void _deleteTip(int id) async {
    await DatabaseHelper.instance.deleteTravelTip(id);
    _loadTips(); // List refresh
  }

  // ✨ DYNAMIC DIALOG: Add aur Edit dono ko handling ke liye combo dialog
  void _showTipDialog({Map<String, dynamic>? editMap}) {
    if (editMap != null) {
      // Edit Mode: Purana data controllers mein set karo
      _titleController.text = editMap['title'] ?? '';
      _descController.text = editMap['description'] ?? '';
    } else {
      // Add Mode: Fields ko empty karo
      _titleController.clear();
      _descController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2F4A3E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            editMap != null ? 'Edit Energy Tip' : 'Add New Energy Tip',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title Input Field
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Tip Title',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFCBBE9C)),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Description Input Field
              TextField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFCBBE9C)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCBBE9C),
                foregroundColor: const Color(0xFF2F4A3E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (_titleController.text.isNotEmpty && _descController.text.isNotEmpty) {
                  final tipData = {
                    'category': 'Energy', // Category hardcoded to Energy for this screen
                    'title': _titleController.text.trim(),
                    'description': _descController.text.trim(),
                  };

                  if (editMap != null) {
                    // ✏️ Database Update Command
                    await DatabaseHelper.instance.updateTravelTip(editMap['id'], tipData);
                  } else {
                    // ➕ Database Insert Command
                    await DatabaseHelper.instance.insertTravelTip(tipData);
                  }

                  if (!mounted) return;
                  Navigator.pop(context); // Dialog close
                  _loadTips(); // Database se updated list dobara load karo
                }
              },
              child: Text(
                editMap != null ? 'Update Tip' : 'Add Tip',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2F4A3E),
              Color(0xFF5E8570),
              Color(0xFFCBBE9C),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Manage Energy Tips',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Dynamic Tips List from Database
              Expanded(
                child: _tips.isEmpty
                    ? const Center(
                  child: Text(
                    'No tips added yet!',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _tips.length,
                  itemBuilder: (context, index) {
                    final tip = _tips[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bolt_rounded, color: Colors.amber, size: 24),
                        ),
                        title: Text(
                          tip['title'] ?? 'No Title',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            tip['description'] ?? 'No Description',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                        // Action Buttons Row (Edit + Delete)
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✏️ EDIT BUTTON
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.white70),
                              onPressed: () => _showTipDialog(editMap: tip),
                            ),
                            // 🗑️ DELETE BUTTON
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
                              onPressed: () => _deleteTip(tip['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // Plus Floating Button (Trigger Add Mode)
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFCBBE9C),
        onPressed: () => _showTipDialog(),
        child: const Icon(Icons.add_rounded, color: Color(0xFF2F4A3E)),
      ),
    );
  }
}