import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import 'diary_screen.dart';
import 'profile_screen.dart';
import 'today_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final d = state.day;
    final pages = [const TodayScreen(), const DiaryScreen(), const ProfileScreen()];
    return Scaffold(
      appBar: AppBar(
        title: Text(['Tổng kết', 'Nhật ký', 'Hồ sơ'][_tab]),
        actions: [
          if (_tab < 2)
            TextButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text('${d.day}/${d.month}/${d.year}'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: d,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) state.setDay(picked);
              },
            ),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.insights), label: 'Tổng kết'),
          NavigationDestination(icon: Icon(Icons.restaurant), label: 'Nhật ký'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}
