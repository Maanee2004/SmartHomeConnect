import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Adresse locale pour ouvrir l’app Web sur un téléphone (même Wi‑Fi).
class LanAccessConfig {
  LanAccessConfig._();

  static const defaultPort = 8080;
  static const _hostKey = 'lan_access_host';
  static const _portKey = 'lan_access_port';

  static bool isPrivateLanHost(String host) {
    final h = host.trim();
    if (h.isEmpty || h == 'localhost' || h == '127.0.0.1') return false;
    return RegExp(r'^(192\.168\.|10\.|172\.(1[6-9]|2\d|3[01])\.)').hasMatch(h);
  }

  /// Web ouvert via l’IP LAN du PC (après scan QR sur le téléphone).
  static bool get isBrowsingOnLanServer =>
      kIsWeb && isPrivateLanHost(Uri.base.host);

  static String? get currentBrowsingLanUrl {
    if (!isBrowsingOnLanServer) return null;
    final port = Uri.base.port;
    final host = Uri.base.host;
    if (port > 0 && port != 80 && port != 443) {
      return 'http://$host:$port/';
    }
    return 'http://$host/';
  }

  static Future<String?> loadHost() async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString(_hostKey)?.trim();
    return host != null && host.isNotEmpty ? host : null;
  }

  static Future<int> loadPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_portKey) ?? defaultPort;
  }

  static Future<void> save({required String host, required int port}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, host.trim());
    await prefs.setInt(_portKey, port);
  }

  static String buildUrl({required String host, required int port}) {
    final h = host.trim();
    if (h.isEmpty) return '';
    return 'http://$h:$port/';
  }
}
