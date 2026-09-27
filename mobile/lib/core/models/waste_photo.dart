import 'dart:typed_data';

class WastePhoto {
  final Uint8List bytes;
  final String name;
  final DateTime selectedAt;
  const WastePhoto({
    required this.bytes,
    required this.name,
    required this.selectedAt,
  });
}
