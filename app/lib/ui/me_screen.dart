import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import 'backup_restore_screen.dart';
import 'day_times_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_screen.dart';
import 'profile_screen.dart';
import 'sources_screen.dart';

/// Tab Tôi: Hồ sơ, Hiển thị, Giờ trong ngày, Nhắc giờ, Sao lưu và khôi phục, Quyền riêng tư, Nguồn số liệu.
class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  static String _mealSummary(DayTimesSettings s) {
    final parts = <String>[
      if (s.hasBreakfast) 'Sáng ${formatMinutesHhMm(s.breakfast)}',
      if (s.hasLunch) 'Trưa ${formatMinutesHhMm(s.lunch)}',
      if (s.hasDinner) 'Tối ${formatMinutesHhMm(s.dinner)}',
    ];
    return parts.isEmpty ? 'Chỉ bữa phụ' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = state.profile;
    final profileSummary = p == null
        ? 'Chưa có thông tin'
        : '${p.sex == Sex.female ? 'Nữ' : 'Nam'} · ${p.ageYears} tuổi · '
            '${p.heightCm.round()} cm · ${p.weightKg.round()} kg';
    final lastBackup = state.lastFileBackupAt;
    final backupSummary = lastBackup == null
        ? 'Chưa sao lưu qua tệp'
        : 'Lần gần nhất: ${fmtBackupDateTime(lastBackup)}';

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(
          minTileHeight: 56,
          leading: const Icon(Icons.person_outline),
          title: const Text('Hồ sơ'),
          subtitle: Text(profileSummary),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
          ),
        ),
        ListTile(
          minTileHeight: 56,
          leading: const Icon(Icons.visibility_outlined),
          title: const Text('Hiển thị'),
          subtitle: Text(state.hideCalories ? 'Đang ẩn số calo' : 'Đang hiện số calo'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const DisplaySettingsScreen()),
          ),
        ),
        ListTile(
          minTileHeight: 56,
          leading: const Icon(Icons.schedule_outlined),
          title: const Text('Giờ trong ngày'),
          subtitle: Text(_mealSummary(state.dayTimesSettings)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const DayTimesScreen()),
          ),
        ),
        ListTile(
          minTileHeight: 56,
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Nhắc giờ'),
          subtitle: Text(state.notificationsEnabled ? 'Đang bật' : 'Chưa bật'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const NotificationSettingsScreen()),
          ),
        ),
        ListTile(
          minTileHeight: 56,
          leading: const Icon(Icons.backup_outlined),
          title: const Text('Sao lưu và khôi phục'),
          subtitle: Text(backupSummary),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const BackupRestoreScreen()),
          ),
        ),
        ListTile(
          minTileHeight: 56,
          leading: const Icon(Icons.lock_outline),
          title: const Text('Quyền riêng tư'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
          ),
        ),
        ListTile(
          minTileHeight: 56,
          leading: const Icon(Icons.menu_book_outlined),
          title: const Text('Nguồn số liệu'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SourcesScreen()),
          ),
        ),
      ],
    );
  }
}

/// Cài đặt Hiển thị (`Tôi -> Hiển thị`): công tắc Ẩn số calo.
class DisplaySettingsScreen extends StatelessWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Hiển thị')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          SwitchListTile(
            title: const Text('Ẩn số calo'),
            subtitle: const Text('App vẫn tính, chỉ không hiện con số.'),
            value: state.hideCalories,
            onChanged: state.setHideCalories,
          ),
          SwitchListTile(
            title: const Text('Hiện thẻ "Bạn có biết"'),
            subtitle: const Text('Mỗi ngày một câu từ quy tắc lịch dùng sản phẩm trong kho.'),
            value: state.dayTimesSettings.showTipCard,
            onChanged: state.diary.saveShowTipCard,
          ),
        ],
      ),
    );
  }
}
