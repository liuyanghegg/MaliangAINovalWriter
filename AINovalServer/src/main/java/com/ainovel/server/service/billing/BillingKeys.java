package com.ainovel.server.service.billing;

/**
 * 计费相关的标准键名，统一providerSpecific与metadata中的键，避免魔法字符串。
 */
public final class BillingKeys {
    public static final String USED_PUBLIC_MODEL = "usedPublicModel";
    public static final String REQUIRES_POST_STREAM_DEDUCTION = "requiresPostStreamDeduction";
    public static final String STREAM_FEATURE_TYPE = "streamFeatureType";
    public static final String PUBLIC_MODEL_CONFIG_ID = "publicModelConfigId";
    public static final String PROVIDER = "provider";
    public static final String MODEL_ID = "modelId";
    public static final String CORRELATION_ID = "correlationId";
    public static final String REQUEST_IDEMPOTENCY_KEY = "idempotencyKey";
    public static final String REQUEST_TYPE = "requestType";

    private BillingKeys() {}
}


