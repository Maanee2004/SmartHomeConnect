import 'package:flutter/material.dart';

import 'components/ac_screen_body.dart';

class ACScreen extends StatelessWidget {
  const ACScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'SMARTHOME ',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: scheme.onSurface),
        ),
        leading: Row(
          children: [
            const SizedBox(width: 8),
            BackButton(color: scheme.onSurface),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 92,
        centerTitle: true,
      ),
      body: const ACScreenBody(),
    );
  }
}
