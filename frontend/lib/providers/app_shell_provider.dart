import 'package:flutter/foundation.dart';

enum AppPage { atividades, eventos, consistencia, ajustes }

class AppShellProvider extends ChangeNotifier {
  static const List<AppPage> pages = [
    AppPage.atividades,
    AppPage.eventos,
    AppPage.consistencia,
    AppPage.ajustes,
  ];

  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  AppPage get currentPage => pages[_currentIndex];

  void selectIndex(int index) {
    if (index < 0 || index >= pages.length || index == _currentIndex) return;
    _currentIndex = index;
    notifyListeners();
  }

  void selectPage(AppPage page) {
    final index = pages.indexOf(page);
    selectIndex(index);
  }
}
