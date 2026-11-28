import 'package:flutter_test/flutter_test.dart';
import 'package:wholewell/ui/supplements_screen.dart';

String? _accept({
  String? code = '0123456789012',
  bool routeIsCurrent = true,
  bool busy = false,
  String? heldBarcode,
  String? lastHandledCode,
}) => ScanProductScreen.acceptLiveCode(
  code: code,
  routeIsCurrent: routeIsCurrent,
  busy: busy,
  heldBarcode: heldBarcode,
  lastHandledCode: lastHandledCode,
);

void main() {
  group('camera quét mã chỉ mở một màn', () {
    test('mã đầu tiên trong khung được nhận, cắt khoảng trắng', () {
      expect(_accept(code: ' 0123456789012 '), '0123456789012');
    });

    test('đang có màn khác hay bảng chọn phiên bản đè lên thì bỏ qua', () {
      expect(_accept(routeIsCurrent: false), isNull);
    });

    test('đang tra mã thì bỏ qua lần báo tiếp theo của camera', () {
      expect(_accept(busy: true), isNull);
    });

    test('đã giữ mã chưa có trong thư viện thì không tra lại', () {
      expect(_accept(heldBarcode: '0123456789012'), isNull);
    });

    test('quay lại màn quét mà máy còn hướng vào mã vừa mở thì không mở lại', () {
      expect(_accept(lastHandledCode: '0123456789012'), isNull);
      expect(_accept(code: '999', lastHandledCode: '0123456789012'), '999');
    });

    test('mã rỗng thì bỏ qua', () {
      expect(_accept(code: null), isNull);
      expect(_accept(code: '  '), isNull);
    });
  });
}
