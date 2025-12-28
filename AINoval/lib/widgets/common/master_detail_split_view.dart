import 'package:flutter/material.dart';

/// 通用左右分栏组件：左侧主列表，右侧详情/编辑
class MasterDetailSplitView extends StatelessWidget {
  final Widget master;
  final Widget detail;
  final int masterFlex;
  final int detailFlex;
  final double dividerWidth;
  final Color? dividerColor;

  const MasterDetailSplitView({
    super.key,
    required this.master,
    required this.detail,
    this.masterFlex = 2,
    this.detailFlex = 3,
    this.dividerWidth = 1,
    this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveDividerColor = dividerColor ??
        Theme.of(context).dividerColor.withOpacity(0.6);

    return Row(
      children: [
        Flexible(
          flex: masterFlex,
          child: master,
        ),
        Container(
          width: dividerWidth,
          color: effectiveDividerColor,
        ),
        Flexible(
          flex: detailFlex,
          child: detail,
        ),
      ],
    );
  }
}


