import 'package:material_ui/material_ui.dart';

import 'privacy_policy_text.dart';

/// Màn đọc toàn văn Chính sách quyền riêng tư trực tiếp trên máy (offline 100%, hiển thị tức thì).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lines = kPrivacyPolicyMarkdown.split('\n');
    return Scaffold(
      appBar: AppBar(title: const Text('Chính sách quyền riêng tư')),
      body: SelectionArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lines.length,
          itemBuilder: (context, index) {
            final raw = lines[index].trimRight();
            if (raw.isEmpty) return const SizedBox(height: 8);
            if (raw.startsWith('# ')) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(raw.substring(2), style: t.headlineSmall),
              );
            }
            if (raw.startsWith('## ')) {
              return Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Text(raw.substring(3), style: t.titleMedium),
              );
            }
            final clean = raw.replaceAll('**', '').replaceAll('`', '');
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(clean, style: t.bodyMedium),
            );
          },
        ),
      ),
    );
  }
}
