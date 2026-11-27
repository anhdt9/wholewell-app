import 'package:health_engine/health_engine.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import 'body_metrics_fields.dart';
import 'common/common_widgets.dart';
import 'privacy_screen.dart';

/// Màn Hồ sơ (mở từ `Tôi -> Hồ sơ` hoặc nút `Sửa` ở dòng nhắc tuổi trên Hôm nay).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _ageCtl = TextEditingController();
  final _heightCtl = TextEditingController();
  final _weightCtl = TextEditingController();

  Sex _sex = Sex.female;
  ActivityLevel _level = ActivityLevel.lowActive;
  bool _caution = false;
  BodyMeasureValidation? _heightCheck;
  BodyMeasureValidation? _weightCheck;
  String? _ageError;
  bool _inited = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    final state = AppScope.of(context);
    final p = state.profile;
    _caution = state.caution;
    if (p != null) {
      _ageCtl.text = '${p.ageYears}';
      _heightCtl.text = '${p.heightCm.round()}';
      _weightCtl.text = '${p.weightKg.round()}';
      _sex = p.sex;
      _level = p.activityLevel;
      _heightCheck = BodyMeasureValidation.validateHeight(_heightCtl.text);
      _weightCheck = BodyMeasureValidation.validateWeight(_weightCtl.text);
    }
  }

  @override
  void dispose() {
    _ageCtl.dispose();
    _heightCtl.dispose();
    _weightCtl.dispose();
    super.dispose();
  }

  String? _validateAge(int minAge) {
    final v = int.tryParse(_ageCtl.text.trim());
    if (v == null) return 'Nhập tuổi từ $minAge đến 120.';
    if (v < minAge) return 'WholeWell hiện chỉ hỗ trợ từ $minAge tuổi.';
    if (v > 120) return 'Nhập tuổi từ $minAge đến 120.';
    return null;
  }

  void _revalidateMeasures() {
    setState(() {
      _heightCheck = BodyMeasureValidation.validateHeight(_heightCtl.text);
      _weightCheck = BodyMeasureValidation.validateWeight(_weightCtl.text);
    });
  }

  Future<void> _save() async {
    final state = AppScope.of(context);
    final minAge = state.pack.minProfileAge;
    final ageErr = _validateAge(minAge);
    final hc = BodyMeasureValidation.validateHeight(_heightCtl.text);
    final wc = BodyMeasureValidation.validateWeight(_weightCtl.text);
    setState(() {
      _ageError = ageErr;
      _heightCheck = hc;
      _weightCheck = wc;
    });
    if (_saving || ageErr != null || !hc.isValid || !wc.isValid) return;

    final age = int.parse(_ageCtl.text.trim());
    setState(() => _saving = true);
    final bool ok;
    try {
      ok = await state.saveProfileFromSettings(
        Profile(
          ageYears: age,
          sex: _sex,
          heightCm: hc.value!,
          weightKg: wc.value!,
          activityLevel: _level,
        ),
        caution: _caution,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted || !ok) return;
    AppFeedback.showSnack(context, 'Đã lưu hồ sơ.');
    Navigator.of(context).maybePop();
  }

  Future<void> _wipeFromPregnancyCard() => confirmAndWipeAllData(
        context,
        isMounted: () => mounted,
        onBusyChanged: (b) => setState(() => _saving = b),
      );

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final minAge = state.pack.minProfileAge;
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _ageCtl,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Tuổi',
              border: const OutlineInputBorder(),
              errorText: _ageError,
            ),
            onChanged: (_) => setState(() => _ageError = _validateAge(minAge)),
          ),
          const SizedBox(height: 16),
          BodyMetricsFields(
            sex: _sex,
            onSexChanged: (s) => setState(() => _sex = s),
            heightCtl: _heightCtl,
            weightCtl: _weightCtl,
            heightCheck: _heightCheck,
            weightCheck: _weightCheck,
            level: _level,
            onLevelChanged: (l) => setState(() => _level = l),
            onChanged: _revalidateMeasures,
            enabled: !_saving,
            suggestedLevel: state.todayWorkouts.isEmpty ? null : state.suggestedLevel(),
          ),
          const SizedBox(height: 20),
          Text(
            'Đang dùng thuốc theo chỉ định của bác sĩ, hoặc có bệnh mạn tính (vd. thận, gan, tim, tiểu đường)?',
            style: t.bodyLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Có'),
                selected: _caution,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: _saving ? null : (_) => setState(() => _caution = true),
              ),
              ChoiceChip(
                label: const Text('Không'),
                selected: !_caution,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: _saving ? null : (_) => setState(() => _caution = false),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu'),
          ),
          const SizedBox(height: 24),
          SurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nếu bạn mang thai hoặc cho con bú, bản này của WholeWell chưa hỗ trợ. '
                  'Xuất dữ liệu sẽ có ở bản cập nhật sau.',
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: cs.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _saving ? null : _wipeFromPregnancyCard,
                  child: const Text('Xóa toàn bộ dữ liệu'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
