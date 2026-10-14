import 'package:flutter/material.dart';
import 'features/attendance/preview/attendance_preview_page.dart';

/// Explicit offline entry point; no authentication, ads, or reward API calls.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Noto Sans KR',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF008A29)),
        useMaterial3: true,
      ),
      home: const AttendancePreviewPage(),
    ),
  );
}
