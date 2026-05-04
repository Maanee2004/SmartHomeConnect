import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants.dart';
import '../../../widget_utils.dart';

class RoundedIconButton extends StatelessWidget {
  const RoundedIconButton({
    super.key,
    required this.icon,
    this.isSelected = false,
    this.onTap,
    required this.tempColor,
  });

  final String icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color tempColor;

  @override
  Widget build(BuildContext context) {
    var bgColor = isSelected ? Colors.white : tempColor.withValues(alpha: 0.4);
    return InkWell(
        onTap: onTap,
        child: wrapInCard(
          widget: SvgPicture.asset(
            icon,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              isSelected ? Colors.black : Colors.white,
              BlendMode.srcIn,
            ),
          ),
          padding: defaultPadding + 4,
          backgroundColor: bgColor,
        ));
  }
}
