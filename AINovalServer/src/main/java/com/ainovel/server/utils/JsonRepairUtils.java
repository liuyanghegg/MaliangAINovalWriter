package com.ainovel.server.utils;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * JSON修复工具类
 * 专门用于修复AI生成的不完整或格式错误的JSON
 */
@Slf4j
public class JsonRepairUtils {

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();
    
    // 匹配JSON对象的正则表达式（简化版）
    private static final Pattern SIMPLE_OBJECT_PATTERN = Pattern.compile("\\{[^{}]*\\}");
    
    // 匹配复杂嵌套JSON对象的正则表达式
    private static final Pattern NESTED_OBJECT_PATTERN = Pattern.compile("\\{(?:[^{}]*(?:\\{[^{}]*\\}[^{}]*)*)*\\}");
    
    // 匹配不完整对象的正则表达式
    private static final Pattern INCOMPLETE_OBJECT_PATTERN = Pattern.compile(",\\s*\\{[^}]*$");
    
    // 匹配JSON字符串中的引号
    private static final Pattern QUOTE_PATTERN = Pattern.compile("\"(?:[^\"\\\\]|\\\\.)*\"");

    /**
     * 尝试修复不完整的JSON字符串
     *
     * @param jsonContent 原始JSON内容
     * @return 修复后的JSON字符串，如果无法修复则返回null
     */
    public static String repairJson(String jsonContent) {
        if (jsonContent == null || jsonContent.trim().isEmpty()) {
            return null;
        }

        String trimmed = jsonContent.trim();
        log.debug("开始修复JSON，原始长度: {}", trimmed.length());

        // 1. 处理数组格式
        if (trimmed.startsWith("[") || trimmed.contains("[")) {
            String repairedArray = repairJsonArray(trimmed);
            if (isValidJson(repairedArray)) {
                log.info("JSON数组修复成功");
                return repairedArray;
            }
        }

        // 2. 处理单个对象格式
        if (trimmed.startsWith("{") || trimmed.contains("{")) {
            String repairedObject = repairJsonObject(trimmed);
            if (isValidJson(repairedObject)) {
                // 包装成数组
                String wrappedArray = "[" + repairedObject + "]";
                if (isValidJson(wrappedArray)) {
                    log.info("JSON对象修复成功并包装为数组");
                    return wrappedArray;
                }
            }
        }

        // 3. 尝试提取所有有效的JSON对象
        List<String> validObjects = extractValidJsonObjects(trimmed);
        if (!validObjects.isEmpty()) {
            String combinedArray = "[" + String.join(",", validObjects) + "]";
            if (isValidJson(combinedArray)) {
                log.info("从原始内容中提取到 {} 个有效对象", validObjects.size());
                return combinedArray;
            }
        }

        log.warn("JSON修复失败，无法生成有效的JSON格式");
        return null;
    }

    /**
     * 修复JSON数组
     */
    private static String repairJsonArray(String jsonContent) {
        String content = jsonContent.trim();

        // 找到数组开始位置
        int arrayStart = content.indexOf('[');
        if (arrayStart < 0) {
            return null;
        }

        content = content.substring(arrayStart);

        // 如果数组已经完整闭合，直接返回
        if (content.endsWith("]") && isBalancedBrackets(content)) {
            return content;
        }

        // 找到最后一个完整的对象
        int lastCompletePos = findLastCompleteObject(content);
        if (lastCompletePos > 0) {
            content = content.substring(0, lastCompletePos) + "]";
        } else {
            // 移除最后一个不完整的对象
            content = removeIncompleteTrailingObject(content);
            if (!content.endsWith("]")) {
                content += "]";
            }
        }

        // 修复对象内部的问题
        content = fixIncompleteObjectsInArray(content);

        return content;
    }

    /**
     * 修复JSON对象
     */
    private static String repairJsonObject(String jsonContent) {
        String content = jsonContent.trim();

        // 找到对象开始位置
        int objStart = content.indexOf('{');
        if (objStart < 0) {
            return null;
        }

        content = content.substring(objStart);

        // 如果对象已经完整闭合，直接返回
        if (content.endsWith("}") && isBalancedBraces(content)) {
            return content;
        }

        // 尝试修复不完整的对象
        if (!content.endsWith("}")) {
            // 移除不完整的字段
            content = removeIncompleteFields(content);
            if (!content.endsWith("}")) {
                content += "}";
            }
        }

        return content;
    }

