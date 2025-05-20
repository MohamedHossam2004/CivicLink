import 'package:flutter/material.dart';
import 'package:gov_app/config/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, 'Home', Icons.home),
            _buildNavItem(1, 'Tasks', Icons.task, onTap: () {
              Navigator.pushNamed(context, '/volunteer', arguments: {'userId': FirebaseAuth.instance.currentUser?.uid});
            }),
            _buildNavItem(2, 'Chat', Icons.chat_bubble_outline),
            _buildNavItem(3, 'Calendar', Icons.calendar_today),
            _buildNavItem(4, 'Profile', Icons.person_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, {Function()? onTap}) {
    final isSelected = currentIndex == index;
    
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryLightColor : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}