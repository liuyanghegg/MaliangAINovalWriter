import 'package:ainoval/utils/web_theme.dart';
import 'package:flutter/material.dart';

class Novel {
  final String id;
  final String title;
  final String description;
  final String category;
  final int wordCount;
  final String lastUpdated;
  final String status; // 草稿 | 连载中 | 已完结
  final int views;
  final String? coverImage;
  final double? rating;

  Novel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.wordCount,
    required this.lastUpdated,
    required this.status,
    required this.views,
    this.coverImage,
    this.rating,
  });
}

class NovelCard extends StatefulWidget {
  final Novel novel;
  final VoidCallback? onContinueWriting;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const NovelCard({
    Key? key,
    required this.novel,
    this.onContinueWriting,
    this.onEdit,
    this.onShare,
    this.onDelete,
  }) : super(key: key);

  @override
  State<NovelCard> createState() => _NovelCardState();
}

class _NovelCardState extends State<NovelCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status, BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);
    switch (status) {
      case '草稿':
        return isDark ? WebTheme.darkGrey400 : WebTheme.grey400;
      case '连载中':
        return Colors.blue.shade600;
      case '已完结':
        return Colors.green.shade600;
      default:
        return isDark ? WebTheme.darkGrey400 : WebTheme.grey400;
    }
  }

  Color _getStatusBackgroundColor(String status, BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);
    switch (status) {
      case '草稿':
        return isDark ? WebTheme.darkGrey200 : WebTheme.grey200;
      case '连载中':
        return Colors.blue.shade100.withOpacity(isDark ? 0.2 : 1.0);
      case '已完结':
        return Colors.green.shade100.withOpacity(isDark ? 0.2 : 1.0);
      default:
        return isDark ? WebTheme.darkGrey200 : WebTheme.grey200;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            transform: Matrix4.identity()
              ..scale(_isHovered ? 1.02 : 1.0),
            decoration: BoxDecoration(
              color: WebTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered 
                  ? (isDark ? WebTheme.darkGrey500 : WebTheme.grey500)
                  : WebTheme.getBorderColor(context),
                width: 1,
              ),
              boxShadow: _isHovered ? [
                BoxShadow(
                  color: WebTheme.getShadowColor(context, opacity: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ] : [
                BoxShadow(
                  color: WebTheme.getShadowColor(context, opacity: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cover Image Area
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                (isDark ? WebTheme.darkGrey300 : WebTheme.grey300).withOpacity(0.2),
                                (isDark ? WebTheme.darkGrey200 : WebTheme.grey200).withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: widget.novel.coverImage != null
                            ? Image.network(
                                widget.novel.coverImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
                              )
                            : _buildPlaceholder(context),
                        ),
                        // Status Badge
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusBackgroundColor(widget.novel.status, context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.novel.status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _getStatusColor(widget.novel.status, context),
                              ),
                            ),
                          ),
                        ),
                        // More Options Button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: (isDark ? WebTheme.darkGrey100 : WebTheme.white).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                            child: PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_horiz,
                                size: 16,
                                color: WebTheme.getTextColor(context, isPrimary: false),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 16, color: WebTheme.getTextColor(context, isPrimary: false)),
                                      const SizedBox(width: 8),
                                      const Text('编辑'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'share',
                                  child: Row(
                                    children: [
                                      Icon(Icons.share, size: 16, color: WebTheme.getTextColor(context, isPrimary: false)),
                                      const SizedBox(width: 8),
                                      const Text('分享'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 16, color: WebTheme.error),
                                      const SizedBox(width: 8),
                                      Text('删除', style: TextStyle(color: WebTheme.error)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    widget.onEdit?.call();
                                    break;
                                  case 'share':
                                    widget.onShare?.call();
                                    break;
                                  case 'delete':
                                    widget.onDelete?.call();
                                    break;
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content Area
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.novel.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isHovered 
                              ? WebTheme.getPrimaryColor(context)
                              : WebTheme.getTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Description
                        Text(
                          widget.novel.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: WebTheme.getSecondaryTextColor(context),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Category and Rating
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: WebTheme.getBorderColor(context),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.novel.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: WebTheme.getTextColor(context, isPrimary: false),
                                ),
                              ),
                            ),
                            if (widget.novel.rating != null) ...[
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber.shade600,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    widget.novel.rating!.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: WebTheme.getSecondaryTextColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Footer
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.menu_book,
                                  size: 12,
                                  color: WebTheme.getSecondaryTextColor(context),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.novel.wordCount.toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]},',
                                  )}字',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: WebTheme.getSecondaryTextColor(context),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.visibility,
                                  size: 12,
                                  color: WebTheme.getSecondaryTextColor(context),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.novel.views.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: WebTheme.getSecondaryTextColor(context),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: WebTheme.getSecondaryTextColor(context),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.novel.lastUpdated,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: WebTheme.getSecondaryTextColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Continue Writing Button
                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: OutlinedButton(
                            onPressed: widget.onContinueWriting,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _isHovered
                                ? WebTheme.white
                                : WebTheme.getTextColor(context),
                              backgroundColor: _isHovered
                                ? WebTheme.getPrimaryColor(context)
                                : Colors.transparent,
                              side: BorderSide(
                                color: WebTheme.getBorderColor(context),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text(
                              '继续创作',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WebTheme.getPrimaryColor(context).withOpacity(0.1),
            WebTheme.getSecondaryColor(context).withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.menu_book,
          size: 48,
          color: WebTheme.getSecondaryTextColor(context).withOpacity(0.5),
        ),
      ),
    );
  }
}