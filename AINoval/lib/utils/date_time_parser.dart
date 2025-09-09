import 'package:ainoval/utils/logger.dart';

/// 解析来自后端的多种日期时间格式 (String, List, double, int, Map)
///
/// 支持格式:
/// - ISO 8601 字符串 (e.g., "2024-07-30T10:00:00Z", "2024-07-30T10:00:00.123Z")
/// - Java LocalDateTime 数组格式 [year, month, day, hour, minute, second, nanoOfSecond]
/// - Unix 时间戳 (秒, double 类型)
/// - Unix 时间戳 (毫秒, int 类型)  
/// - 后端API响应中的嵌套时间字段 (Map格式)
/// - null 值安全处理
DateTime parseBackendDateTime(dynamic dateTimeValue) {
  if (dateTimeValue == null) {
    AppLogger.w('DateTimeParser', '接收到 null 日期时间值，返回当前时间');
    return DateTime.now();
  }

  if (dateTimeValue is String) {
    // 如果是字符串格式，支持多种ISO 8601格式
    try {
      // 先尝试标准解析
      return DateTime.parse(dateTimeValue);
    } catch (e) {
      // 尝试其他常见格式
      try {
        // 处理可能缺少时区信息的格式
        if (!dateTimeValue.contains('Z') && !dateTimeValue.contains('+') && !dateTimeValue.contains('-', 10)) {
          // 假设为本地时间，添加本地时区
          return DateTime.parse('${dateTimeValue}Z');
        }
        // 处理可能的空格分隔格式 "2024-07-30 10:00:00"
        if (dateTimeValue.contains(' ')) {
          final spacedFormat = dateTimeValue.replaceFirst(' ', 'T');
          return DateTime.parse(spacedFormat);
        }
      } catch (e2) {
        AppLogger.e('DateTimeParser', '多种格式解析均失败, 值: "$dateTimeValue"', e2);
      }
      AppLogger.e('DateTimeParser', '解析日期时间字符串失败, 值: "$dateTimeValue"', e);
      return DateTime.now(); // 解析失败时返回当前时间
    }
  } else if (dateTimeValue is Map) {
    // 处理Map格式，可能来自嵌套的API响应
    try {
      // 尝试从Map中提取时间信息
      if (dateTimeValue.containsKey('timestamp')) {
        return parseBackendDateTime(dateTimeValue['timestamp']);
      } else if (dateTimeValue.containsKey('time')) {
        return parseBackendDateTime(dateTimeValue['time']);
      } else if (dateTimeValue.containsKey('datetime')) {
        return parseBackendDateTime(dateTimeValue['datetime']);
      } else if (dateTimeValue.containsKey('createdAt')) {
        return parseBackendDateTime(dateTimeValue['createdAt']);
      } else if (dateTimeValue.containsKey('updatedAt')) {
        return parseBackendDateTime(dateTimeValue['updatedAt']);
      } else {
        // 如果Map包含year, month, day等字段，构造LocalDateTime数组
        if (dateTimeValue.containsKey('year') && dateTimeValue.containsKey('month') && dateTimeValue.containsKey('day')) {
          final year = dateTimeValue['year'] as int;
          final month = dateTimeValue['month'] as int;
          final day = dateTimeValue['day'] as int;
          final hour = (dateTimeValue['hour'] as int?) ?? 0;
          final minute = (dateTimeValue['minute'] as int?) ?? 0;
          final second = (dateTimeValue['second'] as int?) ?? 0;
          final millisecond = (dateTimeValue['millisecond'] as int?) ?? 0;
          final microsecond = (dateTimeValue['microsecond'] as int?) ?? 0;
          
          return DateTime(year, month, day, hour, minute, second, millisecond, microsecond);
        }
      }
      AppLogger.w('DateTimeParser', '无法识别的Map时间格式: $dateTimeValue');
      return DateTime.now();
    } catch (e) {
      AppLogger.e('DateTimeParser', '解析Map格式时间失败, 值: $dateTimeValue', e);
      return DateTime.now();
    }
  } else if (dateTimeValue is List) {
    // 如果是Java LocalDateTime数组格式 [year, month, day, hour, minute, second, nanoOfSecond]
    try {
      // 确保列表元素足够，并进行安全转换
      final year = dateTimeValue.isNotEmpty ? (dateTimeValue[0] as num).toInt() : DateTime.now().year;
      final month = dateTimeValue.length > 1 ? (dateTimeValue[1] as num).toInt() : 1;
      final day = dateTimeValue.length > 2 ? (dateTimeValue[2] as num).toInt() : 1;
      final hour = dateTimeValue.length > 3 ? (dateTimeValue[3] as num).toInt() : 0;
      final minute = dateTimeValue.length > 4 ? (dateTimeValue[4] as num).toInt() : 0;
      final second = dateTimeValue.length > 5 ? (dateTimeValue[5] as num).toInt() : 0;
      // 可选：处理纳秒，转换为毫秒和微秒
      final nanoOfSecond = dateTimeValue.length > 6 ? (dateTimeValue[6] as num).toInt() : 0;
      final millisecond = nanoOfSecond ~/ 1000000;
      final microsecond = (nanoOfSecond % 1000000) ~/ 1000;

      return DateTime(
        year,
        month,
        day,
        hour,
        minute,
        second,
        millisecond,
        microsecond,
      );
    } catch (e) {
      AppLogger.e('DateTimeParser', '解析LocalDateTime数组失败, 值: $dateTimeValue', e);
      return DateTime.now(); // 解析失败时返回当前时间
    }
  } else if (dateTimeValue is double) {
    // 如果是Instant格式的时间戳（秒为单位）
    try {
      // 将秒转换为毫秒
      final milliseconds = (dateTimeValue * 1000).round();
      return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: false); // 假设后端时间戳是本地时间，如果确定是UTC，改为true
    } catch (e) {
      AppLogger.e('DateTimeParser', '解析Instant时间戳(double)失败, 值: $dateTimeValue', e);
      return DateTime.now();
    }
  } else if (dateTimeValue is int) {
    // 假设是毫秒时间戳
    try {
      // 检查时间戳范围，区分秒和毫秒 (一个简单的启发式方法)
      if (dateTimeValue > 3000000000) { // 大约到 2065 年的毫秒数
         return DateTime.fromMillisecondsSinceEpoch(dateTimeValue, isUtc: false); // 假设是毫秒
      } else {
         return DateTime.fromMillisecondsSinceEpoch(dateTimeValue * 1000, isUtc: false); // 假设是秒
      }
    } catch (e) {
      AppLogger.e('DateTimeParser', '解析时间戳(int)失败, 值: $dateTimeValue', e);
      return DateTime.now();
    }
  } else {
    // 其他未知情况返回当前时间
    AppLogger.w('DateTimeParser', '未知的日期时间格式: $dateTimeValue (${dateTimeValue.runtimeType})');
    return DateTime.now();
  }
}

