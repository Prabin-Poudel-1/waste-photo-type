import 'package:flutter/material.dart';

import '../../help/help_screen.dart';
import '../../location_intelligence/waste_map_screen.dart';
import '../../reports/screens/my_reports_screen.dart';
import 'home_screen.dart';

class TouristShell extends StatefulWidget {
  const TouristShell({super.key});

  @override
  State<TouristShell> createState() {
    return _TouristShellState();
  }
}

class _TouristShellState
    extends State<TouristShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() {
            index = 0;
          });
        }
      },
      child: Scaffold(
        body: [
          const HomeScreen(),
          const WasteMapScreen(),
          const MyReportsScreen(),
          const HelpScreen(),
        ][index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) {
            setState(() {
              index = value;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.receipt_long_outlined,
              ),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Icon(Icons.help_outline),
              label: 'Help',
            ),
          ],
        ),
      ),
    );
  }
}// Placeholder: paste the contents of mobile/lib/features/home/screens/tourist_shell.dart from your app here.
