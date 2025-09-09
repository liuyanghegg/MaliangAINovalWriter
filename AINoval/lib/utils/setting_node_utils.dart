import '../models/setting_node.dart';

/// 设定节点工具类
class SettingNodeUtils {
  /// 在节点树中查找节点
  static SettingNode? findNodeInTree(List<SettingNode> nodes, String id) {
    for (final node in nodes) {
      if (node.id == id) {
        return node;
      }
      if (node.children != null) {
        final found = findNodeInTree(node.children!, id);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  /// 在节点树中查找父节点
  static SettingNode? findParentNodeInTree(List<SettingNode> nodes, String childId) {
    for (final node in nodes) {
      if (node.children != null) {
        // 检查是否是直接子节点
        for (final child in node.children!) {
          if (child.id == childId) {
            return node;
          }
        }
        // 递归检查更深层的子节点
        final found = findParentNodeInTree(node.children!, childId);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  /// 获取可以渲染的节点ID列表（父节点为空或已渲染）
  static List<String> getRenderableNodeIds(
    List<SettingNode> rootNodes,
    List<String> renderQueue,
    Set<String> renderedNodeIds,
  ) {
    final List<String> renderable = [];
    
    print('🔍 [SettingNodeUtils] 检查渲染队列: ${renderQueue.length}个节点, 已渲染: ${renderedNodeIds.length}个');
    
    for (final nodeId in renderQueue) {
      final node = findNodeInTree(rootNodes, nodeId);
      if (node == null) {
        print('🔍 [SettingNodeUtils] ❌ 找不到节点: $nodeId');
        continue;
      }
      
      // 如果是根节点（没有父节点）或父节点已渲染，则可以渲染
      final parentNode = findParentNodeInTree(rootNodes, nodeId);
      
      if (parentNode == null) {
        print('🔍 [SettingNodeUtils] ✅ 根节点可渲染: ${node.name}');
        renderable.add(nodeId);
      } else if (renderedNodeIds.contains(parentNode.id)) {
        print('🔍 [SettingNodeUtils] ✅ 父节点已渲染，子节点可渲染: ${node.name}');
        renderable.add(nodeId);
      } else {
        print('🔍 [SettingNodeUtils] ❌ 父节点未渲染: ${node.name} (需要: ${parentNode.name})');
      }
    }
    
    print('🔍 [SettingNodeUtils] 最终可渲染: ${renderable.length}个节点');
    return renderable;
  }
} 