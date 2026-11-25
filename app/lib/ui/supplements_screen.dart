/// Tab Bổ sung và màn Quét mã vạch / Chụp ảnh nhãn để thêm sản phẩm mới.
library;

import 'package:flutter/foundation.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../state/app_scope.dart';
import '../state/app_state.dart';
import 'common/common_widgets.dart';
import 'confirm_ingredients_screen.dart';
import 'labels.dart';
import 'product_detail_screen.dart';

class SupplementsScreen extends StatefulWidget {
  const SupplementsScreen({super.key});

  @override
  State<SupplementsScreen> createState() => _SupplementsScreenState();
}

class _SupplementsScreenState extends State<SupplementsScreen> {
  List<ProductSummary> _items = const [];
  bool _loading = true;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await AppScope.of(context).diary.listProducts();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
        _error = null;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _addProduct() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ScanProductScreen()),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ErrorState(
        message: 'Không tải được danh sách sản phẩm.',
        actionLabel: 'Thử lại',
        onAction: _load,
      );
    }
    if (_items.isEmpty) {
      return EmptyState(
        message: 'Chưa có sản phẩm bổ sung nào.',
        actionLabel: 'Thêm sản phẩm',
        onAction: _addProduct,
      );
    }

    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final s = _items[i];
          final p = s.product;
          final u = countUnitLabel(p.countUnit);
          final parts = <String>[
            s.validRemaining > 0 ? 'Còn ${fmt(s.validRemaining)} $u' : 'Kho đã hết',
            if (s.isLowStock) 'Sắp hết',
            if (s.nearestExpiryMonth != null) 'HSD ${fmtExpiryMonth(s.nearestExpiryMonth!)}',
            if (s.expiredRemaining > 0) 'Đã hết hạn: ${fmt(s.expiredRemaining)} $u',
          ];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(p.name),
            subtitle: Text(parts.join(' · ')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => ProductDetailScreen(productId: p.id)),
              );
              await _load();
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_product',
        onPressed: _addProduct,
        icon: const Icon(Icons.add),
        label: const Text('Thêm sản phẩm'),
      ),
    );
  }
}

class ScanProductScreen extends StatefulWidget {
  const ScanProductScreen({super.key});

  @override
  State<ScanProductScreen> createState() => _ScanProductScreenState();
}

class _ScanProductScreenState extends State<ScanProductScreen> {
  final List<String> _imagePaths = [];
  String? _barcode;
  String? _statusMsg;
  bool _busy = false;
  bool _cameraDenied = false;
  bool _scannerPaused = false;

