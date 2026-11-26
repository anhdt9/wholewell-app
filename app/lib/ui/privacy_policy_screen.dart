import 'package:material_ui/material_ui.dart';

/// Màn đọc toàn văn Chính sách quyền riêng tư trực tiếp trên máy (offline 100%).
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  Future<String>? _policyFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _policyFuture ??=
        DefaultAssetBundle.of(context).loadString('assets/privacy_policy.md', cache: false);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Chính sách quyền riêng tư')),
      body: FutureBuilder<String>(
        future: _policyFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không đọc được Chính sách quyền riêng tư: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final lines = snapshot.data!.split('\n');
          return SelectionArea(
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
          );
        },
      ),
    );
  }
}
