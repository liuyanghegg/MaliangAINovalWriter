// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AI Novel Assistant';

  @override
  String get homeTitle => 'My Novels';

  @override
  String get createNovel => 'Create New Novel';

  @override
  String get importNovel => 'Import Novel';

  @override
  String get editNovel => 'Edit';

  @override
  String get deleteNovel => 'Delete';

  @override
  String deleteConfirmation(Object title) {
    return 'Are you sure you want to delete \'$title\'? This action cannot be undone.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get novelTitle => 'Novel Title';

  @override
  String get novelTitleHint => 'Enter novel title';

  @override
  String get seriesName => 'Series Name (Optional)';

  @override
  String get seriesNameHint => 'If part of a series, enter series name';

  @override
  String get create => 'Create';

  @override
  String lastEdited(Object date) {
    return 'Last edited: $date';
  }

  @override
  String wordCount(Object count) {
    return '$count words';
  }

  @override
  String completionPercentage(Object percentage) {
    return 'Completion: $percentage%';
  }

  @override
  String get noNovels => 'No novels yet. Click the button in the bottom right to create one.';

  @override
  String get retry => 'Retry';

  @override
  String loadingError(Object message) {
    return 'Loading failed: $message';
  }

  @override
  String get unknownState => 'Unknown state';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get editorSettings => 'Editor Settings';

  @override
  String get startWriting => 'Start writing...';

  @override
  String get wordCountTitle => 'Word Count';

  @override
  String get charactersWithSpaces => 'Characters (with spaces)';

  @override
  String get charactersNoSpaces => 'Characters (no spaces)';

  @override
  String get paragraphs => 'Paragraphs';

  @override
  String get readTime => 'Estimated reading time';

  @override
  String get minutes => 'minutes';

  @override
  String get close => 'Close';
}
