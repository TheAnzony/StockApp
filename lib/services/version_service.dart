import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionService {
  static Future<bool> isUpdateRequired() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('version')
          .get();

      if (!doc.exists) return false;

      final minVersion = doc.data()?['min_version'] as String?;
      if (minVersion == null) return false;

      final info = await PackageInfo.fromPlatform();
      return _isOutdated(info.version, minVersion);
    } catch (_) {
      return false;
    }
  }

  static bool _isOutdated(String current, String minimum) {
    final c = current.split('.').map(int.parse).toList();
    final m = minimum.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      final cv = i < c.length ? c[i] : 0;
      final mv = i < m.length ? m[i] : 0;
      if (cv < mv) return true;
      if (cv > mv) return false;
    }
    return false;
  }
}
