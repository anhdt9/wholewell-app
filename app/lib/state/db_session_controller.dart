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

/// Giai đoạn luồng vào app (khớp đặc tả & thiết kế UX việc 4).
enum SessionStage {
  /// Chưa có khóa/CSDL: Chào mừng -> Điều kiện -> Chưa dùng được -> Đồng ý.
  welcome,

  /// CSDL mở được nhưng consent là `khung-tam-0` hoặc thiếu consent hợp lệ.
  upgradeRequired,

  /// Đã có consent hợp lệ, đang dở bước 3/3 Hồ sơ cơ thể.
  onboardingBodyProfile,

  /// Hoàn tất thiết lập, vào màn chính.
  ready,
}

class DbSessionController extends ChangeNotifier {
  final DbOpener? _opener;
  JournalRepository? _repo;
  DataStatus _status;
  SessionStage _stage;
  Future<void>? _starting;

  DbSessionController({DbOpener? opener, JournalRepository? repo, DataStatus? initialStatus})
    : _opener = opener,
      _repo = repo,
      _status = initialStatus ?? (opener != null ? DataStatus.loading : DataStatus.ready),
      _stage = (initialStatus ?? (opener != null ? DataStatus.loading : DataStatus.ready)) == DataStatus.ready
          ? SessionStage.ready
          : SessionStage.welcome;

  JournalRepository? get repo => _repo;
  DataStatus get status => _status;
  SessionStage get stage => _stage;
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
      await _syncStageFromRepo();
      await onReady();
    } else if (_status == DataStatus.welcome) {
      _stage = SessionStage.welcome;
    }
    notifyListeners();
  }

  Future<void> _syncStageFromRepo() async {
    final r = _repo;
    if (r == null) return;
    final consent = await r.latestHealthConsent();
    if (consent == null || consent.contentVersion == khungTamConsentVersion) {
      _stage = SessionStage.upgradeRequired;
      return;
    }
    final step = await r.loadOnboardingStep();
    final profile = await r.loadProfile();
    final hide = await r.loadHideCalories();
    if (step == OnboardingStep.bodyProfile || profile == null) {
      _stage = SessionStage.onboardingBodyProfile;
    } else {
      if (hide == null) {
        await r.saveHideCalories(false);
      }
      if (step != OnboardingStep.done) {
        await r.saveOnboardingStep(OnboardingStep.done);
      }
      _stage = SessionStage.ready;
    }
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
    if (_status == DataStatus.ready) {
      await _syncStageFromRepo();
    }
    notifyListeners();
    return _repo != null;
  }

  Future<bool> upgradeHealthConsent({required int ageYears, required bool caution}) async {
    final r = _repo;
    if (r == null) return false;
    await r.upgradeHealthConsent(contentVersion: mvpConsentVersion, ageYears: ageYears, caution: caution);
    await _syncStageFromRepo();
    // Nếu người dùng khung tạm đã có đủ hồ sơ và tùy chọn calo thì cho vào thẳng app.
    if (_stage != SessionStage.ready) {
      final p = await r.loadProfile();
      final hide = await r.loadHideCalories();
      if (p != null && hide != null) {
        await r.saveOnboardingStep(OnboardingStep.done);
        _stage = SessionStage.ready;
      }
    }
    notifyListeners();
    return true;
  }

  void setStage(SessionStage next) {
    if (_stage == next) return;
    _stage = next;
    notifyListeners();
  }

  Future<Uint8List> exportBackup({
    required String secret,
    int memoryKiB = BackupCodec.defaultMemoryKiB,
    int iterations = BackupCodec.defaultIterations,
    int parallelism = BackupCodec.defaultParallelism,
  }) async {
    final o = _opener;
    final r = _repo;
    if (o == null || r is! DriftJournalRepository) {
      throw StateError('Chỉ sao lưu qua tệp khi CSDL mã hóa đang mở.');
    }
    return o.exportBackup(
      openRepository: r,
      secret: secret,
      memoryKiB: memoryKiB,
      iterations: iterations,
      parallelism: parallelism,
    );
  }

  Future<RestoreOutcome> restoreFromBackup({
    required Uint8List backupBytes,
    required String secret,
    required Future<void> Function() onRestored,
  }) async {
    final o = _opener;
    if (o == null) {
      throw StateError('Chưa có kho lưu trữ CSDL trên thiết bị.');
    }
    final outcome = await o.restoreFromBackup(backupBytes: backupBytes, secret: secret, openRepository: _repo);
    if (outcome is RestoreSucceeded) {
      _repo = null;
      _apply(outcome.openOutcome);
      if (_status == DataStatus.ready) {
        await _syncStageFromRepo();
        await onRestored();
      } else if (_status == DataStatus.welcome) {
        _stage = SessionStage.welcome;
      }
      notifyListeners();
    }
    return outcome;
  }

  Future<void> startOver({required VoidCallback onCleared}) async {
    final o = _opener;
    final r = _repo;
    _repo = null;
    if (o != null) {
      await o.startOver(openRepository: r);
    } else if (r != null) {
      await r.close();
    }
    onCleared();
    _status = DataStatus.welcome;
    _stage = SessionStage.welcome;
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
