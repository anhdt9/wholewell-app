import 'package:health_engine/health_engine.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import '../state/app_state.dart';
import 'backup_restore_screen.dart';
import 'body_metrics_fields.dart';
import 'common/common_widgets.dart';

enum _PreDbStep { welcome, eligibility, notEligible, consent }

/// Luồng lần đầu trước khi có CSDL (`Chào mừng` -> `Điều kiện` -> `Chưa dùng được` / `Đồng ý`).
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  _PreDbStep _step = _PreDbStep.welcome;
  final _ageCtl = TextEditingController();
  bool? _pregnantOrLactating;
  bool? _caution;
  bool _agreed = false;
  bool _busy = false;
  String? _ageError;
  String? _submitError;

  @override
  void dispose() {
    _ageCtl.dispose();
    super.dispose();
  }

  int? _parsedAge() {
    final raw = _ageCtl.text.trim();
    if (raw.isEmpty) return null;
    final v = int.tryParse(raw);
    if (v == null || v < 1 || v > 120) return null;
    return v;
  }

  void _validateAgeOnChange(String value) {
    final raw = value.trim();
    setState(() {
      if (raw.isEmpty) {
        _ageError = null;
      } else {
        final v = int.tryParse(raw);
        _ageError = (v == null || v < 1 || v > 120) ? 'Nhập tuổi từ 1 đến 120.' : null;
      }
    });
  }

  Future<void> _confirmConsent() async {
    final age = _parsedAge();
    final caution = _caution;
    if (age == null || caution == null || !_agreed) return;
    setState(() {
      _busy = true;
      _submitError = null;
    });
    final ok = await AppScope.of(context).completeFirstConsent(ageYears: age, caution: caution);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) _submitError = 'Chưa lưu được. Thử lại';
    });
  }

  Future<void> _declineConsent() async {
    final goWelcome = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text('App cần đồng ý này để tính toán. Bạn có thể quay lại bất cứ lúc nào.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Quay lại')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Về màn Chào mừng'),
          ),
        ],
      ),
    );
    if (goWelcome == true && mounted) {
      setState(() {
        _agreed = false;
        _submitError = null;
        _step = _PreDbStep.welcome;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final minAge = AppScope.of(context).pack.minProfileAge;
    switch (_step) {
      case _PreDbStep.welcome:
        return _WelcomeView(
          onStart: () => setState(() => _step = _PreDbStep.eligibility),
          onRestore: AppScope.of(context).canRestoreFromFile
              ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RestoreBackupScreen(hasExistingData: false),
                    ),
                  )
              : null,
        );
      case _PreDbStep.eligibility:
        final age = _parsedAge();
        final canContinue = age != null && _pregnantOrLactating != null && _caution != null;
        return _EligibilityView(
          stepLabel: '1/4',
          title: null,
          onBack: () => setState(() => _step = _PreDbStep.welcome),
          ageCtl: _ageCtl,
          ageError: _ageError,
          onAgeChanged: _validateAgeOnChange,
          pregnantOrLactating: _pregnantOrLactating,
          onPregnantChanged: (v) => setState(() => _pregnantOrLactating = v),
          caution: _caution,
          onCautionChanged: (v) => setState(() => _caution = v),
          onContinue: !canContinue
              ? null
              : () {
                  if (age < minAge || _pregnantOrLactating == true) {
                    setState(() => _step = _PreDbStep.notEligible);
                  } else {
                    setState(() {
                      _agreed = false;
                      _submitError = null;
                      _step = _PreDbStep.consent;
                    });
                  }
                },
        );
      case _PreDbStep.notEligible:
        return _NotEligibleView(
          isUpgrade: false,
          busy: false,
          onBack: () => setState(() => _step = _PreDbStep.eligibility),
        );
      case _PreDbStep.consent:
        return _ConsentView(
          stepLabel: '2/4',
          title: null,
          onBack: () => setState(() => _step = _PreDbStep.eligibility),
          agreed: _agreed,
          onAgreedChanged: (v) => setState(() => _agreed = v),
          busy: _busy,
          errorText: _submitError,
          onAccept: _agreed ? _confirmConsent : null,
          onDecline: _declineConsent,
        );
    }
  }
}