    /**
     * 找到最后一个完整的JSON对象的结束位置
     */
    private static int findLastCompleteObject(String json) {
        int braceLevel = 0;
        int lastCompletePos = -1;
        boolean inString = false;
        boolean inArray = false;

        for (int i = 0; i < json.length(); i++) {
            char c = json.charAt(i);

            if (c == '"' && (i == 0 || json.charAt(i - 1) != '\\')) {
                inString = !inString;
            }

            if (!inString) {
                switch (c) {
                    case '[':
                        if (!inArray) {
                            inArray = true;
                        }
                        break;
                    case '{':
                        braceLevel++;
                        break;
                    case '}':
                        braceLevel--;
                        if (braceLevel == 0 && inArray) {
                            // 找到一个完整的对象
                            lastCompletePos = i + 1;
                        }
                        break;
                }
            }
        }

        return lastCompletePos;
    }

    /**
     * 移除数组末尾不完整的对象
     */
    private static String removeIncompleteTrailingObject(String json) {
        Matcher matcher = INCOMPLETE_OBJECT_PATTERN.matcher(json);
        if (matcher.find()) {
            return json.substring(0, matcher.start());
        }
        return json;
    }

    /**
     * 修复数组中不完整的对象
     */
    private static String fixIncompleteObjectsInArray(String json) {
        // 这里可以添加更复杂的修复逻辑
        // 比如补全缺失的引号、括号等

        // 简单的修复：移除最后一个逗号后的内容如果它不是完整的对象
        String result = json;

        // 检查最后一个逗号后是否有不完整的内容
        int lastComma = result.lastIndexOf(',');
        int lastBrace = result.lastIndexOf(']');

        if (lastComma > 0 && lastBrace > lastComma) {
            String afterComma = result.substring(lastComma + 1, lastBrace).trim();
            if (!afterComma.isEmpty() && !isValidJsonObject(afterComma)) {
                // 移除最后一个逗号后的不完整内容
                result = result.substring(0, lastComma) + "]";
            }
        }

        return result;
    }

    /**
     * 移除对象中不完整的字段
     */
    private static String removeIncompleteFields(String json) {
        // 找到最后一个完整的字段
        int lastComma = json.lastIndexOf(',');
        if (lastComma > 0) {
            String beforeComma = json.substring(0, lastComma);
            if (isValidPartialObject(beforeComma)) {
                return beforeComma + "}";
            }
        }

        // 如果找不到完整的字段，尝试找到第一个完整的字段
        int firstComma = json.indexOf(',');
        if (firstComma > 0) {
            String beforeComma = json.substring(0, firstComma);
            if (isValidPartialObject(beforeComma)) {
                return beforeComma + "}";
            }
        }

        return json;
    }

    /**
     * 提取所有有效的JSON对象
     */
    private static List<String> extractValidJsonObjects(String content) {
        List<String> validObjects = new ArrayList<>();

        // 首先尝试简单匹配
        Matcher simpleMatcher = SIMPLE_OBJECT_PATTERN.matcher(content);
        while (simpleMatcher.find()) {
            String obj = simpleMatcher.group();
            if (isValidJsonObject(obj)) {
                validObjects.add(obj);
            }
        }

        // 如果简单匹配没有结果，尝试复杂匹配
        if (validObjects.isEmpty()) {
            Matcher nestedMatcher = NESTED_OBJECT_PATTERN.matcher(content);
            while (nestedMatcher.find()) {
                String obj = nestedMatcher.group();
                if (isValidJsonObject(obj)) {
                    validObjects.add(obj);
                }
            }
        }

        return validObjects;
    }

    /**
     * 检查括号是否平衡
     */
    private static boolean isBalancedBrackets(String str) {
        int count = 0;
        boolean inString = false;

        for (int i = 0; i < str.length(); i++) {
            char c = str.charAt(i);

            if (c == '"' && (i == 0 || str.charAt(i - 1) != '\\')) {
                inString = !inString;
            }

            if (!inString) {
                if (c == '[') {
                    count++;
                } else if (c == ']') {
                    count--;
                }
            }
        }

        return count == 0;
    }

    /**
     * 检查大括号是否平衡
     */
    private static boolean isBalancedBraces(String str) {
        int count = 0;
        boolean inString = false;

        for (int i = 0; i < str.length(); i++) {
            char c = str.charAt(i);

            if (c == '"' && (i == 0 || str.charAt(i - 1) != '\\')) {
                inString = !inString;
            }

            if (!inString) {
                if (c == '{') {
                    count++;
                } else if (c == '}') {
                    count--;
                }
            }
        }

        return count == 0;
    }