/// 安全解析时间字段，专门用于处理可能为null的时间值
DateTime? parseBackendDateTimeSafely(dynamic dateTimeValue) {
  if (dateTimeValue == null) {
    return null;
  }
  try {
    return parseBackendDateTime(dateTimeValue);
  } catch (e) {
    AppLogger.e('DateTimeParser', '安全解析时间失败, 值: $dateTimeValue', e);
    return null;
  }
}

/// 解析策略响应中的时间字段
/// 专门处理策略管理相关API响应中的时间字段
Map<String, dynamic> parseStrategyResponseTimestamps(Map<String, dynamic> response) {
  final parsed = Map<String, dynamic>.from(response);
  
  // 常见的时间字段名称列表
  const timeFields = [
    'createdAt', 'updatedAt', 'publishedAt', 'reviewedAt', 
    'submittedAt', 'approvedAt', 'rejectedAt', 'lastModifiedAt',
    'timestamp', 'time', 'date'
  ];
  
  for (final field in timeFields) {
    if (parsed.containsKey(field) && parsed[field] != null) {
      try {
        parsed[field] = parseBackendDateTime(parsed[field]);
      } catch (e) {
        AppLogger.w('DateTimeParser', '解析响应中的时间字段 $field 失败: ${parsed[field]}');
        // 保持原值，避免数据丢失
      }
    }
  }
  
  return parsed;
}

/// 批量解析响应列表中的时间字段
List<Map<String, dynamic>> parseResponseListTimestamps(List<dynamic> responseList) {
  return responseList.map((item) {
    if (item is Map<String, dynamic>) {
      return parseStrategyResponseTimestamps(item);
    }
    return item as Map<String, dynamic>;
  }).toList();
}