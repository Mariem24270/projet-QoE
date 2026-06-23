import 'dart:async';
import 'package:dart_ping/dart_ping.dart';
import 'package:http/http.dart' as http;

class NetworkMetrics {
  final int throughput;
  final int avgBitrate;
  final int delayQos;
  final int jitter;
  final int packetLoss;

  NetworkMetrics({
    required this.throughput,
    required this.avgBitrate,
    required this.delayQos,
    required this.jitter,
    required this.packetLoss,
  });

  Map<String, dynamic> toJson() => {
        'throughput': throughput,
        'avg_bitrate': avgBitrate,
        'delay_qos': delayQos.toDouble(),
        'jitter': jitter.toDouble(),
        'packet_loss': packetLoss ,
      };
}

class NetworkTestService {
  Future<NetworkMetrics> runFullNetworkTest() async {
    try {
      final results = await Future.wait([
        _runPingTest().timeout(const Duration(seconds: 30)),
        _runSpeedTest().timeout(const Duration(seconds: 30)),
      ]);

      final pingData = results[0] ;
      final speedData = results[1] ;

      return NetworkMetrics(
        throughput: speedData['throughput'],
        avgBitrate: speedData['avg_bitrate'],
        delayQos: pingData['delay_qos'],
        jitter: pingData['jitter'],
        packetLoss: pingData['packet_loss'],
      );
    } catch (e) {
      throw Exception('Échec du test réseau : $e');
    }
  }

  Future<Map<String, dynamic>> _runPingTest() async {
    final ping = Ping('8.8.8.8', count: 10, timeout: 2000);
    List<int> delays = [];
    int receivedPackets = 0;
    const int sentPackets = 10;

    await for (final response in ping.stream) {
      if (response.response != null && response.response!.time != null) {
        receivedPackets++;
        delays.add(response.response!.time!.inMilliseconds);
      }
    }

    int lostPackets = sentPackets - receivedPackets;
    double delayQos = 0.0;
    double jitter = 0.0;

    if (delays.isNotEmpty) {
      delayQos = delays.reduce((a, b) => a + b) / delays.length;
      if (delays.length > 1) {
        double totalJitterDiff = 0.0;
        for (int i = 0; i < delays.length - 1; i++) {
          totalJitterDiff += (delays[i + 1] - delays[i]).abs();
        }
        jitter = totalJitterDiff / (delays.length - 1);
      }
    }

    final int packetLossPer1000 = ((lostPackets / sentPackets) * 1000).round();

    return {
      'delay_qos': delayQos.round(),
      'jitter': jitter.round(),
      'packet_loss': packetLossPer1000,
    };
  }

  Future<Map<String, dynamic>> _runSpeedTest() async {
    try {
      final url = Uri.parse('https://www.google.com');
      List<int> speeds = [];
      const int attempts = 3;

      for (int i = 0; i < attempts; i++) {
        final stopwatch = Stopwatch();
        stopwatch.start();
        final response = await http.get(url);
        stopwatch.stop();

        if (response.statusCode == 200) {
          final double fileSizeInBits = response.bodyBytes.length * 8;
          final double durationInSeconds = stopwatch.elapsedMilliseconds / 1000;
          final double speedInBps = fileSizeInBits / durationInSeconds;
          final int speedInKbps = (speedInBps / 1000).round();
          speeds.add(speedInKbps);
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (speeds.isEmpty) {
        return {'throughput': 0, 'avg_bitrate': 0};
      }

      final int lastSpeed = speeds.last;
      final int avgSpeed = speeds.reduce((a, b) => a + b) ~/ speeds.length;

      return {
        'throughput': lastSpeed,
        'avg_bitrate': avgSpeed,
      };
    } catch (e) {
      return {'throughput': 0, 'avg_bitrate': 0};
    }
  }
}