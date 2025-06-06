import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorDebugPage extends StatefulWidget {
  const SensorDebugPage({super.key});

  @override
  State<SensorDebugPage> createState() => _SensorDebugPageState();
}

class _SensorDebugPageState extends State<SensorDebugPage> {
  String _shakeStatus = 'Belum ada shake';
  StreamSubscription? _accelSub;
  double _shakeThreshold = 5.0;
  DateTime? _lastShakeTime;

  @override
  void initState() {
    super.initState();
    _accelSub = accelerometerEvents.listen((event) {
      double acceleration =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (acceleration > _shakeThreshold) {
        if (_lastShakeTime == null ||
            DateTime.now().difference(_lastShakeTime!) > Duration(seconds: 1)) {
          _lastShakeTime = DateTime.now();
          setState(() {
            _shakeStatus =
                'Shake terdeteksi! (acceleration: ${acceleration.toStringAsFixed(2)})';
          });
          print('[DEBUG] SHAKE DETECTED! acceleration=$acceleration');
        }
      }
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shake Sensor:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_shakeStatus,
                style: TextStyle(fontSize: 16, color: Colors.deepPurple)),
            const SizedBox(height: 24),
            const Text('Accelerometer:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            StreamBuilder<AccelerometerEvent>(
              stream: accelerometerEvents,
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data != null) {
                  print(
                      '[DEBUG] Accelerometer: x=${data.x}, y=${data.y}, z=${data.z}');
                }
                return Text(
                  data != null
                      ? 'x: ${data.x.toStringAsFixed(2)}, y: ${data.y.toStringAsFixed(2)}, z: ${data.z.toStringAsFixed(2)}'
                      : 'No data',
                  style: const TextStyle(fontSize: 16),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Gyroscope:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            StreamBuilder<GyroscopeEvent>(
              stream: gyroscopeEvents,
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data != null) {
                  print(
                      '[DEBUG] Gyroscope: x=${data.x}, y=${data.y}, z=${data.z}');
                }
                return Text(
                  data != null
                      ? 'x: ${data.x.toStringAsFixed(2)}, y: ${data.y.toStringAsFixed(2)}, z: ${data.z.toStringAsFixed(2)}'
                      : 'No data',
                  style: const TextStyle(fontSize: 16),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Magnetometer:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            StreamBuilder<MagnetometerEvent>(
              stream: magnetometerEvents,
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data != null) {
                  print(
                      '[DEBUG] Magnetometer: x=${data.x}, y=${data.y}, z=${data.z}');
                }
                return Text(
                  data != null
                      ? 'x: ${data.x.toStringAsFixed(2)}, y: ${data.y.toStringAsFixed(2)}, z: ${data.z.toStringAsFixed(2)}'
                      : 'No data',
                  style: const TextStyle(fontSize: 16),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