/// Luồng nâng cấp bắt buộc cho CSDL có `khung-tam-0`.
class UpgradeConsentFlow extends StatefulWidget {
  const UpgradeConsentFlow({super.key});

  @override
  State<UpgradeConsentFlow> createState() => _UpgradeConsentFlowState();
}

class _UpgradeConsentFlowState extends State<UpgradeConsentFlow> {
  _PreDbStep _step = _PreDbStep.eligibility;
  final _ageCtl = TextEditingController();
  bool? _pregnantOrLactating;
  bool? _caution;
  bool _agreed = false;
  bool _busy = false;
  bool _prefilled = false;
  String? _ageError;
  String? _submitError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    _prefilled = true;
    AppScope.of(context).consentAgeYears().then((age) {
      if (mounted && age != null && _ageCtl.text.isEmpty) {
        setState(() => _ageCtl.text = '$age');
      }
    });
  }

  @override
  void dispose() {
    _ageCtl.dispose();
    super.dispose();
  }

  int? _parsedAge() {
    final raw = _ageCtl.text.trim();
    if (raw.isEmpty) return null;
    final v = int.tryParse(raw);
    if (v == null || v < 1 || v > 120) return null;
    return v;
  }

  Future<void> _confirmUpgrade() async {
    final age = _parsedAge();
    final caution = _caution;
    if (age == null || caution == null || !_agreed) return;
    setState(() {
      _busy = true;
      _submitError = null;
    });
    final ok = await AppScope.of(context).completeUpgradeConsent(ageYears: age, caution: caution);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) _submitError = 'Chưa lưu được. Thử lại';
    });
  }

  Future<void> _wipeOldData() async {
    final confirmed = await showWipeConfirmDialog(context);
    if (!confirmed || !mounted) return;
    setState(() {
      _busy = true;
      _submitError = null;
    });
    await AppScope.of(context).withdrawConsentAndReset();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _declineUpgrade() async {
    final wantWipe = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          content: const Text('App cần đồng ý này để tính toán. Bạn có thể quay lại bất cứ lúc nào.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Quay lại')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: cs.error),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Rút đồng ý và xóa dữ liệu'),
            ),
          ],
        );
      },
    );
    if (wantWipe == true && mounted) {
      await _wipeOldData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final minAge = AppScope.of(context).pack.minProfileAge;
    switch (_step) {
      case _PreDbStep.welcome:
      case _PreDbStep.eligibility:
        final age = _parsedAge();
        final canContinue = age != null && _pregnantOrLactating != null && _caution != null;
        return _EligibilityView(
          stepLabel: null,
          title: 'Xác nhận điều kiện',
          onBack: null,
          ageCtl: _ageCtl,
          ageError: _ageError,
          onAgeChanged: (value) {
            final raw = value.trim();
            setState(() {
              if (raw.isEmpty) {
                _ageError = null;
              } else {
                final v = int.tryParse(raw);
                _ageError = (v == null || v < 1 || v > 120) ? 'Nhập tuổi từ 1 đến 120.' : null;
              }
            });
          },
          pregnantOrLactating: _pregnantOrLactating,
          onPregnantChanged: (v) => setState(() => _pregnantOrLactating = v),
          caution: _caution,
          onCautionChanged: (v) => setState(() => _caution = v),
          onContinue: !canContinue
              ? null
              : () {
                  if (age < minAge || _pregnantOrLactating == true) {
                    setState(() => _step = _PreDbStep.notEligible);
                  } else {
                    setState(() {
                      _agreed = false;
                      _submitError = null;
                      _step = _PreDbStep.consent;
                    });
                  }
                },
        );
      case _PreDbStep.notEligible:
        return _NotEligibleView(
          isUpgrade: true,
          busy: _busy,
          onBack: () => setState(() => _step = _PreDbStep.eligibility),
          onWipeAll: _wipeOldData,
        );
      case _PreDbStep.consent:
        return _ConsentView(
          stepLabel: null,
          title: 'Xác nhận đồng ý',
          onBack: () => setState(() => _step = _PreDbStep.eligibility),
          agreed: _agreed,
          onAgreedChanged: (v) => setState(() => _agreed = v),
          busy: _busy,
          errorText: _submitError,
          onAccept: _agreed ? _confirmUpgrade : null,
          onDecline: _declineUpgrade,
        );
    }
  }
}

