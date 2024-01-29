import 'package:flavorfuse_app/screens/home/HomePage.dart';
import 'package:flavorfuse_app/screens/ordering/OrderHistoryPage.dart';
import 'package:flavorfuse_app/screens/restaurant/ExplorerPage.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class BottomNavBar extends StatefulWidget {
  final int screenInt;
  const BottomNavBar({this.screenInt});

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomePage(),
    RestaurantExplorer(),
    OrderHistoryPage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.screenInt ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      home: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
        extendBody: true, // Add this line
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const CustomBottomNavBar({
    Key key,
    this.selectedIndex,
    this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 40.0, // Adjust the height as needed
          decoration: BoxDecoration(
            color: Colors.white, // Background color of the top area
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15.0),
              topRight: Radius.circular(15.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 3,
                blurRadius: 3,
                offset: Offset(0, 2), // changes position of shadow
              ),
            ],
          ),
        ),
        BottomAppBar(
          color: Colors.transparent,
          elevation: 0.0,
          child: Container(
            decoration: BoxDecoration(
              color:
                  Colors.white, // Background color of the bottom navigation bar
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                AnimatedNavBarItem(
                  icon: FaIcon(FontAwesomeIcons.home).icon,
                  label: 'Home',
                  isSelected: selectedIndex == 0,
                  onTap: () => onItemTapped(0),
                ),
                AnimatedNavBarItem(
                  icon: FaIcon(FontAwesomeIcons.mapMarkedAlt).icon,
                  label: 'Explorer',
                  isSelected: selectedIndex == 1,
                  onTap: () => onItemTapped(1),
                ),
                AnimatedNavBarItem(
                  icon: FaIcon(FontAwesomeIcons.history).icon,
                  label: 'History',
                  isSelected: selectedIndex == 2,
                  onTap: () => onItemTapped(2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AnimatedNavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const AnimatedNavBarItem({
    Key key,
    this.icon,
    this.label,
    this.isSelected,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: 2.2,
              width: isSelected ? 40.0 : 0.0,
              color: isSelected
                  ? Colors.amber[900]
                  : Colors.transparent, // Adjust the color
              margin: const EdgeInsets.only(bottom: 7.0),
            ),
            Icon(
              icon,
              color: isSelected
                  ? Colors.amber[900]
                  : Colors.grey, // Adjust the color
              size: 22.0,
            ),
            const SizedBox(height: 5.0),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 400),
              style: GoogleFonts.openSans(
                textStyle: TextStyle(
                  color: isSelected
                      ? Colors.orange[700]
                      : Colors.grey, // Adjust the color
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12.5,
                ),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
