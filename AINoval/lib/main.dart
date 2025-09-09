import 'dart:io';
import 'dart:async';

// <<< 导入 AiConfigBloc >>>
import 'package:ainoval/blocs/ai_config/ai_config_bloc.dart';
// 导入聊天相关的类
import 'package:ainoval/blocs/auth/auth_bloc.dart';
import 'package:ainoval/blocs/chat/chat_bloc.dart';
import 'package:ainoval/blocs/credit/credit_bloc.dart';
import 'package:ainoval/blocs/editor_version_bloc.dart';
import 'package:ainoval/blocs/novel_list/novel_list_bloc.dart';
import 'package:ainoval/blocs/public_models/public_models_bloc.dart';
import 'package:ainoval/blocs/setting_generation/setting_generation_bloc.dart';
import 'package:ainoval/config/app_config.dart'; // 引入 AppConfig
import 'package:ainoval/l10n/l10n.dart';
import 'package:ainoval/models/app_registration_config.dart';

// import 'package:ainoval/screens/novel_list/novel_list_screen.dart'; // 已删除，使用新页面
import 'package:ainoval/screens/novel_list/novel_list_real_data_screen.dart' deferred as novel_list;
import 'package:ainoval/services/api_service/base/api_client.dart';
import 'package:ainoval/services/api_service/base/sse_client.dart';
// <<< 移除未使用的 Codex Impl 引用 >>>
// import 'package:ainoval/services/api_service/repositories/impl/codex_repository_impl.dart';
import 'package:ainoval/services/api_service/repositories/chat_repository.dart'; // <<< 导入接口
// ApiService import might not be needed directly in main unless provided
// import 'package:ainoval/services/api_service.dart';
import 'package:ainoval/services/api_service/repositories/impl/chat_repository_impl.dart';
import 'package:ainoval/services/api_service/repositories/impl/credit_repository_impl.dart';
import 'package:ainoval/services/api_service/repositories/impl/novel_repository_impl.dart';
import 'package:ainoval/services/api_service/repositories/impl/novel_setting_repository_impl.dart';
import 'package:ainoval/services/api_service/repositories/impl/public_model_repository_impl.dart';
import 'package:ainoval/services/api_service/repositories/impl/storage_repository_impl.dart';
import 'package:ainoval/services/api_service/repositories/impl/user_ai_model_config_repository_impl.dart';
import 'package:ainoval/services/api_service/repositories/impl/setting_generation_repository_impl.dart';
import 'package:ainoval/services/api_service/repositories/impl/universal_ai_repository_impl.dart';
import 'package:ainoval/services/api_service/repositories/impl/preset_aggregation_repository_impl.dart';
import 'package:ainoval/services/api_service/repositories/impl/ai_preset_repository_impl.dart';
import 'package:ainoval/services/api_service/repositories/impl/novel_snippet_repository_impl.dart';
import 'package:ainoval/services/api_service/repositories/novel_repository.dart'; // <<< 导入接口
import 'package:ainoval/services/image_cache_service.dart';
// import 'package:ainoval/services/api_service/repositories/novel_setting_repository.dart';
import 'package:ainoval/services/api_service/repositories/credit_repository.dart';
import 'package:ainoval/services/api_service/repositories/public_model_repository.dart';
import 'package:ainoval/services/api_service/repositories/storage_repository.dart';
// <<< 导入 AI Config 仓库 >>>
import 'package:ainoval/services/api_service/repositories/user_ai_model_config_repository.dart';
import 'package:ainoval/services/api_service/repositories/setting_generation_repository.dart';
import 'package:ainoval/services/api_service/repositories/universal_ai_repository.dart';
import 'package:ainoval/services/api_service/repositories/preset_aggregation_repository.dart';
import 'package:ainoval/services/api_service/repositories/ai_preset_repository.dart';
import 'package:ainoval/services/api_service/repositories/novel_snippet_repository.dart';
import 'package:ainoval/services/auth_service.dart' as auth_service;
import 'package:ainoval/services/local_storage_service.dart';
import 'package:ainoval/services/novel_file_service.dart'; // 导入小说文件服务
// import 'package:ainoval/services/websocket_service.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ainoval/services/api_service/repositories/prompt_repository.dart';
import 'package:ainoval/services/api_service/repositories/impl/prompt_repository_impl.dart';
// 重复导入清理（下方已存在这些导入）
import 'package:ainoval/blocs/universal_ai/universal_ai_bloc.dart';
import 'package:ainoval/utils/navigation_logger.dart';
import 'package:ainoval/blocs/prompt_new/prompt_new_bloc.dart';
import 'package:ainoval/blocs/prompt_new/prompt_new_event.dart';
import 'package:ainoval/blocs/theme/theme_bloc.dart';
import 'package:ainoval/blocs/theme/theme_event.dart';
import 'package:ainoval/blocs/theme/theme_state.dart';
// 导入预设管理BLoC
import 'package:ainoval/blocs/preset/preset_bloc.dart';
import 'package:ainoval/blocs/preset/preset_event.dart';
// 导入预设聚合仓储
import 'package:ainoval/screens/unified_management/unified_management_screen.dart' deferred as unified_mgmt;

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Web 平台下：覆盖 Flutter 全局错误处理，避免 Inspector 在处理 JS 对象时报错
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kIsWeb) {
        // 直接输出字符串化的异常信息，避免 DiagnosticsNode 转换
        debugPrint('FlutterError: ${details.exceptionAsString()}');
        if (details.stack != null) {
          debugPrint(details.stack.toString());
        }
      } else {
        FlutterError.presentError(details);
      }
    };

    // 初始化日志系统
    AppLogger.init();

    // 初始化Hive本地存储
    await Hive.initFlutter();

    // 初始化注册配置
    await _initializeRegistrationConfig();

    // 创建必要的资源文件夹 - 仅在非Web平台执行
    if (!kIsWeb) {
      await _createResourceDirectories();
    }

    // 初始化LocalStorageService
    final localStorageService = LocalStorageService();
    await localStorageService.init();

    // 创建AuthService
    final authServiceInstance = auth_service.AuthService();
    await authServiceInstance.init();

    // 创建 ApiClient 实例并传入 AuthService
    final apiClient = ApiClient(authService: authServiceInstance);
    
    // 创建 SseClient 实例 (单例模式)
    final sseClient = SseClient();
