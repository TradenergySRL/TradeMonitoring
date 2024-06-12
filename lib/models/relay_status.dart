class RelayStatus {
  final int relayIndex;
  final String status;

  RelayStatus({required this.relayIndex, required this.status});

  factory RelayStatus.fromJson(Map<String, dynamic> json) {
    return RelayStatus(
      relayIndex: json['relay_index'],
      status: json['status'],
    );
  }
}