import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart'; // TODO: Enable for avatar upload

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _company;
  String? _contact;
  String? _avatarUrl;
  File? _avatarFile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _name = data['name'] ?? '';
        _company = data['company'] ?? '';
        _contact = data['contact'] ?? '';
        _avatarUrl = data['avatarUrl'];
      });
    } else {
      setState(() {
        _name = user!.displayName ?? '';
        _company = '';
        _contact = user!.email ?? '';
        _avatarUrl = user!.photoURL;
      });
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
      // TODO: Upload to Firebase Storage and get URL
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    _formKey.currentState!.save();
    String? avatarUrl = _avatarUrl;
    // TODO: If _avatarFile != null, upload to Firebase Storage and get URL
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'name': _name,
      'company': _company,
      'contact': _contact,
      'avatarUrl': avatarUrl,
    }, SetOptions(merge: true));
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved.')));
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: CircleAvatar(
                          radius: 48,
                          backgroundImage: _avatarFile != null
                              ? FileImage(_avatarFile!)
                              : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null) as ImageProvider?,
                          child: _avatarFile == null && _avatarUrl == null
                              ? const Icon(Icons.person, size: 48)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      onSaved: (v) => _name = v,
                    ),
                    TextFormField(
                      initialValue: _company,
                      decoration: const InputDecoration(labelText: 'Company'),
                      onSaved: (v) => _company = v,
                    ),
                    TextFormField(
                      initialValue: _contact,
                      decoration: const InputDecoration(labelText: 'Contact'),
                      onSaved: (v) => _contact = v,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      onPressed: _saveProfile,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: _logout,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
