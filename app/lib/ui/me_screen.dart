import 'package:health_engine/health_engine.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import 'common/common_widgets.dart';
import 'profile_screen.dart';

/// Tab Tôi: Hồ sơ, Hiển thị (Ẩn số calo), Xóa toàn bộ dữ liệu.
class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = state.profile;
    final cs = Theme.of(context).colorScheme;
    final profileSummary = p == null
        ? 'Chưa có thông tin'
        : '${p.sex == Sex.female ? 'Nữ' : 'Nam'} · ${p.ageYears} tuổi · '
            '${p.heightCm.round()} cm · ${p.weightKg.round()} kg';

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
        const Divider(height: 24),
        ListTile(
          minTileHeight: 56,
          leading: Icon(Icons.delete_outline, color: cs.error),
          title: Text('Xóa toàn bộ dữ liệu', style: TextStyle(color: cs.error)),
          onTap: () async {
            final ok = await showWipeConfirmDialog(context);
            if (ok && context.mounted) {
              await AppScope.of(context).withdrawConsentAndReset();
            }
          },
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
            onChanged: (v) => state.setHideCalories(v),
          ),
        ],
      ),
    );
  }
}
