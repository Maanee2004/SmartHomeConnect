import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../constants.dart';

class TempDisplay extends StatelessWidget {
  const TempDisplay({
    super.key,
    required this.currentTemp,
    required this.progress,
    required this.mColor,
  });

  final double progress;
  final double currentTemp;
  final double trackWidth = defaultPadding + 4;
  final Color mColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: EdgeInsets.all(defaultPadding * 3),
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                    child: Container(color: glassColor),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Transform.rotate(
                angle: pi,
                child:
                    CustomPaint(painter: TempDisplayPainter(progress, mColor)),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(trackWidth),
                child: Container(
                  decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: mColor.withValues(alpha: 0.45),
                          blurRadius: defaultPadding,
                          offset: Offset(0, defaultPadding + 10),
                          spreadRadius: 4,
                        )
                      ]),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 8),
                          Text(
                            '${currentTemp.toInt()}',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              '°C',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Transform.rotate(
                    angle: pi,
                    child: Padding(
                      padding: EdgeInsets.all(trackWidth + 8),
                      child: CustomPaint(painter: DotPainter(progress, mColor)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TempDisplayPainter extends CustomPainter {
  final double progress;
  final Color mColor;

  TempDisplayPainter(this.progress, this.mColor);

  @override
  void paint(Canvas canvas, Size size) {
    double theta = progress * pi;

    double centerX = size.width / 2;
    double centerY = size.height / 2;

    Offset center = Offset(centerX, centerY);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width / 2),
      0,
      pi,
      true,
      Paint()..color = glassColor,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width / 2),
      0,
      theta,
      true,
      Paint()..color = mColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DotPainter extends CustomPainter {
  final double progress;
  final Color mColor;

  DotPainter(this.progress, this.mColor);

  @override
  void paint(Canvas canvas, Size size) {
    double theta = progress * pi;

    double centerX = size.width / 2;
    double centerY = size.height / 2;

    double dotX = cos(theta) * centerX + centerX;
    double dotY = sin(theta) * centerY + centerY;

    Offset top = Offset(dotX, dotY);

    canvas.drawCircle(top, 3, Paint()..color = mColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
