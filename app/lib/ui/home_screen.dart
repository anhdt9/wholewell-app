import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import 'common/log_sheet.dart';
import 'diary_screen.dart';
import 'me_screen.dart';
import 'supplements_screen.dart';
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
    const pages = [TodayScreen(), DiaryScreen(), SupplementsScreen(), MeScreen()];
    return Scaffold(
      appBar: AppBar(
        title: Text(['Hôm nay', 'Nhật ký', 'Bổ sung', 'Tôi'][_tab]),
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
      floatingActionButton: _tab < 2
          ? FloatingActionButton.extended(
              heroTag: 'log_sheet',
              icon: const Icon(Icons.add),
              label: const Text('Ghi'),
              onPressed: () => showLogSheet(context),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.insights), label: 'Hôm nay'),
          NavigationDestination(icon: Icon(Icons.restaurant), label: 'Nhật ký'),
          NavigationDestination(icon: Icon(Icons.medication_outlined), label: 'Bổ sung'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Tôi'),
        ],
      ),
    );
  }
}
