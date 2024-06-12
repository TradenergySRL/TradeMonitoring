# HVAC System App

## Índice

1. [Descripción](#descripción)
2. [Instalación](#instalación)
   1. [Clonar el repositorio](#clonar-el-repositorio)
   2. [Instalar dependencias](#instalar-dependencias)
3. [Configuración](#configuración)
   1. [Configurar Ngrok con OAuth](#configurar-ngrok-con-oauth)
   2. [Configurar el proyecto Flutter](#configurar-el-proyecto-flutter)
4. [Implementación](#implementación)
   1. [Autenticación](#autenticación)
      1. [Servicio de autenticación](#servicio-de-autenticación)
      2. [Página de inicio de sesión](#página-de-inicio-de-sesión)
   2. [Interfaz de usuario](#interfaz-de-usuario)
      1. [Crear HomePage](#crear-homepage)
      2. [Crear ProfilePage](#crear-profilepage)
5. [Pantalla de inicio personalizada](#pantalla-de-inicio-personalizada)
   1. [Configurar la pantalla de inicio en Android](#configurar-la-pantalla-de-inicio-en-android)
6. [Ejecución de la aplicación](#ejecución-de-la-aplicación)

## 1. Descripción

Aplicación de monitoreo HVAC con autenticación mediante OAuth en Ngrok y una pantalla de inicio personalizada.

## 2. Instalación

### 2.1. Clonar el repositorio

```bash
git clone https://github.com/tu_usuario/hvac_system.git
cd hvac_system
```

### 2.2. Instalar dependencias

Estas son la dependencia que tengo en [pubspec.yaml]

```yaml
dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.6
  http: ^1.2.1
  font_awesome_flutter: ^10.7.0
  syncfusion_flutter_gauges: ^25.2.7
  shared_preferences: ^2.2.3
  provider: ^6.1.2
```

Para installar las dependencia ejeutar el siguiente comando

```bash
flutter pub get
```

## 3. Configuración

### 3.1. Configurar Ngrok con OAuth

Crear una cuenta en Ngrok y configurar OAuth con el proveedor de tu elección (Google en este caso).

Obtener el client_id y client_secret de tu aplicación OAuth de Google.

Configurar Ngrok para que utilice OAuth:

```bash
/usr/local/bin/ngrok http 5000 \
  --domain=together-amazingly-mouse.ngrok-free.app \
  --oauth=google \
  --oauth-client-id="your-client-id" \
  --oauth-client-secret="your-client-secret" &
```

### 3.2. Configurar el proyecto Flutter

Configurar el archivo pubspec.yaml para incluir las dependencias necesarias:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  http: ^0.13.3
  shared_preferences: ^2.0.6
  font_awesome_flutter: ^9.1.0
  syncfusion_flutter_gauges: ^18.4.47
```

Crear los archivos necesarios en el proyecto Flutter:

## 4. Implementación

### 4.1. Autenticación

#### 4.1.1. Servicio de autenticación

Crear el archivo lib/services/auth_service.dart:

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  static const String baseUrl = 'https://together-amazingly-mouse.ngrok-free.app';
  late String _token;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
  String get token => _token;

  Future<void> authenticateWithCredentials(String username, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final auth = 'Basic ${base64Encode(utf8.encode('$username:$password'))}';

    final response = await http.post(
      url,
      headers: {'Authorization': auth},
    );

    if (response.statusCode == 200) {
      _token = json.decode(response.body)['token'];
      _isAuthenticated = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token);
      notifyListeners();
    } else {
      throw Exception('Failed to authenticate');
    }
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('token')) {
      _token = prefs.getString('token')!;
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _isAuthenticated = false;
    notifyListeners();
  }
}
```

#### 4.1.2. Página de inicio de sesión

Crear el archivo lib/pages/login_page.dart:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<AuthService>(context, listen: false).authenticateWithCredentials(
        _usernameController.text,
        _passwordController.text,
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to authenticate: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 4.2. Interfaz de usuario

#### 4.2.1. Crear HomePage

En lib/pages/home_page.dart, define la pantalla principal.

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../services/api_service.dart';
import '../models/power_reading.dart';
import '../models/relay_status.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    fetchInitialData();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchPowerReading();
      fetchRelayStatuses();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchInitialData() async {
    setState(() {
      _isLoading = true;
    });
    await Future.wait([fetchPowerReading(), fetchRelayStatuses()]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchPowerReading() async {
    try {
      PowerReading? reading = await apiService.fetchPowerReading(1, 1, 19034);
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
    0: 5,
    1: 6,
    2: 17,
  };

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/avatar.png'),
              radius: 20,
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
              // Acción al presionar el icono de notificaciones
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
                          'assets/device.png',
                          width: 40,
                          height: 40,
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CADIS Mallen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('TRADE-CS20M', style: TextStyle(fontSize: 14, color: Colors.blue)),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                      ],
                    ),
                  ),
                  const Text('Potencia', style: TextStyle(fontSize: 20)),
                  PowerGauge(powerReading: powerReading, gaugeMaxValue: gaugeMaxValue),
                  const Text('Compresores', style: TextStyle(fontSize: 20)),
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
          backgroundColor: Colors.transparent,
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

    return Container(
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
      child: Center(
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
                color: status.status == 'on' ? Colors.green : Colors.grey,
              ),
            ],
          ),
          Switch(
            value: status.status == 'on',
            onChanged: (value) {
              if (value) {
                turnOnRelay(status.relayIndex);
              } else {
                turnOffRelay(status.relayIndex);
              }
            },
          ),
        ],
      ),
    );
  }
}
```

#### 4.2.2. Crear ProfilePage

En lib/pages/profile_page.dart, define la pantalla del perfil del usuario:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  void _signOut() async {
    await Provider.of<AuthService>(context, listen: false).logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Usuario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Apellido'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu apellido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Datos guardados')),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 5.1. Pantalla de inicio personalizada

### 5.1.1 Configurar la pantalla de inicio en Android

Modificar android/app/src/main/res/drawable/launch_background.xml:

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Modify this file to customize your launch splash screen -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/launch_image" />
    </item>
</layer-list>
```

Modificar android/app/src/main/res/values/styles.xml:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
```

Modificar android/app/src/main/AndroidManifest.xml:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="hvac_system"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

## 6.1 Ejecución de la aplicación

Para ejecutar la aplicación, usa el siguiente comando:

```bash
flutter run
```

Esto lanzará la aplicación en tu dispositivo o emulador conectado.



