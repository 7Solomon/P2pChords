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
  final Map<String, BoundedValue> _variables = {};

  // Variable definitions with default values and ranges
  static final Map<String, Map<String, dynamic>> _variableDefinitions = {
    'fontSize': {'default': 16.0, 'min': 8.0, 'max': 32.0, 'type': double},
    'lineSpacing': {'default': 8.0, 'min': 0.0, 'max': 20.0, 'type': double},
    'rowSpacing': {'default': 8.0, 'min': 0.0, 'max': 20.0, 'type': double},
    'columnSpacing': {'default': 8.0, 'min': 0.0, 'max': 20.0, 'type': double},
    'columnWidth': {
      'default': 200.0,
      'min': 100.0,
      'max': 400.0,
      'type': double
    },
    'rowHeight': {'default': 50.0, 'min': 20.0, 'max': 100.0, 'type': double},
    'sectionCount': {'default': 4, 'min': 1, 'max': 10, 'type': int},
  };

  UiVariables({
    Map<String, dynamic>? initialValues,
  }) {
    // Initialize all variables with default values
    _variableDefinitions.forEach((key, definition) {
      final value = initialValues?[key] ?? definition['default'];
      final min = initialValues?['min$key'] ?? definition['min'];
      final max = initialValues?['max$key'] ?? definition['max'];

      if (definition['type'] == int) {
        _variables[key] = BoundedValue<int>(
          value: value,
          min: min,
          max: max,
        );
      } else {
        _variables[key] = BoundedValue<double>(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
        );
      }
    });
  }

  // Getter methods for all variables
  BoundedValue<double> get fontSize =>
      _variables['fontSize'] as BoundedValue<double>;
  BoundedValue<double> get lineSpacing =>
      _variables['lineSpacing'] as BoundedValue<double>;
  BoundedValue<double> get rowSpacing =>
      _variables['rowSpacing'] as BoundedValue<double>;
  BoundedValue<double> get columnSpacing =>
      _variables['columnSpacing'] as BoundedValue<double>;
  BoundedValue<double> get columnWidth =>
      _variables['columnWidth'] as BoundedValue<double>;
  BoundedValue<double> get rowHeight =>
      _variables['rowHeight'] as BoundedValue<double>;
  BoundedValue<int> get sectionCount =>
      _variables['sectionCount'] as BoundedValue<int>;

  // Get a property by name - for dynamic access
  BoundedValue getProperty(String propertyName) {
    if (!_variables.containsKey(propertyName)) {
      throw ArgumentError('Unknown property: $propertyName');
    }
    return _variables[propertyName]!;
  }

  bool isDifferent(UiVariables other) {
    return _variableDefinitions.keys.any((key) {
      return _variables[key]!.value != other._variables[key]!.value;
    });
  }

  factory UiVariables.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> initialValues = {};

    _variableDefinitions.keys.forEach((key) {
      if (json.containsKey(key)) {
        initialValues[key] = json[key]['value'];
        initialValues['min$key'] = json[key]['min'];
        initialValues['max$key'] = json[key]['max'];
      }
    });

    return UiVariables(initialValues: initialValues);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {};

    _variableDefinitions.keys.forEach((key) {
      result[key] = _variables[key]!.toJson();
    });

    return result;
  }
}
