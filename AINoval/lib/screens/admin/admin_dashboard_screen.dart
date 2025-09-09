/// 管理后台仪表板
/// 包含所有管理功能的导航

import 'package:flutter/material.dart';
import '../../utils/web_theme.dart';
import 'widgets/admin_sidebar.dart';
import 'llm_observability_screen.dart';
import 'public_model_management_screen.dart';
import 'system_presets_management_screen.dart';
import 'public_templates_management_screen.dart';
import 'enhanced_templates_management_screen.dart';
import 'user_management_screen.dart';
import 'role_management_screen.dart';
import 'subscription_management_screen.dart';
import 'billing_audit_screen.dart';
import 'package:get_it/get_it.dart';
import 'package:ainoval/services/api_service/repositories/impl/admin/llm_observability_repository_impl.dart';
import 'package:ainoval/widgets/analytics/analytics_card.dart';
import 'package:ainoval/widgets/analytics/model_usage_chart.dart';
import 'package:ainoval/models/analytics_data.dart';
import 'package:ainoval/models/admin/llm_observability_models.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminOverviewScreen(), // 0: 仪表板
    const LLMObservabilityScreen(), // 1: LLM可观测性
    const UserManagementScreen(), // 2: 用户管理（替换占位页）
    const RoleManagementScreen(), // 3: 角色管理（替换占位页）
    const SubscriptionManagementScreen(), // 4: 订阅管理（替换占位页）
    const PublicModelManagementScreen(), // 5: 公共模型
    const SystemPresetsManagementScreen(), // 6: 系统预设
    const PublicTemplatesManagementScreen(), // 7: 公共模板
    const AdminSystemSettingsScreen(), // 8: 系统配置
    const EnhancedTemplatesManagementScreen(), // 9: 增强模板
    const BillingAuditScreen(), // 10: 计费审计
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.getBackgroundColor(context),
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: WebTheme.getBorderColor(context),
          ),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

// AdminNavigationItem 类已移除，现在使用 AdminSidebar 统一管理导航

