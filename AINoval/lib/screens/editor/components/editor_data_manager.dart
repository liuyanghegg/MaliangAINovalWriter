import 'dart:collection';

/// 编辑器数据管理器 - 高效的双重索引结构
/// 提供O(1)键查找、索引访问、相邻元素获取
class EditorDataManager<T> {
  // 主数据存储：保持插入顺序的列表
  final List<T> _items = [];
  
  // 键到索引的映射：O(1)查找
  final Map<String, int> _keyToIndex = {};
  
  // 索引到键的映射：O(1)反向查找
  final Map<int, String> _indexToKey = {};
  
  /// 获取元素数量
  int get length => _items.length;
  
  /// 是否为空
  bool get isEmpty => _items.isEmpty;
  
  /// 是否非空
  bool get isNotEmpty => _items.isNotEmpty;
  
  /// 获取所有值
  List<T> get values => List.unmodifiable(_items);
  
  /// 获取所有键
  Iterable<String> get keys => _keyToIndex.keys;
  
  /// 添加元素到末尾 - O(1)
  void add(String key, T value) {
    // 如果键已存在，更新值
    if (_keyToIndex.containsKey(key)) {
      final index = _keyToIndex[key]!;
      _items[index] = value;
      return;
    }
    
    // 添加新元素
    final index = _items.length;
    _items.add(value);
    _keyToIndex[key] = index;
    _indexToKey[index] = key;
  }
  
  /// 在指定位置插入元素 - O(n)
  void insertAt(int index, String key, T value) {
    if (_keyToIndex.containsKey(key)) {
      throw ArgumentError('Key $key already exists');
    }
    
    if (index < 0 || index > _items.length) {
      throw RangeError('Index $index out of range');
    }
    
    // 插入元素
    _items.insert(index, value);
    
    // 更新所有索引映射
    _rebuildIndexMaps();
  }
  
  /// 根据键删除元素 - O(n)
  bool removeByKey(String key) {
    final index = _keyToIndex[key];
    if (index == null) return false;
    
    _items.removeAt(index);
    _rebuildIndexMaps();
    return true;
  }
  
  /// 根据索引删除元素 - O(n)
  T? removeAt(int index) {
    if (index < 0 || index >= _items.length) return null;
    
    final value = _items.removeAt(index);
    _rebuildIndexMaps();
    return value;
  }
  
  /// 根据键获取值 - O(1)
  T? getByKey(String key) {
    final index = _keyToIndex[key];
    if (index == null) return null;
    return _items[index];
  }
  
  /// 根据索引获取值 - O(1)
  T? getByIndex(int index) {
    if (index < 0 || index >= _items.length) return null;
    return _items[index];
  }
  
  /// 根据索引获取键 - O(1)
  String? getKeyByIndex(int index) {
    return _indexToKey[index];
  }
  
  /// 根据键获取索引 - O(1)
  int? getIndexByKey(String key) {
    return _keyToIndex[key];
  }
  
  /// 检查是否包含键 - O(1)
  bool containsKey(String key) {
    return _keyToIndex.containsKey(key);
  }
  
  /// 获取前k个元素 - O(1) 时间复杂度（对于小的k值）
  List<T> getPrevious(String key, int count) {
    final index = _keyToIndex[key];
    if (index == null) return [];
    
    final startIndex = (index - count).clamp(0, _items.length);
    final endIndex = index;
    
    return _items.getRange(startIndex, endIndex).toList();
  }
  
  /// 获取后k个元素 - O(1) 时间复杂度（对于小的k值）
  List<T> getNext(String key, int count) {
    final index = _keyToIndex[key];
    if (index == null) return [];
    
    final startIndex = index + 1;
    final endIndex = (startIndex + count).clamp(0, _items.length);
    
    return _items.getRange(startIndex, endIndex).toList();
  }
  
  /// 获取前后k个元素 - O(1) 时间复杂度（对于小的k值）
  List<T> getSurrounding(String key, int count) {
    final index = _keyToIndex[key];
    if (index == null) return [];
    
    final startIndex = (index - count).clamp(0, _items.length);
    final endIndex = (index + count + 1).clamp(0, _items.length);
    
    return _items.getRange(startIndex, endIndex).toList();
  }
  
  /// 获取指定范围的元素 - O(range)
  List<T> getRange(int start, int end) {
    if (start < 0) start = 0;
    if (end > _items.length) end = _items.length;
    if (start >= end) return [];
    
    return _items.getRange(start, end).toList();
  }
  
  /// 清空所有元素 - O(1)
  void clear() {
    _items.clear();
    _keyToIndex.clear();
    _indexToKey.clear();
  }
  
  /// 重建索引映射 - O(n)，仅在插入/删除时调用
  void _rebuildIndexMaps() {
    _keyToIndex.clear();
    _indexToKey.clear();
    
    for (int i = 0; i < _items.length; i++) {
      // 这里需要一个获取键的方法，具体实现由子类重写
    }
  }
  
  /// 遍历所有元素
  void forEach(void Function(String key, T value, int index) action) {
    for (int i = 0; i < _items.length; i++) {
      final key = _indexToKey[i];
      if (key != null) {
        action(key, _items[i], i);
      }
    }
  }
  
  /// 查找符合条件的元素索引
  int indexWhere(bool Function(T value) test) {
    return _items.indexWhere(test);
  }
  
  /// 🚀 新增：查找所有符合条件的元素
  List<T> findAll(bool Function(T value) test) {
    return _items.where(test).toList();
  }
  
  /// 🚀 新增：查找所有符合条件的键值对
  Map<String, T> findAllWithKeys(bool Function(T value) test) {
    final result = <String, T>{};
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (test(item)) {
        final key = _indexToKey[i];
        if (key != null) {
          result[key] = item;
        }
      }
    }
    return result;
  }
}

/// 专门为EditorItem设计的数据管理器
class EditorItemManager extends EditorDataManager<dynamic> {
  /// 重写_rebuildIndexMaps以正确处理EditorItem的键
  @override
  void _rebuildIndexMaps() {
    _keyToIndex.clear();
    _indexToKey.clear();
    
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      String key;
      
      // 根据EditorItem类型生成正确的键
      switch (item.type.toString()) {
        case 'EditorItemType.actHeader':
          key = 'act_${item.act!.id}';
          break;
        case 'EditorItemType.chapterHeader':
          key = 'chapter_${item.chapter!.id}';
          break;
        case 'EditorItemType.scene':
          key = 'scene_${item.scene!.id}';
          break;
        case 'EditorItemType.actFooter':
          key = 'act_footer_${item.act!.id}';
          break;
        default:
          key = item.id;
      }
      
      _keyToIndex[key] = i;
      _indexToKey[i] = key;
    }
  }
} 