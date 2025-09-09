import '../../../../../models/admin/llm_observability_models.dart';
import '../../admin/llm_observability_repository.dart';
import '../../../base/api_client.dart';
import '../../../base/api_exception.dart';
import '../../../../../utils/logger.dart';


/// LLM可观测性仓库实现
class LLMObservabilityRepositoryImpl implements LLMObservabilityRepository {
  final ApiClient _apiClient;
  final String _tag = 'LLMObservabilityRepository';

  LLMObservabilityRepositoryImpl({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // ==================== 日志查询 ====================

  /// 获取所有LLM调用日志
  Future<PagedResponse<LLMTrace>> getAllTraces({
    int page = 0,
    int size = 20,
    String sortBy = 'timestamp',
    String sortDir = 'desc',
  }) async {
    try {
      AppLogger.d(_tag, '获取LLM调用日志: page=$page, size=$size, sortBy=$sortBy, sortDir=$sortDir');
      
      final response = await _apiClient.getWithParams('/admin/llm-observability/traces', queryParameters: {
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDir': sortDir,
      });

      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return PagedResponse.fromJson(response['data'], (json) => LLMTrace.fromJson(json as Map<String, dynamic>));
      } else if (response is Map<String, dynamic>) {
        return PagedResponse.fromJson(response, (json) => LLMTrace.fromJson(json as Map<String, dynamic>));
      } else {
        throw ApiException(-1, 'LLM日志响应格式错误');
      }
    } catch (e) {
      AppLogger.e(_tag, '获取LLM调用日志失败', e);
      rethrow;
    }
  }

  /// 游标分页获取LLM调用日志
  @override
  Future<CursorPageResponse<LLMTrace>> getTracesByCursor({
    String? cursor,
    int limit = 50,
    String? userId,
    String? provider,
    String? model,
    String? sessionId,
    bool? hasError,
    String? businessType,
    String? correlationId,
    String? traceId,
    String? type,
    String? tag,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final params = <String, dynamic>{
        'limit': limit,
      };
      if (cursor != null && cursor.isNotEmpty) params['cursor'] = cursor;
      if (userId != null) params['userId'] = userId;
      if (provider != null) params['provider'] = provider;
      if (model != null) params['model'] = model;
      if (sessionId != null) params['sessionId'] = sessionId;
      if (hasError != null) params['hasError'] = hasError;
      if (businessType != null) params['businessType'] = businessType;
      if (correlationId != null) params['correlationId'] = correlationId;
      if (traceId != null) params['traceId'] = traceId;
      if (type != null) params['type'] = type;
      if (tag != null) params['tag'] = tag;
      if (startTime != null) params['startTime'] = startTime.toIso8601String();
      if (endTime != null) params['endTime'] = endTime.toIso8601String();

      final response = await _apiClient.getWithParams('/admin/llm-observability/traces/cursor', queryParameters: params);
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return CursorPageResponse.fromJson(response['data'], (json) => LLMTrace.fromJson(json as Map<String, dynamic>));
      } else if (response is Map<String, dynamic>) {
        return CursorPageResponse.fromJson(response, (json) => LLMTrace.fromJson(json as Map<String, dynamic>));
      } else {
        throw ApiException(-1, '游标分页响应格式错误');
      }
    } catch (e) {
      AppLogger.e(_tag, '游标分页获取LLM调用日志失败', e);
      rethrow;
    }
  }

