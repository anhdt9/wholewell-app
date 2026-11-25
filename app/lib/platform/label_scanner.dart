/// Interface và cài đặt trên máy cho chụp/chọn ảnh nhãn, OCR và quét mã vạch.
library;

import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrImagePickResult {
  final String? path;
  final bool permissionDenied;
  const OcrImagePickResult({this.path, this.permissionDenied = false});
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
  Future<void> dispose();
}

/// Interface nền tảng cho quét mã vạch (dùng bản giả trong test/desktop).
abstract interface class BarcodeScanner {
  Future<String?> scanBarcode();
}

/// Cài đặt thật dùng `image_picker` + `google_mlkit_text_recognition` (chạy hoàn toàn trên máy).
class MlKitOcrEngine implements OcrEngine {
  final ImagePicker _picker;
  TextRecognizer? _recognizer;

  MlKitOcrEngine({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  @override
  Future<OcrImagePickResult> captureLabelImage() => _pick(ImageSource.camera);

  @override
  Future<OcrImagePickResult> pickLabelImageFromGallery() => _pick(ImageSource.gallery);

  Future<OcrImagePickResult> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 90);
      return OcrImagePickResult(path: file?.path);
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
      final lines = <String>[
        for (final block in recognized.blocks)
          for (final line in block.lines)
            if (line.text.trim().isNotEmpty) line.text.trim(),
      ];
      return OcrLabelResult(lines: lines);
    } on Object {
      return const OcrLabelResult(
        errorMessage: 'Không đọc được chữ rõ trên ảnh. Hãy chụp lại hoặc nhập tay.',
      );
    }
  }

  @override
  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}

/// Bản giả dùng cho unit/widget test.
class FakeOcrEngine implements OcrEngine {
  OcrImagePickResult nextCaptureResult;
  OcrImagePickResult nextGalleryResult;
  OcrLabelResult nextOcrResult;

  FakeOcrEngine({
    this.nextCaptureResult = const OcrImagePickResult(path: '/fake/camera.jpg'),
    this.nextGalleryResult = const OcrImagePickResult(path: '/fake/gallery.jpg'),
    this.nextOcrResult = const OcrLabelResult(),
  });

  @override
  Future<OcrImagePickResult> captureLabelImage() async => nextCaptureResult;

  @override
  Future<OcrImagePickResult> pickLabelImageFromGallery() async => nextGalleryResult;

  @override
  Future<OcrLabelResult> recognizeLabelFromImage(String imagePath) async => nextOcrResult;

  @override
  Future<void> dispose() async {}
}

class FakeBarcodeScanner implements BarcodeScanner {
  String? nextBarcode;
  FakeBarcodeScanner({this.nextBarcode});

  @override
  Future<String?> scanBarcode() async => nextBarcode;
}
