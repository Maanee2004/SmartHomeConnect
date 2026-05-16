import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Bannière compacte lorsqu’aucune connectivité n’est détectée (UI seulement).
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  List<ConnectivityResult>? _results;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  static bool _isOffline(List<ConnectivityResult> r) {
    if (r.isEmpty) return false;
    return r.every((e) => e == ConnectivityResult.none);
  }

  @override
  void initState() {
    super.initState();
    _bind();
  }

  Future<void> _bind() async {
    try {
      final initial = await Connectivity().checkConnectivity();
      if (mounted) setState(() => _results = initial);
    } catch (_) {
      if (mounted) {
        setState(() => _results = const [ConnectivityResult.wifi]);
      }
    }
    _sub = Connectivity().onConnectivityChanged.listen((r) {
      if (mounted) setState(() => _results = r);
    });
  }

  @override
  void dispose() {
    final s = _sub;
    _sub = null;
    if (s != null) {
      unawaited(s.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = _results;
    if (r == null || !_isOffline(r)) return const SizedBox.shrink();
    return Material(
      color: const Color(0xFFB45309),
      child: Semantics(
        label: 'Pas de connexion réseau',
        container: true,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pas de connexion',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
