package com.ainovel.server.service.billing;

import java.util.HashMap;
import java.util.Map;

import lombok.Builder;
import lombok.Getter;

@Builder
@Getter
public class PublicModelBillingContext {
    private final boolean usedPublicModel;
    private final boolean requiresPostStreamDeduction;
    private final String streamFeatureType;
    private final String publicModelConfigId;
    private final String provider;
    private final String modelId;
    private final String correlationId;
    private final String idempotencyKey;

    public Map<String, Object> toProviderSpecific() {
        Map<String, Object> m = new HashMap<>();
        m.put(BillingKeys.USED_PUBLIC_MODEL, usedPublicModel);
        m.put(BillingKeys.REQUIRES_POST_STREAM_DEDUCTION, requiresPostStreamDeduction);
        if (streamFeatureType != null) m.put(BillingKeys.STREAM_FEATURE_TYPE, streamFeatureType);
        if (publicModelConfigId != null) m.put(BillingKeys.PUBLIC_MODEL_CONFIG_ID, publicModelConfigId);
        if (provider != null) m.put(BillingKeys.PROVIDER, provider);
        if (modelId != null) m.put(BillingKeys.MODEL_ID, modelId);
        if (correlationId != null) m.put(BillingKeys.CORRELATION_ID, correlationId);
        if (idempotencyKey != null) m.put(BillingKeys.REQUEST_IDEMPOTENCY_KEY, idempotencyKey);
        return m;
    }
}


