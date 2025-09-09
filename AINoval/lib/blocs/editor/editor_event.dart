part of 'editor_bloc.dart';

abstract class EditorEvent extends Equatable {
  const EditorEvent();

  @override
  List<Object?> get props => [];
}

// 🚀 新增：Plan视图模式切换事件
class SwitchToPlanView extends EditorEvent {
  const SwitchToPlanView();
}

class SwitchToWriteView extends EditorEvent {
  const SwitchToWriteView();
}

// 🚀 新增：Plan视图专用的加载事件（加载场景摘要）
class LoadPlanContent extends EditorEvent {
  const LoadPlanContent();
}

// 🚀 新增：Plan视图的场景移动事件
class MoveScene extends EditorEvent {
  const MoveScene({
    required this.novelId,
    required this.sourceActId,
    required this.sourceChapterId,
    required this.sourceSceneId,
    required this.targetActId,
    required this.targetChapterId,
    required this.targetIndex,
  });
  final String novelId;
  final String sourceActId;
  final String sourceChapterId;
  final String sourceSceneId;
  final String targetActId;
  final String targetChapterId;
  final int targetIndex;

  @override
  List<Object?> get props => [
        novelId,
        sourceActId,
        sourceChapterId,
        sourceSceneId,
        targetActId,
        targetChapterId,
        targetIndex,
      ];
}

// 🚀 新增：从Plan视图切换到Write视图并跳转到指定场景
class NavigateToSceneFromPlan extends EditorEvent {
  const NavigateToSceneFromPlan({
    required this.actId,
    required this.chapterId,
    required this.sceneId,
  });
  final String actId;
  final String chapterId;
  final String sceneId;

  @override
  List<Object?> get props => [actId, chapterId, sceneId];
}

// 🚀 新增：刷新编辑器数据事件（用于Plan视图数据修改后的无感刷新）
class RefreshEditorData extends EditorEvent {
  const RefreshEditorData({
    this.preserveActiveScene = true,
    this.source = 'plan_view',
  });
  final bool preserveActiveScene;
  final String source;

  @override
  List<Object?> get props => [preserveActiveScene, source];
}

// 🚀 新增：沉浸模式切换事件
class SwitchToImmersiveMode extends EditorEvent {
  const SwitchToImmersiveMode({
    this.chapterId,
  });
  final String? chapterId; // 可指定沉浸的章节，为null时使用当前活动章节

  @override
  List<Object?> get props => [chapterId];
}

class SwitchToNormalMode extends EditorEvent {
  const SwitchToNormalMode();
}

// 🚀 新增：沉浸模式下的章节导航事件
class NavigateToNextChapter extends EditorEvent {
  const NavigateToNextChapter();
}

class NavigateToPreviousChapter extends EditorEvent {
  const NavigateToPreviousChapter();
}

/// 使用分页加载编辑器内容事件
class LoadEditorContentPaginated extends EditorEvent {
  const LoadEditorContentPaginated({
    required this.novelId,
    this.loadAllSummaries = false,
  });
  final String novelId;
  final bool loadAllSummaries;

  @override
  List<Object?> get props => [novelId, loadAllSummaries];
}

/// 加载更多场景事件
class LoadMoreScenes extends EditorEvent {

  const LoadMoreScenes({
    required this.fromChapterId,
    required this.direction,
    required this.actId,
    this.chaptersLimit = 3,
    this.targetChapterId,
    this.targetSceneId,
    this.preventFocusChange = false,
    this.loadFromLocalOnly = false,
    this.skipIfLoading = false,
    this.skipAPIFallback = false,
  });
  final String fromChapterId;
  final String direction; // "up" 或 "down" 或 "center"
  final String actId; // 现在将actId作为必需参数
  final int chaptersLimit;
  final String? targetChapterId;
  final String? targetSceneId;
  final bool preventFocusChange;
  final bool loadFromLocalOnly; // 是否只从本地加载，避免网络请求
  final bool skipIfLoading; // 如果已经有加载任务，是否跳过此次加载
  final bool skipAPIFallback; // 当loadFromLocalOnly为true且本地加载失败时，是否跳过API回退

  @override
  List<Object?> get props => [
    fromChapterId,
    direction,
    chaptersLimit,
    actId,
    targetChapterId,
    targetSceneId,
    preventFocusChange,
    loadFromLocalOnly,
    skipIfLoading,
    skipAPIFallback,
  ];
}

class UpdateContent extends EditorEvent {
  const UpdateContent({required this.content});
  final String content;

  @override
  List<Object?> get props => [content];
}

class SaveContent extends EditorEvent {
  const SaveContent();
}

