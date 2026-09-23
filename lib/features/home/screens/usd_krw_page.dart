import 'package:dollar_trapped/features/exchange/screens/usd_krw_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dollar_trapped/features/shared/data/dollar_repository.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:dollar_trapped/features/profile/screens/my_page.dart';
import 'package:dollar_trapped/features/chat/screens/usd_room_page.dart';

class UsdKrwPage extends StatefulWidget {
  const UsdKrwPage({super.key, this.repository, this.initialPage = 1});

  final DollarRepository? repository;
  final int initialPage;

  @override
  State<UsdKrwPage> createState() => _UsdKrwPageState();
}

class _UsdKrwPageState extends State<UsdKrwPage> {
  late final PageController _pageController;
  late int _activePage;

  @override
  void initState() {
    super.initState();
    _activePage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository =
        widget.repository ??
        context.read<DollarRepository?>() ??
        MockDollarRepository();
    return PageView(
      controller: _pageController,
      onPageChanged: (page) {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _activePage = page);
      },
      children: [
        MyPage(
          repository: repository,
          onBack: () => _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          ),
        ),
        UsdKrwDetailPage(repository: repository),
        UsdRoomPage(
          isActive: _activePage == 2,
          repository: repository,
          onRateBarTap: () => _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          ),
        ),
      ],
    );
  }
}
