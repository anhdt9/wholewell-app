/// Tab Bổ sung và màn Quét mã vạch / Chụp ảnh nhãn để thêm sản phẩm mới.
library;

import 'dart:async';

import 'package:dsld_library/dsld_library.dart';
import 'package:flutter/foundation.dart';
import 'package:journal_db/journal_db.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../state/dsld_ingredient_mapper.dart';
import 'common/common_widgets.dart';
import 'confirm_ingredients_screen.dart';
import 'day_times_screen.dart';
import 'dsld_search_screen.dart';
import 'labels.dart';
import 'product_detail_screen.dart';
import 'today_doses_screen.dart';

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
    unawaited(_load());
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

  static double _stockBarRatio(ProductSummary s) {
    if (s.validRemaining <= 0) return 0;
    if (s.estimatedDaysLeft != null) {
      return (s.estimatedDaysLeft! / 30.0).clamp(0.06, 1.0);
    }
    final servings = s.validRemaining / s.product.unitsPerServing;
    return (servings / 30.0).clamp(0.06, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ww = context.wwColors;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LoadingSkeletonBox(height: 76, borderRadius: AppRadius.cardRadius),
            SizedBox(height: AppSpacing.lg),
            LoadingSkeletonBox(height: 20, width: 80),
            SizedBox(height: AppSpacing.sm),
            LoadingSkeletonBox(height: 84, borderRadius: AppRadius.cardRadius),
            SizedBox(height: AppSpacing.sm),
            LoadingSkeletonBox(height: 84, borderRadius: AppRadius.cardRadius),
          ],
        ),
      );
    }
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

    final diary = AppScope.of(context).diary;
    final schedules = diary.actualTodaySchedules;
    final occMap = {for (final o in diary.actualTodayOccurrences) o.scheduleId: o};
    final prodMap = {for (final s in _items) s.product.id: s.product};
    final schedFlags = diary.scheduledUlFlags(overrideSchedules: schedules);
    final schedNotices = [
      for (final n in diary.scheduleNotices(overrideSchedules: schedules))
        if (n.severity == 'notice') n,
    ];

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 88),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              minTileHeight: 60,
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: ww.subtleSurface,
                child: Icon(LucideIcons.clock, size: 20, color: cs.primary),
              ),
              title: Text('Lần uống hôm nay', style: t.titleSmall),
              subtitle: schedules.isEmpty
                  ? const Text('Chưa có lịch uống. Mở một sản phẩm để đặt lịch.')
                  : Text(
                      [
                        for (final s in schedules)
                          '${occMap[s.id]?.status == OccurrenceStatus.taken ? "✓" : occMap[s.id]?.status == OccurrenceStatus.skipped ? "—" : "○"} ${formatMinutesHhMm(s.timeOfDay)} ${prodMap[s.productId]?.name ?? ""}',
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tabularNumberStyle(t.bodySmall),
                    ),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const TodayDosesScreen()),
              ),
            ),
          ),
          Text('Kho', style: t.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < _items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: ww.outlineSubtle.withValues(alpha: 0.5),
                    ),
                  Builder(builder: (ctx) {
                    final s = _items[i];
                    final p = s.product;
                    final u = countUnitLabel(p.countUnit);
                    final hasUl = schedFlags.isNotEmpty &&
                        schedules.any((sc) => sc.productId == p.id);
                    final hasNotice = schedNotices.any((n) => n.productIds.contains(p.id));
                    final ratio = _stockBarRatio(s);
                    final barColor = s.isLowStock || s.validRemaining <= 0
                        ? ww.warningBorder
                        : ww.foodSource;

                    return InkWell(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ProductDetailScreen(productId: p.id),
                          ),
                        );
                        await _load();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ResponsiveStatRow(
                                    leading: Text(p.name, style: t.titleSmall),
                                    trailing: Text(
                                      s.validRemaining > 0
                                          ? 'Còn ${fmt(s.validRemaining)} $u'
                                          : 'Kho đã hết',
                                      style: tabularNumberStyle(
                                        t.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: s.validRemaining <= 0
                                              ? cs.error
                                              : cs.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    LucideIcons.chevronRight,
                                    size: 18,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Semantics(
                              label: s.validRemaining > 0
                                  ? 'Còn ${fmt(s.validRemaining)} $u'
                                  : 'Kho đã hết',
                              child: ClipRRect(
                                borderRadius: AppRadius.pillRadius,
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 4,
                                  backgroundColor: ww.subtleSurface,
                                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                                ),
                              ),
                            ),
                            if (s.isLowStock ||
                                s.nearestExpiryMonth != null ||
                                s.expiredRemaining > 0 ||
                                hasNotice ||
                                hasUl) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  if (s.isLowStock)
                                    _StockStatusPill(
                                      label: 'Sắp hết',
                                      backgroundColor: ww.warningContainer,
                                      foregroundColor: ww.onWarningContainer,
                                      borderColor: ww.warningBorder,
                                    ),
                                  if (s.nearestExpiryMonth != null)
                                    _StockStatusPill(
                                      label: 'HSD ${fmtExpiryMonth(s.nearestExpiryMonth!)}',
                                      backgroundColor: ww.subtleSurface,
                                      foregroundColor: cs.onSurfaceVariant,
                                    ),
                                  if (s.expiredRemaining > 0)
                                    _StockStatusPill(
                                      label: 'Đã hết hạn: ${fmt(s.expiredRemaining)} $u',
                                      backgroundColor: cs.errorContainer,
                                      foregroundColor: cs.onErrorContainer,
                                    ),
                                  if (hasNotice)
                                    _StockStatusPill(
                                      label: 'Lưu ý lịch',
                                      backgroundColor: ww.subtleSurface,
                                      foregroundColor: cs.onSurfaceVariant,
                                    ),
                                  if (hasUl)
                                    _StockStatusPill(
                                      label: 'Lịch vượt giới hạn',
                                      backgroundColor: ww.warningContainer,
                                      foregroundColor: ww.onWarningContainer,
                                      borderColor: ww.warningBorder,
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_product',
        onPressed: _addProduct,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Thêm sản phẩm'),
      ),
    );
  }
}

