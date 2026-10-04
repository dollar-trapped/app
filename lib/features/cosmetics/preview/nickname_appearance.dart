import 'package:flutter/material.dart';

/// Presentation examples only. These values do not grant or equip an item.
enum NicknameAppearance {
  basic('기본 글자색', Color(0xFF151916)),
  dollarGreen('달러 그린', Color(0xFF008A29)),
  vintageGold('빈티지 골드', Color(0xFF906719));

  const NicknameAppearance(this.label, this.color);
  final String label;
  final Color color;
  String get description => '$label · 기본 글꼴 · 배경 없음';
}
