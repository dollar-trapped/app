import 'package:flutter/material.dart';

/// Shared card sleeve, so waiting and reveal frames have the same silhouette.
class GachaCardBack extends StatelessWidget {
  const GachaCardBack({super.key, this.number, this.prompt});
  final int? number;
  final String? prompt;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x55E3D99A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (prompt != null)
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Text(
                prompt!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFF2E9BB), fontSize: 11),
              ),
            ),
          const Center(
            child: Icon(
              Icons.auto_awesome_outlined,
              size: 30,
              color: Color(0xFFF2E9BB),
            ),
          ),
          if (number != null)
            Positioned(
              top: 6,
              left: 8,
              child: Text(
                number.toString().padLeft(2, '0'),
                style: const TextStyle(color: Color(0x99F2E9BB), fontSize: 10),
              ),
            ),
        ],
      ),
    ),
  );
}
