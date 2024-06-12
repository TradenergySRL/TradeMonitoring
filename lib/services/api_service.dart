// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/power_reading.dart';
import '../models/relay_status.dart';

class ApiService {
  static const String baseUrl = 'https://together-amazingly-mouse.ngrok-free.app';
  static const String username = 'admin';
  static const String password = 'password';
  static final String authHeader = 'Basic ${base64Encode(utf8.encode('$username:$password'))}';

  Map<String, String> get headers => {
    'Authorization': authHeader,
    'Content-Type': 'application/json',
  };

  Future<PowerReading?> fetchPowerReading(int device, int unitId, int address) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/read_power/$device/$unitId/$address'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return PowerReading.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load power reading');
    }
  }

  Future<RelayStatus?> fetchRelayStatus(int? gpioPin) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/relay/$gpioPin/status'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return RelayStatus.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load relay status');
    }
  }

  Future<void> turnOnRelay(int gpioPin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/relay/$gpioPin/on'),
      body: jsonEncode({'pin': gpioPin, 'state': 1}),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to turn on relay');
    }
  }

  Future<void> turnOffRelay(int gpioPin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/relay/$gpioPin/off'),
      body: jsonEncode({'pin': gpioPin, 'state': 0}),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to turn off relay');
    }
  }
}
