package com.ainovel.server.web.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 用户积分响应DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserCreditResponseDto {
    
    /**
     * 用户ID
     */
    private String userId;
    
    /**
     * 积分余额
     */
    private Long credits;
    
    /**
     * 积分与美元汇率信息（可选，用于前端计算等值显示）
     */
    private Double creditToUsdRate;
} 