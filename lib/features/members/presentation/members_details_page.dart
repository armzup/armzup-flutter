// lib/features/members/presentation/members_details_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../providers/member_provider.dart';
import 'add_member_page.dart';
import '../../members/models/member_model.dart';

/// Extension for member status colors and text
extension MemberStatus on MemberModel {
  Color getStatusColor() {
    if (isExpired()) return Colors.red;
    if (isExpiringSoon()) return Colors.orange;
    return Colors.green;
  }

  String getStatusText() => getMembershipStatus();
}

/// Reusable Card Container
class CardContainer extends StatelessWidget {
  final Widget child;
  const CardContainer({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class MemberDetailsPage extends StatefulWidget {
  final MemberModel member;

  const MemberDetailsPage({super.key, required this.member});

  @override
  State<MemberDetailsPage> createState() => _MemberDetailsPageState();
}

class _MemberDetailsPageState extends State<MemberDetailsPage> {
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUser();
  }

  void _currentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) _currentUserId = user.uid;
  }

  String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy hh:mm a').format(date);
  }

  /// Helper to format phone numbers for WhatsApp & calls
  String formatPhoneNumber(String phone) {
    String formatted = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!formatted.startsWith('+')) {
      formatted = formatted.replaceFirst(RegExp(r'^0+'), '');
      formatted = formatted.length == 10 ? '+91$formatted' : '+$formatted';
    }
    return formatted;
  }

  /// Snackbars
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  /// Communication actions
  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email, queryParameters: {'subject': 'Gym Membership - ${widget.member.name}'});
    if (await canLaunchUrl(uri)) await launchUrl(uri);
    else _showError('Cannot open email app');
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: formatPhoneNumber(phone));
    if (await canLaunchUrl(uri)) await launchUrl(uri);
    else _showError('Cannot make phone calls');
  }

  Future<void> _launchSMS(String phone) async {
    final uri = Uri(
      scheme: 'sms',
      path: formatPhoneNumber(phone),
      queryParameters: {'body': 'Hello ${widget.member.name}, this is regarding your gym membership.'},
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
    else _showError('Cannot send SMS');
  }

  Future<void> _launchWhatsApp(String phone) async {
    final formatted = formatPhoneNumber(phone).replaceAll('+', '');
    final message = Uri.encodeComponent('Hello ${widget.member.name}, this is regarding your gym membership.');
    final uri = Uri.parse("https://wa.me/$formatted?text=$message");
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    else _showError('WhatsApp not installed');
  }

  /// Edit member
  Future<void> _editMember() async {
    if (_currentUserId == null) return _showError('User not authenticated');
    final result = await Navigator.push<MemberModel>(
      context,
      MaterialPageRoute(builder: (_) => AddMemberPage(existingMember: widget.member)),
    );
    if (result != null && mounted) {
      _showSuccess('Member updated successfully');
      Navigator.pop(context, {'action': 'update', 'data': result});
    }
  }

  /// Delete member
  Future<void> _deleteMember() async {
    if (_currentUserId == null) return _showError('User not authenticated');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Delete Member"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Are you sure you want to delete ${widget.member.name}?"),
            const SizedBox(height: 8),
            const Text("This action cannot be undone.", style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final provider = Provider.of<MemberProvider>(context, listen: false);
        final success = await provider.deleteMember(widget.member.id);
        if (success && mounted) {
          _showSuccess('Member deleted successfully');
          Navigator.pop(context, {'action': 'delete', 'data': widget.member});
        } else if (mounted) _showError(provider.error ?? 'Failed to delete member');
      } catch (e) {
        if (mounted) _showError('Error: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  /// Reusable Info Card
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return CardContainer(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: valueColor)),
                ],
              ),
            ),
            if (onTap != null) Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  /// Reusable Action Button
  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onPressed}) {
    return Expanded(
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [Icon(icon, color: color, size: 24), const SizedBox(height: 4), Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final photo = widget.member.photoUrl ?? widget.member.photoPath;
    if (photo == null || (widget.member.photoPath != null && !File(widget.member.photoPath!).existsSync())) {
      return Container(color: Colors.grey[300], child: const Icon(Icons.person, size: 50));
    }
    if (widget.member.photoUrl != null) return Image.network(widget.member.photoUrl!, width: 100, height: 100, fit: BoxFit.cover);
    return Image.file(File(widget.member.photoPath!), width: 100, height: 100, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.grey[50];
    final statusColor = widget.member.getStatusColor();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Member Details"),
        backgroundColor: isDark ? Colors.grey[850] : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
              ),
            )
          else ...[
            IconButton(icon: const Icon(Icons.edit), onPressed: _editMember, tooltip: 'Edit Member'),
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteMember, tooltip: 'Delete Member'),
          ]
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Section
                CardContainer(
                  child: Column(
                    children: [
                      Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: statusColor, width: 3)), child: ClipOval(child: _buildProfileImage())),
                      const SizedBox(height: 16),
                      Text(widget.member.name, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.3))),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(widget.member.getStatusText(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Quick Actions
                if ((widget.member.email ?? '').isNotEmpty || (widget.member.phone ?? '').isNotEmpty)
                  CardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if ((widget.member.phone ?? '').isNotEmpty) ...[
                              _buildActionButton(icon: Icons.phone, label: 'Call', color: Colors.green, onPressed: () => _launchPhone(widget.member.phone!)),
                              _buildActionButton(icon: Icons.message, label: 'SMS', color: Colors.blue, onPressed: () => _launchSMS(widget.member.phone!)),
                              _buildActionButton(icon: FontAwesomeIcons.whatsapp, label: 'WhatsApp', color: Colors.green, onPressed: () => _launchWhatsApp(widget.member.phone!)),
                            ],
                            if ((widget.member.email ?? '').isNotEmpty)
                              _buildActionButton(icon: Icons.email, label: 'Email', color: Colors.red, onPressed: () => _launchEmail(widget.member.email!)),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Member Information
                CardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Member Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 16),
                      _buildInfoCard(icon: Icons.fitness_center, title: 'Plan', value: widget.member.plan),
                      _buildInfoCard(icon: Icons.currency_rupee, title: 'Fee', value: '₹${widget.member.fee.toStringAsFixed(0)}', valueColor: Colors.green),
                      _buildInfoCard(icon: Icons.calendar_today, title: 'Start Date', value: formatDate(widget.member.startDate)),
                      _buildInfoCard(icon: Icons.event, title: 'Membership Expires', value: formatDate(widget.member.calculateMembershipEnd()), valueColor: statusColor),
                      _buildInfoCard(icon: Icons.timer, title: 'Days Remaining', value: '${widget.member.getDaysRemaining()} days', valueColor: statusColor),
                      if ((widget.member.email ?? '').isNotEmpty) _buildInfoCard(icon: Icons.email, title: 'Email', value: widget.member.email!, onTap: () => _launchEmail(widget.member.email!)),
                      if ((widget.member.phone ?? '').isNotEmpty) _buildInfoCard(icon: Icons.phone, title: 'Phone', value: widget.member.phone!, onTap: () => _launchPhone(widget.member.phone!)),
                      if (widget.member.dob != null) _buildInfoCard(icon: Icons.cake, title: 'Date of Birth', value: formatDate(widget.member.dob!)),
                      if ((widget.member.notes ?? '').isNotEmpty) _buildInfoCard(icon: Icons.note, title: 'Notes', value: widget.member.notes!),
                      _buildInfoCard(icon: Icons.access_time, title: 'Member Since', value: formatDateTime(widget.member.createdAt)),
                      if (widget.member.updatedAt != null) _buildInfoCard(icon: Icons.update, title: 'Last Updated', value: formatDateTime(widget.member.updatedAt!)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) Container(color: Colors.black38, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}
