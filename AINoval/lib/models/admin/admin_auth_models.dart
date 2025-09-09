import 'package:equatable/equatable.dart';

/// 管理员认证请求
class AdminAuthRequest extends Equatable {
  final String username;
  final String password;

  const AdminAuthRequest({
    required this.username,
    required this.password,
  });

  factory AdminAuthRequest.fromJson(Map<String, dynamic> json) {
    return AdminAuthRequest(
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }

  @override
  List<Object?> get props => [username, password];
}

/// 管理员认证响应
class AdminAuthResponse extends Equatable {
  final String token;
  final String refreshToken;
  final String userId;
  final String username;
  final String? displayName;
  final List<String> roles;
  final List<String> permissions;

  const AdminAuthResponse({
    required this.token,
    required this.refreshToken,
    required this.userId,
    required this.username,
    this.displayName,
    required this.roles,
    required this.permissions,
  });

  factory AdminAuthResponse.fromJson(Map<String, dynamic> json) {
    return AdminAuthResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      roles: List<String>.from(json['roles'] as List? ?? []),
      permissions: List<String>.from(json['permissions'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'roles': roles,
      'permissions': permissions,
    };
  }

  @override
  List<Object?> get props => [
        token,
        refreshToken,
        userId,
        username,
        displayName,
        roles,
        permissions,
      ];
} 