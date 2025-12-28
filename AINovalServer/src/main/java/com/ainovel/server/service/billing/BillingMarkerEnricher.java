package com.ainovel.server.service.billing;

import java.util.HashMap;
import java.util.Map;

import com.ainovel.server.domain.model.AIRequest;

public final class BillingMarkerEnricher {

    private BillingMarkerEnricher() {}

    @SuppressWarnings("unchecked")
    public static void applyTo(AIRequest req, PublicModelBillingContext ctx) {
        if (req.getParameters() == null) {
            req.setParameters(new HashMap<>());
        }
        Map<String, Object> params = req.getParameters();
        Object psRaw = params.get("providerSpecific");
        Map<String, Object> providerSpecific;
        if (psRaw instanceof Map<?, ?> m) {
            providerSpecific = (Map<String, Object>) m;
        } else {
            providerSpecific = new HashMap<>();
            params.put("providerSpecific", providerSpecific);
        }
        providerSpecific.putAll(ctx.toProviderSpecific());

        if (req.getMetadata() != null) {
            req.getMetadata().putAll(ctx.toProviderSpecific());
        }
    }
}


