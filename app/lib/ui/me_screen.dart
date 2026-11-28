import 'package:health_engine/health_engine.dart';
import 'package:journal_db/models.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import 'backup_restore_screen.dart';
import 'day_times_screen.dart';
import 'design_system/tokens.dart';
import 'notification_settings_screen.dart';
import 'privacy_screen.dart';
import 'profile_screen.dart';
import 'sources_screen.dart';

/// Tab Tôi: 4 nhóm thẻ (`Hồ sơ & Lịch sinh hoạt`, `Nhắc giờ & Hiển thị`, `Sao lưu`, `Quyền riêng tư & Nguồn`).
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
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final p = state.profile;
    final profileSummary = p == null
        ? 'Chưa có thông tin'
        : '${p.sex == Sex.female ? 'Nữ' : 'Nam'} · ${p.ageYears} tuổi · '
              '${p.heightCm.round()} cm · ${p.weightKg.round()} kg';
    final lastBackup = state.lastFileBackupAt;
    final backupSummary = lastBackup == null
        ? 'Chưa sao lưu qua tệp'
        : 'Lần gần nhất: ${fmtBackupDateTime(lastBackup)}';

    void push(Widget screen) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      children: [
        _MeGroupCard(
          header: 'Hồ sơ & Lịch sinh hoạt',
          textTheme: t,
          cs: cs,
          items: [
            _MeItem(
              icon: LucideIcons.user,
              title: 'Hồ sơ',
              subtitle: profileSummary,
              onTap: () => push(const ProfileScreen()),
            ),
            _MeItem(
              icon: LucideIcons.clock,
              title: 'Giờ trong ngày',
              subtitle: _mealSummary(state.dayTimesSettings),
              onTap: () => push(const DayTimesScreen()),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _MeGroupCard(
          header: 'Nhắc giờ & Hiển thị',
          textTheme: t,
          cs: cs,
          items: [
            _MeItem(
              icon: LucideIcons.bell,
              title: 'Nhắc giờ',
              subtitle: state.notificationsEnabled ? 'Đang bật' : 'Chưa bật',
              onTap: () => push(const NotificationSettingsScreen()),
            ),
            _MeItem(
              icon: LucideIcons.eye,
              title: 'Hiển thị',
              subtitle: state.hideCalories ? 'Đang ẩn số calo' : 'Đang hiện số calo',
              onTap: () => push(const DisplaySettingsScreen()),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _MeGroupCard(
          header: 'Sao lưu',
          textTheme: t,
          cs: cs,
          items: [
            _MeItem(
              icon: LucideIcons.databaseBackup,
              title: 'Sao lưu và khôi phục',
              subtitle: backupSummary,
              onTap: () => push(const BackupRestoreScreen()),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _MeGroupCard(
          header: 'Quyền riêng tư & Nguồn',
          textTheme: t,
          cs: cs,
          items: [
            _MeItem(icon: LucideIcons.lock, title: 'Quyền riêng tư', onTap: () => push(const PrivacyScreen())),
            _MeItem(icon: LucideIcons.bookOpen, title: 'Nguồn số liệu', onTap: () => push(const SourcesScreen())),
          ],
        ),
      ],
    );
  }
}

class _MeItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MeItem({required this.icon, required this.title, this.subtitle, required this.onTap});
}

class _MeGroupCard extends StatelessWidget {
  final String header;
  final List<_MeItem> items;
  final TextTheme textTheme;
  final ColorScheme cs;

  const _MeGroupCard({required this.header, required this.items, required this.textTheme, required this.cs});

  @override
  Widget build(BuildContext context) {
    final ww = context.wwColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
          child: Text(header, style: textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) Divider(height: 1, color: ww.outlineSubtle.withValues(alpha: 0.5)),
                ListTile(
                  minTileHeight: 56,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: ww.subtleSurface,
                    child: Icon(items[i].icon, size: 18, color: cs.primary),
                  ),
                  title: Text(items[i].title),
                  subtitle: items[i].subtitle == null
                      ? null
                      : Text(items[i].subtitle!, style: tabularNumberStyle(null)),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: items[i].onTap,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Cài đặt Hiển thị (`Tôi -> Hiển thị`): công tắc Ẩn số calo và thẻ Bạn có biết.
class DisplaySettingsScreen extends StatelessWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Hiển thị')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
