import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';

Widget wrapInCard({
  required Widget widget,
  double padding = defaultPadding,
  Color? backgroundColor,
}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: backgroundColor,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 24,
          spreadRadius: -6,
          offset: const Offset(0, 18),
        )
      ],
      borderRadius: const BorderRadius.all(Radius.circular(defaultPadding)),
    ),
    child: widget,
  );
}
