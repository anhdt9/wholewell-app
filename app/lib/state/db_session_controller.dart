/// Điều phối phiên CSDL mã hóa (`DbOpener`, trạng thái mở khóa, bắt đầu lại).
library;

import 'package:flutter/foundation.dart';
import 'package:journal_db/journal_db.dart';

/// Màn trước khi vào app, theo kết quả mở CSDL (thiết kế tổng thể, dòng "Toàn app").
enum DataStatus {
  loading,
  welcome,
  ready,
  waitingForUnlock,
  keyStuck,
  cannotOpen,
  installBroken,
  needsUpdate,
  lowStorage,

  /// Nền tảng chưa có kho khóa (iOS, máy tính): chưa làm trong MVP.
  unsupportedPlatform,
}

/// Khung tạm chưa có màn Điều kiện, Đồng ý (việc 4): lần lưu hồ sơ đầu tiên là bước
/// đồng ý, câu thuốc, bệnh ghi "Không". **Chỉ để thử nội bộ, không phát cho người
/// thử bên ngoài.** Việc 4 phải phát hiện phiên bản này và hỏi lại cả màn Điều kiện
/// lẫn Đồng ý.
const khungTamConsentVersion = 'khung-tam-0';

class DbSessionController extends ChangeNotifier {
  final DbOpener? _opener;
  JournalRepository? _repo;
  DataStatus _status;
  Future<void>? _starting;

  DbSessionController({DbOpener? opener, JournalRepository? repo, DataStatus? initialStatus})
      : _opener = opener,
        _repo = repo,
        _status = initialStatus ?? (opener != null ? DataStatus.loading : DataStatus.ready);

  JournalRepository? get repo => _repo;
  DataStatus get status => _status;
  bool get hasOpener => _opener != null;

  Future<void> start({required Future<void> Function() onReady}) =>
      _starting ??= _start(onReady).whenComplete(() => _starting = null);

  Future<void> _start(Future<void> Function() onReady) async {
    final o = _opener;
    if (o != null) {
      final old = _repo;
      _repo = null;
      if (old != null) await old.close();
      _status = DataStatus.loading;
      notifyListeners();
      _apply(await o.open());
    }
    if (_status == DataStatus.ready) {
      await onReady();
    }
    notifyListeners();
  }

  Future<bool> ensureCreatedForConsent(ConsentInput input, {required Future<void> Function() onAlreadyExists}) async {
    final o = _opener;
    if (_repo != null || o == null || _status != DataStatus.welcome) return true;
    try {
      _apply(await o.createNew(input));
    } on DbAlreadyExistsException {
      await onAlreadyExists();
      return false;
    }
    notifyListeners();
    return _repo != null;
  }

  Future<void> startOver({required VoidCallback onCleared}) async {
    final o = _opener;
    if (o == null) return;
    final r = _repo;
    _repo = null;
    await o.startOver(openRepository: r);
    onCleared();
    _status = DataStatus.welcome;
    notifyListeners();
  }

  void _apply(OpenOutcome r) {
    _status = switch (r) {
      Opened() => DataStatus.ready,
      Welcome() => DataStatus.welcome,
      WaitingForUnlock() => DataStatus.waitingForUnlock,
      KeyStuck() => DataStatus.keyStuck,
      CannotOpen() => DataStatus.cannotOpen,
      InstallBroken() => DataStatus.installBroken,
      NeedsUpdate() => DataStatus.needsUpdate,
      LowStorage() => DataStatus.lowStorage,
    };
    if (r is Opened) _repo = r.repository;
  }
}
