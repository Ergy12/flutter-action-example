class Formula {
  final String id;
  String name;
  String? expression;
  bool isConditional;
  List<Condition>? conditions;
  String? defaultExpression;
  
  Formula({
    required this.id,
    required this.name,
    this.expression,
    this.isConditional = false,
    this.conditions,
    this.defaultExpression,
  });
  
  Formula copyWith({
    String? name,
    String? expression,
    bool? isConditional,
    List<Condition>? conditions,
    String? defaultExpression,
  }) {
    return Formula(
      id: this.id,
      name: name ?? this.name,
      expression: expression ?? this.expression,
      isConditional: isConditional ?? this.isConditional,
      conditions: conditions ?? this.conditions,
      defaultExpression: defaultExpression ?? this.defaultExpression,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'expression': expression,
      'isConditional': isConditional,
      'conditions': conditions?.map((c) => c.toJson()).toList(),
      'defaultExpression': defaultExpression,
    };
  }
  
  factory Formula.fromJson(Map<String, dynamic> json) {
    return Formula(
      id: json['id'],
      name: json['name'],
      expression: json['expression'],
      isConditional: json['isConditional'] ?? false,
      conditions: json['conditions'] != null
          ? (json['conditions'] as List).map((i) => Condition.fromJson(i)).toList()
          : null,
      defaultExpression: json['defaultExpression'],
    );
  }
}

class Condition {
  String condition;
  String resultExpression;
  
  Condition({
    required this.condition,
    required this.resultExpression,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'resultExpression': resultExpression,
    };
  }
  
  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      condition: json['condition'],
      resultExpression: json['resultExpression'],
    );
  }
}
