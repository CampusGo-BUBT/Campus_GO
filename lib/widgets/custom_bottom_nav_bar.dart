import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onFabTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Responsive theme colors for Light and Dark modes
    final navColor = isDark ? const Color(0xFF1E293B) : const Color(0xFF94B9F5);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFF7CA6F2);
    final fabBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final fabIconColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E3A8A);

    return Container(
      height: 90,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Floating curved bar container
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                color: navColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.5)
                        : navColor.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 1. Home
                  _NavItem(
                    icon: Icons.home_rounded,
                    isSelected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  // 2. Chat / Messages
                  _NavItem(
                    icon: Icons.chat_bubble_rounded,
                    isSelected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  // Space for central FAB
                  const SizedBox(width: 48),
                  // 3. Saved / Bookmark
                  _NavItem(
                    icon: Icons.bookmark_rounded,
                    isSelected: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  // 4. Profile
                  _NavItem(
                    icon: Icons.person_rounded,
                    isSelected: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                ],
              ),
            ),
          ),

          // Central Floating + Action Button
          Positioned(
            bottom: 22,
            child: GestureDetector(
              onTap: onFabTap,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: fabBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: navColor, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add,
                  color: fabIconColor,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: isSelected
            ? const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              )
            : null,
        child: Icon(
          icon,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