/* 
    // 创建ApiService (如果 ApiService 需要 ApiClient, 则传入)
    // 假设 ApiService 构造函数接受 apiClient (如果不需要则忽略)
    final apiService = ApiService(/* apiClient: apiClient */); 
    
    // 创建WebSocketService
    final webSocketService = WebSocketService(); */

    // 创建NovelRepository (它不再需要MockDataService)
    final novelRepository = NovelRepositoryImpl(/* apiClient: apiClient */);

    // 创建ChatRepository，并传入 ApiClient
    final chatRepository = ChatRepositoryImpl(
      apiClient: apiClient, // 使用直接创建的 apiClient
    );

    // 创建StorageRepository实例
    final storageRepository = StorageRepositoryImpl(apiClient);

    // 创建UserAIModelConfigRepository
    final userAIModelConfigRepository =
        UserAIModelConfigRepositoryImpl(apiClient: apiClient);

    // 创建PublicModelRepository
    final publicModelRepository = PublicModelRepositoryImpl(apiClient: apiClient);

    // 创建CreditRepository
    final creditRepository = CreditRepositoryImpl(apiClient: apiClient);

    // 创建NovelSettingRepository
    final novelSettingRepository = NovelSettingRepositoryImpl(apiClient: apiClient);



    // 创建PromptRepository
    final promptRepository = PromptRepositoryImpl(apiClient);

    // 创建NovelFileService
    final novelFileService = NovelFileService(
      novelRepository: novelRepository,
      // editorRepository 暂时为空，可以后续添加
    );

    // 创建NovelSnippetRepository
    final novelSnippetRepository = NovelSnippetRepositoryImpl(apiClient);

    // 创建UniversalAIRepository
    final universalAIRepository = UniversalAIRepositoryImpl(apiClient: apiClient);

    // 创建PresetAggregationRepository
    final presetAggregationRepository = PresetAggregationRepositoryImpl(apiClient);

    // 创建AIPresetRepository
    final aiPresetRepository = AIPresetRepositoryImpl(apiClient: apiClient);

    // 创建SettingGenerationRepository
    final settingGenerationRepository = SettingGenerationRepositoryImpl(
      apiClient: apiClient,
      sseClient: sseClient,
    );

    // 初始化图片缓存服务（如需预热可在此调用）
    // ImageCacheService().prewarm();

    AppLogger.i('Main', '应用程序初始化完成，准备启动界面');

    runApp(MultiRepositoryProvider(
      providers: [
        RepositoryProvider<auth_service.AuthService>.value(
            value: authServiceInstance),
        RepositoryProvider<ApiClient>.value(value: apiClient),
        RepositoryProvider<NovelRepository>.value(value: novelRepository),
        RepositoryProvider<ChatRepository>.value(value: chatRepository),
        RepositoryProvider<StorageRepository>.value(value: storageRepository),
        RepositoryProvider<UserAIModelConfigRepository>.value(
            value: userAIModelConfigRepository),
        RepositoryProvider<PublicModelRepository>.value(
            value: publicModelRepository),
        RepositoryProvider<CreditRepository>.value(
            value: creditRepository),
        RepositoryProvider<LocalStorageService>.value(
            value: localStorageService),
        RepositoryProvider<PromptRepository>(
          create: (context) => promptRepository,
        ),
        RepositoryProvider<NovelFileService>.value(
          value: novelFileService,
        ),
        RepositoryProvider<NovelSnippetRepository>.value(
          value: novelSnippetRepository,
        ),
        RepositoryProvider<UniversalAIRepository>.value(
          value: universalAIRepository,
        ),
        RepositoryProvider<PresetAggregationRepository>.value(
          value: presetAggregationRepository,
        ),
        RepositoryProvider<AIPresetRepository>.value(
          value: aiPresetRepository,
        ),
        RepositoryProvider<SettingGenerationRepository>.value(
          value: settingGenerationRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authService: context.read<auth_service.AuthService>(),
            )..add(AuthInitialize()),
          ),
          BlocProvider<NovelListBloc>(
            create: (context) => NovelListBloc(
              repository: context.read<NovelRepository>(),
            ),
          ),
          BlocProvider<AiConfigBloc>(
            create: (context) => AiConfigBloc(
              repository: context.read<UserAIModelConfigRepository>(),
            ),
          ),
          BlocProvider<PublicModelsBloc>(
            create: (context) => PublicModelsBloc(
              repository: context.read<PublicModelRepository>(),
            ),
          ),
          BlocProvider<CreditBloc>(
            create: (context) => CreditBloc(
              repository: context.read<CreditRepository>(),
            ),
          ),
          BlocProvider<SettingGenerationBloc>(
            create: (context) => SettingGenerationBloc(
              repository: context.read<SettingGenerationRepository>(),
            ),
          ),
          /*
          BlocProvider<ReaderBloc>(
            create: (context) => ReaderBloc(
              repository: context.read<NovelRepository>(),
            ),
          ),
          */
          BlocProvider<ChatBloc>(
            create: (context) => ChatBloc(
              repository: context.read<ChatRepository>(),
              authService: context.read<auth_service.AuthService>(),
              aiConfigBloc: context.read<AiConfigBloc>(),
              publicModelsBloc: context.read<PublicModelsBloc>(),
              settingRepository: novelSettingRepository,
              snippetRepository: novelSnippetRepository,
            ),
          ),
          BlocProvider<EditorVersionBloc>(
            create: (context) => EditorVersionBloc(
              novelRepository: context.read<NovelRepository>(),
            ),
          ),
          BlocProvider<UniversalAIBloc>(
            create: (context) => UniversalAIBloc(
              repository: context.read<UniversalAIRepository>(),
            ),
          ),
          BlocProvider<PromptNewBloc>(
            create: (context) => PromptNewBloc(
              promptRepository: context.read<PromptRepository>(),
            ),
          ),
          BlocProvider<ThemeBloc>(
            create: (context) => ThemeBloc()..add(ThemeInitialize()),
          ),
          BlocProvider<PresetBloc>(
            create: (context) => PresetBloc(
              aggregationRepository: context.read<PresetAggregationRepository>(),
              presetRepository: context.read<AIPresetRepository>(),
            ),
          ),
        ],
        child: const MyApp(),
      ),
    ));
  }, (error, stack) {
    // 兜底：捕获所有未处理异常并记录，避免在 Web 上出现 LegacyJavaScriptObject -> DiagnosticsNode 的崩溃
    AppLogger.e('Uncaught', '未捕获异常: $error', error, stack);
  });
}