/// 管理后台概览页面
class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  late LLMObservabilityRepositoryImpl _repository;
  bool _loading = true;
  String? _error;

  Map<String, dynamic> _overview = const {};
  List<ModelUsageData> _modelUsage = const [];

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<LLMObservabilityRepositoryImpl>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.getOverviewStatistics(),
        _repository.getModelStatistics(),
      ]);

      final overview = results[0] as Map<String, dynamic>;
      final modelStats = results[1] as List<ModelStatistics>;

      setState(() {
        _overview = overview;
        _modelUsage = _buildModelUsageFromStats(modelStats);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  List<ModelUsageData> _buildModelUsageFromStats(List<ModelStatistics> stats) {
    if (stats.isEmpty) return const [];
    // 优先使用 Token 占比，没有则按调用次数占比
    int totalTokens = 0;
    for (final s in stats) {
      totalTokens += s.statistics.totalTokens;
    }

    final bool useTokens = totalTokens > 0;
    final int totalBase = useTokens
        ? totalTokens
        : stats.fold<int>(0, (acc, s) => acc + s.statistics.totalCalls);

    if (totalBase == 0) return const [];

    final List<ModelUsageData> result = [];
    const palette = ['#3B82F6', '#8B5CF6', '#10B981', '#F59E0B', '#EF4444', '#06B6D4'];
    for (int i = 0; i < stats.length; i++) {
      final s = stats[i];
      final int base = useTokens ? s.statistics.totalTokens : s.statistics.totalCalls;
      final int pct = ((base / totalBase) * 100).round();
      result.add(ModelUsageData(
        modelName: s.modelName,
        percentage: pct,
        totalTokens: useTokens ? base : s.statistics.totalTokens,
        color: palette[i % palette.length],
      ));
    }
    // 只取前8个，避免图例过长
    result.sort((a, b) => b.totalTokens.compareTo(a.totalTokens));
    return result.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: WebTheme.getBackgroundColor(context),
        foregroundColor: WebTheme.getTextColor(context),
        title: Text(
          '管理后台仪表板',
          style: TextStyle(color: WebTheme.getTextColor(context)),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _error != null
                ? Center(child: Text('加载失败: $_error'))
                : (_loading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverviewStatsRow(context),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 模型占比图
                              Expanded(
                                child: AnalyticsCard(
                                  title: '模型占比',
                                  value: '',
                                  child: ModelUsageChart(
                                    data: _modelUsage,
                                    viewMode: AnalyticsViewMode.daily,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 模块入口卡片区
                              Expanded(
                                child: GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.6,
                                  children: const [
                                    OverviewCard(
                                      title: 'LLM可观测性',
                                      description: '监控AI模型调用日志、性能指标和错误统计',
                                      icon: Icons.visibility,
                                      count: '—',
                                    ),
                                    OverviewCard(
                                      title: '用户管理',
                                      description: '管理用户账户，查看用户统计信息',
                                      icon: Icons.people,
                                      count: '—',
                                    ),
                                    OverviewCard(
                                      title: '公共模型',
                                      description: '管理和配置系统可用的AI模型',
                                      icon: Icons.cloud,
                                      count: '—',
                                    ),
                                    OverviewCard(
                                      title: '系统预设',
                                      description: '管理系统级别的预设配置',
                                      icon: Icons.smart_button,
                                      count: '—',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.2,
                              children: const [
                                OverviewCard(
                                  title: '公共模板',
                                  description: '管理公共提示词模板库',
                                  icon: Icons.article,
                                  count: '—',
                                ),
                                OverviewCard(
                                  title: '增强模板',
                                  description: '管理用户提交的增强模板',
                                  icon: Icons.auto_awesome,
                                  count: '—',
                                ),
                                OverviewCard(
                                  title: '订阅管理',
                                  description: '订阅套餐、配额与结算',
                                  icon: Icons.subscriptions,
                                  count: '—',
                                ),
                              ],
                            ),
                          ),
                        ],
                      )),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewStatsRow(BuildContext context) {
    final totalCalls = (_overview['totalCalls'] ?? 0).toString();
    final successfulCalls = (_overview['successfulCalls'] ?? 0).toString();
    final failedCalls = (_overview['failedCalls'] ?? 0).toString();
    final successRate = ((_overview['successRate'] ?? 0.0) as num).toDouble();

    return Row(
      children: [
        Expanded(
          child: AnalyticsOverviewCard(
            title: '总调用次数',
            value: totalCalls,
            icon: Icons.analytics,
            subtitle: '统计范围内的模型调用总数',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnalyticsOverviewCard(
            title: '成功次数',
            value: successfulCalls,
            icon: Icons.check_circle,
            subtitle: '无错误完成的调用次数',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnalyticsOverviewCard(
            title: '失败次数',
            value: failedCalls,
            icon: Icons.error_outline,
            subtitle: '发生错误的调用次数',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnalyticsOverviewCard(
            title: '成功率',
            value: '${successRate.toStringAsFixed(1)}%',
            icon: Icons.percent,
            subtitle: '成功调用占比',
          ),
        ),
      ],
    );
  }
}

class OverviewCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? count;

  const OverviewCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: WebTheme.getCardColor(context),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: WebTheme.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: WebTheme.getTextColor(context),
                ),
                const Spacer(),
                if (count != null)
                  Text(
                    count!,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: WebTheme.getTextColor(context),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: WebTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: WebTheme.getSecondaryTextColor(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// 占位页面 - 用户管理
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: WebTheme.getBackgroundColor(context),
        foregroundColor: WebTheme.getTextColor(context),
        title: Text(
          '用户管理',
          style: TextStyle(color: WebTheme.getTextColor(context)),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              '用户管理页面',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: WebTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '此功能正在开发中...',
              style: TextStyle(
                fontSize: 16,
                color: WebTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 占位页面 - 角色管理
class AdminRolesScreen extends StatelessWidget {
  const AdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: WebTheme.getBackgroundColor(context),
        foregroundColor: WebTheme.getTextColor(context),
        title: Text(
          '角色管理',
          style: TextStyle(color: WebTheme.getTextColor(context)),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security_outlined,
              size: 64,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              '角色管理页面',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: WebTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '此功能正在开发中...',
              style: TextStyle(
                fontSize: 16,
                color: WebTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 占位页面 - 订阅管理
class AdminSubscriptionScreen extends StatelessWidget {
  const AdminSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: WebTheme.getBackgroundColor(context),
        foregroundColor: WebTheme.getTextColor(context),
        title: Text(
          '订阅管理',
          style: TextStyle(color: WebTheme.getTextColor(context)),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.subscriptions_outlined,
              size: 64,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              '订阅管理页面',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: WebTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '此功能正在开发中...',
              style: TextStyle(
                fontSize: 16,
                color: WebTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 占位页面 - 系统设置
class AdminSystemSettingsScreen extends StatelessWidget {
  const AdminSystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: WebTheme.getBackgroundColor(context),
        foregroundColor: WebTheme.getTextColor(context),
        title: Text(
          '系统配置',
          style: TextStyle(color: WebTheme.getTextColor(context)),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_outlined,
              size: 64,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              '系统配置页面',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: WebTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '此功能正在开发中...',
              style: TextStyle(
                fontSize: 16,
                color: WebTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}