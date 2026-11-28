/// Màn Thông tin sản phẩm, Chi tiết sản phẩm và Quản lý hộp (kho, hạn dùng).
library;

import 'dart:async';

import 'package:dsld_library/dsld_library.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/models.dart';
import 'package:material_ui/material_ui.dart';

import '../state/app_scope.dart';
import 'add_supplement_screen.dart';
import 'common/common_widgets.dart';
import 'confirm_ingredients_screen.dart';
import 'day_times_screen.dart';
import 'edit_schedule_screen.dart';
import 'labels.dart';

class ProductInfoScreen extends StatefulWidget {
  final List<IngredientDraft>? initialIngredients;
  final Product? editingProduct;
  final String? initialBarcode;
  final String? initialName;
  final double? initialBoxRemaining;
  final double? initialUnitsPerServing;
  final CountUnit? initialCountUnit;

  const ProductInfoScreen({
    super.key,
    this.initialIngredients,
    this.editingProduct,
    this.initialBarcode,
    this.initialName,
    this.initialBoxRemaining,
    this.initialUnitsPerServing,
    this.initialCountUnit,
  });

  @override
  State<ProductInfoScreen> createState() => _ProductInfoScreenState();
}

class _ProductInfoScreenState extends State<ProductInfoScreen> {
  late TextEditingController _name;
  late TextEditingController _barcode;
  late TextEditingController _unitsPerServing;
  final _boxRemaining = TextEditingController();
  final _boxExpiry = TextEditingController();
  late CountUnit _countUnit;
  String? _error;
  bool _saving = false;

  bool get _isEdit => widget.editingProduct != null;

  @override
  void initState() {
    super.initState();
    final p = widget.editingProduct;
    _name = TextEditingController(text: p?.name ?? widget.initialName ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? widget.initialBarcode ?? '');
    _unitsPerServing = TextEditingController(
      text: p != null
          ? fmt(p.unitsPerServing)
          : (widget.initialUnitsPerServing != null ? fmt(widget.initialUnitsPerServing!) : '1'),
    );
    _countUnit = p?.countUnit ?? widget.initialCountUnit ?? CountUnit.tablet;
    if (p == null && widget.initialBoxRemaining != null) {
      _boxRemaining.text = fmt(widget.initialBoxRemaining!);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _barcode.dispose();
    _unitsPerServing.dispose();
    _boxRemaining.dispose();
    _boxExpiry.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nhập tên sản phẩm.');
      return;
    }
    final ups = double.tryParse(_unitsPerServing.text.trim().replaceAll(',', '.'));
    if (ups == null || !ups.isFinite || ups <= 0) {
      setState(() => _error = 'Số đơn vị mỗi khẩu phần phải lớn hơn 0.');
      return;
    }

    double? boxRem;
    String? boxExp;
    if (!_isEdit && _boxRemaining.text.trim().isNotEmpty) {
      boxRem = double.tryParse(_boxRemaining.text.trim().replaceAll(',', '.'));
      if (boxRem == null || !boxRem.isFinite || boxRem < 0) {
        setState(() => _error = 'Số còn lại không được âm.');
        return;
      }
      final parsed = parseExpiryMmYyyy(_boxExpiry.text);
      if (!parsed.ok) {
        setState(() => _error = 'Nhập hạn dùng theo tháng/năm (MM/YYYY), tháng từ 01 đến 12.');
        return;
      }
      boxExp = parsed.yyyyMm;
    }

    setState(() {
      _error = null;
      _saving = true;
    });
    final state = AppScope.of(context);
    final bc = _barcode.text.trim().isEmpty ? null : _barcode.text.trim();

    if (_isEdit) {
      await state.diary.updateProductInfo(
        widget.editingProduct!.id,
        name: name,
        countUnit: _countUnit,
        unitsPerServing: ups,
        barcode: bc,
      );
      if (mounted) Navigator.pop(context, true);
      return;
    }

    final pid = await state.diary.createProductWithIngredientsAndBox(
      name: name,
      countUnit: _countUnit,
      unitsPerServing: ups,
      barcode: bc,
      ingredients: widget.initialIngredients ?? const [],
      initialBoxRemaining: boxRem,
      initialBoxExpiryMonth: boxExp,
    );
    if (!mounted) return;
    if (pid == null) {
      setState(() {
        _saving = false;
        _error = 'Không lưu được sản phẩm.';
      });
      return;
    }
    final nav = Navigator.of(context);
    nav.popUntil((r) => r.isFirst);
    nav.push(MaterialPageRoute<void>(builder: (_) => ProductDetailScreen(productId: pid)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa thông tin sản phẩm' : 'Thông tin sản phẩm')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Tên sản phẩm *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _barcode,
            decoration: const InputDecoration(labelText: 'Mã vạch (tùy chọn)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<CountUnit>(
            initialValue: _countUnit,
            decoration: const InputDecoration(labelText: 'Đơn vị đếm'),
            items: [for (final u in CountUnit.values) DropdownMenuItem(value: u, child: Text(countUnitLabel(u)))],
            onChanged: (v) {
              if (v != null) setState(() => _countUnit = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _unitsPerServing,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Số đơn vị mỗi khẩu phần *'),
          ),
          if (!_isEdit) ...[
            const SizedBox(height: 20),
            Text('Hộp đang mở (tùy chọn)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _boxRemaining,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Số còn lại'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _boxExpiry,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [ExpiryMonthInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Hạn dùng', hintText: 'MM/YYYY'),
                  ),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(onPressed: _saving ? null : _save, child: const Text('Lưu sản phẩm')),
        ],
      ),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductDetail? _detail;
  ProductSummary? _summary;
  DsldProductDetail? _dsldMatch;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_load());
  }

  Future<void> _load() async {
    final state = AppScope.of(context);
    final diary = state.diary;
    final detail = await diary.getProductDetail(widget.productId);
    final summaries = await diary.listProducts(includeArchived: true);
    final summary = summaries.where((s) => s.product.id == widget.productId).firstOrNull;
    DsldProductDetail? dsldMatch;
    final bc = detail?.product.barcode;
    if (bc != null && bc.isNotEmpty && state.dsldLibrary != null) {
      dsldMatch = (await state.dsldLibrary!.findByBarcode(bc)).firstOrNull;
    }
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _summary = summary;
      _dsldMatch = dsldMatch;
      _loading = false;
    });
  }

  Future<void> _editIngredients() async {
    final detail = _detail;
    if (detail == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConfirmIngredientsScreen(
          editingProductId: detail.product.id,
          initialLines: [for (final i in detail.ingredients) EditableIngredient.fromSaved(i)],
          onConfirmed: (ctx, drafts) async {
            final ok = await AppScope.of(ctx).diary.saveProductIngredients(detail.product.id, drafts);
            if (ok && ctx.mounted) Navigator.pop(ctx);
          },
        ),
      ),
    );
    await _load();
  }

