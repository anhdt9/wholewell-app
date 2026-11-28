/// Interface và cài đặt trên máy cho chụp/chọn ảnh nhãn, OCR và quét mã vạch.
library;

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrImagePickResult {
  final List<String> paths;
  final bool permissionDenied;
  const OcrImagePickResult({this.paths = const [], this.permissionDenied = false});

  String? get path => paths.isEmpty ? null : paths.first;
}

class OcrLabelResult {
  final List<String> lines;
  final String? errorMessage;
  const OcrLabelResult({this.lines = const [], this.errorMessage});
}

/// Interface nền tảng cho chụp/chọn ảnh nhãn và nhận dạng chữ trên máy.
abstract interface class OcrEngine {
  Future<OcrImagePickResult> captureLabelImage();
  Future<OcrImagePickResult> pickLabelImageFromGallery();
  Future<OcrLabelResult> recognizeLabelFromImage(String imagePath);
  Future<OcrLabelResult> recognizeLabelFromImages(List<String> imagePaths);
  Future<String?> extractLabelJsonWithOnDeviceAi(List<String> ocrLines);
  Future<void> openAppSettings();
  Future<void> dispose();
}

/// Interface nền tảng cho quét mã vạch (dùng bản giả trong test/desktop).
abstract interface class BarcodeScanner {
  Future<String?> scanBarcode();
  Future<String?> scanBarcodeFromImage(String imagePath);
}

/// Cài đặt thật dùng `google_mlkit_document_scanner` (làm phẳng nhãn cong) + `image_picker` + `google_mlkit_text_recognition`.
class MlKitOcrEngine implements OcrEngine {
  final ImagePicker _picker;
  TextRecognizer? _recognizer;
  DocumentScanner? _scanner;

  MlKitOcrEngine({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  @override
  Future<OcrImagePickResult> captureLabelImage() async {
    try {
      _scanner ??= DocumentScanner(
        options: DocumentScannerOptions(
          documentFormats: const {DocumentFormat.jpeg},
          mode: ScannerMode.full,
          pageLimit: 4,
          isGalleryImport: true,
        ),
      );
      final result = await _scanner!.scanDocument();
      final images = result.images ?? const <String>[];
      if (images.isNotEmpty) {
        return OcrImagePickResult(paths: images);
      }
      return const OcrImagePickResult();
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        return const OcrImagePickResult(permissionDenied: true);
      }
      // Fallback sang ImagePicker nếu máy không hỗ trợ DocumentScanner.
      return _pick(ImageSource.camera);
    } on Object {
      return _pick(ImageSource.camera);
    }
  }

  @override
  Future<OcrImagePickResult> pickLabelImageFromGallery() => _pick(ImageSource.gallery);

  Future<OcrImagePickResult> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 95);
      return OcrImagePickResult(paths: file == null ? const [] : [file.path]);
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied' || e.code == 'photo_access_denied') {
        return const OcrImagePickResult(permissionDenied: true);
      }
      return const OcrImagePickResult();
    }
  }

  @override
  Future<OcrLabelResult> recognizeLabelFromImage(String imagePath) async {
    try {
      final rec = _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
      final input = InputImage.fromFilePath(imagePath);
      final recognized = await rec.processImage(input);

      // Nhóm các TextLine theo hàng ngang (Y) để ghép cột trái (tên chất) + cột phải (số lượng).
      final allLines = <TextLine>[
        for (final block in recognized.blocks)
          for (final line in block.lines)
            if (line.text.trim().isNotEmpty) line,
      ];
      if (allLines.isEmpty) return const OcrLabelResult(lines: []);

      allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
      final rows = <List<TextLine>>[];
      for (final line in allLines) {
        final cy = line.boundingBox.center.dy;
        final h = math.max(10.0, line.boundingBox.height);
        List<TextLine>? targetRow;
        for (final row in rows) {
          final ref = row.first;
          final refCy = ref.boundingBox.center.dy;
          final refH = math.max(10.0, ref.boundingBox.height);
          if ((cy - refCy).abs() <= math.min(h, refH) * 0.65) {
            targetRow = row;
            break;
          }
        }
        if (targetRow != null) {
          targetRow.add(line);
        } else {
          rows.add([line]);
        }
      }

      final merged = <String>[];
      for (final row in rows) {
        row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
        merged.add(row.map((l) => l.text.trim()).join(' '));
      }
      return OcrLabelResult(lines: merged);
    } on Object {
      return const OcrLabelResult(errorMessage: 'Không đọc được chữ rõ trên ảnh. Hãy chụp lại hoặc nhập tay.');
    }
  }

  @override
  Future<OcrLabelResult> recognizeLabelFromImages(List<String> imagePaths) async {
    final all = <String>[];
    String? err;
    for (final path in imagePaths) {
      final res = await recognizeLabelFromImage(path);
      if (res.errorMessage != null) {
        err = res.errorMessage;
      } else {
        all.addAll(res.lines);
      }
    }
    if (all.isEmpty && err != null) {
      return OcrLabelResult(errorMessage: err);
    }
    return OcrLabelResult(lines: all);
  }

  @override
  Future<String?> extractLabelJsonWithOnDeviceAi(List<String> ocrLines) async {
    if (ocrLines.isEmpty) return null;
    try {
      const channel = MethodChannel('vn.wholewell.app/genai_label');
      return await channel.invokeMethod<String>('extractLabelJson', {'ocrText': ocrLines.join('\n')});
    } on Object {
      return null;
    }
  }

  @override
  Future<void> openAppSettings() async {
    try {
      const channel = MethodChannel('vn.wholewell.app/settings');
      await channel.invokeMethod<void>('openAppSettings');
    } on Object {
      // Nền tảng khác Android không cần mở cài đặt hệ thống qua kênh này.
    }
  }

  @override
  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
    await _scanner?.close();
    _scanner = null;
  }
}

