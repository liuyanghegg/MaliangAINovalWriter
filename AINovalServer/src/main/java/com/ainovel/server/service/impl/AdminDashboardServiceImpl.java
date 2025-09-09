package com.ainovel.server.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.ainovel.server.controller.AdminDashboardController.*;
import com.ainovel.server.repository.UserRepository;
import com.ainovel.server.repository.NovelRepository;
import com.ainovel.server.repository.AIChatMessageRepository;
import com.ainovel.server.service.AdminDashboardService;
import com.ainovel.server.domain.model.User;
import com.ainovel.server.domain.model.Novel;
import com.ainovel.server.domain.model.AIChatMessage;

import reactor.core.publisher.Mono;
import reactor.core.publisher.Flux;

import java.time.LocalDateTime;
import java.time.LocalDate;
import java.util.List;
import java.util.ArrayList;
import java.util.stream.Collectors;

/**
 * 管理员仪表板服务实现
 */
@Service
public class AdminDashboardServiceImpl implements AdminDashboardService {
    
    private static final Logger logger = LoggerFactory.getLogger(AdminDashboardServiceImpl.class);
    
    private final UserRepository userRepository;
    private final NovelRepository novelRepository;
    private final AIChatMessageRepository aiChatMessageRepository;
    
    @Autowired
    public AdminDashboardServiceImpl(UserRepository userRepository, 
                                   NovelRepository novelRepository,
                                   AIChatMessageRepository aiChatMessageRepository) {
        this.userRepository = userRepository;
        this.novelRepository = novelRepository;
        this.aiChatMessageRepository = aiChatMessageRepository;
    }
    
    @Override
    public Mono<DashboardStats> getDashboardStats() {
        logger.debug("开始获取管理员仪表板统计数据");
        
        // 并行获取各种统计数据
        Mono<Long> totalUsersMono = userRepository.count();
        Mono<Long> activeUsersMono = getActiveUsersCount();
        Mono<Long> totalNovelsMono = novelRepository.count();
        Mono<Long> aiRequestsTodayMono = getAiRequestsToday();
        Mono<Double> creditsConsumedMono = getTotalCreditsConsumed();
        Mono<List<ChartData>> userGrowthDataMono = getUserGrowthData();
        Mono<List<ChartData>> requestsDataMono = getRequestsData();
        Mono<List<ActivityItem>> recentActivitiesMono = getRecentActivities();
        
        return Mono.zip(totalUsersMono, activeUsersMono, totalNovelsMono, 
                       aiRequestsTodayMono, creditsConsumedMono, userGrowthDataMono,
                       requestsDataMono, recentActivitiesMono)
                .map(tuple -> {
                    DashboardStats stats = new DashboardStats(
                        tuple.getT1().intValue(),  // totalUsers
                        tuple.getT2().intValue(),  // activeUsers
                        tuple.getT3().intValue(),  // totalNovels
                        tuple.getT4().intValue(),  // aiRequestsToday
                        tuple.getT5(),             // creditsConsumed
                        tuple.getT6(),             // userGrowthData
                        tuple.getT7(),             // requestsData
                        tuple.getT8()              // recentActivities
                    );
                    
                    logger.debug("成功获取管理员仪表板统计数据: totalUsers={}, activeUsers={}, totalNovels={}",
                            stats.getTotalUsers(), stats.getActiveUsers(), stats.getTotalNovels());
                    
                    return stats;
                })
                .doOnError(e -> logger.error("获取管理员仪表板统计数据失败", e));
    }
    
    /**
     * 创建安全的ActivityItem，确保所有字段都非空
     */
    private ActivityItem createSafeActivityItem(String id, String userId, String userName, 
                                              String action, String description, 
                                              LocalDateTime timestamp, String metadata) {
        return new ActivityItem(
            id != null ? id : "unknown",
            userId != null ? userId : "unknown", 
            userName != null ? userName : "未知用户",
            action != null ? action : "未知操作",
            description != null ? description : "无描述",
            timestamp != null ? timestamp : LocalDateTime.now(),
            metadata != null ? metadata : "{}"
        );
    }
    
    private Mono<Long> getActiveUsersCount() {
        // 定义活跃用户为最近30天内登录的用户
        LocalDateTime thirtyDaysAgo = LocalDateTime.now().minusDays(30);
        return userRepository.countByAccountStatusAndLastLoginAtAfter(
            User.AccountStatus.ACTIVE, thirtyDaysAgo)
            .onErrorReturn(0L); // 如果查询失败，返回0
    }
    
    private Mono<Long> getAiRequestsToday() {
        LocalDate today = LocalDate.now();
        LocalDateTime startOfDay = today.atStartOfDay();
        LocalDateTime endOfDay = today.atTime(23, 59, 59);
        
        return aiChatMessageRepository.countByCreatedAtBetween(startOfDay, endOfDay)
            .onErrorReturn(0L); // 如果查询失败，返回0
    }
    
    private Mono<Double> getTotalCreditsConsumed() {
        return userRepository.findByTotalCreditsUsedGreaterThan(0L)
                .map(user -> user.getTotalCreditsUsed() != null ? user.getTotalCreditsUsed().doubleValue() : 0.0)
                .reduce(0.0, Double::sum)
                .onErrorReturn(0.0); // 如果查询失败，返回0.0
    }
    
