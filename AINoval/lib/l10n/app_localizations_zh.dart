// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'AI小说助手';

  @override
  String get homeTitle => '我的小说';

  @override
  String get createNovel => '创建新小说';

  @override
  String get importNovel => '导入小说';

  @override
  String get editNovel => '编辑';

  @override
  String get deleteNovel => '删除';

  @override
  String deleteConfirmation(Object title) {
    return '确定要删除《$title》吗？此操作不可撤销。';
  }

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get novelTitle => '小说标题';

  @override
  String get novelTitleHint => '请输入小说标题';

  @override
  String get seriesName => '系列名称 (可选)';

  @override
  String get seriesNameHint => '如果是系列作品，请输入系列名称';

  @override
  String get create => '创建';

  @override
  String lastEdited(Object date) {
    return '上次编辑: $date';
  }

  @override
  String wordCount(Object count) {
    return '$count字';
  }

  @override
  String completionPercentage(Object percentage) {
    return '完成度: $percentage%';
  }

  @override
  String get noNovels => '暂无小说，点击右下角按钮创建新小说';

  @override
  String get retry => '重试';

  @override
  String loadingError(Object message) {
    return '加载失败: $message';
  }

  @override
  String get unknownState => '未知状态';

  @override
  String get save => '保存';

  @override
  String get saved => '已保存';

  @override
  String get editorSettings => '编辑器设置';

  @override
  String get startWriting => '开始您的创作...';

  @override
  String get wordCountTitle => '字数统计';

  @override
  String get charactersWithSpaces => '字符数（含空格）';

  @override
  String get charactersNoSpaces => '字符数（不含空格）';

  @override
  String get paragraphs => '段落数';

  @override
  String get readTime => '预计阅读时间';

  @override
  String get minutes => '分钟';

  @override
  String get close => '关闭';
}
