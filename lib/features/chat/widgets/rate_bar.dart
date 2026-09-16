import 'package:flutter/material.dart';

class RateBar extends StatelessWidget {
  const RateBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE1E6E2))),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'USD/KRW',
                    style: TextStyle(
                      color: Color(0xFF667069),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 20 / 13,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '1,346.09원',
                    style: TextStyle(
                      color: Color(0xFF151916),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                '▼ 8.31 (−0.61%) · 전일 대비',
                style: TextStyle(
                  color: Color(0xFF2463B5),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
          Text(
            '›',
            style: TextStyle(
              color: Color(0xFF667069),
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
