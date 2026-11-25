import 'package:health_engine/health_engine.dart';
import 'package:material_ui/material_ui.dart';

import 'labels.dart';

/// Kiểm tra và hiển thị thông báo chặn (`<= 0`, trống, `> 300`) hoặc nhắc nhẹ ngoài khoảng hợp lý.
class BodyMeasureValidation {
  final double? value;
  final String? blockingError;
  final String? softWarning;

  const BodyMeasureValidation({this.value, this.blockingError, this.softWarning});

  bool get isValid => value != null && blockingError == null;

  static BodyMeasureValidation validateHeight(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    final v = double.tryParse(t);
    if (v == null || v <= 0 || v > 300) {
      return const BodyMeasureValidation(blockingError: 'Nhập chiều cao hợp lệ (1–300 cm).');
    }
    if (v < 120 || v > 220) {
      return BodyMeasureValidation(value: v, softWarning: 'Kiểm tra lại chiều cao.');
    }
    return BodyMeasureValidation(value: v);
  }

  static BodyMeasureValidation validateWeight(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    final v = double.tryParse(t);
    if (v == null || v <= 0 || v > 300) {
      return const BodyMeasureValidation(blockingError: 'Nhập cân nặng hợp lệ (1–300 kg).');
    }
    if (v < 30 || v > 250) {
      return BodyMeasureValidation(value: v, softWarning: 'Kiểm tra lại cân nặng.');
    }
    return BodyMeasureValidation(value: v);
  }
}

/// Khối nhập Giới tính sinh học, Chiều cao, Cân nặng, Mức vận động dùng chung giữa 3/4 và Hồ sơ.
class BodyMetricsFields extends StatelessWidget {
  final Sex? sex;
  final ValueChanged<Sex> onSexChanged;
  final TextEditingController heightCtl;
  final TextEditingController weightCtl;
  final BodyMeasureValidation? heightCheck;
  final BodyMeasureValidation? weightCheck;
  final ActivityLevel? level;
  final ValueChanged<ActivityLevel> onLevelChanged;
  final VoidCallback onChanged;
  final bool enabled;
  final ActivityLevel? suggestedLevel;

  const BodyMetricsFields({
    super.key,
    required this.sex,
    required this.onSexChanged,
    required this.heightCtl,
    required this.weightCtl,
    required this.heightCheck,
    required this.weightCheck,
    required this.level,
    required this.onLevelChanged,
    required this.onChanged,
    this.enabled = true,
    this.suggestedLevel,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Giới tính sinh học', style: t.titleSmall),
        const SizedBox(height: 8),
        RadioGroup<Sex>(
          groupValue: sex,
          onChanged: enabled
              ? (v) {
                  if (v != null) onSexChanged(v);
                }
              : (_) {},
          child: const Row(
            children: [
              Expanded(
                child: RadioListTile<Sex>(
                  value: Sex.male,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Nam'),
                ),
              ),
              Expanded(
                child: RadioListTile<Sex>(
                  value: Sex.female,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Nữ'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: heightCtl,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Chiều cao',
            suffixText: 'cm',
            border: const OutlineInputBorder(),
            errorText: heightCheck?.blockingError,
            helperText: heightCheck?.blockingError == null ? heightCheck?.softWarning : null,
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: weightCtl,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Cân nặng',
            suffixText: 'kg',
            border: const OutlineInputBorder(),
            errorText: weightCheck?.blockingError,
            helperText: weightCheck?.blockingError == null ? weightCheck?.softWarning : null,
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<ActivityLevel>(
          key: ValueKey(level),
          initialValue: level,
          decoration: const InputDecoration(
            labelText: 'Mức vận động',
            border: OutlineInputBorder(),
          ),
          hint: const Text('Chọn mức vận động'),
          items: [
            for (final l in ActivityLevel.values)
              DropdownMenuItem(value: l, child: Text(levelLabel(l))),
          ],
          onChanged: !enabled
              ? null
              : (v) {
                  if (v != null) onLevelChanged(v);
                },
        ),
        if (suggestedLevel != null) ...[
          const SizedBox(height: 8),
          Text('Gợi ý từ nhật ký 7 ngày qua: ${levelLabel(suggestedLevel!)}', style: t.bodySmall),
        ],
      ],
    );
  }
}
