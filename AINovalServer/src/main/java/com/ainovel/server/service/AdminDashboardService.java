package com.ainovel.server.service;

import com.ainovel.server.controller.AdminDashboardController.DashboardStats;
import reactor.core.publisher.Mono;

/**
 * 管理员仪表板服务接口
 */
public interface AdminDashboardService {
    
    /**
     * 获取仪表板统计数据
     * @return 仪表板统计数据
     */
    Mono<DashboardStats> getDashboardStats();
}