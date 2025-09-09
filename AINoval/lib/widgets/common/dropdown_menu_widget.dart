import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

class MenuItemData {
  final String value;
  final String label;
  final IconData? icon;
  final Color? color;

  MenuItemData({
    required this.value,
    required this.label,
    this.icon,
    this.color,
  });
}

class DropdownMenuWidget extends StatefulWidget {
  final Widget trigger;
  final List<MenuItemData> items;
  final Function(String)? onItemSelected;
  final Offset offset;
  final double? width;

  const DropdownMenuWidget({
    Key? key,
    required this.trigger,
    required this.items,
    this.onItemSelected,
    this.offset = const Offset(0, 8),
    this.width,
  }) : super(key: key);

  @override
  State<DropdownMenuWidget> createState() => _DropdownMenuWidgetState();
}

class _DropdownMenuWidgetState extends State<DropdownMenuWidget> {
  final GlobalKey _triggerKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final RenderBox renderBox = _triggerKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible barrier to detect outside clicks
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // Dropdown menu
          Positioned(
            left: position.dx + widget.offset.dx,
            top: position.dy + size.height + widget.offset.dy,
            width: widget.width ?? size.width,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: _buildDropdownContent(context),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    // 检查 Widget 是否还处于活跃状态
    if (mounted) {
      setState(() {
        _isOpen = true;
      });
    }
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    // 检查 Widget 是否还处于活跃状态，避免在 dispose 后调用 setState
    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  Widget _buildDropdownContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WebTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: WebTheme.getBorderColor(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: WebTheme.getShadowColor(context, opacity: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.items.map((item) {
            return InkWell(
              onTap: () {
                widget.onItemSelected?.call(item.value);
                _closeDropdown();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: WebTheme.getBorderColor(context).withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (item.icon != null) ...[
                      Icon(
                        item.icon,
                        size: 16,
                        color: item.color ?? WebTheme.getSecondaryTextColor(context),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: item.color ?? WebTheme.getTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _triggerKey,
      onTap: _toggleDropdown,
      child: widget.trigger,
    );
  }

  @override
  void dispose() {
    // 直接清理 overlay，不调用 setState
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }
}