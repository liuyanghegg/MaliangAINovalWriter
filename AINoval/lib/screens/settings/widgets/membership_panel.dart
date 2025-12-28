import 'package:ainoval/models/admin/subscription_models.dart';
import 'package:ainoval/services/api_service/repositories/payment_repository.dart';
import 'package:ainoval/services/api_service/repositories/subscription_repository.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MembershipPanel extends StatefulWidget {
  const MembershipPanel({super.key});

  @override
  State<MembershipPanel> createState() => _MembershipPanelState();
}

class _MembershipPanelState extends State<MembershipPanel> {
  final _subRepo = PublicSubscriptionRepository();
  final _payRepo = PaymentRepository();

  final String _tag = 'MembershipPanel';
  bool _loading = true;
  List<SubscriptionPlan> _plans = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plans = await _subRepo.listActivePlans();
      setState(() {
        _plans = plans;
      });
    } catch (e) {
      AppLogger.e(_tag, '获取订阅计划失败', e);
      setState(() {
        _error = '获取订阅计划失败';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _buy(SubscriptionPlan plan, PayChannel channel) async {
    try {
      final order = await _payRepo.createPayment(planId: plan.id!, channel: channel);
      if (order.paymentUrl.isNotEmpty) {
        final uri = Uri.parse(order.paymentUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      AppLogger.e(_tag, '创建支付失败', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建支付失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _fetchPlans, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_plans.isEmpty) {
      return const Center(child: Text('暂无可购买的会员计划'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = _plans[index];
        final feats = p.features ?? const {};
        final aiDaily = feats['ai.daily.calls']?.toString();
        final importDaily = feats['import.daily.limit']?.toString();
        final novelMax = feats['novel.max.count']?.toString();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p.planName, style: Theme.of(context).textTheme.titleLarge),
                    Text('${p.price.toStringAsFixed(2)} ${p.currency}')
                  ],
                ),
                if (p.description != null && p.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(p.description!),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (aiDaily != null) _badge(context, 'AI每日次数 $aiDaily'),
                    if (importDaily != null) _badge(context, '导入每日次数 $importDaily'),
                    if (novelMax != null) _badge(context, '可创作小说数 $novelMax'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _buy(p, PayChannel.wechat),
                      child: const Text('微信支付'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => _buy(p, PayChannel.alipay),
                      child: const Text('支付宝'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _badge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }
}




