import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/subscription/subscription_bloc.dart';
import '../../utils/web_theme.dart';
import 'widgets/subscription_plan_table.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> {
  @override
  void initState() {
    super.initState();
    // 加载订阅计划数据
    context.read<SubscriptionBloc>().add(LoadSubscriptionPlans());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.getBackgroundColor(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面标题
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Text(
                '订阅管理',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: WebTheme.getTextColor(context),
                ),
              ),
            ),
            // 内容区域
            Expanded(
              child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
                builder: (context, state) {
                  if (state is SubscriptionLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          WebTheme.getTextColor(context),
                        ),
                      ),
                    );
                  } else if (state is SubscriptionError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '加载失败：${state.message}',
                            style: TextStyle(
                              color: WebTheme.getTextColor(context),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<SubscriptionBloc>().add(LoadSubscriptionPlans());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WebTheme.getTextColor(context),
                              foregroundColor: WebTheme.getBackgroundColor(context),
                            ),
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    );
                  } else if (state is SubscriptionPlansLoaded) {
                    return SubscriptionPlanTable(plans: state.plans);
                  } else {
                    // 初始状态或其他状态，显示空状态
                    return Center(
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
                            '暂无订阅计划数据',
                            style: TextStyle(
                              color: WebTheme.getSecondaryTextColor(context),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<SubscriptionBloc>().add(LoadSubscriptionPlans());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WebTheme.getTextColor(context),
                              foregroundColor: WebTheme.getBackgroundColor(context),
                            ),
                            child: const Text('加载订阅计划'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}