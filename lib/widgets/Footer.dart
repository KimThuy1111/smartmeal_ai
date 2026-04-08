import 'package:flutter/material.dart';
import 'package:smartmeal_ai/screens/SuggestMealScreen.dart';
import '../screens/FoodDiaryScreen.dart';
import '../screens/HomeScreen.dart';
import '../screens/UserProfileScreen.dart';

class Footer extends StatelessWidget {
  final int currentIndex;

  const Footer({
    super.key,
    required this.currentIndex,
  });

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget screen;

    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = const FoodDiaryScreen();
        break;
      case 2:
        screen = const SuggestMealScreen();
        break;
      case 3:
        screen = const UserProfileScreen();
        break;
      default:
        screen = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(context, Icons.home, "Trang chủ", 0),
          _navItem(context, Icons.book, "Nhật ký", 1),
          _navItem(context, Icons.search, "Gợi ý", 2),
          _navItem(context, Icons.person, "Hồ sơ", 3),
        ],
      ),
    );
  }

  Widget _navItem(
      BuildContext context,
      IconData icon,
      String text,
      int index,
      ) {
    bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => _navigate(context, index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected
                ? const Color(0xFF00C569)
                : Colors.grey,
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isSelected
                  ? const Color(0xFF00C569)
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}