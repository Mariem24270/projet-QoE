import 'package:flutter/material.dart';
import 'measurement_view_model.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: MeasurementWidget()),
      ),
    );
  }
}

class MeasurementWidget extends StatefulWidget {
  const MeasurementWidget({super.key});

  @override
  State<MeasurementWidget> createState() => _MeasurementWidgetState();
}

class _MeasurementWidgetState extends State<MeasurementWidget> {
  final MeasurementViewModel viewModel = MeasurementViewModel();
  String result = "Appuyez sur le bouton";

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(result, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 20),
        if (viewModel.isLoading)
          const CircularProgressIndicator()
        else
          ElevatedButton(
            onPressed: () async {
              setState(() => result = "Mesure en cours...");
              await viewModel.startMeasurement();
              setState(() {
                if (viewModel.mosScore != null) {
                  result = "MOS: ${viewModel.mosScore!.toStringAsFixed(2)}";
                } else {
                  result = "Erreur: ${viewModel.errorMessage}";
                }
              });
            },
            child: const Text("Mesurer"),
          ),
      ],
    );
  }
}
