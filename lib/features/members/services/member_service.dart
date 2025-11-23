// lib/features/members/services/member_service.dart
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../models/member_model.dart';
import '../data/member_repository.dart';

class MemberService {
  final MemberRepository _repository = MemberRepository();

  // Add a new member
  Future<bool> addMember(MemberModel member) async {
    try {
      await _repository.addMember(member);
      return true;
    } catch (e) {
      print('Add member error: $e');
      return false;
    }
  }

  // Update an existing member
  Future<bool> updateMember(MemberModel member) async {
    try {
      await _repository.updateMember(member);
      return true;
    } catch (e) {
      print('Update member error: $e');
      return false;
    }
  }

  // Delete a member by ID
  Future<bool> deleteMember(String memberId) async {
    try {
      await _repository.deleteMember(memberId);
      return true;
    } catch (e) {
      print('Delete member error: $e');
      return false;
    }
  }

  // Fetch all members for a specific owner
  Future<List<MemberModel>> fetchMembers(String ownerId) async {
    try {
      return await _repository.streamMembers(ownerId).first;
    } catch (e) {
      print('Fetch members error: $e');
      return [];
    }
  }

  // Launch phone call
  Future<void> callMember(String phone) async {
    final formatted = _formatPhone(phone);
    final uri = Uri.parse("tel:$formatted");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // Send SMS
  Future<void> messageMember(String phone) async {
    final formatted = _formatPhone(phone);
    final uri = Uri.parse("sms:$formatted");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // Open WhatsApp chat
  Future<void> whatsappMember(String phone) async {
    final formatted = _formatPhone(phone).replaceAll('+', '');
    final uri = Uri.parse("https://wa.me/$formatted");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // Format phone number for calling/WhatsApp
  String _formatPhone(String phone) {
    String formatted = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!formatted.startsWith('+')) {
      formatted = formatted.length == 10 ? '+91$formatted' : '+$formatted';
    }
    return formatted;
  }
}
