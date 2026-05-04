import 'package:flutter/material.dart';

class NumberButton extends StatelessWidget {
  const NumberButton({
    super.key,
    required this.number,
    required this.onTap,
    this.isSelected = false,
  });

  final int number;
  final bool isSelected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap(number);
      },
      child: SizedBox(
        width: 32,
        height: 32,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Center(
            child: Text(
              "$number",
              style: (Theme.of(context).textTheme.bodyLarge ??
                      const TextStyle())
                  .apply(color: isSelected ? Colors.black : Colors.white),
            ),
          ),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white38, width: 1),
          ),
        ),
      ),
    );
  }
}
