/// Màn Tìm trong thư viện thực phẩm bổ sung (NIH DSLD offline).
library;

import 'package:dsld_library/dsld_library.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import 'common/common_widgets.dart';

class DsldSearchScreen extends StatefulWidget {
  const DsldSearchScreen({super.key});

  @override
  State<DsldSearchScreen> createState() => _DsldSearchScreenState();
}

class _DsldSearchScreenState extends State<DsldSearchScreen> {
  final _ctrl = TextEditingController();
  List<DsldProductSummary> _results = const [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onQueryChanged(String raw) async {
    final q = raw.trim();
    if (q.length < 2) {
      setState(() {
        _results = const [];
        _searched = false;
      });
      return;
    }
    final lib = AppScope.of(context).dsldLibrary;
    if (lib == null) return;
    setState(() => _loading = true);
    final hits = await lib.searchByName(q, limit: 30);
    if (!mounted) return;
    setState(() {
      _results = hits;
      _loading = false;
      _searched = true;
    });
  }

  Future<void> _pick(DsldProductSummary item) async {
    final lib = AppScope.of(context).dsldLibrary;
    if (lib == null) return;
    setState(() => _loading = true);
    final detail = await lib.getDetail(item.dsldId);
    if (!mounted) return;
    setState(() => _loading = false);
    if (detail != null) {
      Navigator.of(context).pop(detail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lib = AppScope.of(context).dsldLibrary;
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm trong thư viện')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(LucideIcons.search),
                hintText: 'Tìm tên sản phẩm hoặc tên hãng...',
              ),
              onChanged: _onQueryChanged,
            ),
          ),
          Expanded(
            child: lib == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Thư viện nhãn tạm thời không khả dụng, vẫn dùng được chụp nhãn.'),
                    ),
                  )
                : _loading
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            LoadingSkeletonBox(height: 56),
                            SizedBox(height: AppSpacing.sm),
                            LoadingSkeletonBox(height: 56),
                            SizedBox(height: AppSpacing.sm),
                            LoadingSkeletonBox(height: 56),
                          ],
                        ),
                      )
                    : !_searched
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Nhập tên sản phẩm hoặc tên hãng (tiếng Anh trên nhãn).'),
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Không thấy kết quả phù hợp.'),
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Chụp ảnh bảng thành phần'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _results.length + 1,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              if (i == _results.length) {
                                return ListTile(
                                  title: const Text('Không thấy sản phẩm? Chụp ảnh bảng thành phần'),
                                  trailing: const Icon(LucideIcons.camera),
                                  onTap: () => Navigator.of(context).pop(),
                                );
                              }
                              final item = _results[i];
                              final sub = [
                                if (item.brandName.isNotEmpty) item.brandName,
                                if (item.servingSize.isNotEmpty) item.servingSize,
                              ].join(' · ');
                              return ListTile(
                                title: Text(item.productName),
                                subtitle: sub.isEmpty ? null : Text(sub),
                                trailing: const Icon(LucideIcons.chevronRight),
                                onTap: () => _pick(item),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
