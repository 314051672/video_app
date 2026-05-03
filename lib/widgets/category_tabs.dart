import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../theme/app_theme.dart';

class CategoryTabs extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeSelected;

  const CategoryTabs({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, videoProvider, child) {
        final types = videoProvider.types;
        
        final validTypes = types.where((type) {
          final typeId = type['type_id'];
          final typePid = type['type_pid'];
          final typeName = type['type_name']?.toString() ?? '';
          final isAdult = typeName.contains('伦理') || typeName.contains('成人');
          return typePid != 0 && !isAdult;
        }).toList();
        
        return Container(
          color: AppTheme.cardBackground,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildTab(context, 'all', '全部', selectedType == 'all'),
                ...validTypes.map((type) {
                  final typeId = type['type_id'].toString();
                  final typeName = type['type_name']?.toString() ?? '';
                  return _buildTab(context, typeId, typeName, selectedType == typeId);
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTab(BuildContext context, String type, String name, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => onTypeSelected(type),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.transparent,
            ),
          ),
          child: Text(
            name,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