  bool get _useLiveMobileScanner =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _handleBarcode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty || _busy) return;
    setState(() => _busy = true);
    final state = AppScope.of(context);
    final found = await state.diary.findProductByBarcode(trimmed);
    if (!mounted) return;
    if (found != null) {
      setState(() => _busy = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Đã tìm thấy sản phẩm đã lưu.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => ProductDetailScreen(productId: found.id)),
      );
      return;
    }
    setState(() {
      _busy = false;
      _barcode = trimmed;
      _statusMsg = 'Chưa có sản phẩm với mã vạch này. Hãy chụp hoặc chọn ảnh nhãn.';
    });
  }

  Future<void> _scanWithAdapter() async {
    final scanner = AppScope.of(context).barcodeScanner;
    if (scanner == null) return;
    final code = await scanner.scanBarcode();
    if (code != null && mounted) await _handleBarcode(code);
  }

  Future<void> _addImage({required bool fromCamera}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _scannerPaused = true;
      _statusMsg = null;
    });
    // Nhả camera từ MobileScanner trước khi mở DocumentScanner / ImagePicker.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    final state = AppScope.of(context);
    final picked = fromCamera
        ? await state.ocrEngine.captureLabelImage()
        : await state.ocrEngine.pickLabelImageFromGallery();
    if (!mounted) return;
    if (picked.permissionDenied) {
      setState(() {
        _busy = false;
        _scannerPaused = false;
        _cameraDenied = fromCamera;
        _statusMsg = 'Chưa có quyền máy ảnh. Bạn có thể mở cài đặt, chọn ảnh từ thư viện hoặc nhập tay.';
      });
      return;
    }
    if (picked.paths.isEmpty) {
      setState(() {
        _busy = false;
        _scannerPaused = false;
      });
      return;
    }
    setState(() {
      _busy = false;
      _scannerPaused = false;
      _cameraDenied = false;
      _imagePaths.addAll(picked.paths);
      _statusMsg = 'Đã thêm ${picked.paths.length} ảnh (tổng ${_imagePaths.length}). Có thể chụp thêm mặt khác rồi bấm Đọc thông tin.';
    });
  }

  Future<void> _analyzeImages() async {
    if (_busy || _imagePaths.isEmpty) return;
    setState(() {
      _busy = true;
      _statusMsg = 'Đang đọc chữ trên ${_imagePaths.length} ảnh...';
    });
    final state = AppScope.of(context);
    final ocr = await state.ocrEngine.recognizeLabelFromImages(_imagePaths);
    if (!mounted) return;
    if (ocr.errorMessage != null && ocr.lines.isEmpty) {
      setState(() {
        _busy = false;
        _statusMsg = ocr.errorMessage;
      });
      return;
    }
    ParsedLabelPackage? pkg;
    final aiJson = await state.ocrEngine.extractLabelJsonWithOnDeviceAi(ocr.lines);
    if (aiJson != null) {
      pkg = SupplementLabelParser.parseAiJson(aiJson, ocr.lines);
    }
    pkg ??= SupplementLabelParser.parsePackage(ocr.lines);
    if (!mounted) return;
    setState(() => _busy = false);
    _openConfirm(
      [for (final p in pkg.ingredients) EditableIngredient.fromParsed(p, state.pack)],
      pkg: pkg,
    );
  }

  void _openConfirm(List<EditableIngredient> initial, {ParsedLabelPackage? pkg}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConfirmIngredientsScreen(
          initialLines: initial,
          rawOcrLines: pkg?.rawLines ?? const [],
          scannedBarcode: _barcode,
          onConfirmed: (ctx, drafts) async {
            await Navigator.of(ctx).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => ProductInfoScreen(
                  initialIngredients: drafts,
                  initialBarcode: _barcode,
                  initialName: pkg?.suggestedProductName,
                  initialBoxRemaining: pkg?.suggestedBoxRemaining,
                  initialUnitsPerServing: pkg?.suggestedUnitsPerServing,
                  initialCountUnit: pkg?.suggestedCountUnit,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adapter = AppScope.of(context).barcodeScanner;
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm sản phẩm')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (adapter != null)
            OutlinedButton.icon(
              onPressed: _busy ? null : _scanWithAdapter,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Quét mã vạch'),
            )
          else if (_useLiveMobileScanner && !_scannerPaused)
            SizedBox(
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  onDetect: (capture) {
                    final code = capture.barcodes.firstOrNull?.rawValue;
                    if (code != null && _barcode == null) {
                      _handleBarcode(code);
                    }
                  },
                ),
              ),
            )
          else
            Container(
              height: 110,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Đưa mã vạch vào khung để tìm sản phẩm đã lưu.'),
            ),
          const SizedBox(height: 12),
          if (_barcode != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Mã vạch đã quét: $_barcode'),
            ),
          if (_imagePaths.isNotEmpty) ...[
            Text('Ảnh đã chọn (${_imagePaths.length})', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            for (var i = 0; i < _imagePaths.length; i++)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.image_outlined),
                title: Text('Ảnh ${i + 1}'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _busy ? null : () => setState(() => _imagePaths.removeAt(i)),
                ),
              ),
            const SizedBox(height: 8),
          ],
          if (_statusMsg != null) ...[
            Text(
              _statusMsg!,
              style: _cameraDenied
                  ? TextStyle(color: Theme.of(context).colorScheme.error)
                  : Theme.of(context).textTheme.bodyMedium,
            ),
            if (_cameraDenied) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => AppScope.of(context).ocrEngine.openAppSettings(),
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Mở cài đặt'),
              ),
            ],
            const SizedBox(height: 12),
          ],
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_imagePaths.isNotEmpty) ...[
            FilledButton.icon(
              onPressed: _busy ? null : _analyzeImages,
              icon: const Icon(Icons.document_scanner_outlined),
              label: Text('Đọc thông tin từ ${_imagePaths.length} ảnh'),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _addImage(fromCamera: true),
            icon: const Icon(Icons.photo_camera),
            label: Text(_imagePaths.isEmpty ? 'Chụp ảnh nhãn (tên, thành phần)' : 'Chụp thêm ảnh khác'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _addImage(fromCamera: false),
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(_imagePaths.isEmpty ? 'Chọn ảnh từ thư viện' : 'Chọn thêm ảnh từ thư viện'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : () => _openConfirm(const []),
            child: const Text('Nhập tay từng dòng'),
          ),
        ],
      ),
    );
  }
}
