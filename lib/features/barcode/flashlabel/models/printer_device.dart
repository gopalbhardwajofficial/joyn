enum PrinterProtocol {
  tspl,    // Seznik Josh, Tejas, Rudra, FlashLabel (Label / TSPL mode)
  escPos,  // Seznik Dev, Veer, POS-58, POS-80 (Receipt / ESC-POS mode)
  cpcl,    // CPCL Mobile Label format
  zpl,     // ZPL Zebra format
}

class ThermalPrinterDevice {
  final String id;
  final String name;
  final String address;
  final int rssi;
  final bool isConnected;
  final bool isSimulated;
  final PrinterProtocol protocol;
  final int paperWidthMm;

  ThermalPrinterDevice({
    required this.id,
    required this.name,
    required this.address,
    this.rssi = -60,
    this.isConnected = false,
    this.isSimulated = false,
    this.protocol = PrinterProtocol.tspl,
    this.paperWidthMm = 100,
  });

  ThermalPrinterDevice copyWith({
    String? id,
    String? name,
    String? address,
    int? rssi,
    bool? isConnected,
    bool? isSimulated,
    PrinterProtocol? protocol,
    int? paperWidthMm,
  }) {
    return ThermalPrinterDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      rssi: rssi ?? this.rssi,
      isConnected: isConnected ?? this.isConnected,
      isSimulated: isSimulated ?? this.isSimulated,
      protocol: protocol ?? this.protocol,
      paperWidthMm: paperWidthMm ?? this.paperWidthMm,
    );
  }
}

