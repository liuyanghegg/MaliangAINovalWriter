package com.ainovel.server.service.ai.tools.fallback.impl;

import com.ainovel.server.service.ai.tools.fallback.ToolFallbackParser;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import java.util.*;

/**
 * text_to_settings 兜底 JSON 解析器
 * 支持从带 Markdown 代码块或纯文本中提取 JSON，并转换为参数结构：
 * { nodes: [...], complete?: boolean }
 */
@Slf4j
@RequiredArgsConstructor
public class TextToSettingsJsonFallbackParser implements ToolFallbackParser {

    @Override
    public String getToolName() {
        return "text_to_settings";
    }

    @Override
    public boolean canParse(String rawText) {
        if (rawText == null) return false;
        String t = rawText.trim();
        // 粗略判断：包含 json 代码块或花括号结构
        return t.contains("```json") || t.contains("\"nodes\"") || (t.contains("{") && t.contains("}"));
    }

    @Override
    public Map<String, Object> parseToToolParams(String rawText) throws Exception {
        if (rawText == null || rawText.isBlank()) return null;
        String json = extractJson(rawText);
        if (json == null || json.isBlank()) return null;

        Map<String, Object> obj = JsonUtils.safeParseObject(json);
        if (obj == null) {
            // 兼容顶层即为数组的情形：
            // [ { nodes: [...] } ] 或 [ { ...node... }, { ...node... } ]
            List<Object> arr = JsonUtils.safeParseList(json);
            if (arr == null || arr.isEmpty()) return null;

            // 情形A：数组元素是对象且包含 nodes 字段
            for (Object element : arr) {
                if (element instanceof Map<?, ?>) {
                    Map<?, ?> rawMap = (Map<?, ?>) element;
                    Object nodesObj0 = rawMap.get("nodes");
                    if (nodesObj0 instanceof List<?>) {
                        List<Map<String, Object>> nodes = normalizeNodeList((List<?>) nodesObj0);
                        Map<String, Object> params = new HashMap<>();
                        params.put("nodes", nodes != null ? nodes : new ArrayList<>());
                        Object completeObj0 = rawMap.get("complete");
                        if (completeObj0 instanceof Boolean) params.put("complete", (Boolean) completeObj0);
                        return params;
                    }
                }
            }

            // 情形B：数组元素直接就是节点对象
            boolean allObjects = true;
            for (Object element : arr) {
                if (!(element instanceof Map<?, ?>)) { allObjects = false; break; }
            }
            if (allObjects) {
                List<Map<String, Object>> nodes = normalizeNodeList(arr);
                Map<String, Object> params = new HashMap<>();
                params.put("nodes", nodes != null ? nodes : new ArrayList<>());
                return params;
            }
            return null;
        }

        // 兼容 nodes / settings
        List<Map<String, Object>> nodes = null;
        Object nodesObj = obj.get("nodes");
        if (nodesObj instanceof List<?>) {
            nodes = normalizeNodeList((List<?>) nodesObj);
        }
        if ((nodes == null || nodes.isEmpty())) {
            Object settingsObj = obj.get("settings");
            if (settingsObj instanceof List<?>) {
                nodes = normalizeNodeList((List<?>) settingsObj);
            }
        }

        Boolean complete = null;
        Object completeObj = obj.get("complete");
        if (completeObj instanceof Boolean) complete = (Boolean) completeObj;

        if (nodes == null) nodes = new ArrayList<>();
        Map<String, Object> params = new HashMap<>();
        params.put("nodes", nodes);
        if (complete != null) params.put("complete", complete);
        return params;
    }

    private String extractJson(String text) {
        String t = text.trim();
        // 优先提取 ```json ... ```
        int codeIdx = t.indexOf("```json");
        if (codeIdx >= 0) {
            int start = codeIdx + "```json".length();
            int endFence = t.indexOf("```", start);
            if (endFence > start) {
                return t.substring(start, endFence).trim();
            }
        }
        // 其次提取首个 {..} 块（简单括号配对）
        int open = t.indexOf('{');
        if (open >= 0) {
            int depth = 0;
            for (int i = open; i < t.length(); i++) {
                char c = t.charAt(i);
                if (c == '{') depth++;
                else if (c == '}') {
                    depth--;
                    if (depth == 0) {
                        return t.substring(open, i + 1);
                    }
                }
            }
        }
        return null;
    }

    private List<Map<String, Object>> normalizeNodeList(List<?> rawList) {
        List<Map<String, Object>> nodes = new ArrayList<>();
        for (Object item : rawList) {
            if (item instanceof Map<?, ?>) {
                Map<?, ?> m = (Map<?, ?>) item;
                Map<String, Object> node = new HashMap<>();
                Object id = m.get("id");
                Object name = m.get("name");
                Object type = m.get("type");
                Object description = m.get("description");
                Object parentId = m.get("parentId");
                Object tempId = m.get("tempId");
                Object attributes = m.get("attributes");
                if (id != null) node.put("id", String.valueOf(id));
                if (name != null) node.put("name", String.valueOf(name));
                if (type != null) node.put("type", String.valueOf(type));
                if (description != null) node.put("description", String.valueOf(description));
                node.put("parentId", parentId != null ? String.valueOf(parentId) : null);
                if (tempId != null) node.put("tempId", String.valueOf(tempId));
                if (attributes instanceof Map<?, ?>) node.put("attributes", attributes);
                nodes.add(node);
            }
        }
        return nodes;
    }
}