// 初始化注册配置
Future<void> _initializeRegistrationConfig() async {
  try {
    // 确保注册配置已初始化，设置默认值
    // 默认开启邮箱注册和手机注册，需要验证码验证
    final phoneEnabled = await AppRegistrationConfig.isPhoneRegistrationEnabled();
    final emailEnabled = await AppRegistrationConfig.isEmailRegistrationEnabled();
    final verificationRequired = await AppRegistrationConfig.isVerificationRequired();
    
    AppLogger.i('Registration', 
        '📝 注册配置已加载 - 邮箱注册: $emailEnabled, 手机注册: $phoneEnabled, 验证码验证: $verificationRequired');
    
    // 如果没有任何注册方式可用，启用默认的邮箱注册
    if (!phoneEnabled && !emailEnabled) {
      await AppRegistrationConfig.setEmailRegistrationEnabled(true);
      AppLogger.i('Registration', '🔧 已自动启用邮箱注册功能');
    }
  } catch (e) {
    AppLogger.e('Registration', '初始化注册配置失败', e);
  }
}

// 创建资源文件夹
Future<void> _createResourceDirectories() async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final assetsDir = Directory('${appDir.path}/assets');
    final imagesDir = Directory('${assetsDir.path}/images');
    final iconsDir = Directory('${assetsDir.path}/icons');

    // 创建资源目录
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }

    // 创建图像目录
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    // 创建图标目录
    if (!await iconsDir.exists()) {
      await iconsDir.create(recursive: true);
    }

    AppLogger.i('ResourceDir', '资源文件夹创建成功');
  } catch (e) {
    AppLogger.e('ResourceDir', '创建资源文件夹失败', e);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _postLoginBootstrapped = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ImageCacheService().clearCache();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // 应用进入后台或被关闭时清理图片缓存
        ImageCacheService().clearCache();
        break;
      case AppLifecycleState.resumed:
        // 应用恢复时可以预加载一些图片
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return ValueListenableBuilder<String>(
          valueListenable: WebTheme.variantListenable,
          builder: (context, variant, _) {
            // 根据当前变体重建主题
            return MaterialApp(
          navigatorObservers: [NavigationLogger()],
          title: 'AINoval',
              theme: WebTheme.buildLightTheme(),
              darkTheme: WebTheme.buildDarkTheme(),
          themeMode: themeState.themeMode,
          initialRoute: '/',
          routes: {
        '/': (context) => BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              curr is AuthAuthenticated || curr is AuthUnauthenticated,
          listener: (context, state) {
            AppLogger.i('MyApp', '🔔 AuthBloc状态变化: ${state.runtimeType}');
            
            if (state is AuthAuthenticated) {
              if (_postLoginBootstrapped) {
                AppLogger.i('MyApp', '🔁 已完成登录后的初始化，跳过重复触发');
              }
              final userId = AppConfig.userId;
              if (userId != null) {
                AppLogger.i('MyApp',
                    'User authenticated, loading AiConfigs, PublicModels, Credits, Novels, Presets and PromptPackages for user $userId');
                // 并行加载用户AI配置、公共模型和用户积分
                if (!_postLoginBootstrapped) {
                  context.read<AiConfigBloc>().add(LoadAiConfigs(userId: userId));
                  context.read<PublicModelsBloc>().add(const LoadPublicModels());
                  // 每次登录都强制重新加载积分，避免复用上个账号缓存
                  context.read<CreditBloc>().add(const LoadUserCredits());
                  // 用户登录成功后，加载一次小说列表数据（仅在未加载时）
                  final novelState = context.read<NovelListBloc>().state;
                  if (novelState is! NovelListLoaded) {
                    context.read<NovelListBloc>().add(LoadNovels());
                  }
                  // 预设与提示词包
                  context.read<PresetBloc>().add(const LoadAllPresetData());
                  context.read<PromptNewBloc>().add(const LoadAllPromptPackages());
                  _postLoginBootstrapped = true;
                }
              } else {
                AppLogger.e('MyApp',
                    'User authenticated but userId is null in AppConfig!');
              }
            } else if (state is AuthUnauthenticated) {
              AppLogger.i('MyApp', '✅ 用户已退出登录，清理所有BLoC状态');
              _postLoginBootstrapped = false;
              
              // 清理所有BLoC状态，停止进行中的请求
              try {
                // 重置 AI 配置，避免跨用户复用本地缓存/内存状态
                context.read<AiConfigBloc>().add(const ResetAiConfigs());
              } catch (e) {
                AppLogger.w('MyApp', '重置AiConfigBloc状态失败', e);
              }
              try {
                // 清理小说列表状态
                context.read<NovelListBloc>().add(ClearNovels());
                AppLogger.i('MyApp', '✅ NovelListBloc状态已清理');
              } catch (e) {
                AppLogger.w('MyApp', '清理NovelListBloc状态失败', e);
              }
              
              // 清空积分显示为游客（0）
              try {
                context.read<CreditBloc>().add(const ClearCredits());
                AppLogger.i('MyApp', '✅ CreditBloc状态已清空');
              } catch (e) {
                AppLogger.w('MyApp', '清空CreditBloc状态失败', e);
              }
              
              // 清除用户显示名称为游客
              AppConfig.setUsername(null);
              AppConfig.setUserId(null);
              AppConfig.setAuthToken(null);
              // 可以根据需要添加其他BLoC的清理逻辑
              // 但暂时先清理最关键的小说列表，避免404请求
            } else if (state is AuthLoading) {
              AppLogger.i('MyApp', '⏳ 认证状态加载中...');
            } else if (state is AuthError) {
              AppLogger.w('MyApp', '❌ 认证错误: ${state.message}');
            }
          },
          buildWhen: (prev, curr) =>
              curr is AuthAuthenticated || curr is AuthUnauthenticated,
          builder: (context, state) {
            AppLogger.i('MyApp', '🏗️ 构建UI，当前状态: ${state.runtimeType}');
            
            if (state is AuthAuthenticated) {
              AppLogger.i(
                  'MyApp', '📚 显示小说列表界面');
              // 🚀 登录成功后异步加载并应用用户的主题变体，确保全局组件使用保存的主题色
              final userId = AppConfig.userId;
              if (userId != null) {
                () async {
                  try {
                    final settings = await NovelRepositoryImpl.getInstance().getUserEditorSettings(userId);
                    WebTheme.applyVariant(settings.themeVariant);
                    AppLogger.i('MyApp', '🎨 已应用用户主题变体: ${settings.themeVariant}');
                  } catch (e) {
                    AppLogger.w('MyApp', '无法应用用户主题变体: $e');
                  }
                }();
              }
              // 异步加载小说列表页面，实现代码分割
              return FutureBuilder(
                future: novel_list.loadLibrary(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return novel_list.NovelListRealDataScreen();
                  }
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              );
            }
            // 未登录：默认展示小说列表的“游客模式”界面，受控于页面内的鉴权弹窗
            return FutureBuilder(
              future: novel_list.loadLibrary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return novel_list.NovelListRealDataScreen();
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            );
          },
        ),
            '/unified-management': (context) => FutureBuilder(
              future: unified_mgmt.loadLibrary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return unified_mgmt.UnifiedManagementScreen();
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),


          },
          debugShowCheckedModeBanner: false,

          // 添加完整的本地化支持
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.all,
          locale: const Locale('zh', 'CN'), // 设置默认语言为中文
        );
          },
        );
      },
    );
  }
}


