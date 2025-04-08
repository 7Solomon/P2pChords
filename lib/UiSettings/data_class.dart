class BoundedValue<T extends num> {
  T _value;
  final T min;
  final T max;

  BoundedValue({
    required T value,
    required this.min,
    required this.max,
  }) : _value = _clamp(value, min, max);

  T get value => _value;

  set value(T newValue) {
    _value = _clamp(newValue, min, max);
  }

  static T _clamp<T extends num>(T value, T min, T max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  String toStringAsFixed(int fractionDigits) {
    return _value.toStringAsFixed(fractionDigits);
  }

  factory BoundedValue.fromJson(Map<String, dynamic> json) {
    return BoundedValue(
      value: json['value'],
      min: json['min'],
      max: json['max'],
    );
  }

  toJson() {
    return {
      'value': _value,
      'min': min,
      'max': max,
    };
  }
}

class UiVariables {
  final BoundedValue<double> fontSize;
  final BoundedValue<double> lineSpacing;
  final BoundedValue<int> sectionCount;
  final BoundedValue<double> columnWidth;
  final BoundedValue<double> columnSpacing;
  final BoundedValue<double> rowSpacing;

  UiVariables({
    // fontSize
    double fontSize = 16.0,
    double minFontSize = 8.0,
    double maxFontSize = 32.0,
    // linePadding
    double lineSpacing = 8.0,
    double minLineSpacing = 0.0,
    double maxLineSpacing = 20.0,
    // sectionCount
    int sectionCount = 4,
    int minSectionCount = 1,
    int maxSectionCount = 10,
    // columnWidth
    double columnWidth = 200.0,
    double minColumnWidth = 100.0,
    double maxColumnWidth = 400.0,
    // columnSpacing
    double columnSpacing = 8.0,
    double minColumnSpacing = 0.0,
    double maxColumnSpacing = 20.0,
    // rowSpacing
    double rowSpacing = 8.0,
    double minRowSpacing = 0.0,
    double maxRowSpacing = 20.0,
  })  : fontSize = BoundedValue<double>(
          value: fontSize,
          min: minFontSize,
          max: maxFontSize,
        ),
        lineSpacing = BoundedValue<double>(
          value: lineSpacing,
          min: minLineSpacing,
          max: maxLineSpacing,
        ),
        rowSpacing = BoundedValue<double>(
          value: lineSpacing,
          min: minLineSpacing,
          max: maxLineSpacing,
        ),
        columnSpacing = BoundedValue<double>(
          value: lineSpacing,
          min: minLineSpacing,
          max: maxLineSpacing,
        ),
        columnWidth = BoundedValue<double>(
          value: 200.0,
          min: 100.0,
          max: 400.0,
        ),
        sectionCount = BoundedValue<int>(
          value: sectionCount,
          min: minSectionCount,
          max: maxSectionCount,
        );

  isDifferent(UiVariables other) {
    return fontSize.value != other.fontSize.value ||
        lineSpacing.value != other.lineSpacing.value ||
        sectionCount.value != other.sectionCount.value;
  }

  factory UiVariables.fromJson(Map<String, dynamic> json) {
    return UiVariables(
      fontSize: json['fontSize']['value'],
      minFontSize: json['fontSize']['min'],
      maxFontSize: json['fontSize']['max'],
      lineSpacing: json['lineSpacing']['value'],
      minLineSpacing: json['lineSpacing']['min'],
      maxLineSpacing: json['lineSpacing']['max'],
      sectionCount: json['sectionCount']['value'],
      minSectionCount: json['sectionCount']['min'],
      maxSectionCount: json['sectionCount']['max'],
      columnWidth: json['columnWidth']['value'],
      minColumnWidth: json['columnWidth']['min'],
      maxColumnWidth: json['columnWidth']['max'],
      columnSpacing: json['columnSpacing']['value'],
      minColumnSpacing: json['columnSpacing']['min'],
      maxColumnSpacing: json['columnSpacing']['max'],
      rowSpacing: json['rowSpacing']['value'],
      minRowSpacing: json['rowSpacing']['min'],
      maxRowSpacing: json['rowSpacing']['max'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize.toJson(),
      'lineSpacing': lineSpacing.toJson(),
      'sectionCount': sectionCount.toJson(),
      'columnWidth': columnWidth.toJson(),
      'columnSpacing': columnSpacing.toJson(),
      'rowSpacing': rowSpacing.toJson(),
    };
  }
}
