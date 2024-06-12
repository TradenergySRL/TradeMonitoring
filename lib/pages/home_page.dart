import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../services/api_service.dart';
import '../models/power_reading.dart';
import '../models/relay_status.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late ApiService apiService;
  PowerReading powerReading = PowerReading(power: 0.0, device: 0, unitId: 0, address: 0);
  List<RelayStatus> relayStatuses = [
    RelayStatus(relayIndex: 0, status: 'off'),
    RelayStatus(relayIndex: 1, status: 'off'),
    RelayStatus(relayIndex: 2, status: 'off')
  ];
  bool _isLoading = true;
  Timer? _timer;
  final double gaugeMaxValue = 50.0;
  int _selectedIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    fetchInitialData();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchPowerReading(_tabController.index + 1); // Fetch based on current tab
      fetchRelayStatuses();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    fetchPowerReading(_tabController.index + 1); // Fetch based on current tab
  }

  Future<void> fetchInitialData() async {
    setState(() {
      _isLoading = true;
    });
    await Future.wait([fetchPowerReading(1), fetchRelayStatuses()]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchPowerReading(int deviceId) async {
    try {
      PowerReading? reading = await apiService.fetchPowerReading(deviceId, 1, 19034);
      setState(() {
        if (reading != null) {
          powerReading = reading;
        }
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchRelayStatuses() async {
    try {
      List<RelayStatus> statuses = [];
      for (int i = 0; i < 3; i++) {
        int? gpioPin = relayPinMap[i];
        RelayStatus? status = await apiService.fetchRelayStatus(gpioPin);
        if (status != null) {
          statuses.add(status);
        }
      }
      setState(() {
        relayStatuses = statuses;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> turnOnRelay(int relayIndex) async {
    try {
      await apiService.turnOnRelay(relayIndex);
      await Future.delayed(const Duration(seconds: 1));
      fetchRelayStatuses();
    } catch (e) {
      print(e);
    }
  }

  Future<void> turnOffRelay(int relayIndex) async {
    try {
      await apiService.turnOffRelay(relayIndex);
      await Future.delayed(const Duration(seconds: 1));
      fetchRelayStatuses();
    } catch (e) {
      print(e);
    }
  }

  final Map<int, int> relayPinMap = {
    0: 17,
    1: 27,
    2: 22,
  };

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/avatar.png'), // Reemplaza con la imagen de perfil
              radius: 20, // Tamaño del avatar 40x40 píxeles
            ),
            SizedBox(width: 8),
            Text(
              'gregorymoreno.iem',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
               Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Mi dispositivo', style: TextStyle(fontSize: 20)),
                  Container(
                    margin: const EdgeInsets.only(top: 10.0, bottom: 20.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/device.png', // Reemplaza con la imagen del dispositivo
                          width: 40,
                          height: 40,
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CADI Mallen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('TRADE-CS20M', style: TextStyle(fontSize: 14, color: Colors.blue)),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                      ],
                    ),
                  ),
                  const Text('Compresores', style: TextStyle(fontSize: 20)),
                  TabBar(
                          controller: _tabController,
                          labelColor: Colors.green,
                          unselectedLabelColor: Colors.grey,
                          tabs: const [
                            Tab(text: 'Compresor 1'),
                            Tab(text: 'Compresor 2'),
                            Tab(text: 'Compresor 3'),
                          ],
                        ),
                  Container(
                    margin: const EdgeInsets.only(top: 10.0, bottom: 20.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        
                        SizedBox(
                          height: 300, // Ajusta según sea necesario
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              PowerGauge(powerReading: powerReading, gaugeMaxValue: gaugeMaxValue),
                              PowerGauge(powerReading: powerReading, gaugeMaxValue: gaugeMaxValue),
                              PowerGauge(powerReading: powerReading, gaugeMaxValue: gaugeMaxValue),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Relés', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 10),
                  ...relayStatuses.map((status) {
                    int index = relayStatuses.indexOf(status);
                    return RelayControl(
                      index: index,
                      status: status,
                      turnOnRelay: turnOnRelay,
                      turnOffRelay: turnOffRelay,
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.device_hub_outlined),
              label: 'Dispositivo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              label: 'Comunicación',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Yo',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          backgroundColor: Colors.transparent, // Para que el contenedor blanco se vea
          showUnselectedLabels: true,
        ),
      ),
    );
  }
}

class PowerGauge extends StatelessWidget {
  final PowerReading powerReading;
  final double gaugeMaxValue;

  const PowerGauge({
    required this.powerReading,
    required this.gaugeMaxValue,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double gaugeSize = MediaQuery.of(context).size.width * 0.5;

    return Center(
      child: SizedBox(
        height: gaugeSize,
        width: gaugeSize,
        child: SfRadialGauge(
          axes: <RadialAxis>[
            RadialAxis(
              minimum: 0,
              maximum: gaugeMaxValue,
              ranges: <GaugeRange>[
                GaugeRange(startValue: 0, endValue: gaugeMaxValue * 0.33, color: Colors.green),
                GaugeRange(startValue: gaugeMaxValue * 0.33, endValue: gaugeMaxValue * 0.66, color: Colors.yellow),
                GaugeRange(startValue: gaugeMaxValue * 0.66, endValue: gaugeMaxValue, color: Colors.red),
              ],
              pointers: <GaugePointer>[
                NeedlePointer(value: double.parse(powerReading.power.toStringAsFixed(2))),
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                  widget: Text(
                    '${powerReading.power.toStringAsFixed(2)} kW',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  angle: 90,
                  positionFactor: 0.5,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RelayControl extends StatelessWidget {
  final int index;
  final RelayStatus status;
  final Future<void> Function(int relayIndex) turnOnRelay;
  final Future<void> Function(int relayIndex) turnOffRelay;

  const RelayControl({
    required this.index,
    required this.status,
    required this.turnOnRelay,
    required this.turnOffRelay,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text('Compresor ${index + 1}'),
              const SizedBox(width: 10),
              FaIcon(
                FontAwesomeIcons.solidSnowflake,
                color: status.status == 'off' ? Colors.green : Colors.grey,
              ),
            ],
          ),
          Switch(
            value: status.status == 'off',
            onChanged: (value) {
              if (value) {
                turnOffRelay(status.relayIndex);
              } else {
                turnOnRelay(status.relayIndex);
              }
            },
          ),
        ],
      ),
    );
  }
}
