package com.ainovel.server.service.ai.tools.fallback.impl;

import com.ainovel.server.service.ai.tools.fallback.ToolFallbackParser;
import lombok.extern.slf4j.Slf4j;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * create_compose_outlines 兜底 JSON 解析器
 * 支持从带 Markdown 代码块或纯文本中提取 JSON，并转换为参数结构：
 * { outlines: [ { index:number, title:string, summary:string }, ... ] }
 */
@Slf4j
public class CreateComposeOutlinesJsonFallbackParser implements ToolFallbackParser {

    @Override
    public String getToolName() {
        return "create_compose_outlines";
    }

    @Override
    public boolean canParse(String rawText) {
        if (rawText == null) return false;
        String t = rawText.trim();
        // 粗略判断：包含 json 代码块或包含 outlines 字段，或存在花括号/方括号结构
        return t.contains("```json") || t.contains("\"outlines\"") ||
                ((t.contains("{") && t.contains("}")) || (t.contains("[") && t.contains("]")));
    }

    @Override
    public Map<String, Object> parseToToolParams(String rawText) throws Exception {
        if (rawText == null || rawText.isBlank()) return null;
        String json = extractJson(rawText);
        if (json == null || json.isBlank()) return null;

        // 尝试对象解析
        Map<String, Object> obj = JsonUtils.safeParseObject(json);
        if (obj != null) {
            Object outlinesObj = obj.get("outlines");
            if (outlinesObj instanceof List<?>) {
                List<Map<String, Object>> outlines = normalizeOutlinesList((List<?>) outlinesObj);
                Map<String, Object> params = new HashMap<>();
                params.put("outlines", outlines);
                return params;
            }
            // 若对象本身看起来就是一个 outline 项，尝试兼容：{ index/title/summary }
            if (obj.containsKey("title") || obj.containsKey("summary")) {
                List<Map<String, Object>> outlines = new ArrayList<>();
                outlines.add(normalizeOutlineMap(obj));
                Map<String, Object> params = new HashMap<>();
                params.put("outlines", outlines);
                return params;
            }
        }

        // 顶层数组解析
        List<Object> arr = JsonUtils.safeParseList(json);
        if (arr != null && !arr.isEmpty()) {
            // 允许两种形式：
            // A) [ { outlines: [...] } ]
            // B) [ { index/title/summary }, { ... } ]
            for (Object element : arr) {
                if (element instanceof Map<?, ?>) {
                    Map<?, ?> rawMap = (Map<?, ?>) element;
                    Object outlinesObj = rawMap.get("outlines");
                    if (outlinesObj instanceof List<?>) {
                        List<Map<String, Object>> outlines = normalizeOutlinesList((List<?>) outlinesObj);
                        Map<String, Object> params = new HashMap<>();
                        params.put("outlines", outlines);
                        return params;
                    }
                }
            }

            boolean allObjects = true;
            for (Object element : arr) {
                if (!(element instanceof Map<?, ?>)) { allObjects = false; break; }
            }
            if (allObjects) {
                List<Map<String, Object>> outlines = normalizeOutlinesList(arr);
                Map<String, Object> params = new HashMap<>();
                params.put("outlines", outlines);
                return params;
            }
        }

        return null;
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
        // 其次提取首个 {..} 或 [..] 块（简单括号配对）
        int openObj = t.indexOf('{');
        int openArr = t.indexOf('[');
        int open = -1;
        boolean isArray = false;
        if (openObj >= 0 && (openArr < 0 || openObj < openArr)) {
            open = openObj;
        } else if (openArr >= 0) {
            open = openArr;
            isArray = true;
        }
        if (open >= 0) {
            int depth = 0;
            for (int i = open; i < t.length(); i++) {
                char c = t.charAt(i);
                if (c == (isArray ? '[' : '{')) depth++;
                else if (c == (isArray ? ']' : '}')) {
                    depth--;
                    if (depth == 0) {
                        return t.substring(open, i + 1);
                    }
                }
            }
        }
        return null;
    }

    private List<Map<String, Object>> normalizeOutlinesList(List<?> rawList) {
        List<Map<String, Object>> outlines = new ArrayList<>();
        int autoIndex = 1;
        for (Object item : rawList) {
            if (item instanceof Map<?, ?>) {
                Map<?, ?> m = (Map<?, ?>) item;
                Map<String, Object> outline = normalizeOutlineMap(m);
                if (!outline.isEmpty()) {
                    // 自动补 index
                    if (!outline.containsKey("index") || !(outline.get("index") instanceof Number)) {
                        outline.put("index", autoIndex);
                    }
                    autoIndex = Math.max(autoIndex, ((Number) outline.get("index")).intValue() + 1);
                    outlines.add(outline);
                }
            }
        }
        return outlines;
    }

    private Map<String, Object> normalizeOutlineMap(Map<?, ?> m) {
        Map<String, Object> outline = new HashMap<>();
        // index 兼容 index/idx/order
        Object idxObj = firstNonNull(m.get("index"), m.get("idx"), m.get("order"));
        Integer idx = null;
        if (idxObj instanceof Number) {
            idx = ((Number) idxObj).intValue();
        } else if (idxObj instanceof String s) {
            try { idx = Integer.parseInt(s.trim()); } catch (Exception ignore) {}
        }
        if (idx != null) outline.put("index", idx);

        // title 兼容 title/name
        Object titleObj = firstNonNull(m.get("title"), m.get("name"));
        String title = titleObj != null ? String.valueOf(titleObj) : null;
        if (title != null) outline.put("title", title);

        // summary 兼容 summary/desc/description
        Object summaryObj = firstNonNull(m.get("summary"), m.get("desc"), m.get("description"));
        String summary = summaryObj != null ? String.valueOf(summaryObj) : null;
        if (summary != null) outline.put("summary", summary);

        return outline;
    }

    private Object firstNonNull(Object... values) {
        for (Object v : values) {
            if (v != null) return v;
        }
        return null;
    }
}