    /**
     * 检查字符串是否是有效的JSON
     */
    private static boolean isValidJson(String json) {
        if (json == null || json.trim().isEmpty()) {
            return false;
        }

        try {
            OBJECT_MAPPER.readTree(json);
            return true;
        } catch (JsonProcessingException e) {
            return false;
        }
    }

    /**
     * 检查字符串是否是有效的JSON对象
     */
    private static boolean isValidJsonObject(String json) {
        if (json == null || json.trim().isEmpty()) {
            return false;
        }

        try {
            JsonNode node = OBJECT_MAPPER.readTree(json);
            return node.isObject();
        } catch (JsonProcessingException e) {
            return false;
        }
    }

    /**
     * 检查字符串是否是有效的部分JSON对象（可能缺少结尾括号）
     */
    private static boolean isValidPartialObject(String json) {
        if (json == null || json.trim().isEmpty()) {
            return false;
        }

        // 尝试添加结尾括号后解析
        String withBrace = json.trim();
        if (!withBrace.endsWith("}")) {
            withBrace += "}";
        }

        return isValidJsonObject(withBrace);
    }

    /**
     * 激进JSON修复 - 优先保留内容完整性
     */
    public static String aggressiveJsonRepair(String response) {
        if (response == null || response.trim().isEmpty()) {
            return null;
        }

        String content = response.trim();
        log.debug("开始激进修复，原始长度: {}", content.length());

        // 1. 寻找JSON数组的开始
        int arrayStart = content.indexOf('[');
        if (arrayStart >= 0) {
            String arrayContent = content.substring(arrayStart);
            String repairedArray = aggressiveRepairArray(arrayContent);
            if (repairedArray != null) {
                return repairedArray;
            }
        }

        // 2. 寻找JSON对象的开始
        int objStart = content.indexOf('{');
        if (objStart >= 0) {
            String objContent = content.substring(objStart);
            String repairedObj = aggressiveRepairObject(objContent);
            if (repairedObj != null) {
                return "[" + repairedObj + "]";
            }
        }

        // 3. 最后尝试从整个内容中提取所有可能的对象
        return extractAllPossibleObjects(content);
    }

    /**
     * 激进修复JSON数组
     */
    private static String aggressiveRepairArray(String arrayContent) {
        if (!arrayContent.startsWith("[")) {
            return null;
        }

        // 如果已经是完整的数组，直接返回
        if (arrayContent.endsWith("]") && isValidJson(arrayContent)) {
            return arrayContent;
        }

        // 激进策略：尽可能保留更多内容
        String workingContent = arrayContent;

        // 如果没有结尾，添加结尾
        if (!workingContent.endsWith("]")) {
            // 寻找最后一个可能的完整对象位置
            int lastObjectEnd = findLastObjectEnd(workingContent);
            if (lastObjectEnd > 0) {
                workingContent = workingContent.substring(0, lastObjectEnd) + "]";
            } else {
                // 简单添加结尾
                workingContent += "]";
            }
        }

        // 尝试修复常见问题
        workingContent = fixCommonJsonIssues(workingContent);

        // 验证修复结果
        if (isValidJson(workingContent)) {
            log.debug("激进数组修复成功，长度: {}", workingContent.length());
            return workingContent;
        }

        // 如果还是不行，尝试更激进的方法
        return fallbackRepairArray(arrayContent);
    }

    /**
     * 激进修复JSON对象
     */
    private static String aggressiveRepairObject(String objContent) {
        if (!objContent.startsWith("{")) {
            return null;
        }

        // 如果已经是完整的对象，直接返回
        if (objContent.endsWith("}") && isValidJsonObject(objContent)) {
            return objContent;
        }

        String workingContent = objContent;

        // 如果没有结尾，添加结尾
        if (!workingContent.endsWith("}")) {
            // 寻找最后一个完整字段的结束位置
            int lastFieldEnd = findLastFieldEnd(workingContent);
            if (lastFieldEnd > 0) {
                workingContent = workingContent.substring(0, lastFieldEnd) + "}";
            } else {
                workingContent += "}";
            }
        }

        // 修复常见问题
        workingContent = fixCommonJsonIssues(workingContent);

        if (isValidJsonObject(workingContent)) {
            log.debug("激进对象修复成功，长度: {}", workingContent.length());
            return workingContent;
        }

        return null;
    }

