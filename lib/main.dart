import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); //runApp 전에 Flutter 서비스 사용을 위해 바인딩 초기화
  SystemChrome.setSystemUIOverlayStyle( //상태바/시스템 내비게이션 바 스타일 설정
    const SystemUiOverlayStyle( //OS 시스템 UI의 색상/아이콘 밝기 설정
      statusBarColor: Color(0xFFFFFFFF),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFFFFFF),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const DollarTrappedApp()); //DollarTrappedApp을 루트 위젯으로 앱 실행
}
