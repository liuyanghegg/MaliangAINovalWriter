import 'package:flutter/material.dart';
import 'package:ainoval/models/preset_models.dart';
import 'package:ainoval/services/ai_preset_service.dart';
import 'package:ainoval/utils/logger.dart';

/// 预设菜单项数据
class PresetMenuItemData {
  final IconData icon;
  final String label;
  final bool hasSubmenu;
  final bool disabled;
  final bool isDangerous;
  final Future<void> Function(BuildContext context, AIPresetService presetService, String featureType)? onTap;

  const PresetMenuItemData({
    required this.icon,
    required this.label,
    this.hasSubmenu = false,
    this.disabled = false,
    this.isDangerous = false,
    this.onTap,
  });
}

/// 预设菜单分组数据
class PresetMenuSectionData {
  final String? title;
  final List<PresetMenuItemData> items;
  final bool dividerAtBottom;

  const PresetMenuSectionData({
    this.title,
    required this.items,
    this.dividerAtBottom = true,
  });
}

/// 预设菜单定义
class PresetMenuDefinitions {
  static List<dynamic> getMenuItems({
    required Function() onCreatePreset,
    required Function() onManagePresets,
  }) {
    return [
      // 主要操作
      PresetMenuSectionData(
        title: null,
        items: [
          PresetMenuItemData(
            icon: Icons.bookmark_add,
            label: 'Create Preset',
            onTap: (context, presetService, featureType) async {
              onCreatePreset();
            },
          ),
          PresetMenuItemData(
            icon: Icons.edit_outlined,
            label: 'Update Preset',
            disabled: true, // 暂时禁用
            onTap: null,
          ),
        ],
        dividerAtBottom: true,
      ),
      
      // 最近使用的预设
      PresetMenuSectionData(
        title: '最近使用',
        items: [], // 动态加载
        dividerAtBottom: true,
      ),
      
      // 收藏预设
      PresetMenuSectionData(
        title: '收藏预设',
        items: [], // 动态加载
        dividerAtBottom: true,
      ),
      
      // 管理操作
      PresetMenuSectionData(
        title: null,
        items: [
          PresetMenuItemData(
            icon: Icons.settings,
            label: 'Manage Presets',
            onTap: (context, presetService, featureType) async {
              onManagePresets();
            },
          ),
        ],
        dividerAtBottom: false,
      ),
    ];
  }

  /// 获取动态预设菜单项（包含实际预设数据）
  static Future<List<dynamic>> getDynamicMenuItems({
    required String featureType,
    required Function() onCreatePreset,
    required Function() onManagePresets,
    required Function(AIPromptPreset preset) onPresetSelected,
    String? novelId,
  }) async {
    final presetService = AIPresetService();
    
    try {
      // 使用新的统一接口获取功能预设列表
      final presetListResponse = await presetService.getFeaturePresetList(featureType, novelId: novelId);

      final recentPresets = presetListResponse.recentUsed.map((item) => item.preset).toList();
      final favoritePresets = presetListResponse.favorites.map((item) => item.preset).toList();

      return [
        // 主要操作
        PresetMenuSectionData(
          title: null,
          items: [
            PresetMenuItemData(
              icon: Icons.bookmark_add,
              label: 'Create Preset',
              onTap: (context, presetService, featureType) async {
                onCreatePreset();
              },
            ),
            PresetMenuItemData(
              icon: Icons.edit_outlined,
              label: 'Update Preset',
              disabled: true, // 暂时禁用
              onTap: null,
            ),
          ],
          dividerAtBottom: true,
        ),
        
        // 最近使用的预设
        if (recentPresets.isNotEmpty) ...[
          PresetMenuSectionData(
            title: '最近使用',
            items: recentPresets.map((preset) => PresetMenuItemData(
              icon: Icons.history,
              label: preset.presetName ?? '未命名预设',
              onTap: (context, presetService, featureType) async {
                onPresetSelected(preset);
                // 记录使用
                presetService.applyPreset(preset.presetId).catchError((e) {
                  AppLogger.w('PresetMenu', '记录预设使用失败', e);
                });
              },
            )).toList(),
            dividerAtBottom: true,
          ),
        ],
        
        // 收藏预设
        if (favoritePresets.isNotEmpty) ...[
          PresetMenuSectionData(
            title: '收藏预设',
            items: favoritePresets.map((preset) => PresetMenuItemData(
              icon: Icons.favorite,
              label: preset.presetName ?? '未命名预设',
              onTap: (context, presetService, featureType) async {
                onPresetSelected(preset);
                // 记录使用
                presetService.applyPreset(preset.presetId).catchError((e) {
                  AppLogger.w('PresetMenu', '记录预设使用失败', e);
                });
              },
            )).toList(),
            dividerAtBottom: true,
          ),
        ],
        
        // 空状态提示
        if (recentPresets.isEmpty && favoritePresets.isEmpty) ...[
          PresetMenuSectionData(
            title: null,
            items: [
              PresetMenuItemData(
                icon: Icons.info_outline,
                label: '暂无预设',
                disabled: true,
                onTap: null,
              ),
            ],
            dividerAtBottom: true,
          ),
        ],
        
        // 管理操作
        PresetMenuSectionData(
          title: null,
          items: [
            PresetMenuItemData(
              icon: Icons.settings,
              label: 'Manage Presets',
              onTap: (context, presetService, featureType) async {
                onManagePresets();
              },
            ),
          ],
          dividerAtBottom: false,
        ),
      ];
    } catch (e) {
      AppLogger.e('PresetMenuDefinitions', '加载预设数据失败', e);
      
      // 返回基础菜单
      return [
        PresetMenuSectionData(
          title: null,
          items: [
            PresetMenuItemData(
              icon: Icons.bookmark_add,
              label: 'Create Preset',
              onTap: (context, presetService, featureType) async {
                onCreatePreset();
              },
            ),
            PresetMenuItemData(
              icon: Icons.settings,
              label: 'Manage Presets',
              onTap: (context, presetService, featureType) async {
                onManagePresets();
              },
            ),
          ],
          dividerAtBottom: false,
        ),
      ];
    }
  }
} 