// lib/features/dashboard/presentation/main_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../members/presentation/members_page.dart';
import '../../members/presentation/add_member_page.dart';
import '../../subscriptions/presentation/subscription_popup.dart';
import '../../transactions/presentation/transactions_page.dart';
import '../../reports/presentation/reports_page.dart';
import '../providers/dashboard_provider.dart';
import 'dashboard_tab.dart';

class MainPage extends StatefulWidget {
  final String userId;
  const MainPage({super.key, required this.userId});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  bool _popupShown = false;

  @override
  void initState() {
    super.initState();
    // _checkTrial will run after the first frame — provider will be present.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTrial());
  }

  Future<void> _checkTrial() async {
    final provider = context.read<DashboardProvider>();
    await provider.fetchAllData();

    if (!_popupShown && !provider.isTrialActive && mounted) {
      _popupShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SubscriptionPopup.show(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardProvider>(
      create: (_) {
        final p = DashboardProvider(ownerId: widget.userId);
        // start loading data in background
        p.fetchAllData();
        return p;
      },
      child: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          final screens = [
            DashboardTab(userId: widget.userId),
            const MembersPage(),
            const TransactionsPage(),
            const ReportsPage(),
          ];

          return Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
            floatingActionButton: _currentIndex == 0
                ? FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddMemberPage(),
                        ),
                      );
                    },
                    child: const Icon(Icons.add),
                  )
                : null,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              onTap: (index) => setState(() => _currentIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: "Dashboard",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: "Members",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.payment),
                  label: "Transactions",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: "Reports",
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
