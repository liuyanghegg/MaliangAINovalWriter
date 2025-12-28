package com.ainovel.server.service.ai.genai;

import com.ainovel.server.service.ai.tools.ToolExecutionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.bytebuddy.ByteBuddy;
import net.bytebuddy.description.modifier.Visibility;
import net.bytebuddy.description.modifier.Ownership;
import net.bytebuddy.dynamic.loading.ClassLoadingStrategy;
import net.bytebuddy.dynamic.DynamicType;
import net.bytebuddy.implementation.MethodDelegation;
import net.bytebuddy.implementation.bind.annotation.AllArguments;
import net.bytebuddy.implementation.bind.annotation.Origin;
import net.bytebuddy.implementation.bind.annotation.RuntimeType;
import org.springframework.stereotype.Component;

import java.lang.reflect.Method;
import java.security.MessageDigest;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Gemini SDK 工具桥（单例 Bean）：
 * - 将 toolSpecifications 动态生成方法：与工具名同名
 * - 强类型参数：基础类型（boolean/number/string）拆参，复杂/数组退化为 String JSON
 * - 返回值 String（JSON）
 */
@Slf4j
@RequiredArgsConstructor
@Component
public class GeminiSdkToolBridge {

    private final ToolExecutionService toolExecutionService;

    private static final Map<String, List<Method>> CACHE = new ConcurrentHashMap<>();

    public List<Method> buildMethods(String modelName, List<Object> toolSpecifications, String toolContextId) {
        if (toolSpecifications == null || toolSpecifications.isEmpty()) return List.of();
        String cacheKey = buildCacheKey(modelName, toolSpecifications);
        return CACHE.computeIfAbsent(cacheKey, k -> generateBridgeClass(toolSpecifications, toolContextId));
    }

    private String buildCacheKey(String modelName, List<Object> specs) {
        List<String> names = new ArrayList<>();
        for (Object o : specs) {
            String n = tryGetString(o, "name", "getName");
            if (n != null) names.add(n);
        }
        Collections.sort(names);
        return modelName + "::" + String.join(",", names);
    }

    private List<Method> generateBridgeClass(List<Object> toolSpecifications, String toolContextId) {
        try {
            try { System.setProperty("net.bytebuddy.experimental", "true"); } catch (Exception ignore) {}
            String className = "com.ainovel.server.service.ai.genai.GeminiToolBridge$" + UUID.randomUUID().toString().replace('-', '_');
            DynamicType.Builder<?> classBuilder = new ByteBuddy()
                    .subclass(Object.class)
                    .name(className);

            List<String> methodNames = new ArrayList<>();
            List<Class<?>[]> methodParamTypes = new ArrayList<>();
            List<Object> interceptors = new ArrayList<>();

            for (Object spec : toolSpecifications) {
                String toolName = tryGetString(spec, "name", "getName");
                if (toolName == null || toolName.isEmpty()) continue;
                String methodName = sanitize(toolName);
                methodNames.add(methodName);

                List<ParamDef> params = parseParamDefs(spec);
                boolean useSingleJson = params.isEmpty();
                Class<?>[] paramTypes;
                String[] paramNames;
                if (useSingleJson) {
                    paramTypes = new Class<?>[]{String.class};
                    paramNames = new String[]{"argumentsJson"};
                } else {
                    paramTypes = new Class<?>[params.size()];
                    paramNames = new String[params.size()];
                    for (int i = 0; i < params.size(); i++) {
                        paramTypes[i] = params.get(i).type;
                        paramNames[i] = params.get(i).name;
                    }
                }
                methodParamTypes.add(paramTypes);
                interceptors.add(new ToolInvoker(toolExecutionService, toolContextId, toolName));

                // 定义方法
                DynamicType.Builder.MethodDefinition.ParameterDefinition<?> mb =
                        classBuilder.defineMethod(methodName, String.class, Visibility.PUBLIC, Ownership.STATIC);
                if (paramTypes.length == 1 && "argumentsJson".equals(paramNames[0])) {
                    mb = mb.withParameter(String.class, "argumentsJson");
                } else {
                    for (int i = 0; i < paramTypes.length; i++) {
                        mb = mb.withParameter(paramTypes[i], paramNames[i]);
                    }
                }
                classBuilder = mb.intercept(MethodDelegation.to(interceptors.get(interceptors.size() - 1)));
            }

            Class<?> generated = classBuilder
                    .make()
                    .load(getClass().getClassLoader(), ClassLoadingStrategy.Default.WRAPPER)
                    .getLoaded();

            List<Method> methods = new ArrayList<>();
            for (int i = 0; i < methodNames.size(); i++) {
                String mn = methodNames.get(i);
                Class<?>[] pts = methodParamTypes.get(i);
                methods.add(generated.getMethod(mn, pts));
            }
            return methods;
        } catch (Exception e) {
            log.error("Failed to generate tool bridge class: {}", e.getMessage(), e);
            return List.of();
        }
    }

