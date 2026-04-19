import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  static const _appDistributionUrl =
      'https://appdistribution.firebase.google.com/testerapps/1:1016052971435:android:2ade449e1f79598e8504ee';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.system_update, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Actualización requerida',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Hay una nueva versión disponible. Debes actualizarla para continuar.',
                style: TextStyle(fontSize: 15, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text('Actualizar ahora', style: TextStyle(color: Colors.white, fontSize: 16)),
                onPressed: () => launchUrl(Uri.parse(_appDistributionUrl),
                    mode: LaunchMode.externalApplication),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
