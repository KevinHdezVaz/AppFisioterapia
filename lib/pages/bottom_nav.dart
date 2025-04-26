import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/pages/PromotionsScreen.dart';
import 'package:user_auth_crudd10/pages/RewardsScreen.dart';
import 'package:user_auth_crudd10/pages/TicketUploadScreen.dart';
import 'package:user_auth_crudd10/pages/home_page.dart';
import 'package:user_auth_crudd10/pages/others/profile_page.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/colors.dart';

class BottomNavBar extends StatefulWidget {
  final int initialIndex;

  const BottomNavBar({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _selectedIndex;
  final StorageService _storageService = StorageService();
  late final List<Widget> _pages;

  void _changeIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    _pages = [
      const HomeScreen(),
      const TicketUploadScreen(),
      const RewardsScreen(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: LumorahColors.primary.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.7),
            backgroundColor: LumorahColors.primary,
            currentIndex: _selectedIndex,
            onTap: _changeIndex,
            elevation: 0,
            iconSize: 24,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt_outlined),
                activeIcon: Icon(Icons.camera_alt),
                label: 'Subir Ticket',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.card_giftcard_outlined),
                activeIcon: Icon(Icons.card_giftcard),
                label: 'Premios',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