    private String tryGetString(Object obj, String... methodNames) {
        for (String m : methodNames) {
            try {
                var method = obj.getClass().getMethod(m);
                Object val = method.invoke(obj);
                if (val != null) return val.toString();
            } catch (Exception ignored) {}
        }
        return null;
    }

    private List<ParamDef> parseParamDefs(Object spec) {
        List<ParamDef> params = new ArrayList<>();
        try {
            Object parameters = null;
            try { parameters = spec.getClass().getMethod("getParameters").invoke(spec); } catch (Exception ignore) {}
            if (parameters == null && spec instanceof Map<?, ?> m) {
                parameters = m.get("parameters");
            }
            if (!(parameters instanceof Map<?, ?> pm)) return params;
            Object propsObj = pm.get("properties");
            if (!(propsObj instanceof Map<?, ?> props)) return params;
            for (Map.Entry<?, ?> e : props.entrySet()) {
                String name = e.getKey() == null ? null : e.getKey().toString();
                if (name == null || name.isEmpty()) continue;
                Class<?> type = String.class; // default as String
                if (e.getValue() instanceof Map<?, ?> def) {
                    Object typeStr = def.get("type");
                    if (typeStr != null) {
                        String t = typeStr.toString();
                        switch (t) {
                            case "boolean" -> type = boolean.class;
                            case "integer" -> type = long.class;
                            case "number" -> type = double.class;
                            case "string" -> type = String.class;
                            case "array", "object" -> type = String.class; // complex → JSON string
                            default -> type = String.class;
                        }
                    }
                }
                params.add(new ParamDef(name, type));
            }
        } catch (Exception ignore) {}
        return params;
    }

    private static class ParamDef {
        final String name; final Class<?> type;
        ParamDef(String n, Class<?> t) { this.name = n; this.type = t; }
    }

    private String sanitize(String name) {
        return name.replaceAll("[^a-zA-Z0-9_]", "_");
    }

    public static class ToolInvoker {
        private final ToolExecutionService service;
        private final String contextId;
        private final String toolName;

        private static final Map<String, String> IDEMP_CACHE = new ConcurrentHashMap<>();
        private static final Map<String, Long> IDEMP_TIME = new ConcurrentHashMap<>();
        private static final long IDEMP_TTL_MS = 1500; // 1.5s 窗口去重

        public ToolInvoker(ToolExecutionService s, String ctx, String tool) {
            this.service = s; this.contextId = ctx; this.toolName = tool;
        }

        @RuntimeType
        public String intercept(@AllArguments Object[] args, @Origin Method origin) throws Exception {
            try {
                String json;
                if (args == null || args.length == 0) {
                    json = "{}";
                } else if (args.length == 1 && args[0] instanceof String s) {
                    json = s != null ? s : "{}";
                } else {
                    String[] paramNames = new String[origin.getParameterCount()];
                    for (int i = 0; i < origin.getParameterCount(); i++) {
                        paramNames[i] = origin.getParameters()[i].getName();
                    }
                    StringBuilder sb = new StringBuilder();
                    sb.append('{');
                    for (int i = 0; i < args.length; i++) {
                        if (i > 0) sb.append(',');
                        sb.append('"').append(paramNames[i] != null ? paramNames[i] : ("arg" + i)).append('"').append(':');
                        Object v = args[i];
                        if (v == null) sb.append("null");
                        else if (v instanceof Number || v instanceof Boolean) sb.append(v.toString());
                        else sb.append('"').append(escape(String.valueOf(v))).append('"');
                    }
                    sb.append('}');
                    json = sb.toString();
                }
                String key = hash(contextId + "|" + toolName + "|" + json);
                long now = System.currentTimeMillis();
                Long ts = IDEMP_TIME.get(key);
                if (ts != null && (now - ts) < IDEMP_TTL_MS) {
                    String cached = IDEMP_CACHE.get(key);
                    if (cached != null) return cached;
                }
                String result = service.invokeTool(contextId, toolName, json);
                IDEMP_CACHE.put(key, result);
                IDEMP_TIME.put(key, now);
                return result;
            } catch (Exception e) {
                return errorJson(e.getMessage());
            }
        }

        private String escape(String s) {
            return s.replace("\\", "\\\\").replace("\"", "\\\"");
        }

        private String errorJson(String msg) {
            return "{\"success\":false,\"error\":" + quote(msg) + ",\"timestamp\":" + System.currentTimeMillis() + "}";
        }

        private String quote(String s) {
            if (s == null) return "\"\"";
            return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"") + "\"";
        }

        private String hash(String s) {
            try {
                MessageDigest md = MessageDigest.getInstance("MD5");
                byte[] d = md.digest(s.getBytes());
                StringBuilder sb = new StringBuilder();
                for (byte b : d) sb.append(String.format("%02x", b));
                return sb.toString();
            } catch (Exception e) {
                return Integer.toHexString(s.hashCode());
            }
        }
    }
}
