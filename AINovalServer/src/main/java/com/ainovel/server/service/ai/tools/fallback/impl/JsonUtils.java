package com.ainovel.server.service.ai.tools.fallback.impl;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.json.JsonReadFeature;

import java.util.Map;
import java.util.List;

/**
 * 轻量 JSON 工具，避免在业务类中散落解析逻辑。
 */
public final class JsonUtils {

    private static final ObjectMapper mapper = new ObjectMapper()
            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
            .configure(JsonParser.Feature.ALLOW_COMMENTS, true)
            .configure(JsonParser.Feature.ALLOW_UNQUOTED_FIELD_NAMES, true)
            .configure(JsonParser.Feature.ALLOW_SINGLE_QUOTES, true)
            .enable(JsonReadFeature.ALLOW_TRAILING_COMMA.mappedFeature());

    private JsonUtils() {}

    public static Map<String, Object> safeParseObject(String json) {
        try {
            if (json == null || json.isBlank()) return null;
            return mapper.readValue(json, new TypeReference<Map<String, Object>>(){});
        } catch (Exception ignore) {
            return null;
        }
    }

    public static List<Object> safeParseList(String json) {
        try {
            if (json == null || json.isBlank()) return null;
            return mapper.readValue(json, new TypeReference<List<Object>>(){});
        } catch (Exception ignore) {
            return null;
        }
    }
}


