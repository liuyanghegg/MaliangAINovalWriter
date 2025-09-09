import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/widgets/common/animated_container_widget.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:ainoval/widgets/common/badge.dart';

class CategoryTagsNew extends StatelessWidget {
  final Function(String) onTagClick;

  const CategoryTagsNew({
    Key? key,
    required this.onTagClick,
  }) : super(key: key);

  static const List<Map<String, String>> categories = [
    {'name': '现代都市', 'prompt': '创作一个现代都市背景的小说，主角是一位在大城市奋斗的年轻人...'},
    {'name': '古风仙侠', 'prompt': '创作一个古风仙侠小说，描述一位修仙者的成长历程...'},
    {'name': '科幻未来', 'prompt': '创作一个科幻未来题材的小说，背景设定在2100年的地球...'},
    {'name': '悬疑推理', 'prompt': '创作一个悬疑推理小说，围绕一起神秘的案件展开...'},
    {'name': '校园青春', 'prompt': '创作一个校园青春小说，讲述高中生活中的友情与成长...'},
    {'name': '历史架空', 'prompt': '创作一个历史架空小说，设定在一个虚构的古代王朝...'},
    {'name': '玄幻魔法', 'prompt': '创作一个玄幻魔法小说，主角意外获得了强大的魔法力量...'},
    {'name': '军事战争', 'prompt': '创作一个军事战争小说，描述一场激烈的现代战争...'},
    {'name': '商战职场', 'prompt': '创作一个商战职场小说，主角在大企业中的奋斗历程...'},
    {'name': '穿越重生', 'prompt': '创作一个穿越重生小说，主角回到了十年前的自己...'},
    {'name': '末世求生', 'prompt': '创作一个末世求生小说，描述人类在灾难后的生存斗争...'},
    {'name': '异世冒险', 'prompt': '创作一个异世界冒险小说，主角被传送到了陌生的世界...'},
    {'name': '武侠江湖', 'prompt': '创作一个武侠江湖小说，讲述侠客行走江湖的故事...'},
    {'name': '娱乐圈', 'prompt': '创作一个娱乐圈题材的小说，主角是一位新人演员...'},
    {'name': '电竞游戏', 'prompt': '创作一个电竞游戏小说，描述职业选手的比赛生涯...'},
    {'name': '灵异恐怖', 'prompt': '创作一个灵异恐怖小说，主角遭遇了超自然现象...'},
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainerWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择小说分类',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: WebTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: categories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              
              return AnimatedContainerWidget(
                animationType: AnimationType.scaleIn,
                delay: Duration(milliseconds: index * 50),
                child: Badge(
                  text: category['name']!,
                  variant: BadgeVariant.outline,
                  onTap: () => onTagClick(category['prompt']!),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  fontSize: 14,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            '点击标签快速填充创作提示词，或直接在上方输入框中输入您的想法',
            style: TextStyle(
              fontSize: 14,
              color: WebTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}