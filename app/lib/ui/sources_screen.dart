/// Màn Nguồn số liệu: hiển thị chuẩn tham chiếu và nguồn NIH ODS cho 5 quy tắc lịch.
library;

import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import 'common/common_widgets.dart';

class SourcesScreen extends StatelessWidget {
  final String? highlightRuleId;
  const SourcesScreen({super.key, this.highlightRuleId});

  @override
  Widget build(BuildContext context) {
    final pack = AppScope.of(context).pack;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nguồn số liệu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Phiên bản gói dữ liệu: ${pack.version}', style: t.bodySmall),
          const SizedBox(height: 16),
          Text('Quy tắc lịch uống (NIH ODS)', style: t.titleMedium),
          const SizedBox(height: 8),
          for (final r in pack.scheduleRules)
            SurfaceCard(
              margin: const EdgeInsets.only(bottom: 10),
              color: r.id == highlightRuleId ? cs.secondaryContainer : cs.surfaceContainerLow,
              borderColor: r.id == highlightRuleId ? cs.primary : cs.outlineVariant,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.messageVi, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    'Nguồn: ${pack.sources[r.source]?.title ?? r.source} · Tra ngày ${r.accessedDate}',
                    style: t.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  SelectableText(r.url, style: t.bodySmall?.copyWith(color: cs.primary)),
                  const SizedBox(height: 4),
                  Text('Trích: "${r.quote}"', style: t.bodySmall),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text('Tất cả nguồn chuẩn', style: t.titleMedium),
          const SizedBox(height: 8),
          for (final s in pack.sources.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.title),
              subtitle: SelectableText(s.retrieved == null ? s.url : '${s.url} (tra ${s.retrieved})'),
            ),
        ],
      ),
    );
  }
}
