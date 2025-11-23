// lib/features/members/presentation/add_member_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../members/models/member_model.dart';
import '../data/member_repository.dart';

class AddMemberPage extends StatefulWidget {
  final MemberModel? existingMember; // optional for editing

  const AddMemberPage({super.key, this.existingMember});

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = MemberRepository();
  final _picker = ImagePicker();
  final _storage = FirebaseStorage.instance;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _planCtrl;

  late DateTime _startDate;
  late DateTime _expiryDate;
  File? _imageFile;

  bool get isEditing => widget.existingMember != null;

  @override
  void initState() {
    super.initState();

    _nameCtrl = TextEditingController(text: widget.existingMember?.name ?? "");
    _phoneCtrl = TextEditingController(text: widget.existingMember?.phone ?? "");
    _emailCtrl = TextEditingController(text: widget.existingMember?.email ?? "");
    _planCtrl = TextEditingController(text: widget.existingMember?.plan ?? "");

    _startDate = widget.existingMember?.startDate ?? DateTime.now();
    _expiryDate = widget.existingMember != null
        ? widget.existingMember!.calculateMembershipEnd()
        : _startDate.add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _planCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _expiryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _expiryDate = _startDate.add(Duration(days: widget.existingMember?.durationDays ?? 30));
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(String memberId) async {
    if (_imageFile == null) return widget.existingMember?.photoUrl;
    final ref = _storage.ref().child('member_photos/$memberId.jpg');
    await ref.putFile(_imageFile!);
    return await ref.getDownloadURL();
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    final memberId = isEditing ? widget.existingMember!.id : _repo.newId();
    final currentOwnerId = FirebaseAuth.instance.currentUser?.uid ?? '';

    String? photoUrl = await _uploadImage(memberId);

    final newMember = MemberModel(
      id: memberId,
      ownerId: currentOwnerId,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      plan: _planCtrl.text.trim(),
      startDate: _startDate,
      durationDays: _expiryDate.difference(_startDate).inDays,
      photoUrl: photoUrl,
      createdAt: widget.existingMember?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (isEditing) {
      await _repo.updateMember(newMember);
    } else {
      await _repo.addMember(newMember);
    }

    if (!mounted) return;
    Navigator.pop(context, newMember);
  }

  Future<void> _deleteMember() async {
    if (!isEditing) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to delete ${widget.existingMember!.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repo.deleteMember(widget.existingMember!.id);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Widget _buildPhotoSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: _imageFile != null
                ? FileImage(_imageFile!)
                : (widget.existingMember?.photoUrl != null
                    ? NetworkImage(widget.existingMember!.photoUrl!)
                    : null) as ImageProvider?,
            child: _imageFile == null && widget.existingMember?.photoUrl == null
                ? const Icon(Icons.person, size: 60, color: Colors.white70)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: () => _pickImage(fromCamera: true),
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colors.black54)),
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.white),
                  onPressed: () => _pickImage(fromCamera: false),
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colors.black54)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime? date, VoidCallback onTap) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.grey.withOpacity(0.1),
      title: Text(date != null
          ? "$label: ${date.toLocal().toString().split(" ")[0]}"
          : "$label: Not set"),
      trailing: const Icon(Icons.date_range),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Member" : "Add Member"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveMember,
            tooltip: "Save",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildPhotoSection(),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v!.isEmpty ? "Enter name" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone",
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (v) =>
                    v!.length < 10 ? "Enter valid phone" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (v) => v!.isNotEmpty && !v.contains("@")
                    ? "Enter valid email"
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _planCtrl,
                decoration: const InputDecoration(
                  labelText: "Plan (e.g., Monthly, Yearly)",
                  prefixIcon: Icon(Icons.card_membership),
                ),
                validator: (v) => v!.isEmpty ? "Enter plan" : null,
              ),
              const SizedBox(height: 20),
              _buildDateTile("Start Date", _startDate, () => _pickDate(isStart: true)),
              const SizedBox(height: 8),
              _buildDateTile("Expiry Date", _expiryDate, () => _pickDate(isStart: false)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveMember,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? "Update Member" : "Add Member"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  textStyle:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              if (isEditing)
                OutlinedButton.icon(
                  onPressed: _deleteMember,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Delete Member"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    foregroundColor: Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
