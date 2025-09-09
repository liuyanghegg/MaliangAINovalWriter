import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/admin/admin_bloc.dart';
import '../../utils/web_theme.dart';
import 'widgets/user_management_table.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    // 加载用户数据
    context.read<AdminBloc>().add(LoadUsers());
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
                '用户管理',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: WebTheme.getTextColor(context),
                ),
              ),
            ),
            // 内容区域
            Expanded(
              child: BlocBuilder<AdminBloc, AdminState>(
                builder: (context, state) {
                  if (state is AdminLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          WebTheme.getTextColor(context),
                        ),
                      ),
                    );
                  } else if (state is AdminError) {
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
                              context.read<AdminBloc>().add(LoadUsers());
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
                  } else if (state is UsersLoaded) {
                    return UserManagementTable(users: state.users);
                  } else {
                    // 初始状态或其他状态，显示空状态
                    return Center(
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
                            '暂无用户数据',
                            style: TextStyle(
                              color: WebTheme.getSecondaryTextColor(context),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<AdminBloc>().add(LoadUsers());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WebTheme.getTextColor(context),
                              foregroundColor: WebTheme.getBackgroundColor(context),
                            ),
                            child: const Text('加载用户'),
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