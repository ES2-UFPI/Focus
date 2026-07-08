import 'package:flutter/foundation.dart';

enum AppPage { atividades, eventos, disciplinas, consistencia, perfil, pomodoro, ajustes }

class AppShellProvider extends ChangeNotifier {
  static const List<AppPage> pages = [
    AppPage.atividades,
    AppPage.eventos,
    AppPage.disciplinas,
    AppPage.consistencia,
    AppPage.perfil,
    AppPage.pomodoro,
    AppPage.ajustes,
  ];

  int _currentIndex = 0;
  int _pomodoroRefreshRevision = 0;

  int get currentIndex => _currentIndex;

  AppPage get currentPage => pages[_currentIndex];

  int get pomodoroRefreshRevision => _pomodoroRefreshRevision;

  void selectIndex(int index) {
    if (index < 0 || index >= pages.length || index == _currentIndex) return;
    _currentIndex = index;
    notifyListeners();
  }

  void selectPage(AppPage page) {
    final index = pages.indexOf(page);
    selectIndex(index);
  }

  void notifyPomodoroDataChanged() {
    _pomodoroRefreshRevision++;
    notifyListeners();
  }
}
