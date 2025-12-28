package com.ainovel.server.common.exception;

/**
 * 积分不足异常
 * 当用户积分余额不足以完成AI请求时抛出
 */
public class InsufficientCreditsException extends RuntimeException {

    private final long requiredCredits;
    private final long currentCredits;

    public InsufficientCreditsException(long requiredCredits) {
        super(String.format("积分余额不足，需要 %d 积分", requiredCredits));
        this.requiredCredits = requiredCredits;
        this.currentCredits = 0; // 未知当前积分
    }

    public InsufficientCreditsException(long requiredCredits, long currentCredits) {
        super(String.format("积分余额不足，需要 %d 积分，当前余额 %d 积分", requiredCredits, currentCredits));
        this.requiredCredits = requiredCredits;
        this.currentCredits = currentCredits;
    }

    public InsufficientCreditsException(String message, long requiredCredits) {
        super(message);
        this.requiredCredits = requiredCredits;
        this.currentCredits = 0;
    }

    public long getRequiredCredits() {
        return requiredCredits;
    }

    public long getCurrentCredits() {
        return currentCredits;
    }
} 