class UpdateSceneContent extends EditorEvent {
  const UpdateSceneContent({
    required this.novelId,
    required this.actId,
    required this.chapterId,
    required this.sceneId,
    required this.content,
    this.wordCount,
    this.shouldRebuild = true,
    this.isMinorChange,
  });
  final String novelId;
  final String actId;
  final String chapterId;
  final String sceneId;
  final String content;
  final String? wordCount;
  final bool shouldRebuild;
  final bool? isMinorChange; // 是否为微小改动，微小改动可以不刷新保存状态UI

  @override
  List<Object?> get props =>
      [novelId, actId, chapterId, sceneId, content, wordCount, shouldRebuild, isMinorChange];
}

class UpdateSummary extends EditorEvent {
  const UpdateSummary({
    required this.novelId,
    required this.actId,
    required this.chapterId,
    required this.sceneId,
    required this.summary,
    this.shouldRebuild = true,
  });
  final String novelId;
  final String actId;
  final String chapterId;
  final String sceneId;
  final String summary;
  final bool shouldRebuild;

  @override
  List<Object?> get props =>
      [novelId, actId, chapterId, sceneId, summary, shouldRebuild];
}

class SetActiveChapter extends EditorEvent {
  const SetActiveChapter({
    required this.actId,
    required this.chapterId,
    this.shouldScroll = true,
    this.silent = false,
  });
  final String actId;
  final String chapterId;
  final bool shouldScroll;
  final bool silent;

  @override
  List<Object?> get props => [actId, chapterId, shouldScroll, silent];
}

class ToggleEditorSettings extends EditorEvent {
  const ToggleEditorSettings();
}

class UpdateEditorSettings extends EditorEvent {
  const UpdateEditorSettings({required this.settings});
  final Map<String, dynamic> settings;

  @override
  List<Object?> get props => [settings];
}

/// 🚀 新增：加载用户编辑器设置事件
class LoadUserEditorSettings extends EditorEvent {
  const LoadUserEditorSettings({required this.userId});
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class UpdateActTitle extends EditorEvent {
  const UpdateActTitle({
    required this.actId,
    required this.title,
  });
  final String actId;
  final String title;

  @override
  List<Object?> get props => [actId, title];
}

class UpdateChapterTitle extends EditorEvent {
  const UpdateChapterTitle({
    required this.actId,
    required this.chapterId,
    required this.title,
  });
  final String actId;
  final String chapterId;
  final String title;

  @override
  List<Object?> get props => [actId, chapterId, title];
}

// 添加新的Act事件
class AddNewAct extends EditorEvent {
  const AddNewAct({this.title = '新Act'});
  final String title;

  @override
  List<Object?> get props => [title];
}

// 添加新的Chapter事件
class AddNewChapter extends EditorEvent {
  const AddNewChapter({
    required this.novelId,
    required this.actId,
    this.title = '新章节',
  });
  final String novelId;
  final String actId;
  final String title;

  @override
  List<Object?> get props => [novelId, actId, title];
}

// 添加新的Scene事件
class AddNewScene extends EditorEvent {
  const AddNewScene({
    required this.novelId,
    required this.actId,
    required this.chapterId,
    required this.sceneId,
  });
  final String novelId;
  final String actId;
  final String chapterId;
  final String sceneId;

  @override
  List<Object?> get props => [novelId, actId, chapterId, sceneId];
}

// 设置活动场景事件
class SetActiveScene extends EditorEvent {
  const SetActiveScene({
    required this.actId,
    required this.chapterId,
    required this.sceneId,
    this.shouldScroll = true,
    this.silent = false,
  });
  final String actId;
  final String chapterId;
  final String sceneId;
  final bool shouldScroll;
  final bool silent;

  @override
  List<Object?> get props => [actId, chapterId, sceneId, shouldScroll, silent];
}

// 删除场景事件 (New Event)
class DeleteScene extends EditorEvent {
  const DeleteScene({
    required this.novelId,
    required this.actId,
    required this.chapterId,
    required this.sceneId,
  });
  final String novelId;
  final String actId;
  final String chapterId;
  final String sceneId;

  @override
  List<Object?> get props => [novelId, actId, chapterId, sceneId];
}

// 删除章节事件
class DeleteChapter extends EditorEvent {
  const DeleteChapter({
    required this.novelId,
    required this.actId,
    required this.chapterId,
  });
  final String novelId;
  final String actId;
  final String chapterId;

  @override
  List<Object?> get props => [novelId, actId, chapterId];
}

// 删除卷(Act)事件
class DeleteAct extends EditorEvent {
  const DeleteAct({
    required this.novelId,
    required this.actId,
  });
  final String novelId;
  final String actId;