  /// 根据用户ID获取LLM调用日志
  Future<PagedResponse<LLMTrace>> getTracesByUserId(
    String userId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      AppLogger.d(_tag, '获取用户LLM调用日志: userId=$userId, page=$page, size=$size');
      
      final response = await _apiClient.getWithParams('/admin/llm-observability/traces/user/$userId', queryParameters: {
        'page': page,
        'size': size,
      });

      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return PagedResponse.fromJson(response['data'], (json) => LLMTrace.fromJson(json as Map<String, dynamic>));
      } else if (response is Map<String, dynamic>) {
        return PagedResponse.fromJson(response, (json) => LLMTrace.fromJson(json as Map<String, dynamic>));
      } else {
        throw ApiException(-1, '用户LLM日志响应格式错误');
      }
    } catch (e) {
      AppLogger.e(_tag, '获取用户LLM调用日志失败', e);
      rethrow;
    }
  }

  /// 根据提供商获取LLM调用日志
  Future<PagedResponse<LLMTrace>> getTracesByProvider(
    String provider, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      AppLogger.d(_tag, '获取提供商LLM调用日志: provider=$provider, page=$page, size=$size');
      
      final response = await _apiClient.getWithParams('/admin/llm-observability/traces/provider/$provider', queryParameters: {
        'page': page,
        'size': size,
      });

      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return PagedResponse.fromJson(response['data'], (json) => LLMTrace.fromJson(json as Map<String, dynamic>));
      } else if (response is Map<String, dynamic>) {
        return PagedResponse.fromJson(response, (json) => LLMTrace.fromJson(json as Map<String, dynamic>));
      } else {
        throw ApiException(-1, '提供商LLM日志响应格式错误');
      }
    } catch (e) {
      AppLogger.e(_tag, '获取提供商LLM调用日志失败', e);
      rethrow;
    }
  }

  /// 根据模型名称获取LLM调用日志
  Future<PagedResponse<LLMTrace>> getTracesByModel(
    String modelName, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      AppLogger.d(_tag, '获取模型LLM调用日志: modelName=$modelName, page=$page, size=$size');
      
      final response = await _apiClient.getWithParams('/admin/llm-observability/traces/model/$modelName', queryParameters: {
        'page': page,
        'size': size,
      });

      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return PagedResponse.fromJson(response['data'], (json) => LLMTrace.fromJson(json as Map<String, dynamic>));
      } else if (response is Map<String, dynamic>) {
        return PagedResponse.fromJson(response, (json) => LLMTrace.fromJson(json as Map<String, dynamic>));
      } else {
        throw ApiException(-1, '模型LLM日志响应格式错误');
      }
    } catch (e) {
      AppLogger.e(_tag, '获取模型LLM调用日志失败', e);
      rethrow;
    }
  }

  /// 根据时间范围获取LLM调用日志
  Future<PagedResponse<LLMTrace>> getTracesByTimeRange(
    DateTime startTime,
    DateTime endTime, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      AppLogger.d(_tag, '按时间范围获取LLM调用日志: startTime=$startTime, endTime=$endTime, page=$page, size=$size');
      
      final response = await _apiClient.getWithParams('/admin/llm-observability/traces/timerange', queryParameters: {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'page': page,
        'size': size,
      });

      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return PagedResponse.fromJson(response['data'], (json) => LLMTrace.fromJson(json as Map<String, dynamic>));
      } else if (response is Map<String, dynamic>) {
        return PagedResponse.fromJson(response, (json) => LLMTrace.fromJson(json as Map<String, dynamic>));
      } else {
        throw ApiException(-1, '时间范围LLM日志响应格式错误');
      }
    } catch (e) {
      AppLogger.e(_tag, '按时间范围获取LLM调用日志失败', e);
      rethrow;
    }
  }

  /// 搜索LLM调用日志
  Future<PagedResponse<LLMTrace>> searchTraces(
    LLMTraceSearchCriteria criteria, {
    String? businessType,
    String? correlationId,
    String? traceId,
    String? type,
    String? tag,
  }) async {
    try {
      AppLogger.d(_tag, '搜索LLM调用日志: criteria=$criteria');
      
      final queryParams = <String, dynamic>{
        'page': criteria.page,
        'size': criteria.size,
      };
      
      if (criteria.userId != null) queryParams['userId'] = criteria.userId;
      if (criteria.provider != null) queryParams['provider'] = criteria.provider;
      if (criteria.model != null) queryParams['model'] = criteria.model;
      if (criteria.sessionId != null) queryParams['sessionId'] = criteria.sessionId;
      if (criteria.hasError != null) queryParams['hasError'] = criteria.hasError;
      if (criteria.startTime != null) queryParams['startTime'] = criteria.startTime!.toIso8601String();
      if (criteria.endTime != null) queryParams['endTime'] = criteria.endTime!.toIso8601String();
      if (businessType != null && businessType.isNotEmpty) queryParams['businessType'] = businessType;
      if (correlationId != null && correlationId.isNotEmpty) queryParams['correlationId'] = correlationId;
      if (traceId != null && traceId.isNotEmpty) queryParams['traceId'] = traceId;
      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (tag != null && tag.isNotEmpty) queryParams['tag'] = tag;
      
      final response = await _apiClient.getWithParams('/admin/llm-observability/traces/search', queryParameters: queryParams);

      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return PagedResponse.fromJson(response['data'], (json) => LLMTrace.fromJson(json as Map<String, dynamic>));
      } else if (response is Map<String, dynamic>) {
        return PagedResponse.fromJson(response, (json) => LLMTrace.fromJson(json as Map<String, dynamic>));
      } else {
        throw ApiException(-1, '搜索LLM日志响应格式错误');
      }
    } catch (e) {
      AppLogger.e(_tag, '搜索LLM调用日志失败', e);
      rethrow;
    }
  }

  /// 获取单个LLM调用日志详情
  Future<LLMTrace?> getTraceById(String traceId) async {
    try {
      AppLogger.d(_tag, '获取LLM调用日志详情: traceId=$traceId');
      
      final response = await _apiClient.getWithParams('/admin/llm-observability/traces/$traceId');

      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return LLMTrace.fromJson(response['data']);
      } else if (response is Map<String, dynamic>) {
        return LLMTrace.fromJson(response);
      } else {
        return null;
      }
    } catch (e) {
      AppLogger.e(_tag, '获取LLM调用日志详情失败', e);
      if (e is ApiException && e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  // ==================== 统计分析 ====================

  /// 获取LLM调用统计概览
  Future<Map<String, dynamic>> getOverviewStatistics({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      AppLogger.d(_tag, '获取LLM调用统计概览: startTime=$startTime, endTime=$endTime');
      
      final queryParams = <String, dynamic>{};
      if (startTime != null) queryParams['startTime'] = startTime.toIso8601String();
      if (endTime != null) queryParams['endTime'] = endTime.toIso8601String();
      
      final response = await _apiClient.getWithParams('/admin/llm-observability/statistics/overview', queryParameters: queryParams);

      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return response['data'];
      } else if (response is Map<String, dynamic>) {
        return response;
      } else {
        throw ApiException(-1, '统计概览响应格式错误');
      }
    } catch (e) {
      AppLogger.e(_tag, '获取LLM调用统计概览失败', e);
      rethrow;
    }
  }

    /// 获取提供商统计信息
  @override
  Future<List<ProviderStatistics>> getProviderStatistics({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      AppLogger.d(_tag, '获取提供商统计信息: startTime=$startTime, endTime=$endTime');
      
      final queryParams = <String, dynamic>{};
      if (startTime != null) queryParams['startTime'] = startTime.toIso8601String();
      if (endTime != null) queryParams['endTime'] = endTime.toIso8601String();
      
      final response = await _apiClient.getWithParams('/admin/llm-observability/statistics/providers', queryParameters: queryParams);

      Map<String, dynamic> dataMap;
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        final d = response['data'];
        if (d is Map<String, dynamic>) {
          dataMap = d;
        } else {
          AppLogger.w(_tag, '提供商统计 data 非 Map，实际为: ${d.runtimeType}');
          return [];
        }
      } else if (response is Map<String, dynamic>) {
        dataMap = response;
      } else {
        AppLogger.w(_tag, '提供商统计响应不是 Map，实际为: ${response.runtimeType}');
        return [];
      }

      final Map<String, num> callsByProvider = Map<String, num>.from(dataMap['callsByProvider'] ?? {});
      final Map<String, num> errorsByProvider = Map<String, num>.from(dataMap['errorsByProvider'] ?? {});
      final Map<String, num> avgDurationByProvider = Map<String, num>.from(dataMap['avgDurationByProvider'] ?? {});

      final List<ProviderStatistics> result = [];
      for (final entry in callsByProvider.entries) {
        final String provider = entry.key;
        final int totalCalls = entry.value.toInt();
        final int failed = (errorsByProvider[provider] ?? 0).toInt();
        final int successful = totalCalls - failed;
        final double successRate = totalCalls == 0 ? 0.0 : successful / totalCalls * 100.0;
        final double avgLatency = (avgDurationByProvider[provider] ?? 0).toDouble();

        final stats = LLMStatistics(
          totalCalls: totalCalls,
          successfulCalls: successful,
          failedCalls: failed,
          successRate: successRate,
          averageLatency: avgLatency,
          totalTokens: 0,
        );

        result.add(ProviderStatistics(provider: provider, statistics: stats, models: const []));
      }

      // 排序：按调用次数降序
      result.sort((a, b) => b.statistics.totalCalls.compareTo(a.statistics.totalCalls));
      return result;
    } catch (e) {
      AppLogger.e(_tag, '获取提供商统计信息失败', e);
      // 出错时返回空列表而不是抛出异常，避免崩溃
      return [];
    }
  }

  /// 获取模型统计信息
  @override
  Future<List<ModelStatistics>> getModelStatistics({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      AppLogger.d(_tag, '获取模型统计信息: startTime=$startTime, endTime=$endTime');
      
      final queryParams = <String, dynamic>{};
      if (startTime != null) queryParams['startTime'] = startTime.toIso8601String();
      if (endTime != null) queryParams['endTime'] = endTime.toIso8601String();
      
      final response = await _apiClient.getWithParams('/admin/llm-observability/statistics/models', queryParameters: queryParams);

      Map<String, dynamic> dataMap;
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        final d = response['data'];
        if (d is Map<String, dynamic>) {
          dataMap = d;
        } else {
          AppLogger.w(_tag, '模型统计 data 非 Map，实际为: ${d.runtimeType}');
          return [];
        }
      } else if (response is Map<String, dynamic>) {
        dataMap = response;
      } else {
        AppLogger.w(_tag, '模型统计响应不是 Map，实际为: ${response.runtimeType}');
        return [];
      }

      final Map<String, num> callsByModel = Map<String, num>.from(dataMap['callsByModel'] ?? {});
      final Map<String, num> errorsByModel = Map<String, num>.from(dataMap['errorsByModel'] ?? {});
      final Map<String, num> tokensByModel = Map<String, num>.from(dataMap['tokensByModel'] ?? {});

      final List<ModelStatistics> result = [];
      for (final entry in callsByModel.entries) {
        final String modelName = entry.key;
        final int totalCalls = entry.value.toInt();
        final int failed = (errorsByModel[modelName] ?? 0).toInt();
        final int successful = totalCalls - failed;
        final double successRate = totalCalls == 0 ? 0.0 : successful / totalCalls * 100.0;
        final int totalTokens = (tokensByModel[modelName] ?? 0).toInt();

        final stats = LLMStatistics(
          totalCalls: totalCalls,
          successfulCalls: successful,
          failedCalls: failed,
          successRate: successRate,
          averageLatency: 0.0,
          totalTokens: totalTokens,
        );

        // 后端未提供 provider 归属，这里尝试从模型名前缀简单推断，否则留空
        final provider = _inferProviderFromModel(modelName);
        result.add(ModelStatistics(modelName: modelName, provider: provider, statistics: stats));
      }

      // 排序：按调用次数降序
      result.sort((a, b) => b.statistics.totalCalls.compareTo(a.statistics.totalCalls));
      return result;
    } catch (e) {
      AppLogger.e(_tag, '获取模型统计信息失败', e);
      // 出错时返回空列表而不是抛出异常，避免崩溃
      return [];
    }
  }

  String _inferProviderFromModel(String modelName) {
    final lower = modelName.toLowerCase();
    if (lower.contains('gpt') || lower.contains('o1') || lower.contains('openai')) return 'OpenAI';
    if (lower.contains('claude') || lower.contains('anthropic')) return 'Anthropic';
    if (lower.contains('gemini') || lower.contains('google') || lower.contains('palm')) return 'Google';
    if (lower.contains('glm') || lower.contains('zhipu')) return 'ZhipuAI';
    if (lower.contains('qwen') || lower.contains('dashscope') || lower.contains('ali')) return 'AliCloud';
    return '';
  }

  /// 获取用户统计信息
  @override
  Future<List<UserStatistics>> getUserStatistics({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      AppLogger.d(_tag, '获取用户统计信息: startTime=$startTime, endTime=$endTime');
      
      final queryParams = <String, dynamic>{};
      if (startTime != null) queryParams['startTime'] = startTime.toIso8601String();
      if (endTime != null) queryParams['endTime'] = endTime.toIso8601String();
      
      final response = await _apiClient.getWithParams('/admin/llm-observability/statistics/users', queryParameters: queryParams);

      Map<String, dynamic> dataMap;
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        final d = response['data'];
        if (d is Map<String, dynamic>) {
          dataMap = d;
        } else {
          AppLogger.w(_tag, '用户统计 data 非 Map，实际为: ${d.runtimeType}');
          return [];
        }
      } else if (response is Map<String, dynamic>) {
        dataMap = response;
      } else {
        AppLogger.w(_tag, '用户统计响应不是 Map，实际为: ${response.runtimeType}');
        return [];
      }

      final Map<String, num> callsByUser = Map<String, num>.from(dataMap['callsByUser'] ?? {});
      final Map<String, num> tokensByUser = Map<String, num>.from(dataMap['tokensByUser'] ?? {});
      final Map<String, num> errorsByUser = Map<String, num>.from(dataMap['errorsByUser'] ?? {});

      final List<UserStatistics> result = [];
      for (final entry in callsByUser.entries) {
        final String userId = entry.key;
        final int totalCalls = entry.value.toInt();
        final int failed = (errorsByUser[userId] ?? 0).toInt();
        final int successful = totalCalls - failed;
        final double successRate = totalCalls == 0 ? 0.0 : successful / totalCalls * 100.0;
        final int totalTokens = (tokensByUser[userId] ?? 0).toInt();

        final stats = LLMStatistics(
          totalCalls: totalCalls,
          successfulCalls: successful,
          failedCalls: failed,
          successRate: successRate,
          averageLatency: 0.0,
          totalTokens: totalTokens,
        );

        result.add(UserStatistics(
          userId: userId,
          username: null,
          statistics: stats,
          topModels: const [],
          topProviders: const [],
        ));
      }

      // 排序：按调用次数降序
      result.sort((a, b) => b.statistics.totalCalls.compareTo(a.statistics.totalCalls));
      return result;
    } catch (e) {
      AppLogger.e(_tag, '获取用户统计信息失败', e);
      // 出错时返回空列表而不是抛出异常，避免崩溃
      return [];
    }
  }

  /// 获取错误统计信息
  @override
  Future<List<ErrorStatistics>> getErrorStatistics({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      AppLogger.d(_tag, '获取错误统计信息: startTime=$startTime, endTime=$endTime');
      
      final queryParams = <String, dynamic>{};
      if (startTime != null) queryParams['startTime'] = startTime.toIso8601String();
      if (endTime != null) queryParams['endTime'] = endTime.toIso8601String();
      
      final response = await _apiClient.getWithParams('/admin/llm-observability/statistics/errors', queryParameters: queryParams);

      List<dynamic> dataList;
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          dataList = data;
        } else {
          AppLogger.w(_tag, '错误统计数据不是List格式: ${data.runtimeType}');
          return [];
        }
      } else if (response is List) {
        dataList = response;
      } else {
        AppLogger.w(_tag, '错误统计响应格式错误，返回空列表: ${response.runtimeType}');
        return [];
      }

      return dataList
          .map((item) => ErrorStatistics.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.e(_tag, '获取错误统计信息失败', e);
      return [];
    }
  }

  /// 获取性能统计信息
  @override
  Future<PerformanceStatistics> getPerformanceStatistics({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      AppLogger.d(_tag, '获取性能统计信息: startTime=$startTime, endTime=$endTime');
      
      final queryParams = <String, dynamic>{};
      if (startTime != null) queryParams['startTime'] = startTime.toIso8601String();
      if (endTime != null) queryParams['endTime'] = endTime.toIso8601String();
      
      final response = await _apiClient.getWithParams('/admin/llm-observability/statistics/performance', queryParameters: queryParams);

      Map<String, dynamic> data;
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        data = response['data'];
      } else if (response is Map<String, dynamic>) {
        data = response;
      } else {
        throw ApiException(-1, '性能统计响应格式错误');
      }

      return PerformanceStatistics.fromJson(data);
    } catch (e) {
      AppLogger.e(_tag, '获取性能统计信息失败', e);
      // 返回空的性能统计对象
      return const PerformanceStatistics(
        averageLatency: 0.0,
        medianLatency: 0.0,
        p95Latency: 0.0,
        p99Latency: 0.0,
        averageThroughput: 0.0,
        latencyTrends: [],
        throughputTrends: [],
      );
    }
  }

  /// 获取趋势数据
  @override
  Future<Map<String, dynamic>> getTrends({
    String? metric,
    String? groupBy,
    String? businessType,
    String? model,
    String? provider,
    String interval = 'hour',
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'interval': interval,
      };
      if (metric != null) queryParams['metric'] = metric;
      if (groupBy != null) queryParams['groupBy'] = groupBy;
      if (businessType != null) queryParams['businessType'] = businessType;
      if (model != null) queryParams['model'] = model;
      if (provider != null) queryParams['provider'] = provider;
      if (startTime != null) queryParams['startTime'] = startTime.toIso8601String();
      if (endTime != null) queryParams['endTime'] = endTime.toIso8601String();

      final response = await _apiClient.getWithParams('/admin/llm-observability/statistics/trends', queryParameters: queryParams);

      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return response['data'];
      } else if (response is Map<String, dynamic>) {
        return response;
      } else {
        throw ApiException(-1, '趋势数据响应格式错误');
      }
    } catch (e) {
      AppLogger.e(_tag, '获取趋势数据失败', e);
      rethrow;
    }
  }

  // ==================== 系统管理 ====================

  /// 导出LLM调用日志
  @override
  Future<List<LLMTrace>> exportTraces({
    Map<String, dynamic>? filterCriteria,
  }) async {
    try {
      AppLogger.d(_tag, '导出LLM调用日志: filterCriteria=$filterCriteria');
      
      dynamic response;
      try {
        // 优先使用带过滤的高级导出端点
        response = await _apiClient.post('/admin/llm-observability/export2', data: filterCriteria ?? {});
      } catch (e) {
        AppLogger.w(_tag, 'export2 不可用，回退到 export', e);
        response = await _apiClient.post('/admin/llm-observability/export', data: filterCriteria ?? {});
      }

      if (response is Map<String, dynamic> && response.containsKey('data')) {
        final List<dynamic> traces = response['data'];
        return traces.map((trace) => LLMTrace.fromJson(trace)).toList();
      } else if (response is List<dynamic>) {
        return response.map((trace) => LLMTrace.fromJson(trace)).toList();
      } else {
        throw ApiException(-1, '导出日志响应格式错误');
      }
    } catch (e) {
      AppLogger.e(_tag, '导出LLM调用日志失败', e);
      rethrow;
    }
  }

  /// 清理旧日志
  @override
  Future<Map<String, dynamic>> cleanupOldTraces(DateTime beforeTime) async {
    try {
      AppLogger.d(_tag, '清理旧日志: beforeTime=$beforeTime');
      
      final response = await _apiClient.deleteWithParams('/admin/llm-observability/cleanup', queryParameters: {
        'beforeTime': beforeTime.toIso8601String(),
      });

      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return response['data'];
      } else if (response is Map<String, dynamic>) {
        return response;
      } else {
        return {'deletedCount': 0};
      }
    } catch (e) {
      AppLogger.e(_tag, '清理旧日志失败', e);
      rethrow;
    }
  }

  /// 获取系统健康状态
  @override
  Future<SystemHealthStatus> getSystemHealth() async {
    try {
      AppLogger.d(_tag, '获取系统健康状态');
      
      final response = await _apiClient.getWithParams('/admin/llm-observability/health');

      Map<String, dynamic> data;
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        data = response['data'];
      } else if (response is Map<String, dynamic>) {
        data = response;
      } else {
        throw ApiException(-1, '系统健康状态响应格式错误');
      }

      return SystemHealthStatus.fromJson(data);
    } catch (e) {
      AppLogger.e(_tag, '获取系统健康状态失败', e);
      // 返回默认的系统健康状态
      return const SystemHealthStatus(
        components: {},
        status: HealthStatus.unknown,
      );
    }
  }

  /// 获取数据库状态
  @override
  Future<Map<String, dynamic>> getDatabaseStatus() async {
    try {
      AppLogger.d(_tag, '获取数据库状态');
      
      final response = await _apiClient.getWithParams('/admin/llm-observability/database/status');

      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return response['data'];
      } else if (response is Map<String, dynamic>) {
        return response;
      } else {
        throw ApiException(-1, '数据库状态响应格式错误');
      }
    } catch (e) {
      AppLogger.e(_tag, '获取数据库状态失败', e);
      rethrow;
    }
  }
}