class _StockStatusPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  const _StockStatusPill({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.pillRadius,
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Text(
        label,
        style: tabularNumberStyle(
          t.labelSmall?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w500,
          ),
        ),
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
    try {
      final state = AppScope.of(context);
      final found = await state.diary.findProductByBarcode(trimmed);
      if (!mounted) return;
      if (found != null) {
        setState(() => _busy = false);
        AppFeedback.showSnack(context, 'Đã tìm thấy sản phẩm đã lưu.');
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => ProductDetailScreen(productId: found.id)),
        );
        return;
      }

      final dsld = state.dsldLibrary;
      if (dsld != null) {
        final matches = await dsld.findByBarcode(trimmed);
        if (!mounted) return;
        if (matches.length == 1) {
          setState(() => _busy = false);
          _openDsldProduct(matches.first);
          return;
        }
        if (matches.length > 1) {
          setState(() => _busy = false);
          final picked = await _pickDsldVersion(trimmed, matches);
          if (picked != null && mounted) {
            _openDsldProduct(picked);
          }
          return;
        }
      }

      setState(() {
        _busy = false;
        _barcode = trimmed;
        _statusMsg = 'Chưa thấy trong thư viện nhãn. Hãy chụp bảng thành phần hoặc nhập tay.';
      });
    } on Object {
      if (mounted) {
        setState(() {
          _statusMsg = 'Chưa tra được mã vạch. Thử lại.';
        });
      }
    } finally {
      if (mounted && _busy) {
        setState(() => _busy = false);
      }
    }
  }

  Future<DsldProductDetail?> _pickDsldVersion(String barcode, List<DsldProductDetail> matches) {
    return showModalBottomSheet<DsldProductDetail>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chọn phiên bản nhãn', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Mã $barcode có ${matches.length} bản ghi:'),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: matches.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = matches[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(m.productName),
                      subtitle: Text([
                        if (m.brandName.isNotEmpty) m.brandName,
                        if (m.servingSize.isNotEmpty) m.servingSize,
                      ].join(' · ')),
                      trailing: const Icon(LucideIcons.chevronRight),
                      onTap: () => Navigator.pop(ctx, m),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDsldProduct(DsldProductDetail detail) {
    final state = AppScope.of(context);
    final mapped = DsldIngredientMapper.mapProduct(detail, state.pack);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConfirmIngredientsScreen(
          initialLines: mapped.ingredients,
          scannedBarcode: mapped.barcode,
          fromDsld: true,
          onConfirmed: (ctx, drafts) async {
            await Navigator.of(ctx).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => ProductInfoScreen(
                  initialIngredients: drafts,
                  initialBarcode: mapped.barcode,
                  initialName: mapped.displayName,
                  initialUnitsPerServing: mapped.suggestedUnitsPerServing,
                  initialCountUnit: mapped.suggestedCountUnit,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openDsldSearch() async {
    final detail = await Navigator.of(context).push<DsldProductDetail>(
      MaterialPageRoute<DsldProductDetail>(builder: (_) => const DsldSearchScreen()),
    );
    if (detail != null && mounted) {
      _openDsldProduct(detail);
    }
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
    try {
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

      if (!fromCamera && _barcode == null) {
        final detected = await _detectBarcodeFromImages(picked.paths, state);
        if (!mounted) return;
        if (detected != null) {
          setState(() {
            _busy = false;
            _scannerPaused = false;
            _cameraDenied = false;
            _imagePaths.addAll(picked.paths);
          });
          await _handleBarcode(detected);
          return;
        }
      }

      setState(() {
        _busy = false;
        _scannerPaused = false;
        _cameraDenied = false;
        _imagePaths.addAll(picked.paths);
        _statusMsg = 'Đã thêm ${picked.paths.length} ảnh (tổng ${_imagePaths.length}). Có thể chụp thêm mặt khác rồi bấm Đọc thông tin.';
      });
    } on Object {
      if (mounted) {
        setState(() {
          _statusMsg = 'Chưa chọn hoặc chụp được ảnh. Thử lại.';
        });
      }
    } finally {
      if (mounted && (_busy || _scannerPaused)) {
        setState(() {
          _busy = false;
          _scannerPaused = false;
        });
      }
    }
  }

  Future<String?> _detectBarcodeFromImages(List<String> paths, AppState state) async {
    final adapter = state.barcodeScanner;
    if (adapter != null) {
      for (final p in paths) {
        final code = await adapter.scanBarcodeFromImage(p);
        if (code != null && code.trim().isNotEmpty) return code.trim();
      }
      return null;
    }
    if (!_useLiveMobileScanner) return null;
    final ctrl = MobileScannerController();
    try {
      for (final p in paths) {
        final capture = await ctrl.analyzeImage(p);
        final code = capture?.barcodes.firstOrNull?.rawValue;
        if (code != null && code.trim().isNotEmpty) return code.trim();
      }
    } finally {
      await ctrl.dispose();
    }
    return null;
  }

  Future<void> _analyzeImages() async {
    if (_busy || _imagePaths.isEmpty) return;
    setState(() {
      _busy = true;
      _statusMsg = 'Đang đọc chữ trên ${_imagePaths.length} ảnh...';
    });
    try {
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
    } on Object {
      if (mounted) {
        setState(() {
          _statusMsg = 'Không đọc được chữ từ ảnh. Thử lại hoặc nhập tay.';
        });
      }
    } finally {
      if (mounted && _busy) {
        setState(() => _busy = false);
      }
    }
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
    final state = AppScope.of(context);
    final adapter = state.barcodeScanner;
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm sản phẩm')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (adapter != null)
            OutlinedButton.icon(
              onPressed: _busy ? null : _scanWithAdapter,
              icon: const Icon(LucideIcons.scanBarcode),
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
                      unawaited(_handleBarcode(code));
                    }
                  },
                ),
              ),
            )
          else
            const SizedBox(
              height: 110,
              child: SurfaceCard(
                color: Colors.transparent,
                child: Center(
                  child: Text(
                    'Đưa mã vạch vào khung để tìm sản phẩm đã lưu hoặc trong thư viện nhãn.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (state.dsldLibraryPreparing) ...[
            const Text('Đang chuẩn bị thư viện nhãn (lần đầu)...'),
            const SizedBox(height: 6),
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
          ] else if (state.dsldLibraryBroken) ...[
            const Text('Thư viện nhãn tạm thời không khả dụng, vẫn dùng được chụp nhãn.'),
            const SizedBox(height: 12),
          ],
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
                leading: const Icon(LucideIcons.image),
                title: Text('Ảnh ${i + 1}'),
                trailing: IconButton(
                  tooltip: 'Xóa ảnh',
                  icon: const Icon(LucideIcons.x),
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
                icon: const Icon(LucideIcons.settings),
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
              icon: const Icon(LucideIcons.scanText),
              label: Text('Đọc thông tin từ ${_imagePaths.length} ảnh'),
            ),
            const SizedBox(height: 8),
          ],
          if (state.dsldLibrary != null) ...[
            OutlinedButton.icon(
              onPressed: _busy ? null : _openDsldSearch,
              icon: const Icon(LucideIcons.search),
              label: const Text('Tìm theo tên sản phẩm'),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _addImage(fromCamera: true),
            icon: const Icon(LucideIcons.camera),
            label: Text(_imagePaths.isEmpty ? 'Chụp ảnh nhãn (tên, thành phần)' : 'Chụp thêm ảnh khác'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _addImage(fromCamera: false),
            icon: const Icon(LucideIcons.image),
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