  @override
  List<Object?> get props => [novelId, actId];
}

// 生成场景摘要事件
class GenerateSceneSummaryRequested extends EditorEvent {
  final String sceneId;
  final String? styleInstructions;

  const GenerateSceneSummaryRequested({
    required this.sceneId,
    this.styleInstructions,
  });

  @override
  List<Object?> get props => [sceneId, styleInstructions];
}

// 从摘要生成场景内容事件
class GenerateSceneFromSummaryRequested extends EditorEvent {
  final String novelId;
  final String summary;
  final String? chapterId;
  final String? styleInstructions;
  final bool useStreamingMode;

  const GenerateSceneFromSummaryRequested({
    required this.novelId,
    required this.summary,
    this.chapterId,
    this.styleInstructions,
    this.useStreamingMode = true,
  });

  @override
  List<Object?> get props => [novelId, summary, chapterId, styleInstructions, useStreamingMode];
}

// 更新生成的场景内容事件 (用于流式响应)
class UpdateGeneratedSceneContent extends EditorEvent {
  final String content;

  const UpdateGeneratedSceneContent(this.content);

  @override
  List<Object?> get props => [content];
}

// 完成场景生成事件
class SceneGenerationCompleted extends EditorEvent {
  final String content;

  const SceneGenerationCompleted(this.content);

  @override
  List<Object?> get props => [content];
}

// 场景生成失败事件
class SceneGenerationFailed extends EditorEvent {
  final String error;

  const SceneGenerationFailed(this.error);

  @override
  List<Object?> get props => [error];
}

// 场景摘要生成完成事件
class SceneSummaryGenerationCompleted extends EditorEvent {
  final String summary;

  const SceneSummaryGenerationCompleted(this.summary);

  @override
  List<Object?> get props => [summary];
}

// 场景摘要生成失败事件
class SceneSummaryGenerationFailed extends EditorEvent {
  final String error;

  const SceneSummaryGenerationFailed(this.error);

  @override
  List<Object?> get props => [error];
}

// 停止场景生成事件
class StopSceneGeneration extends EditorEvent {
  const StopSceneGeneration();

  @override
  List<Object?> get props => [];
}

// 刷新编辑器事件
class RefreshEditor extends EditorEvent {
  const RefreshEditor();

  @override
  List<Object?> get props => [];
}

// 设置待处理的摘要内容事件
class SetPendingSummary extends EditorEvent {
  final String summary;

  const SetPendingSummary({
    required this.summary,
  });

  @override
  List<Object?> get props => [summary];
}

/// 保存场景内容事件
class SaveSceneContent extends EditorEvent {
  final String novelId;
  final String actId;
  final String chapterId;
  final String sceneId;
  final String content;
  final String wordCount;
  final bool localOnly; // 添加参数：是否只保存到本地

  const SaveSceneContent({
    required this.novelId,
    required this.actId,
    required this.chapterId,
    required this.sceneId,
    required this.content,
    required this.wordCount,
    this.localOnly = false, // 默认为false，表示同时同步到服务器
  });

  @override
  List<Object?> get props => [novelId, actId, chapterId, sceneId, content, wordCount, localOnly];
}

/// 强制保存场景内容事件 - 用于SceneEditor dispose时的数据保存
/// 这个事件会立即、同步地保存场景内容，不经过防抖处理
class ForceSaveSceneContent extends EditorEvent {
  final String novelId;
  final String actId;
  final String chapterId;
  final String sceneId;
  final String content;
  final String? wordCount;
  final String? summary;

  const ForceSaveSceneContent({
    required this.novelId,
    required this.actId,
    required this.chapterId,
    required this.sceneId,
    required this.content,
    this.wordCount,
    this.summary,
  });

  @override
  List<Object?> get props => [novelId, actId, chapterId, sceneId, content, wordCount, summary];
}

class UpdateVisibleRange extends EditorEvent {
  const UpdateVisibleRange({
    required this.startIndex,
    required this.endIndex,
  });
  final int startIndex;
  final int endIndex;
  
  @override
  List<Object?> get props => [startIndex, endIndex];
}

/// 重置章节加载标记
class ResetActLoadingFlags extends EditorEvent {
  const ResetActLoadingFlags();
}

/// 设置章节加载边界标记
class SetActLoadingFlags extends EditorEvent {
  final bool? hasReachedEnd;
  final bool? hasReachedStart;

  const SetActLoadingFlags({
    this.hasReachedEnd,
    this.hasReachedStart,
  });
}

// 设置焦点章节事件
class SetFocusChapter extends EditorEvent {
  const SetFocusChapter({
    required this.chapterId,
  });
  final String chapterId;

  @override
  List<Object?> get props => [chapterId];
}
