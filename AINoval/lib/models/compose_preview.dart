class ComposeChapterPreview {
  final int index;
  final String title;
  final String outline;
  final String content;

  const ComposeChapterPreview({
    required this.index,
    this.title = '',
    this.outline = '',
    this.content = '',
  });

  ComposeChapterPreview copyWith({
    String? title,
    String? outline,
    String? content,
  }) {
    return ComposeChapterPreview(
      index: index,
      title: title ?? this.title,
      outline: outline ?? this.outline,
      content: content ?? this.content,
    );
  }
}

class ComposeReadyInfo {
  final bool ready;
  final String reason;
  final String novelId;
  final String sessionId;
  const ComposeReadyInfo({
    required this.ready,
    required this.reason,
    required this.novelId,
    required this.sessionId,
  });
}


