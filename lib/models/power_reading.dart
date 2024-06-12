class PowerReading {
  final int device;
  final int unitId;
  final int address;
  final double power;

  PowerReading({required this.device, required this.unitId, required this.address, required this.power});

  factory PowerReading.fromJson(Map<String, dynamic> json) {
    return PowerReading(
      device: json['device'],
      unitId: json['unit_id'],
      address: json['address'],
      power: json['power'],
    );
  }
}