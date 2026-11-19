import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/excel_data_row.dart';
import '../services/printer_service.dart';
import '../theme/app_colors.dart';
import '../widgets/thermal_preview_dialog.dart';

class ExcelBatchScreen extends StatefulWidget {
  const ExcelBatchScreen({super.key});

  @override
  State<ExcelBatchScreen> createState() => _ExcelBatchScreenState();
}

class _ExcelBatchScreenState extends State<ExcelBatchScreen> {
  final PrinterService _printerService = PrinterService();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Excel dataset from Screenshot 4
  late List<ExcelDataRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = [
      ExcelDataRow(index: 1, number: '1', name: 'Michael Brown', extra: '21', isSelected: true),
      ExcelDataRow(index: 2, number: '2', name: 'Sarah Johnson', extra: '21', isSelected: true),
      ExcelDataRow(index: 3, number: '3', name: 'David Wilson', extra: '21', isSelected: false),
      ExcelDataRow(index: 4, number: '4', name: 'Emily Davis', extra: '21', isSelected: false),
      ExcelDataRow(index: 5, number: '5', name: 'Robert Taylor', extra: '21', isSelected: true),
      ExcelDataRow(index: 6, number: '6', name: 'Jennifer Miller', extra: '31', isSelected: true),
      ExcelDataRow(index: 7, number: '7', name: 'James Anderson', extra: '31', isSelected: true),
      ExcelDataRow(index: 8, number: '8', name: 'Linda Thomas', extra: '31', isSelected: true),
      ExcelDataRow(index: 9, number: '9', name: 'William Jackson', extra: '31', isSelected: false),
      ExcelDataRow(index: 10, number: '10', name: 'Elizabeth White', extra: '31', isSelected: true),
      ExcelDataRow(index: 11, number: '11', name: 'Richard Harris', extra: '77', isSelected: false),
      ExcelDataRow(index: 12, number: '12', name: 'Mary Martin', extra: '77', isSelected: false),
      ExcelDataRow(index: 13, number: '13', name: 'Thomas Garcia', extra: '77', isSelected: true),
    ];
  }

  bool get _isAllSelected => _rows.every((r) => r.isSelected);

  void _toggleSelectAll(bool? val) {
    setState(() {
      final target = val ?? false;
      for (final r in _rows) {
        r.isSelected = target;
      }
    });
  }

  void _importExcelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );
      if (result != null && result.files.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported ${result.files.first.name} successfully!')),
          );
        }
      }
    } catch (e) {
      debugPrint("Excel pick error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRows = _rows.where((r) {
      if (_searchQuery.isEmpty) return true;
      return r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.number.contains(_searchQuery) ||
          r.extra.contains(_searchQuery);
    }).toList();

    final selectedCount = _rows.where((r) => r.isSelected).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Data',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined, color: AppColors.primary),
            tooltip: 'Import Excel / CSV',
            onPressed: _importExcelFile,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Box (Screenshot 4)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Search Excel content',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white, size: 20),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),

          // 2. Column toggles (Screenshot 4: Number, Name)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.edit, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    const Text('Number', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('Name', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.refresh, size: 16, color: Colors.grey),
              ],
            ),
          ),

          const Divider(height: 1),

          // 3. Data Table (Screenshot 4)
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              physics: const BouncingScrollPhysics(),
              itemCount: filteredRows.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final row = filteredRows[index];

                return InkWell(
                  onTap: () {
                    setState(() {
                      row.isSelected = !row.isSelected;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Row(
                      children: [
                        // Green Checkbox
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: row.isSelected ? AppColors.primary : Colors.transparent,
                            border: Border.all(
                              color: row.isSelected ? AppColors.primary : Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                          child: row.isSelected
                              ? const Icon(Icons.check, size: 13, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 16),

                        // Index / Number column
                        SizedBox(
                          width: 32,
                          child: Text(
                            row.number,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                          ),
                        ),

                        // Name column
                        Expanded(
                          child: Text(
                            row.name,
                            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                          ),
                        ),

                        // Extra / Qty column
                        Text(
                          row.extra,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. Sticky Bottom Action Bar (Screenshot 4)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Select All Rows checkbox
                GestureDetector(
                  onTap: () => _toggleSelectAll(!_isAllSelected),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isAllSelected ? AppColors.primary : Colors.transparent,
                          border: Border.all(
                            color: _isAllSelected ? AppColors.primary : Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: _isAllSelected
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Select All Rows ($selectedCount)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),

                // Green Confirm / Batch Print Button
                ElevatedButton(
                  onPressed: selectedCount == 0
                      ? null
                      : () {
                          // Trigger batch print dialog
                          ThermalPrintProgressDialog.show(
                            context: context,
                            previewWidget: Container(
                              height: 160,
                              padding: const EdgeInsets.all(12),
                              color: Colors.white,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Batch Print: $selectedCount Labels',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '1st Item: ${_rows.firstWhere((r) => r.isSelected).name}',
                                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            labelTitle: 'Batch Print ($selectedCount Labels)',
                            labelSizeStr: '50×30mm',
                            onPrintConfirmed: (copies) async {
                              await _printerService.printTestDiagnostic();
                            },
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
