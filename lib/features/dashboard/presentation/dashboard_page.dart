// lib/features/dashboard/presentation/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../members/presentation/add_member_page.dart';
import '../../subscriptions/presentation/subscription_popup.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/summary_card.dart';

class DashboardPage extends StatefulWidget {
  final String userId;
  const DashboardPage({super.key, required this.userId});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _popupShown = false;

  @override
  Widget build(BuildContext context) {
    // Self-contained provider: ensures DashboardProvider exists for this page
    return ChangeNotifierProvider<DashboardProvider>(
      create: (_) {
        final p = DashboardProvider(ownerId: widget.userId);
        // start loading data
        p.fetchAllData();
        return p;
      },
      builder: (context, _) {
        // Now this context *has* the provider
        final provider = Provider.of<DashboardProvider>(context);

        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!_popupShown && (provider.expiryDate == null || !provider.isTrialActive)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _popupShown = true;
            SubscriptionPopup.show(context);
          });
        }

        final summary = provider.getSummary();

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    SummaryCard(
                      title: "Active Members",
                      value: '${summary['active']}',
                      color: Colors.green.shade400,
                    ),
                    SummaryCard(
                      title: "Expiring in 10 Days",
                      value: '${summary['expiring']}',
                      color: Colors.orange.shade400,
                    ),
                    SummaryCard(
                      title: "Expired Members",
                      value: '${summary['expired']}',
                      color: Colors.red.shade400,
                    ),
                    SummaryCard(
                      title: "Today's Leads",
                      value: '${summary['transactions']}',
                      color: Colors.grey.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  "🎂 Birthdays Today",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildBirthdayList(provider),

                const SizedBox(height: 20),

                const Text(
                  "⚠️ Expired Members",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildExpiredList(provider),

                const SizedBox(height: 20),

                if (provider.expiryDate != null)
                  Text(
                    "Subscription expires on: ${DateFormat('dd/MM/yyyy').format(provider.expiryDate!)}",
                    style: const TextStyle(fontSize: 16),
                  )
                else
                  const Text("No active subscription", style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add, size: 30, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddMemberPage()),
              );
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  Widget _buildBirthdayList(DashboardProvider provider) {
    final birthdays = provider.getBirthdaysToday();
    if (birthdays.isEmpty) return const Text("No birthdays today 🎉");

    return Column(
      children: birthdays.map((member) {
        final name = member['memberName'] ?? 'Unnamed';
        return Card(
          color: Colors.pink.shade100,
          child: ListTile(
            leading: const Icon(Icons.cake, color: Colors.pink),
            title: Text(name),
            subtitle: const Text("Wish them a Happy Birthday! 🎂"),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpiredList(DashboardProvider provider) {
    final expiredMembers = provider.getExpiredMembers();
    if (expiredMembers.isEmpty) return const Text("No expired members 🎉");

    return Column(
      children: expiredMembers.map((member) {
        final name = member['memberName'] ?? 'Unnamed';
        return Card(
          color: Colors.red.shade100,
          child: ListTile(
            leading: const Icon(Icons.warning, color: Colors.red),
            title: Text(name),
            subtitle: const Text("Membership expired"),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => provider.renewSubscription(),
              child: const Text("Renew"),
            ),
          ),
        );
      }).toList(),
    );
  }
}
