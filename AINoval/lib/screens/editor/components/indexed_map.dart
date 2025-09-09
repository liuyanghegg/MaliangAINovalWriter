/// 索引化的Map数据结构，同时支持键查找和索引访问
/// 提供O(1)的键查找、索引访问、相邻元素获取
class IndexedMap<K, V> {
  final Map<K, _IndexedNode<K, V>> _keyToNode = <K, _IndexedNode<K, V>>{};
  final List<_IndexedNode<K, V>> _orderedNodes = <_IndexedNode<K, V>>[];
  
  /// 获取元素数量
  int get length => _orderedNodes.length;
  
  /// 是否为空
  bool get isEmpty => _orderedNodes.isEmpty;
  
  /// 是否非空
  bool get isNotEmpty => _orderedNodes.isNotEmpty;
  
  /// 获取所有键
  Iterable<K> get keys => _keyToNode.keys;
  
  /// 获取所有值
  Iterable<V> get values => _orderedNodes.map((node) => node.value);
  
  /// 添加或更新元素到末尾
  void add(K key, V value) {
    if (_keyToNode.containsKey(key)) {
      // 更新现有元素
      _keyToNode[key]!.value = value;
      return;
    }
    
    final node = _IndexedNode<K, V>(
      key: key,
      value: value,
      index: _orderedNodes.length,
    );
    
    _keyToNode[key] = node;
    _orderedNodes.add(node);
  }
  
  /// 在指定位置插入元素
  void insertAt(int index, K key, V value) {
    if (_keyToNode.containsKey(key)) {
      throw ArgumentError('Key $key already exists');
    }
    
    if (index < 0 || index > _orderedNodes.length) {
      throw RangeError('Index $index out of range');
    }
    
    final node = _IndexedNode<K, V>(
      key: key,
      value: value,
      index: index,
    );
    
    _keyToNode[key] = node;
    _orderedNodes.insert(index, node);
    
    // 更新后续节点的索引
    _updateIndicesFrom(index);
  }
  
  /// 根据键删除元素
  bool removeKey(K key) {
    final node = _keyToNode[key];
    if (node == null) return false;
    
    final index = node.index;
    _keyToNode.remove(key);
    _orderedNodes.removeAt(index);
    
    // 更新后续节点的索引
    _updateIndicesFrom(index);
    
    return true;
  }
  
  /// 根据索引删除元素
  V? removeAt(int index) {
    if (index < 0 || index >= _orderedNodes.length) {
      return null;
    }
    
    final node = _orderedNodes.removeAt(index);
    _keyToNode.remove(node.key);
    
    // 更新后续节点的索引
    _updateIndicesFrom(index);
    
    return node.value;
  }
  
  /// 根据键获取值 - O(1)
  V? operator [](K key) {
    return _keyToNode[key]?.value;
  }
  
  /// 根据索引获取值 - O(1)
  V? getAt(int index) {
    if (index < 0 || index >= _orderedNodes.length) {
      return null;
    }
    return _orderedNodes[index].value;
  }
  
  /// 根据索引获取键 - O(1)
  K? getKeyAt(int index) {
    if (index < 0 || index >= _orderedNodes.length) {
      return null;
    }
    return _orderedNodes[index].key;
  }
  
  /// 根据键获取索引 - O(1)
  int? getIndex(K key) {
    return _keyToNode[key]?.index;
  }
  
  /// 检查是否包含键 - O(1)
  bool containsKey(K key) {
    return _keyToNode.containsKey(key);
  }
  
  /// 获取前k个元素 - O(k)，但通常k很小所以近似O(1)
  List<V> getPrevious(K key, int count) {
    final node = _keyToNode[key];
    if (node == null) return [];
    
    final startIndex = (node.index - count).clamp(0, _orderedNodes.length);
    final endIndex = node.index;
    
    return _orderedNodes
        .getRange(startIndex, endIndex)
        .map((n) => n.value)
        .toList();
  }
  
  /// 获取后k个元素 - O(k)，但通常k很小所以近似O(1)
  List<V> getNext(K key, int count) {
    final node = _keyToNode[key];
    if (node == null) return [];
    
    final startIndex = node.index + 1;
    final endIndex = (startIndex + count).clamp(0, _orderedNodes.length);
    
    return _orderedNodes
        .getRange(startIndex, endIndex)
        .map((n) => n.value)
        .toList();
  }
  
  /// 获取前后k个元素 - O(k)
  List<V> getSurrounding(K key, int count) {
    final node = _keyToNode[key];
    if (node == null) return [];
    
    final startIndex = (node.index - count).clamp(0, _orderedNodes.length);
    final endIndex = (node.index + count + 1).clamp(0, _orderedNodes.length);
    
    return _orderedNodes
        .getRange(startIndex, endIndex)
        .map((n) => n.value)
        .toList();
  }
  
  /// 获取指定范围的元素 - O(range)
  List<V> getRange(int start, int end) {
    if (start < 0) start = 0;
    if (end > _orderedNodes.length) end = _orderedNodes.length;
    if (start >= end) return [];
    
    return _orderedNodes
        .getRange(start, end)
        .map((n) => n.value)
        .toList();
  }
  
  /// 清空所有元素
  void clear() {
    _keyToNode.clear();
    _orderedNodes.clear();
  }
  
  /// 更新指定位置之后的所有节点索引
  void _updateIndicesFrom(int startIndex) {
    for (int i = startIndex; i < _orderedNodes.length; i++) {
      _orderedNodes[i].index = i;
    }
  }
  
  /// 转换为List
  List<V> toList() {
    return _orderedNodes.map((node) => node.value).toList();
  }
  
  /// 转换为Map
  Map<K, V> toMap() {
    return Map.fromEntries(
      _orderedNodes.map((node) => MapEntry(node.key, node.value)),
    );
  }
  
  /// 遍历所有元素
  void forEach(void Function(K key, V value, int index) action) {
    for (int i = 0; i < _orderedNodes.length; i++) {
      final node = _orderedNodes[i];
      action(node.key, node.value, i);
    }
  }
  
  /// 查找符合条件的元素索引
  int indexWhere(bool Function(V value) test) {
    for (int i = 0; i < _orderedNodes.length; i++) {
      if (test(_orderedNodes[i].value)) {
        return i;
      }
    }
    return -1;
  }
}

/// 内部节点类
class _IndexedNode<K, V> {
  final K key;
  V value;
  int index;
  
  _IndexedNode({
    required this.key,
    required this.value,
    required this.index,
  });
  
  @override
  String toString() => 'Node($key: $value @ $index)';
} 