import 'dart:async';
import 'package:http/http.dart' as http;

class NetworkMetrics {
  final double throughput;
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
        'throughput': throughput.round(), 
        'avg_bitrate': avgBitrate,
        'delay_qos': delayQos.toDouble(),
        'jitter': jitter.toDouble(),
        'packet_loss': packetLoss ,
      };
}

class NetworkTestService {
  Future<NetworkMetrics> runFullNetworkTest() async {
    try {
      final List<Map<String, dynamic>> results = await Future.wait([
        _runPingTest(),
        _runSpeedTest(),
      ]);

      final pingData = results[0];
      final speedData = results[1];

      return NetworkMetrics(
        throughput: (speedData['throughput'] as num).toDouble(),
        avgBitrate: (speedData['avg_bitrate'] as num).toInt(),
        delayQos: (pingData['delay_qos'] as num).toInt(),
        jitter: (pingData['jitter'] as num).toInt(),
        packetLoss: (pingData['packet_loss'] as num).toInt(),
      );
    } catch (e) {
      return NetworkMetrics(
        throughput: 0.1,
        avgBitrate: 90,
        delayQos: 600,
        jitter: 150,
        packetLoss: 100,
      );
    }
  }

  Future<Map<String, dynamic>> _runPingTest() async {
    final url = Uri.parse('https://google.com');
    List<int> delays = [];
    int receivedPackets = 0;
    const int sentPackets = 15;
    final startTime = DateTime.now();

    for (int i = 0; i < sentPackets; i++) {
      if (DateTime.now().difference(startTime).inSeconds > 30) {
        break;
      }
      try {
        final stopwatch = Stopwatch()..start();
        final response = await http.get(url).timeout(const Duration(milliseconds: 1500));
        stopwatch.stop();

        if (response.statusCode == 200) {
          receivedPackets++;
          delays.add(stopwatch.elapsedMilliseconds);
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 50));
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
    } else {
      delayQos = 600.0;
      jitter = 150.0;
    }

    final int packetLossPercentage = ((lostPackets / sentPackets) * 100).round();

    return {
      'delay_qos': delayQos.round(),
      'jitter': jitter.round(),
      'packet_loss': packetLossPercentage,
    };
  }

  Future<Map<String, dynamic>> _runSpeedTest() async {
    try {
      final url = Uri.parse('https://google.com');
      double totalBytes = 0;
      const int attempts = 4;
      
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < attempts; i++) {
        if (stopwatch.elapsed.inSeconds > 30) {
          break;
        }
        try {
          final response = await http.get(url).timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            totalBytes += response.bodyBytes.length;
          }
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      stopwatch.stop();

      final double durationInSeconds = stopwatch.elapsedMilliseconds / 1000;
      if (totalBytes == 0 || durationInSeconds == 0) {
        return {'throughput': 0.01, 'avg_bitrate': 10};
      }

      final double totalBits = totalBytes * 8;
      final double speedInBps = totalBits / durationInSeconds;
      
      final double throughputMbps = (speedInBps / 1000000) * 15.5;
      final int avgBitrateKbps = ((speedInBps / 1000) * 9.5).round();

      return {
        'throughput': throughputMbps < 0.01 ? 0.01 : double.parse(throughputMbps.toStringAsFixed(2)),
        'avg_bitrate': avgBitrateKbps,
      };
    } catch (e) {
      return {'throughput': 0.01, 'avg_bitrate': 10};
    }
  }
}