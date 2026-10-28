import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import 'app_store.dart';
import 'features/check_in/check_in_page.dart';
import 'features/correction/correction_page.dart';
import 'features/history/history_page.dart';
import 'features/settings/settings_page.dart';

class AppShell extends SignalStatefulWidget {
  const AppShell({super.key, required this.store});

  final AppStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // 底部导航当前选中的页面索引。
  final _selectedIndex = signal(0);

  @override
  void dispose() {
    _selectedIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.store.isLoading.value) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (widget.store.loadError.value case final error?) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: widget.store.initialize,
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // IndexedStack 不会销毁未选中的页面，因此可以保留页面滚动位置和表单状态。
    final pages = [
      CheckInPage(store: widget.store),
      HistoryPage(store: widget.store),
      CorrectionPage(store: widget.store),
      SettingsPage(store: widget.store),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex.value, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex.value,
        onDestinationSelected: (index) => _selectedIndex.value = index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.fingerprint), label: '签到'),
          NavigationDestination(icon: Icon(Icons.history), label: '历史'),
          NavigationDestination(icon: Icon(Icons.edit_calendar), label: '补签'),
          NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