/// Bước 3/4: Hồ sơ cơ thể (sau khi đã có consent & tuổi từ bước Điều kiện).
class OnboardingBodyProfileScreen extends StatefulWidget {
  const OnboardingBodyProfileScreen({super.key});

  @override
  State<OnboardingBodyProfileScreen> createState() => _OnboardingBodyProfileScreenState();
}

class _OnboardingBodyProfileScreenState extends State<OnboardingBodyProfileScreen> {
  Sex? _sex;
  ActivityLevel? _level;
  final _heightCtl = TextEditingController();
  final _weightCtl = TextEditingController();
  BodyMeasureValidation? _heightCheck;
  BodyMeasureValidation? _weightCheck;
  bool _inited = false;
  bool _saving = false;
  String? _saveError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    final p = AppScope.of(context).profile;
    if (p != null) {
      _sex = p.sex;
      _level = p.activityLevel;
      _heightCtl.text = '${p.heightCm.round()}';
      _weightCtl.text = '${p.weightKg.round()}';
      _heightCheck = BodyMeasureValidation.validateHeight(_heightCtl.text);
      _weightCheck = BodyMeasureValidation.validateWeight(_weightCtl.text);
    }
  }

  @override
  void dispose() {
    _heightCtl.dispose();
    _weightCtl.dispose();
    super.dispose();
  }

  void _revalidate() {
    setState(() {
      _heightCheck =
          _heightCtl.text.trim().isEmpty ? null : BodyMeasureValidation.validateHeight(_heightCtl.text);
      _weightCheck =
          _weightCtl.text.trim().isEmpty ? null : BodyMeasureValidation.validateWeight(_weightCtl.text);
      _saveError = null;
    });
  }

  Future<void> _submit() async {
    final hc = BodyMeasureValidation.validateHeight(_heightCtl.text);
    final wc = BodyMeasureValidation.validateWeight(_weightCtl.text);
    setState(() {
      _heightCheck = hc;
      _weightCheck = wc;
    });
    if (_sex == null || _level == null || !hc.isValid || !wc.isValid) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });
    final state = AppScope.of(context);
    final age = await state.consentAgeYears() ?? state.pack.minProfileAge;
    final ok = await state.saveOnboardingBodyProfile(Profile(
      ageYears: age,
      sex: _sex!,
      heightCm: hc.value!,
      weightKg: wc.value!,
      activityLevel: _level!,
    ));
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (!ok) _saveError = 'Chưa lưu được. Thử lại';
    });
  }

  @override
  Widget build(BuildContext context) {
    final hc = _heightCheck;
    final wc = _weightCheck;
    final canSubmit = _sex != null &&
        _level != null &&
        hc != null &&
        wc != null &&
        hc.isValid &&
        wc.isValid;

    return StepScaffold(
      stepLabel: '3/4',
      primaryLabel: 'Tiếp tục',
      busy: _saving,
      onPrimary: canSubmit ? _submit : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BodyMetricsFields(
            sex: _sex,
            onSexChanged: (s) => setState(() => _sex = s),
            heightCtl: _heightCtl,
            weightCtl: _weightCtl,
            heightCheck: _heightCheck,
            weightCheck: _weightCheck,
            level: _level,
            onLevelChanged: (l) => setState(() => _level = l),
            onChanged: _revalidate,
            enabled: !_saving,
          ),
          if (_saveError != null) ...[
            const SizedBox(height: 12),
            Text(_saveError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}

/// Bước 4/4: Hiển thị calo (không chọn sẵn).
class OnboardingCalorieDisplayScreen extends StatefulWidget {
  const OnboardingCalorieDisplayScreen({super.key});

  @override
  State<OnboardingCalorieDisplayScreen> createState() => _OnboardingCalorieDisplayScreenState();
}

class _OnboardingCalorieDisplayScreenState extends State<OnboardingCalorieDisplayScreen> {
  bool? _hideCalories;
  bool _saving = false;
  String? _saveError;

  Future<void> _finish() async {
    final hide = _hideCalories;
    if (hide == null) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final ok = await AppScope.of(context).completeCalorieDisplayOnboarding(hide);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (!ok) _saveError = 'Chưa lưu được. Thử lại';
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    return StepScaffold(
      stepLabel: '4/4',
      onBack: () => state.session.setStage(SessionStage.onboardingBodyProfile),
      primaryLabel: 'Xong',
      busy: _saving,
      onPrimary: _hideCalories != null ? _finish : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bạn muốn thấy số calo không?', style: t.titleLarge),
          const SizedBox(height: 16),
          RadioGroup<bool>(
            groupValue: _hideCalories,
            onChanged: _saving ? (_) {} : (v) => setState(() => _hideCalories = v),
            child: const Column(
              children: [
                RadioListTile<bool>(
                  value: false,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Hiện số calo'),
                ),
                RadioListTile<bool>(
                  value: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Ẩn số calo'),
                  subtitle: Text('App vẫn tính, chỉ không hiện con số.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Đổi ở Tôi → Hiển thị.', style: t.bodySmall),
          if (_saveError != null) ...[
            const SizedBox(height: 12),
            Text(_saveError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback? onRestore;
  const _WelcomeView({required this.onStart, this.onRestore});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return StepScaffold(
      primaryLabel: 'Bắt đầu',
      onPrimary: onStart,
      secondaryLabel: onRestore == null ? null : 'Khôi phục từ bản sao lưu',
      onSecondary: onRestore,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('WholeWell', style: t.headlineMedium),
          const SizedBox(height: 16),
          const Text(
            'So lượng vi chất bạn nạp từ bữa ăn và thực phẩm bổ sung với mức khuyến nghị.',
          ),
          const SizedBox(height: 16),
          const Text('• Chỉ để tham khảo, không thay lời khuyên của bác sĩ'),
          const SizedBox(height: 8),
          const Text('• Dữ liệu chỉ nằm trên máy này, không gửi đi đâu'),
          const SizedBox(height: 8),
          const Text('• Không cần mạng'),
        ],
      ),
    );
  }
}

class _EligibilityView extends StatelessWidget {
  final String? stepLabel;
  final String? title;
  final VoidCallback? onBack;
  final TextEditingController ageCtl;
  final String? ageError;
  final ValueChanged<String> onAgeChanged;
  final bool? pregnantOrLactating;
  final ValueChanged<bool> onPregnantChanged;
  final bool? caution;
  final ValueChanged<bool> onCautionChanged;
  final VoidCallback? onContinue;

  const _EligibilityView({
    required this.stepLabel,
    required this.title,
    required this.onBack,
    required this.ageCtl,
    required this.ageError,
    required this.onAgeChanged,
    required this.pregnantOrLactating,
    required this.onPregnantChanged,
    required this.caution,
    required this.onCautionChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return StepScaffold(
      stepLabel: stepLabel,
      title: title,
      onBack: onBack,
      primaryLabel: 'Tiếp tục',
      onPrimary: onContinue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vài câu để chọn mức tham chiếu phù hợp.', style: t.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: ageCtl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Tuổi',
              border: const OutlineInputBorder(),
              errorText: ageError,
            ),
            onChanged: onAgeChanged,
          ),
          const SizedBox(height: 20),
          _YesNoQuestion(
            question: 'Đang mang thai hoặc cho con bú?',
            value: pregnantOrLactating,
            onChanged: onPregnantChanged,
          ),
          const SizedBox(height: 20),
          _YesNoQuestion(
            question:
                'Đang dùng thuốc theo chỉ định của bác sĩ, hoặc có bệnh mạn tính (vd. thận, gan, tim, tiểu đường)?',
            value: caution,
            onChanged: onCautionChanged,
          ),
        ],
      ),
    );
  }
}

class _YesNoQuestion extends StatelessWidget {
  final String question;
  final bool? value;
  final ValueChanged<bool> onChanged;
  const _YesNoQuestion({required this.question, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Có'),
              selected: value == true,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (_) => onChanged(true),
            ),
            ChoiceChip(
              label: const Text('Không'),
              selected: value == false,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (_) => onChanged(false),
            ),
          ],
        ),
      ],
    );
  }
}

class _NotEligibleView extends StatelessWidget {
  final bool isUpgrade;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback? onWipeAll;

  const _NotEligibleView({
    required this.isUpgrade,
    required this.busy,
    required this.onBack,
    this.onWipeAll,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return StepScaffold(
      primaryLabel: 'Quay lại',
      busy: busy,
      onPrimary: onBack,
      secondaryLabel: isUpgrade ? 'Xóa toàn bộ dữ liệu' : null,
      onSecondary: isUpgrade ? onWipeAll : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'WholeWell hiện dành cho người từ 18 tuổi, không mang thai, không cho con bú. '
            'Hãy hỏi bác sĩ hoặc dược sĩ về dinh dưỡng và thực phẩm bổ sung.',
          ),
          if (isUpgrade) ...[
            const SizedBox(height: 16),
            Text(
              'Trên máy vẫn còn dữ liệu cũ.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConsentView extends StatelessWidget {
  final String? stepLabel;
  final String? title;
  final VoidCallback onBack;
  final bool agreed;
  final ValueChanged<bool> onAgreedChanged;
  final bool busy;
  final String? errorText;
  final VoidCallback? onAccept;
  final VoidCallback onDecline;

  const _ConsentView({
    required this.stepLabel,
    required this.title,
    required this.onBack,
    required this.agreed,
    required this.onAgreedChanged,
    required this.busy,
    required this.errorText,
    required this.onAccept,
    required this.onDecline,
  });

  void _showFullDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thông tin xử lý dữ liệu sức khỏe', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text(
                '• Dữ liệu bạn nhập (tuổi, giới tính sinh học, chiều cao, cân nặng, mức vận động, '
                'bữa ăn, nước uống, buổi tập, thực phẩm bổ sung) chỉ dùng để so sánh với mức tham chiếu trên máy.\n'
                '• Toàn bộ được lưu trong CSDL mã hóa trên máy này; không gửi tới máy chủ hay bên thứ ba.\n'
                '• Bạn có thể sửa hồ sơ ở Tôi → Hồ sơ hoặc rút đồng ý và xóa toàn bộ dữ liệu bất cứ lúc nào ở tab Tôi.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return StepScaffold(
      stepLabel: stepLabel,
      title: title,
      onBack: onBack,
      primaryLabel: 'Đồng ý và tiếp tục',
      busy: busy,
      onPrimary: onAccept,
      secondaryLabel: 'Không đồng ý',
      onSecondary: onDecline,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dữ liệu sức khỏe của bạn', style: t.titleLarge),
          const SizedBox(height: 12),
          const Text(
            'App lưu tuổi, chiều cao, cân nặng, món ăn, bổ sung bạn ghi để so với mức tham chiếu.',
          ),
          const SizedBox(height: 12),
          const Text('• Lưu mã hóa trên máy này'),
          const SizedBox(height: 6),
          const Text('• Không gửi cho ai, kể cả nhóm phát triển'),
          const SizedBox(height: 6),
          const Text('• Xem, sửa ở Tôi → Hồ sơ; xóa ở tab Tôi'),
          const SizedBox(height: 20),
          CheckboxListTile(
            value: agreed,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Tôi đồng ý cho app xử lý dữ liệu sức khỏe của tôi cho mục đích trên.'),
            onChanged: busy ? null : (v) => onAgreedChanged(v == true),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: busy ? null : () => _showFullDetails(context),
              child: const Text('Đọc đầy đủ'),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 8),
            Text(errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
