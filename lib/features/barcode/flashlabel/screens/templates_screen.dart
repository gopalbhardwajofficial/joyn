import 'package:flutter/material.dart';
import '../services/template_service.dart';
import '../theme/app_colors.dart';
import '../widgets/label_canvas_view.dart';
import 'freestyle_editor_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  int _selectedSourceTab = 2; // 0: Local, 1: Cloud, 2: Share (from Screenshot 2)
  String _selectedCategory = 'Business';
  String _selectedSubcategory = 'Sealing Label';
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final filteredTemplates = TemplateService.templates.where((t) {
      if (_searchQuery.isNotEmpty) {
        return t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return t.category == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header: Back, Tabs (Local, Cloud, Share), Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSourceTab(0, 'Local'),
                        const SizedBox(width: 24),
                        _buildSourceTab(1, 'Cloud'),
                        const SizedBox(width: 24),
                        _buildSourceTab(2, 'Share'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search, color: AppColors.textPrimary),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) _searchQuery = '';
                      });
                    },
                  ),
                ],
              ),
            ),

            if (_isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  autofocus: true,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search templates...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 4),

            // 2. Category horizontal pills (Business, Festivals, Work Scenarios...)
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: TemplateService.categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final cat = TemplateService.categories[index];
                  final isSelected = cat == _selectedCategory;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: isSelected ? 20 : 0,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 3. Subcategories row (Price Label, Sealing Label, Thank you, Discount, Barcode)
            Container(
              height: 36,
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: TemplateService.subcategories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final sub = TemplateService.subcategories[index];
                  final isSelected = sub == _selectedSubcategory;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedSubcategory = sub),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.grey.shade200 : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        sub,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. Grid of Templates (Screenshot 2: 2 columns)
            Expanded(
              child: filteredTemplates.isEmpty
                  ? Center(
                      child: Text(
                        'No templates in this category',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: filteredTemplates.length,
                      itemBuilder: (context, index) {
                        final template = filteredTemplates[index];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FreestyleEditorScreen(initialTemplate: template),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Preview Card
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: template.backgroundColor,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                    ),
                                    child: LabelCanvasView(
                                      size: template.size,
                                      elements: template.elements,
                                      backgroundColor: template.backgroundColor,
                                    ),
                                  ),
                                ),

                                // Label metadata
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        template.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        template.sizeSubtitle,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceTab(int index, String title) {
    final isSelected = _selectedSourceTab == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedSourceTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: isSelected ? 24 : 0,
            height: 2.5,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
