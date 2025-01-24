//custom_drawer.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Simple model for each nav item (icon + text)
class SidebarItem {
  final IconData icon;
  final String label;

  SidebarItem({required this.icon, required this.label});
}

class PersistentSidebar extends StatefulWidget {
  final String headerTitle;            // e.g. "Super Admin", "Hospital Portal"
  final List<SidebarItem> items;       // e.g. [SidebarItem(icon: Icons.person, label: "Doctors")]
  final int selectedIndex;             // which item is currently active
  final Function(int) onMenuItemClicked;

  const PersistentSidebar({
    super.key,
    required this.headerTitle,
    required this.items,
    required this.selectedIndex,
    required this.onMenuItemClicked,
  });

  @override
  _PersistentSidebarState createState() => _PersistentSidebarState();
}

class _PersistentSidebarState extends State<PersistentSidebar>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    // Create an animation controller for each item
    _controllers = List.generate(
      widget.items.length,
          (_) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    // Create a curved animation for each item
    _animations = _controllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      );
    }).toList();

    // Forward ALL controllers so that every label is visible (no reversing)
    for (final controller in _controllers) {
      controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant PersistentSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // We won't reverse the old selected item’s label,
    // because we want *all* labels to remain visible.
    //
    // So we do nothing special here, or we can re-forward
    // all controllers if you like. Typically, do nothing is enough.
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,                       // fixed sidebar width
      color: AppTheme.primaryColor,     // main background color
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildHeaderLogo(widget.headerTitle),
          const SizedBox(height: 24),

          // List of nav items
          Expanded(
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = (index == widget.selectedIndex);

                return GestureDetector(
                  onTap: () => widget.onMenuItemClicked(index),
                  child: _SidebarAnimatedItem(
                    item: item,
                    isSelected: isSelected,
                    animation: _animations[index],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeaderLogo(String title) {
    // This replicates the circle + text at the top.
    // If you want an icon or an image instead, customize here.
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.accentColor,
        borderRadius: BorderRadius.circular(30),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// This is just like the `_NavItem` in your `_PersistentNavbar`:
/// Animated background, icon scale, plus we always show the label
/// (fade/scale is set to 1.0 for unselected items).
class _SidebarAnimatedItem extends StatelessWidget {
  final SidebarItem item;
  final bool isSelected;
  final Animation<double> animation;

  const _SidebarAnimatedItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.accentColor.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppTheme.accentColor, width: 2)
            : Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          /// Icon container with animated size
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isSelected ? 40 : 30,
            height: isSelected ? 40 : 30,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accentColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: isSelected ? 24 : 20,
            ),
          ),
          const SizedBox(width: 12),

          /// We do a *conditional* fade/scale:
          /// - If selected => use the animation
          /// - If not selected => we want it to appear at 1.0
          ///   so it's still visible.
          FadeTransition(
            opacity: isSelected ? animation : const AlwaysStoppedAnimation(1.0),
            child: ScaleTransition(
              scale: isSelected ? animation : const AlwaysStoppedAnimation(1.0),
              child: Text(
                item.label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