  Future<void> _archive() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Lưu trữ sản phẩm',
      message: 'Ẩn sản phẩm khỏi danh sách? Dữ liệu lịch sử đã uống vẫn được giữ.',
      confirmLabel: 'Lưu trữ',
    );
    if (ok && mounted) {
      final state = AppScope.of(context);
      await state.diary.archiveProduct(widget.productId);
      await state.syncNotifications();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final detail = _detail;
    if (_loading || detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final p = detail.product;
    final summary =
        _summary ??
        summarizeProduct(
          product: p,
          boxes: detail.boxes,
          activeSchedules: const [],
          recentDoses14Days: const [],
          now: DateTime.now(),
        );
    final unit = countUnitLabel(p.countUnit);
    final stockText = summary.validRemaining > 0 ? 'Còn ${fmt(summary.validRemaining)} $unit' : 'Kho đã hết';
    final hsdText = summary.nearestExpiryMonth == null ? '' : ' · HSD ${fmtExpiryMonth(summary.nearestExpiryMonth!)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') {
                final changed = await Navigator.of(context)
                    .push<bool>(MaterialPageRoute<bool>(builder: (_) => ProductInfoScreen(editingProduct: p)));
                if (changed == true) await _load();
              } else if (v == 'archive') {
                await _archive();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Sửa thông tin sản phẩm')),
              PopupMenuItem(value: 'archive', child: Text('Lưu trữ sản phẩm')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('1 khẩu phần = ${fmt(p.unitsPerServing)} $unit'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text('$stockText$hsdText'),
              subtitle: summary.expiredRemaining > 0
                  ? Text('Đã hết hạn: ${fmt(summary.expiredRemaining)} $unit')
                  : Text('${detail.boxes.length} hộp · Chạm để xem / thêm hộp'),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () async {
                await Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => ProductBoxesScreen(product: p)));
                await _load();
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Thành phần mỗi khẩu phần (${detail.ingredients.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final ing in detail.ingredients)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                ing.nutrientId == null
                    ? (ing.freeName ?? 'Chất khác')
                    : (state.pack.nutrients[ing.nutrientId!]?.nameVi ?? ing.nutrientId!),
              ),
              subtitle: Text(_ingredientSub(ing, state.pack)),
              trailing: Text(
                ing.amountPerServing != null && ing.unit != null
                    ? '${fmt(ing.amountPerServing!)} ${unitLabel(ing.unit!)}'
                    : (ing.labelAmount != null && ing.labelUnit != null
                          ? '${fmt(ing.labelAmount!)} ${unitLabel(ing.labelUnit!)}'
                          : ''),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          const SizedBox(height: 16),
          if (_dsldMatch != null &&
              (_dsldMatch!.suggestedUse.isNotEmpty || _dsldMatch!.otherIngredients.isNotEmpty)) ...[
            if (_dsldMatch!.suggestedUse.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Cách dùng trên nhãn'),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(alignment: Alignment.centerLeft, child: Text(_dsldMatch!.suggestedUse)),
                  ),
                ],
              ),
            if (_dsldMatch!.otherIngredients.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Thành phần khác (theo nhãn)'),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(alignment: Alignment.centerLeft, child: Text(_dsldMatch!.otherIngredients)),
                  ),
                ],
              ),
            const SizedBox(height: 8),
          ],
          OutlinedButton(onPressed: _editIngredients, child: const Text('Sửa thành phần')),
          const SizedBox(height: 12),
          Builder(
            builder: (ctx) {
              final diary = state.diary;
              final prodSchedules = [
                for (final s in diary.actualTodaySchedules)
                  if (s.productId == p.id) s,
              ];
              final prodNotices = [
                for (final n in diary.scheduleNotices(overrideSchedules: diary.actualTodaySchedules))
                  if (n.severity == 'notice' && n.productIds.contains(p.id)) n,
              ];
              Future<void> openSchedule([Schedule? existing]) async {
                final nav = Navigator.of(context);
                if (!diary.dayTimesSettings.dayTimesConfirmed) {
                  final confirmed = await nav.push<bool>(
                    MaterialPageRoute<bool>(builder: (_) => const DayTimesScreen(onboardingFlow: true)),
                  );
                  if (confirmed != true || !mounted) return;
                }
                await nav.push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditScheduleScreen(product: p, existingSchedule: existing),
                  ),
                );
                await _load();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (prodSchedules.isEmpty)
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Lịch uống'),
                      subtitle: Text('Chưa có lịch uống'),
                    )
                  else
                    for (final s in prodSchedules)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Lịch: mỗi ngày ${fmt(s.servings * p.unitsPerServing)} $unit lúc ${formatMinutesHhMm(s.timeOfDay)}',
                        ),
                        trailing: const Icon(LucideIcons.chevronRight),
                        onTap: () => openSchedule(s),
                      ),
                  for (final n in prodNotices) ...[SafetyNote(message: n.messageVi), const SizedBox(height: 8)],
                  OutlinedButton(
                    onPressed: openSchedule,
                    child: Text(prodSchedules.isEmpty ? 'Đặt lịch' : 'Thêm lịch'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              await Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => AddSupplementScreen(initialProductId: p.id)));
              await _load();
            },
            child: const Text('Ghi lần uống'),
          ),
        ],
      ),
    );
  }

  String _ingredientSub(ProductIngredient ing, ReferencePack pack) {
    if (ing.nutrientId == null) return 'Không có mức tham chiếu';
    final parts = <String>[];
    if (ing.form != NutrientForm.unknown) {
      final meta = pack.compoundMeta[ing.nutrientId!]?[ing.form];
      parts.add(meta?.nameVi ?? ing.form);
    } else if (ing.isCompound) {
      parts.add('Chưa rõ dạng');
    }
    if (ing.labelAmount != null && ing.labelUnit != null) {
      parts.add('nhãn ${fmt(ing.labelAmount!)} ${unitLabel(ing.labelUnit!)}');
    }
    return parts.join(' · ');
  }
}

