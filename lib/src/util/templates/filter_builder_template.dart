import 'package:dart_style/dart_style.dart';

/// Generates the OData filter builder infrastructure utility.
class FilterBuilderTemplate {
  /// Formats the given [code] using DartFormatter.
  String format(String code) {
    return DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format(code);
  }

  /// Generates the OData filter builder utility.
  ///
  /// This produces a static infrastructure file (like `odata_query.dart`)
  /// containing `ODataFieldType`, `ODataFilterOp`, `ODataFilterEntry`,
  /// and `ODataFilterBuilder` with IFS Cloud enum support.
  String generate() {
    return format(r'''

/// OData v4 field data types for filter expression formatting.
enum ODataFieldType {
  /// String field — supports contains, startswith, eq.
  string,

  /// Numeric field (int/double) — supports eq, ne, lt, le, gt, ge.
  number,

  /// DateTime field — supports eq, lt, le, gt, ge, between.
  date,

  /// DateTimeOffset field — supports eq, lt, le, gt, ge, between.
  dateTime,

  /// Enum field — supports eq (uses string value).
  enumType,

  /// Boolean field — supports eq.
  boolType,
}

/// OData v4 filter operators.
enum ODataFilterOp {
  /// Equality: `Field eq 'value'`
  eq,

  /// Not equal: `Field ne 'value'`
  ne,

  /// Less than: `Field lt value`
  lt,

  /// Less or equal: `Field le value`
  le,

  /// Greater than: `Field gt value`
  gt,

  /// Greater or equal: `Field ge value`
  ge,

  /// String contains: `contains(Field,'value')`
  contains,

  /// String starts with: `startswith(Field,'value')`
  startswith,

  /// Between (date/number): generates `Field ge X and Field le Y`
  between,
}

/// Human-readable labels for filter operators.
extension ODataFilterOpLabel on ODataFilterOp {
  /// Returns a human-readable label.
  String get label {
    switch (this) {
      case ODataFilterOp.eq:
        return 'equals';
      case ODataFilterOp.ne:
        return 'not equal';
      case ODataFilterOp.lt:
        return 'less than';
      case ODataFilterOp.le:
        return '≤';
      case ODataFilterOp.gt:
        return 'greater than';
      case ODataFilterOp.ge:
        return '≥';
      case ODataFilterOp.contains:
        return 'contains';
      case ODataFilterOp.startswith:
        return 'starts with';
      case ODataFilterOp.between:
        return 'between';
    }
  }
}

/// Describes a single OData filter entry.
class ODataFilterEntry {
  /// Creates a new [ODataFilterEntry].
  const ODataFilterEntry({
    required this.odataField,
    required this.op,
    required this.fieldType,
    this.label,
    this.value,
    this.valueTo,
    this.selectedValues = const {},
    this.enumQualifier,
    this.allowedOps,
  });

  /// The OData field name (e.g. `RequisitionNo`).
  final String odataField;

  /// The filter operator.
  final ODataFilterOp op;

  /// The field data type.
  final ODataFieldType fieldType;

  /// A human-readable label for the field.
  final String? label;

  /// The filter value (for non-enum types).
  final String? value;

  /// The upper bound for between operators.
  final String? valueTo;

  /// Selected enum values (for enum type).
  final Set<String> selectedValues;

  /// IFS Cloud enum qualifier (e.g.
  /// `IfsApp.PurchaseRequisitionHandling.PurchaseRequisitionState`).
  final String? enumQualifier;

  /// Allowed operators for this field.
  final List<ODataFilterOp>? allowedOps;
}

/// Describes a filterable field configuration for a specific entity.
class FilterFieldConfig {
  /// Creates a new [FilterFieldConfig].
  const FilterFieldConfig({
    required this.odataField,
    required this.label,
    required this.fieldType,
    this.enumQualifier,
    this.enumValues = const [],
  });

  /// The OData field name.
  final String odataField;

  /// Human-readable label.
  final String label;

  /// The OData field type.
  final ODataFieldType fieldType;

  /// IFS Cloud enum qualifier (for enum fields only).
  final String? enumQualifier;

  /// Available enum values (for enum fields only).
  final List<String> enumValues;
}

/// Builds OData `$filter` expressions from a list of [ODataFilterEntry].
class ODataFilterBuilder {
  ODataFilterBuilder._();

  /// Builds a combined `$filter` expression from a list of entries.
  ///
  /// Returns `null` if no valid expressions are produced.
  static String? build(List<ODataFilterEntry> entries) {
    final parts = <String>[];
    for (final entry in entries) {
      final hasValue = entry.fieldType == ODataFieldType.enumType
          ? entry.selectedValues.isNotEmpty
          : entry.value != null && entry.value!.isNotEmpty;
      if (!hasValue) continue;
      final expr = _buildExpression(entry);
      if (expr != null) parts.add(expr);
    }
    return parts.isEmpty ? null : parts.join(' and ');
  }

  static String? _buildExpression(ODataFilterEntry entry) {
    switch (entry.fieldType) {
      case ODataFieldType.string:
        return _stringExpr(entry);
      case ODataFieldType.number:
        return _numberExpr(entry);
      case ODataFieldType.date:
      case ODataFieldType.dateTime:
        return _dateExpr(entry);
      case ODataFieldType.enumType:
        return _enumExpr(entry);
      case ODataFieldType.boolType:
        return _boolExpr(entry);
    }
  }

  static String? _stringExpr(ODataFilterEntry e) {
    if (e.value == null || e.value!.isEmpty) return null;
    switch (e.op) {
      case ODataFilterOp.contains:
        return "contains(${e.odataField},'${e.value}')";
      case ODataFilterOp.startswith:
        return "startswith(${e.odataField},'${e.value}')";
      case ODataFilterOp.ne:
        return "${e.odataField} ne '${e.value}'";
      case ODataFilterOp.eq:
      case ODataFilterOp.lt:
      case ODataFilterOp.le:
      case ODataFilterOp.gt:
      case ODataFilterOp.ge:
      case ODataFilterOp.between:
        // Default text-based matcher fallback is exact equality
        return "${e.odataField} eq '${e.value}'";
    }
  }

  static String? _numberExpr(ODataFilterEntry e) {
    if (e.value == null || e.value!.isEmpty) return null;
    if (e.op == ODataFilterOp.between && e.valueTo != null) {
      return '(${e.odataField} ge ${e.value} and '
          '${e.odataField} le ${e.valueTo})';
    }
    return '${e.odataField} ${e.op.name} ${e.value}';
  }

  static String? _dateExpr(ODataFilterEntry e) {
    if (e.value == null || e.value!.isEmpty) return null;
    if (e.op == ODataFilterOp.between && e.valueTo != null) {
      return '(${e.odataField} ge ${e.value} and '
          '${e.odataField} le ${e.valueTo})';
    }
    return '${e.odataField} ${e.op.name} ${e.value}';
  }

  static String? _enumExpr(ODataFilterEntry e) {
    if (e.selectedValues.isEmpty) return null;
    final qualifier = e.enumQualifier ?? e.odataField;
    if (e.selectedValues.length == 1) {
      return "${e.odataField} eq $qualifier'${e.selectedValues.first}'";
    }
    final conditions = e.selectedValues
        .map((v) => "${e.odataField} eq $qualifier'$v'")
        .join(' or ');
    return '($conditions)';
  }

  static String? _boolExpr(ODataFilterEntry e) {
    if (e.value == null || e.value!.isEmpty) return null;
    return '${e.odataField} eq ${e.value}';
  }
}
''');
  }
}