    /**
     * 寻找最后一个对象的结束位置
     */
    private static int findLastObjectEnd(String content) {
        int lastBracePos = -1;
        int braceLevel = 0;
        boolean inString = false;

        for (int i = 0; i < content.length(); i++) {
            char c = content.charAt(i);

            if (c == '"' && (i == 0 || content.charAt(i - 1) != '\\')) {
                inString = !inString;
            }

            if (!inString) {
                if (c == '{') {
                    braceLevel++;
                } else if (c == '}') {
                    braceLevel--;
                    if (braceLevel >= 0) {
                        lastBracePos = i + 1;
                    }
                }
            }
        }

        return lastBracePos;
    }

    /**
     * 寻找最后一个字段的结束位置
     */
    private static int findLastFieldEnd(String content) {
        // 寻找最后一个有效的字段结束位置
        int lastValidPos = -1;
        boolean inString = false;
        boolean inValue = false;

        for (int i = 0; i < content.length(); i++) {
            char c = content.charAt(i);

            if (c == '"' && (i == 0 || content.charAt(i - 1) != '\\')) {
                inString = !inString;
            }

            if (!inString) {
                if (c == ':') {
                    inValue = true;
                } else if (c == ',' || c == '}') {
                    if (inValue) {
                        lastValidPos = i;
                        inValue = false;
                    }
                }
            }
        }

        return lastValidPos > 0 ? lastValidPos : content.length() - 1;
    }

    /**
     * 修复常见的JSON问题
     */
    private static String fixCommonJsonIssues(String json) {
        String fixed = json;

        // 修复多余的逗号
        fixed = fixed.replaceAll(",\\s*([}\\]])", "$1");

        // 修复缺失的引号（简单情况）
        fixed = fixed.replaceAll("([{,]\\s*)([a-zA-Z_][a-zA-Z0-9_]*)\\s*:", "$1\"$2\":");

        // 修复字符串值缺失引号（简单情况）
        fixed = fixed.replaceAll(":\\s*([a-zA-Z_][a-zA-Z0-9_\\s]*?)([,}])", ":\"$1\"$2");

        return fixed;
    }

    /**
     * 后备数组修复方法
     */
    private static String fallbackRepairArray(String arrayContent) {
        // 提取所有可能的JSON对象，即使它们可能不完整
        List<String> objects = new ArrayList<>();
        String content = arrayContent.substring(1); // 移除开头的 [

        // 使用更宽松的对象匹配
        int start = 0;
        int braceLevel = 0;
        boolean inString = false;
        int objStart = -1;

        for (int i = 0; i < content.length(); i++) {
            char c = content.charAt(i);

            if (c == '"' && (i == 0 || content.charAt(i - 1) != '\\')) {
                inString = !inString;
            }

            if (!inString) {
                if (c == '{') {
                    if (braceLevel == 0) {
                        objStart = i;
                    }
                    braceLevel++;
                } else if (c == '}') {
                    braceLevel--;
                    if (braceLevel == 0 && objStart >= 0) {
                        String obj = content.substring(objStart, i + 1);
                        try {
                            if (isValidJsonObject(obj)) {
                                objects.add(obj);
                            }
                        } catch (Exception e) {
                            // 忽略无效对象
                        }
                        objStart = -1;
                    }
                }
            }
        }

        if (!objects.isEmpty()) {
            String result = "[" + String.join(",", objects) + "]";
            if (isValidJson(result)) {
                log.debug("后备修复成功，提取 {} 个对象", objects.size());
                return result;
            }
        }

        return null;
    }

    /**
     * 提取所有可能的对象
     */
    private static String extractAllPossibleObjects(String content) {
        List<String> objects = new ArrayList<>();

        // 使用更激进的正则表达式匹配
        Pattern[] patterns = {
            Pattern.compile("\\{[^{}]*\\}"), // 简单对象
            Pattern.compile("\\{(?:[^{}]*\\{[^{}]*\\}[^{}]*)*\\}"), // 嵌套对象
            Pattern.compile("\\{[^}]*\\}") // 宽松匹配
        };

        for (Pattern pattern : patterns) {
            Matcher matcher = pattern.matcher(content);
            while (matcher.find()) {
                String obj = matcher.group();
                try {
                    if (isValidJsonObject(obj)) {
                        objects.add(obj);
                    }
                } catch (Exception e) {
                    // 继续尝试下一个
                }
            }
            if (!objects.isEmpty()) {
                break; // 找到就停止
            }
        }

        if (!objects.isEmpty()) {
            String result = "[" + String.join(",", objects) + "]";
            if (isValidJson(result)) {
                log.debug("提取所有对象成功，找到 {} 个对象", objects.size());
                return result;
            }
        }

        return null;
    }

