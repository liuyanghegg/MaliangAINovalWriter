import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/widgets/common/app_sidebar.dart';
import 'package:ainoval/widgets/common/user_avatar_menu.dart';
import 'package:ainoval/screens/settings/settings_panel.dart';
import 'package:ainoval/screens/editor/managers/editor_state_manager.dart';
import 'package:ainoval/models/editor_settings.dart';
import 'package:ainoval/services/api_service/repositories/subscription_repository.dart';
import 'package:ainoval/services/api_service/repositories/payment_repository.dart';
import 'package:ainoval/models/admin/subscription_models.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isSidebarExpanded = true;
  final _subRepo = PublicSubscriptionRepository();
  final _payRepo = PaymentRepository();
  bool _loading = true;
  String? _error;
  List<SubscriptionPlan> _plans = const [];

  BillingCycle _selectedCycle = BillingCycle.monthly;
  static const double _featureColumnWidth = 240.0;
  static const double _planColumnWidth = 220.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final plans = await _subRepo.listActivePlans();
      if (!mounted) return;
      setState(() { _plans = plans; });
    } catch (e) {
      if (!mounted) return;
      // 带上具体异常信息，便于排查是否为鉴权/解析问题
      setState(() { _error = '加载订阅信息失败: $e'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);
    return Scaffold(
      backgroundColor: WebTheme.getBackgroundColor(context),
      body: Row(
        children: [
          AppSidebar(
            isExpanded: _isSidebarExpanded,
            currentRoute: 'my_subscription',
            onExpandedChanged: (v) => setState(() { _isSidebarExpanded = v; }),
            onNavigate: (route) {
              if (route == 'my_subscription') return;
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: WebTheme.getBorderColor(context), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '订阅与升级',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: WebTheme.getTextColor(context),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 20),
                        onPressed: () {},
                        color: WebTheme.getSecondaryTextColor(context),
                      ),
                      const SizedBox(width: 8),
                      UserAvatarMenu(
                        size: 16,
                        onOpenSettings: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (dialogContext) => Dialog(
                              insetPadding: const EdgeInsets.all(16),
                              backgroundColor: Colors.transparent,
                              child: SettingsPanel(
                                stateManager: EditorStateManager(),
                                userId: '',
                                onClose: () => Navigator.of(dialogContext).pop(),
                                editorSettings: const EditorSettings(),
                                onEditorSettingsChanged: (_) {},
                                initialCategoryIndex: SettingsPanel.accountManagementCategoryIndex,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Ultra-Modern Hero
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ultra-large main title
                      Text(
                        '创作升级',
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          color: WebTheme.getTextColor(context),
                          height: 0.9,
                          letterSpacing: -2.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Minimal subtitle
                      Text(
                        '选择适合你的方案',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: WebTheme.getSecondaryTextColor(context),
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 64),
                      // Ultra-simple toggle
                      _ultraSimpleToggle(context),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: _loading
                      ? _skeletonContent(context)
                      : _error != null
                          ? _errorView(context, _error!)
                          : SingleChildScrollView(
                              child: Column(
                                children: [
                                  const SizedBox(height: 40),
                                  // Ultra-clean plans section
                                  Center(child: _plansSection(context)),
                                  const SizedBox(height: 80),
                                  // Modern comparison section
                                  _modernComparisonSection(context),
                                  const SizedBox(height: 120),
                                ],
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



  Widget _plansSection(BuildContext context) {
    final filtered = _filteredPlans();
    if (filtered.isEmpty) {
      return const SizedBox(height: 200);
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            // 窄屏：单列栈叠，卡片自适应宽度
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: filtered
                  .map((plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _ultraCleanCard(context, plan),
                      ))
                  .toList(),
            );
          } else {
            // 宽屏：使用 Wrap 实现响应式多列，避免 Row+Expanded 在滚动视图中的无限宽问题
            return Wrap(
              spacing: 32,
              runSpacing: 24,
              children: filtered
                  .map((plan) => SizedBox(
                        width: 360,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _ultraCleanCard(context, plan),
                        ),
                      ))
                  .toList(),
            );
          }
        },
      ),
    );
  }

  Widget _ultraCleanCard(BuildContext context, SubscriptionPlan p) {
    final feats = p.features ?? const {};
    final recommended = p.recommended;
    
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: recommended 
            ? WebTheme.getTextColor(context).withOpacity(0.04)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: recommended 
            ? Border.all(
                color: WebTheme.getTextColor(context).withOpacity(0.08),
                width: 1,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Minimal badge for recommended
          if (recommended) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: WebTheme.getTextColor(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '推荐',
                style: TextStyle(
                  color: WebTheme.getBackgroundColor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Plan name - ultra large
          Text(
            p.planName,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: WebTheme.getTextColor(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          
          // Price - massive and clean
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '¥${p.price.toInt()}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: WebTheme.getTextColor(context),
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ ${p.billingCycle == BillingCycle.monthly ? "月" : "年"}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: WebTheme.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Minimal feature list - only top 3
          ...(_getTopFeatures(feats).take(3).map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: WebTheme.getTextColor(context),
                height: 1.4,
              ),
            ),
          ))),
          
          const SizedBox(height: 40),
          
          // Single CTA button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _buyPlan(p, PayChannel.wechat),
              style: ElevatedButton.styleFrom(
                backgroundColor: WebTheme.getTextColor(context),
                foregroundColor: WebTheme.getBackgroundColor(context),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                '立即选择',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  List<String> _getTopFeatures(Map<String, dynamic> features) {
    final List<String> topFeatures = [];
    
    // Only show the most important features in a clean way
    if (features['ai.daily.calls'] != null) {
      final calls = features['ai.daily.calls'];
      topFeatures.add(calls == -1 ? '无限AI调用' : '每日${calls}次AI调用');
    }
    
    if (features['novel.max.count'] != null) {
      final count = features['novel.max.count'];
      topFeatures.add(count == -1 ? '无限小说项目' : '最多${count}个小说项目');
    }
    
    if (features['import.daily.limit'] != null) {
      final limit = features['import.daily.limit'];
      topFeatures.add(limit == -1 ? '无限导入' : '每日导入${limit}次');
    }
    
    // Add default features if none specified
    if (topFeatures.isEmpty) {
      topFeatures.addAll([
        '核心创作功能',
        '云端同步备份',
        '多设备支持',
      ]);
    }
    
    return topFeatures;
  }

  Widget _modernComparisonSection(BuildContext context) {
    final filtered = _filteredPlans();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // Section title
          Text(
            '功能对比',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: WebTheme.getTextColor(context),
              letterSpacing: -1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          // Table-style comparison
          _buildComparisonTable(context, filtered),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context, List<SubscriptionPlan> plans) {
    final featureGroups = {
      '创作功能': [
        {'key': 'ai.daily.calls', 'name': 'AI 每日调用次数'},
        {'key': 'novel.max.count', 'name': '小说项目数量'},
        {'key': 'import.daily.limit', 'name': '导入限制'},
        {'key': 'export.formats', 'name': '导出格式'},
      ],
      'AI 集成': [
        {'key': 'ai.scene.summary', 'name': 'AI 场景摘要'},
        {'key': 'ai.character.extraction', 'name': 'AI 角色提取'},
        {'key': 'ai.story.generation', 'name': 'AI 故事生成'},
      ],
      '协作功能': [
        {'key': 'collaboration.viewer', 'name': '邀请查看者'},
        {'key': 'collaboration.editor', 'name': '邀请编辑者'},
        {'key': 'collaboration.team', 'name': '团队协作'},
      ],
      '支持服务': [
        {'key': 'priority.support', 'name': '优先客服支持'},
        {'key': 'advanced.features', 'name': '高级功能'},
      ],
    };

    return Container(
      decoration: BoxDecoration(
        color: WebTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WebTheme.getBorderColor(context).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header row
                    _buildTableHeader(context, plans),
                    // Feature groups
                    ...featureGroups.entries.map((group) =>
                      _buildFeatureGroup(context, group.key, group.value, plans)
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, List<SubscriptionPlan> plans) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: WebTheme.getBorderColor(context).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Feature column header
          SizedBox(
            width: _featureColumnWidth,
            child: Text(
              '功能',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: WebTheme.getSecondaryTextColor(context),
              ),
            ),
          ),
          // Plan headers
          ...plans.map((plan) {
            final isRecommended = plan.recommended;
            return SizedBox(
              width: _planColumnWidth,
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isRecommended 
                      ? WebTheme.getTextColor(context).withOpacity(0.04)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isRecommended 
                      ? Border.all(
                          color: WebTheme.getTextColor(context).withOpacity(0.25),
                          width: 2,
                        )
                      : Border.all(
                          color: Colors.transparent,
                          width: 2,
                        ),
                ),
                child: Column(
                  children: [
                    Text(
                      plan.planName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: WebTheme.getTextColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isRecommended) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: WebTheme.getTextColor(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '推荐',
                          style: TextStyle(
                            color: WebTheme.getBackgroundColor(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _getPlanDescription(plan),
                      style: TextStyle(
                        fontSize: 12,
                        color: WebTheme.getSecondaryTextColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeatureGroup(BuildContext context, String groupName, List<Map<String, String>> features, List<SubscriptionPlan> plans) {
    return Column(
      children: [
        // Group header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: WebTheme.getTextColor(context).withOpacity(0.02),
          child: Text(
            groupName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: WebTheme.getTextColor(context),
            ),
          ),
        ),
        // Feature rows
        ...features.map((feature) => 
          _buildFeatureRow(context, feature['name']!, feature['key']!, plans)
        ),
      ],
    );
  }

  Widget _buildFeatureRow(BuildContext context, String featureName, String featureKey, List<SubscriptionPlan> plans) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: WebTheme.getBorderColor(context).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Feature name
          SizedBox(
            width: _featureColumnWidth,
            child: Text(
              featureName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: WebTheme.getTextColor(context),
              ),
            ),
          ),
          // Plan values
          ...plans.map((plan) {
            final isRecommended = plan.recommended;
            final featureValue = (plan.features ?? {})[featureKey];
            return SizedBox(
              width: _planColumnWidth,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isRecommended 
                      ? WebTheme.getTextColor(context).withOpacity(0.06)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isRecommended 
                      ? Border.all(
                          color: WebTheme.getTextColor(context).withOpacity(0.15),
                          width: 1,
                        )
                      : Border.all(
                          color: Colors.transparent,
                          width: 1,
                        ),
                ),
                child: Center(
                  child: _buildFeatureIcon(context, featureValue),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(BuildContext context, dynamic value) {
    if (value == null || (value is num && value == 0)) {
      return Text(
        '—',
        style: TextStyle(
          fontSize: 16,
          color: WebTheme.getSecondaryTextColor(context),
        ),
      );
    } else if (value is bool) {
      return Icon(
        value ? Icons.check : Icons.close,
        color: value 
            ? const Color(0xFF10B981)
            : WebTheme.getSecondaryTextColor(context),
        size: 18,
      );
    } else if (value is num) {
      if (value < 0) {
        return Text(
          '无限制',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF10B981),
          ),
        );
      } else {
        return Text(
          value.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: WebTheme.getTextColor(context),
          ),
        );
      }
    } else {
      return Text(
        value.toString(),
        style: TextStyle(
          fontSize: 14,
          color: WebTheme.getTextColor(context),
        ),
      );
    }
  }

  String _getPlanDescription(SubscriptionPlan plan) {
    if (plan.description != null && plan.description!.isNotEmpty) {
      return plan.description!;
    }
    // Default descriptions based on plan name
    switch (plan.planName.toLowerCase()) {
      case 'basic':
      case '基础版':
        return '适合初学者，满足基本创作需求';
      case 'pro':
      case '专业版':
        return '适合专业作者，提供高级功能';
      case 'premium':
      case '高级版':
        return '适合团队协作，功能最全面';
      default:
        return '为创作者量身定制的方案';
    }
  }







  Widget _ultraSimpleToggle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Monthly
        GestureDetector(
          onTap: () => setState(() { _selectedCycle = BillingCycle.monthly; }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Text(
              '月付',
              style: TextStyle(
                fontSize: 18,
                fontWeight: _selectedCycle == BillingCycle.monthly ? FontWeight.w700 : FontWeight.w400,
                color: _selectedCycle == BillingCycle.monthly 
                    ? WebTheme.getTextColor(context)
                    : WebTheme.getSecondaryTextColor(context),
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Container(
          width: 1,
          height: 20,
          color: WebTheme.getBorderColor(context),
        ),
        const SizedBox(width: 24),
        // Yearly
        GestureDetector(
          onTap: () => setState(() { _selectedCycle = BillingCycle.yearly; }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              children: [
                Text(
                  '年付',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: _selectedCycle == BillingCycle.yearly ? FontWeight.w700 : FontWeight.w400,
                    color: _selectedCycle == BillingCycle.yearly 
                        ? WebTheme.getTextColor(context)
                        : WebTheme.getSecondaryTextColor(context),
                  ),
                ),
                if (_selectedCycle == BillingCycle.yearly) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '省17%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<SubscriptionPlan> _filteredPlans() {
    final list = _plans.where((p) => p.billingCycle == _selectedCycle).toList();
    list.sort((a, b) {
      if (a.recommended != b.recommended) return a.recommended ? -1 : 1;
      return b.priority.compareTo(a.priority);
    });
    return list;
  }

  Widget _skeletonContent(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _errorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: WebTheme.getSecondaryTextColor(context)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: WebTheme.getTextColor(context))),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _loadData, child: const Text('重试'))
        ],
      ),
    );
  }

  Future<void> _buyPlan(SubscriptionPlan p, PayChannel channel) async {
    try {
      final order = await _payRepo.createPayment(planId: p.id!, channel: channel);
      if (order.paymentUrl.isNotEmpty) {
        final uri = Uri.parse(order.paymentUrl);
        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建订单失败: $e')),
      );
    }
  }
}



