class ExcelDataRow {
  final int index;
  final String number;
  final String name;
  final String extra;
  bool isSelected;

  ExcelDataRow({
    required this.index,
    required this.number,
    required this.name,
    required this.extra,
    this.isSelected = true,
  });

  ExcelDataRow copyWith({
    int? index,
    String? number,
    String? name,
    String? extra,
    bool? isSelected,
  }) {
    return ExcelDataRow(
      index: index ?? this.index,
      number: number ?? this.number,
      name: name ?? this.name,
      extra: extra ?? this.extra,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