    /**
     * 智能截取JSON - 保留尽可能多的有效内容
     */
    public static String intelligentTruncation(String jsonContent) {
        if (jsonContent == null || jsonContent.trim().isEmpty()) {
            return null;
        }

        String content = jsonContent.trim();

        // 如果是数组格式
        if (content.startsWith("[")) {
            int lastCompletePos = findLastCompleteObject(content);
            if (lastCompletePos > 0) {
                String truncated = content.substring(0, lastCompletePos) + "]";
                if (isValidJson(truncated)) {
                    return truncated;
                }
            }
        }

        // 如果是对象格式
        if (content.startsWith("{")) {
            String repaired = repairJsonObject(content);
            if (isValidJson(repaired)) {
                return "[" + repaired + "]";
            }
        }

        return null;
    }

    /**
     * 从响应中提取所有可能的JSON内容 - 激进修复模式
     */
    public static String extractJsonFromResponse(String response) {
        if (response == null || response.isEmpty()) {
            return null;
        }

        log.debug("开始从响应中提取JSON，响应长度: {}", response.length());

        // 1. 优先尝试激进修复 - 保留最多内容
        String aggressiveRepaired = aggressiveJsonRepair(response);
        if (aggressiveRepaired != null) {
            log.info("激进修复成功，修复后长度: {}", aggressiveRepaired.length());
            return aggressiveRepaired;
        }

        // 2. 尝试提取完整的JSON数组
        String arrayJson = extractCompleteJsonArray(response);
        if (arrayJson != null && isValidJson(arrayJson)) {
            log.info("提取完整JSON数组成功，长度: {}", arrayJson.length());
            return arrayJson;
        }

        // 3. 尝试提取完整的JSON对象并包装为数组
        String objectJson = extractCompleteJsonObject(response);
        if (objectJson != null && isValidJsonObject(objectJson)) {
            String wrappedArray = "[" + objectJson + "]";
            if (isValidJson(wrappedArray)) {
                log.info("提取完整JSON对象成功，长度: {}", wrappedArray.length());
                return wrappedArray;
            }
        }

        // 4. 常规修复
        String repairedJson = repairJson(response);
        if (repairedJson != null) {
            log.info("常规修复成功，长度: {}", repairedJson.length());
            return repairedJson;
        }

        // 5. 智能截取（最后的兜底）
        String truncatedJson = intelligentTruncation(response);
        if (truncatedJson != null) {
            log.info("智能截取成功，长度: {}", truncatedJson.length());
            return truncatedJson;
        }

        log.warn("无法从响应中提取有效的JSON内容");
        return null;
    }

    /**
     * 提取完整的JSON数组
     */
    private static String extractCompleteJsonArray(String response) {
        int arrayStart = response.indexOf('[');
        if (arrayStart < 0) {
            return null;
        }

        int level = 0;
        boolean inString = false;

        for (int i = arrayStart; i < response.length(); i++) {
            char c = response.charAt(i);

            if (c == '"' && (i == 0 || response.charAt(i - 1) != '\\')) {
                inString = !inString;
            }

            if (!inString) {
                if (c == '[') {
                    level++;
                } else if (c == ']') {
                    level--;
                    if (level == 0) {
                        return response.substring(arrayStart, i + 1);
                    }
                }
            }
        }

        return null;
    }

    /**
     * 提取完整的JSON对象
     */
    private static String extractCompleteJsonObject(String response) {
        int objStart = response.indexOf('{');
        if (objStart < 0) {
            return null;
        }

        int level = 0;
        boolean inString = false;

        for (int i = objStart; i < response.length(); i++) {
            char c = response.charAt(i);

            if (c == '"' && (i == 0 || response.charAt(i - 1) != '\\')) {
                inString = !inString;
            }

            if (!inString) {
                if (c == '{') {
                    level++;
                } else if (c == '}') {
                    level--;
                    if (level == 0) {
                        return response.substring(objStart, i + 1);
                    }
                }
            }
        }

        return null;
    }
} 