class ProductBoxesScreen extends StatefulWidget {
  final Product product;
  const ProductBoxesScreen({super.key, required this.product});

  @override
  State<ProductBoxesScreen> createState() => _ProductBoxesScreenState();
}

class _ProductBoxesScreenState extends State<ProductBoxesScreen> {
  List<StockBox> _boxes = const [];
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_load());
  }

  Future<void> _load() async {
    final detail = await AppScope.of(context).diary.getProductDetail(widget.product.id);
    if (!mounted) return;
    setState(() {
      _boxes = detail?.boxes ?? const [];
      _loading = false;
    });
  }

  Future<void> _editBox([StockBox? box]) async {
    final diary = AppScope.of(context).diary;
    final remCtrl = TextEditingController(text: box == null ? '' : fmt(box.remaining));
    final expCtrl = TextEditingController(text: box?.expiryMonth == null ? '' : fmtExpiryMonth(box!.expiryMonth!));
    String? err;
    var saving = false;
    final bool? saved;
    try {
      saved = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(box == null ? 'Thêm hộp' : 'Sửa hộp'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: remCtrl,
                  enabled: !saving,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'Số còn lại (${countUnitLabel(widget.product.countUnit)})'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: expCtrl,
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [ExpiryMonthInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Hạn dùng (tùy chọn)', hintText: 'MM/YYYY'),
                ),
                if (err != null) ...[
                  const SizedBox(height: 8),
                  Text(err!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                ],
              ],
            ),
            actions: [
              if (box != null)
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setLocal(() => saving = true);
                          try {
                            await diary.deleteProductBox(box.id);
                            if (ctx.mounted) Navigator.pop(ctx, true);
                          } on Object {
                            if (ctx.mounted) {
                              setLocal(() {
                                saving = false;
                                err = 'Không xóa được hộp. Thử lại.';
                              });
                            }
                          }
                        },
                  child: Text('Xóa', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                ),
              TextButton(onPressed: saving ? null : () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final rem = double.tryParse(remCtrl.text.trim().replaceAll(',', '.'));
                        if (rem == null || !rem.isFinite || rem < 0) {
                          setLocal(() => err = 'Số còn lại không được âm.');
                          return;
                        }
                        final parsed = parseExpiryMmYyyy(expCtrl.text);
                        if (!parsed.ok) {
                          setLocal(() => err = 'Nhập hạn dùng theo tháng/năm (MM/YYYY), tháng từ 01 đến 12.');
                          return;
                        }
                        setLocal(() {
                          saving = true;
                          err = null;
                        });
                        try {
                          if (box == null) {
                            await diary.addProductBox(widget.product.id, remaining: rem, expiryMonth: parsed.yyyyMm);
                          } else {
                            await diary.updateProductBox(box.id, remaining: rem, expiryMonth: parsed.yyyyMm);
                          }
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } on Object {
                          if (ctx.mounted) {
                            setLocal(() {
                              saving = false;
                              err = 'Không lưu được hộp. Thử lại.';
                            });
                          }
                        }
                      },
                child: const Text('Lưu'),
              ),
            ],
          ),
        ),
      );
    } finally {
      remCtrl.dispose();
      expCtrl.dispose();
    }
    if (saved == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final curMonth = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    final valid = [
      for (final b in _boxes)
        if (b.expiryMonth == null || b.expiryMonth!.compareTo(curMonth) >= 0) b,
    ];
    final expired = [
      for (final b in _boxes)
        if (b.expiryMonth != null && b.expiryMonth!.compareTo(curMonth) < 0) b,
    ];
    final unit = countUnitLabel(widget.product.countUnit);

    return Scaffold(
      appBar: AppBar(title: Text('Hộp: ${widget.product.name}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _boxes.isEmpty
          ? const Center(child: Text('Chưa có hộp nào.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (valid.isNotEmpty) ...[
                  Text('Còn hạn', style: Theme.of(context).textTheme.titleSmall),
                  for (final b in valid)
                    ListTile(
                      title: Text('Còn ${fmt(b.remaining)} $unit'),
                      subtitle: Text(
                        b.expiryMonth == null ? 'Không ghi hạn dùng' : 'HSD ${fmtExpiryMonth(b.expiryMonth!)}',
                      ),
                      trailing: const Icon(LucideIcons.chevronRight),
                      onTap: () => _editBox(b),
                    ),
                ],
                if (expired.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Đã hết hạn', style: Theme.of(context).textTheme.titleSmall),
                  for (final b in expired)
                    ListTile(
                      title: Text('Còn ${fmt(b.remaining)} $unit'),
                      subtitle: Text('HSD ${fmtExpiryMonth(b.expiryMonth!)}'),
                      trailing: const Icon(LucideIcons.chevronRight),
                      onTap: () => _editBox(b),
                    ),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _editBox,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Thêm hộp'),
      ),
    );
  }
}