/// Bản giả dùng cho unit/widget test.
class FakeOcrEngine implements OcrEngine {
  OcrImagePickResult nextCaptureResult;
  OcrImagePickResult nextGalleryResult;
  OcrLabelResult nextOcrResult;
  String? nextAiJson;
  final Map<String, OcrLabelResult> resultsByPath;

  FakeOcrEngine({
    this.nextCaptureResult = const OcrImagePickResult(paths: ['/fake/camera.jpg']),
    this.nextGalleryResult = const OcrImagePickResult(paths: ['/fake/gallery.jpg']),
    this.nextOcrResult = const OcrLabelResult(),
    this.nextAiJson,
    this.resultsByPath = const {},
  });

  @override
  Future<OcrImagePickResult> captureLabelImage() async => nextCaptureResult;

  @override
  Future<OcrImagePickResult> pickLabelImageFromGallery() async => nextGalleryResult;

  @override
  Future<OcrLabelResult> recognizeLabelFromImage(String imagePath) async => resultsByPath[imagePath] ?? nextOcrResult;

  @override
  Future<OcrLabelResult> recognizeLabelFromImages(List<String> imagePaths) async {
    final all = <String>[];
    String? err;
    for (final p in imagePaths) {
      final res = await recognizeLabelFromImage(p);
      if (res.errorMessage != null) {
        err = res.errorMessage;
      } else {
        all.addAll(res.lines);
      }
    }
    if (all.isEmpty && err != null) return OcrLabelResult(errorMessage: err);
    return OcrLabelResult(lines: all);
  }

  @override
  Future<String?> extractLabelJsonWithOnDeviceAi(List<String> ocrLines) async => nextAiJson;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> dispose() async {}
}

class FakeBarcodeScanner implements BarcodeScanner {
  String? nextBarcode;
  String? nextBarcodeFromImage;
  FakeBarcodeScanner({this.nextBarcode, this.nextBarcodeFromImage});

  @override
  Future<String?> scanBarcode() async => nextBarcode;

  @override
  Future<String?> scanBarcodeFromImage(String imagePath) async => nextBarcodeFromImage;
}