    private Mono<List<ChartData>> getUserGrowthData() {
        LocalDateTime now = LocalDateTime.now();
        
        // 并行查询最近7天的用户增长数据
        List<Mono<ChartData>> dailyDataMonos = new ArrayList<>();
        
        for (int i = 6; i >= 0; i--) {
            final LocalDateTime date = now.minusDays(i);
            final LocalDateTime startOfDay = date.toLocalDate().atStartOfDay();
            final LocalDateTime endOfDay = date.toLocalDate().atTime(23, 59, 59);
            
            Mono<ChartData> dailyDataMono = userRepository
                    .countByCreatedAtBetween(startOfDay, endOfDay)
                    .map(count -> new ChartData(
                        date.toLocalDate().toString(),
                        count.doubleValue(),
                        date
                    ));
            
            dailyDataMonos.add(dailyDataMono);
        }
        
        return Flux.fromIterable(dailyDataMonos)
                .flatMap(mono -> mono)
                .collectList()
                .onErrorReturn(new ArrayList<>()); // 如果查询失败，返回空列表
    }
    
    private Mono<List<ChartData>> getRequestsData() {
        LocalDateTime now = LocalDateTime.now();
        
        // 并行查询最近24小时的请求数据
        List<Mono<ChartData>> hourlyDataMonos = new ArrayList<>();
        
        for (int i = 23; i >= 0; i--) {
            final LocalDateTime hour = now.minusHours(i);
            final LocalDateTime startOfHour = hour.withMinute(0).withSecond(0).withNano(0);
            final LocalDateTime endOfHour = hour.withMinute(59).withSecond(59).withNano(999999999);
            
            Mono<ChartData> hourlyDataMono = aiChatMessageRepository
                    .countByCreatedAtBetween(startOfHour, endOfHour)
                    .map(count -> new ChartData(
                        String.format("%02d:00", hour.getHour()),
                        count.doubleValue(),
                        hour
                    ));
            
            hourlyDataMonos.add(hourlyDataMono);
        }
        
        return Flux.fromIterable(hourlyDataMonos)
                .flatMap(mono -> mono)
                .collectList()
                .onErrorReturn(new ArrayList<>()); // 如果查询失败，返回空列表
    }
    
    private Mono<List<ActivityItem>> getRecentActivities() {
        LocalDateTime now = LocalDateTime.now();
        
        // 获取最近的用户注册活动
        Mono<List<ActivityItem>> recentUsersMono = userRepository
                .findTop10ByOrderByCreatedAtDesc()
                .take(5)
                .map(user -> createSafeActivityItem(
                    "user_" + (user.getId() != null ? user.getId() : "unknown"),
                    user.getId(),
                    user.getDisplayName() != null ? user.getDisplayName() : user.getUsername(),
                    "用户注册",
                    "新用户注册成功",
                    user.getCreatedAt(),
                    String.format("{\"email\":\"%s\"}", 
                        user.getEmail() != null ? user.getEmail() : "unknown@example.com")
                ))
                .collectList();
        
        // 获取最近的小说创建活动
        Mono<List<ActivityItem>> recentNovelsMono = novelRepository
                .findTop10ByOrderByCreatedAtDesc()
                .take(5)
                .map(novel -> createSafeActivityItem(
                    "novel_" + (novel.getId() != null ? novel.getId() : "unknown"),
                    novel.getAuthor() != null ? novel.getAuthor().getId() : null,
                    novel.getAuthor() != null ? novel.getAuthor().getUsername() : null,
                    "小说创建",
                    String.format("创建了新小说《%s》", 
                        novel.getTitle() != null ? novel.getTitle() : "无标题"),
                    novel.getCreatedAt(),
                    String.format("{\"novelId\":\"%s\",\"title\":\"%s\"}", 
                        novel.getId() != null ? novel.getId() : "unknown",
                        novel.getTitle() != null ? novel.getTitle() : "无标题")
                ))
                .collectList();
        
        // 获取最近的AI聊天活动
        Mono<List<ActivityItem>> recentMessagesMono = aiChatMessageRepository
                .findTop20ByOrderByCreatedAtDesc()
                .take(5)
                .filter(message -> "user".equals(message.getRole())) // 只显示用户消息
                .map(message -> createSafeActivityItem(
                    "message_" + (message.getId() != null ? message.getId() : "unknown"),
                    message.getUserId(),
                    "用户", // 这里可以后续优化关联用户信息
                    "AI对话",
                    "使用AI进行对话交流",
                    message.getCreatedAt(),
                    String.format("{\"model\":\"%s\",\"sessionId\":\"%s\"}", 
                        message.getModelName() != null ? message.getModelName() : "unknown",
                        message.getSessionId() != null ? message.getSessionId() : "unknown")
                ))
                .collectList();
        
        // 合并所有活动并按时间排序
        return Mono.zip(recentUsersMono, recentNovelsMono, recentMessagesMono)
                .map(tuple -> {
                    List<ActivityItem> allActivities = new ArrayList<>();
                    allActivities.addAll(tuple.getT1());
                    allActivities.addAll(tuple.getT2());
                    allActivities.addAll(tuple.getT3());
                    
                    return allActivities.stream()
                            .sorted((a, b) -> b.getTimestamp().compareTo(a.getTimestamp()))
                            .limit(10)
                            .collect(Collectors.toList());
                })
                .onErrorReturn(new ArrayList<>()); // 如果查询失败，返回空列表而不是错误
    }
}