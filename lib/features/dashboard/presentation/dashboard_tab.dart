// lib/features/dashboard/presentation/dashboard_tab.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardTab extends StatelessWidget {
  final String userId;
  const DashboardTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    // Do NOT create a provider here — MainPage supplies it.
    final provider = Provider.of<DashboardProvider>(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = provider.getSummary();
    final birthdays = provider.getBirthdaysToday();
    final expired = provider.getExpiredMembers();

    return RefreshIndicator(
      onRefresh: provider.fetchAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Subscription Info
            Card(
              color: isDark ? Colors.grey[850] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
                title: Text(
                  "Subscription",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor),
                ),
                subtitle: Text(
                  provider.expiryDate != null
                      ? "Expires on: ${provider.expiryDate!.toLocal().toString().split(' ')[0]}"
                      : "No subscription found",
                  style: TextStyle(color: textColor.withOpacity(0.7)),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.blueGrey : Colors.blue,
                  ),
                  onPressed: provider.renewSubscription,
                  child: const Text("Renew"),
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// Summary Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildSummaryCard(
                    "Active", summary['active'] ?? 0, Colors.green, isDark),
                _buildSummaryCard(
                    "Expiring", summary['expiring'] ?? 0, Colors.orange, isDark),
                _buildSummaryCard(
                    "Expired", summary['expired'] ?? 0, Colors.red, isDark),
                _buildSummaryCard(
                    "Transactions", summary['transactions'] ?? 0, Colors.blue, isDark),
              ],
            ),
            const SizedBox(height: 24),

            /// Birthdays Today
            if (birthdays.isNotEmpty) ...[
              Text(
                "🎂 Birthdays Today",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              ...birthdays.map((m) => Card(
                color: isDark ? Colors.grey[850] : Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.cake, color: Colors.pink),
                  title: Text(m['name'] ?? "Unknown",
                      style: TextStyle(color: textColor)),
                  subtitle: Text("Happy Birthday!",
                      style: TextStyle(color: textColor.withOpacity(0.7))),
                ),
              )),
              const SizedBox(height: 24),
            ],

            /// Expired Members
            if (expired.isNotEmpty) ...[
              Text(
                "⚠️ Expired Members",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              ...expired.map((m) => Card(
                color: isDark ? Colors.grey[850] : Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(m['name'] ?? "Unknown",
                      style: TextStyle(color: textColor)),
                  subtitle: Text("Membership expired",
                      style: TextStyle(color: textColor.withOpacity(0.7))),
                ),
              )),
              const SizedBox(height: 24),
            ],

            /// Recent Transactions
            Text(
              "💳 Recent Transactions",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            ...provider.txns.take(5).map((txn) {
              final createdAt =
                  (txn['createdAt'] as Timestamp?)?.toDate().toString() ?? '';
              return Card(
                color: isDark ? Colors.grey[850] : Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.payment, color: Colors.blue),
                  title: Text("₹${txn['amount'] ?? 0}",
                      style: TextStyle(color: textColor)),
                  subtitle: Text("Plan: ${txn['plan'] ?? 'N/A'}",
                      style: TextStyle(color: textColor.withOpacity(0.7))),
                  trailing: Text(
                    createdAt.split(' ')[0],
                    style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, int count, Color color, bool isDark) {
    return Card(
      color: isDark ? Colors.grey[900] : color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("$count",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }
}
