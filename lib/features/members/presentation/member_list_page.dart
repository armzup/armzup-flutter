// lib/features/members/presentation/members_list_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/member_model.dart';
import '../providers/member_provider.dart';
import 'add_member_page.dart';
import 'members_details_page.dart';

class MembersListPage extends StatefulWidget {
  const MembersListPage({super.key});

  @override
  State<MembersListPage> createState() => _MembersListPageState();
}

class _MembersListPageState extends State<MembersListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _sortByExpiry = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<MemberProvider>(context, listen: false);
        provider.init(_currentUserId!);
      });
    }
  }

  String _formatPhone(String phone) {
    String formatted = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!formatted.startsWith('+')) {
      formatted = formatted.length == 10 ? '+91$formatted' : '+$formatted';
    }
    return formatted;
  }

  Future<void> _callMember(String phone) async {
    final uri = Uri.parse("tel:${_formatPhone(phone)}");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _messageMember(String phone) async {
    final uri = Uri.parse("sms:${_formatPhone(phone)}");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsappMember(String phone) async {
    final uri = Uri.parse("https://wa.me/${_formatPhone(phone).replaceAll('+', '')}");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  List<MemberModel> _filterMembers(List<MemberModel> members) {
    List<MemberModel> filtered = List.from(members);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((m) {
        final query = _searchQuery.toLowerCase();
        return m.name.toLowerCase().contains(query) ||
            (m.phone?.toLowerCase().contains(query) ?? false) ||
            (m.email?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    switch (_selectedFilter) {
      case 'Active':
        filtered = filtered.where((m) => !m.isExpired()).toList();
        break;
      case 'Expiring':
        filtered = filtered.where((m) => m.isExpiringSoon() && !m.isExpired()).toList();
        break;
      case 'Expired':
        filtered = filtered.where((m) => m.isExpired()).toList();
        break;
    }

    if (_sortByExpiry) {
      filtered.sort((a, b) => a.calculateMembershipEnd().compareTo(b.calculateMembershipEnd()));
    } else {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    return filtered;
  }

  Color _getStatusColor(MemberModel member) {
    if (member.isExpired()) return Colors.red.shade200;
    if (member.isExpiringSoon()) return Colors.orange.shade200;
    return Colors.green.shade200;
  }

  Future<void> _navigateToAddMember(MemberProvider provider, [MemberModel? member]) async {
    final result = await Navigator.push<MemberModel>(
      context,
      MaterialPageRoute(builder: (_) => AddMemberPage(existingMember: member)),
    );
    if (result != null) provider.refresh();
  }

  Future<void> _navigateToDetails(MemberProvider provider, MemberModel member) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MemberDetailsPage(member: member)),
    );
    if (result != null) provider.refresh();
  }

  Future<void> _deleteMember(MemberProvider provider, MemberModel member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to delete ${member.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Delete photo from Firebase Storage if exists
    if (member.photoUrl != null) {
      try {
        await FirebaseStorage.instance.refFromURL(member.photoUrl!).delete();
      } catch (_) {}
    }

    final success = await provider.deleteMember(member.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Member deleted successfully' : provider.error ?? 'Failed to delete'),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  Widget _buildMemberCard(MemberProvider provider, MemberModel member) {
    final color = _getStatusColor(member);
    final membershipEnd = member.calculateMembershipEnd();
    final daysRemaining = member.getDaysRemaining();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color.withOpacity(0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetails(provider, member),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: ClipOval(
                  child: member.photoUrl != null
                      ? Image.network(member.photoUrl!, fit: BoxFit.cover)
                      : (member.photoPath != null && File(member.photoPath!).existsSync()
                      ? Image.file(File(member.photoPath!), fit: BoxFit.cover)
                      : _buildInitialsAvatar(member.name, color)),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${member.plan} • ₹${member.fee.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(
                        '${DateFormat('dd MMM').format(member.startDate)} - ${DateFormat('dd MMM yyyy').format(membershipEnd)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text(
                      daysRemaining >= 0
                          ? daysRemaining == 0
                              ? 'Expires today'
                              : '$daysRemaining days remaining'
                          : 'Expired ${-daysRemaining} days ago',
                      style: TextStyle(
                        fontSize: 12,
                        color: member.isExpired()
                            ? Colors.red.shade800
                            : member.isExpiringSoon()
                                ? Colors.orange.shade800
                                : Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  if (member.phone != null && member.phone!.isNotEmpty)
                    IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => _callMember(member.phone!)),
                  if (member.phone != null && member.phone!.isNotEmpty)
                    IconButton(icon: const Icon(Icons.message, color: Colors.blue), onPressed: () => _messageMember(member.phone!)),
                  if (member.phone != null && member.phone!.isNotEmpty)
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
                      onPressed: () => _whatsappMember(member.phone!),
                    ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _navigateToAddMember(provider, member);
                  if (value == 'delete') _deleteMember(provider, member);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String name, Color color) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: color.withOpacity(0.2),
      child: Center(child: Text(initials, style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildSearchFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _searchQuery = ''; _searchController.clear(); }))
                  : null,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Members')),
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(value: 'Expiring', child: Text('Expiring Soon')),
                    DropdownMenuItem(value: 'Expired', child: Text('Expired')),
                  ],
                  onChanged: (val) => setState(() => _selectedFilter = val ?? 'All'),
                ),
              ),
              IconButton(
                icon: Icon(_sortByExpiry ? Icons.sort : Icons.sort_by_alpha),
                onPressed: () => setState(() => _sortByExpiry = !_sortByExpiry),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) return const Scaffold(body: Center(child: Text('Please log in')));

    return Consumer<MemberProvider>(
      builder: (context, provider, _) {
        final members = provider.members;
        final filtered = _filterMembers(members);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Members'),
                Text('${filtered.length} of ${members.length}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            actions: [IconButton(onPressed: provider.refresh, icon: const Icon(Icons.refresh))],
          ),
          body: provider.loading
              ? const Center(child: CircularProgressIndicator())
              : provider.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          Text('Error: ${provider.error}'),
                          ElevatedButton(onPressed: provider.refresh, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: provider.refresh,
                      child: Column(
                        children: [
                          _buildSearchFilter(),
                          Expanded(
                            child: filtered.isEmpty
                                ? Center(child: Text('No members found', style: TextStyle(fontSize: 18, color: Colors.grey[600])))
                                : ListView.builder(
                                    itemCount: filtered.length,
                                    itemBuilder: (ctx, i) => _buildMemberCard(provider, filtered[i]),
                                  ),
                          ),
                        ],
                      ),
                    ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _navigateToAddMember(provider),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
