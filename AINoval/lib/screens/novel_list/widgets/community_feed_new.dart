import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/widgets/common/animated_container_widget.dart';

class CommunityPost {
  final String id;
  final String title;
  final String content;
  final Author author;
  final int likes;
  final int quotes;
  final int comments;
  final bool isLiked;
  final String timeAgo;
  final String category;

  CommunityPost({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.likes,
    required this.quotes,
    required this.comments,
    required this.isLiked,
    required this.timeAgo,
    required this.category,
  });
}

class Author {
  final String name;
  final String avatar;
  final String username;

  Author({
    required this.name,
    required this.avatar,
    required this.username,
  });
}

class CommunityFeedNew extends StatefulWidget {
  final Function(String) onApplyPrompt;

  const CommunityFeedNew({
    Key? key,
    required this.onApplyPrompt,
  }) : super(key: key);

  @override
  State<CommunityFeedNew> createState() => _CommunityFeedNewState();
}

class _CommunityFeedNewState extends State<CommunityFeedNew> {
  final List<CommunityPost> _posts = [
    CommunityPost(
      id: '1',
      title: '玄幻小说开头万能模板',
      content: '写一个少年在家族被灭后意外获得神秘力量的故事开头，要有悬念感和代入感，字数控制在500字左右...',
      author: Author(
        name: '笔墨生花',
        avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop',
        username: '@writer_master',
      ),
      likes: 142,
      quotes: 28,
      comments: 15,
      isLiked: false,
      timeAgo: '2小时前',
      category: '玄幻修仙',
    ),
    CommunityPost(
      id: '2',
      title: '现代都市情感描写技巧',
      content: '帮我写一段都市男女主角初次相遇的情景，要体现出心动的感觉，环境设定在咖啡厅，要求自然不做作...',
      author: Author(
        name: '城市夜语',
        avatar: 'https://images.unsplash.com/photo-1494790108755-2616b9d25e62?w=400&h=400&fit=crop',
        username: '@city_romance',
      ),
      likes: 89,
      quotes: 12,
      comments: 8,
      isLiked: true,
      timeAgo: '4小时前',
      category: '现代都市',
    ),
    CommunityPost(
      id: '3',
      title: '科幻世界观构建提示',
      content: '构建一个2080年的未来世界，包含AI管理城市、虚拟现实普及、太空殖民等元素，要求逻辑自洽...',
      author: Author(
        name: '未来预言家',
        avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop',
        username: '@sci_fi_master',
      ),
      likes: 203,
      quotes: 45,
      comments: 32,
      isLiked: false,
      timeAgo: '6小时前',
      category: '科幻未来',
    ),
    CommunityPost(
      id: '4',
      title: '古风诗词对白生成',
      content: '为古装剧本创作古风对白，男女主角在月下相遇的情景，要求用词典雅，意境优美，符合古代语言风格...',
      author: Author(
        name: '古韵悠长',
        avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop',
        username: '@ancient_poet',
      ),
      likes: 156,
      quotes: 34,
      comments: 19,
      isLiked: true,
      timeAgo: '8小时前',
      category: '古风仙侠',
    ),
  ];

  void _toggleLike(String postId) {
    setState(() {
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        final post = _posts[index];
        _posts[index] = CommunityPost(
          id: post.id,
          title: post.title,
          content: post.content,
          author: post.author,
          likes: post.isLiked ? post.likes - 1 : post.likes + 1,
          quotes: post.quotes,
          comments: post.comments,
          isLiked: !post.isLiked,
          timeAgo: post.timeAgo,
          category: post.category,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '社区精选',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: WebTheme.getTextColor(context),
              ),
            ),
            TextButton(
              onPressed: () {
                // Handle view more
              },
              child: Text(
                '查看更多',
                style: TextStyle(
                  fontSize: 14,
                  color: WebTheme.getSecondaryTextColor(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Posts List
        Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _posts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final post = _posts[index];
              return AnimatedContainerWidget(
                animationType: AnimationType.fadeIn,
                delay: Duration(milliseconds: index * 100),
                child: _buildPostCard(context, post),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(BuildContext context, CommunityPost post) {
    final isDark = WebTheme.isDarkMode(context);
    
    return Container(
      decoration: BoxDecoration(
        color: WebTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WebTheme.getBorderColor(context).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: WebTheme.getShadowColor(context, opacity: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(post.author.avatar),
                  backgroundColor: WebTheme.getEmptyStateColor(context),
                ),
                const SizedBox(width: 12),
                // Author Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.author.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: WebTheme.getTextColor(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            post.timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: WebTheme.getSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        post.author.username,
                        style: TextStyle(
                          fontSize: 12,
                          color: WebTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                // More Options
                IconButton(
                  icon: Icon(
                    Icons.more_horiz,
                    size: 16,
                    color: WebTheme.getSecondaryTextColor(context),
                  ),
                  onPressed: () {
                    // Handle more options
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: WebTheme.getTextColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  post.content,
                  style: TextStyle(
                    fontSize: 12,
                    color: WebTheme.getSecondaryTextColor(context),
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Action Buttons
                Row(
                  children: [
                    // Like Button
                    _buildActionButton(
                      context,
                      icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                      label: post.likes.toString(),
                      color: post.isLiked ? Theme.of(context).colorScheme.error : null,
                      onTap: () => _toggleLike(post.id),
                    ),
                    const SizedBox(width: 16),
                    // Quote Button
                    _buildActionButton(
                      context,
                      icon: Icons.format_quote,
                      label: post.quotes.toString(),
                      onTap: () {
                        // Handle quote
                      },
                    ),
                    const SizedBox(width: 16),
                    // Comment Button
                    _buildActionButton(
                      context,
                      icon: Icons.comment_outlined,
                      label: post.comments.toString(),
                      onTap: () {
                        // Handle comment
                      },
                    ),
                    const SizedBox(width: 16),
                    // Apply Button
                    _buildActionButton(
                      context,
                      icon: Icons.flash_on,
                      label: '应用',
                      color: WebTheme.getPrimaryColor(context),
                      onTap: () => widget.onApplyPrompt(post.content),
                    ),
                  ],
                ),
                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: WebTheme.getEmptyStateColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    final defaultColor = WebTheme.getSecondaryTextColor(context);
    final buttonColor = color ?? defaultColor;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: buttonColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: buttonColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}