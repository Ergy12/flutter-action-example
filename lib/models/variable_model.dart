class Variable {
  final String id;
  String name;
  String? description;
  VariableType type;
  dynamic initialValue;
  List<String>? options;
  
  Variable({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.initialValue,
    this.options,
  });
  
  Variable copyWith({
    String? name,
    String? description,
    VariableType? type,
    dynamic initialValue,
    List<String>? options,
  }) {
    return Variable(
      id: this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      initialValue: initialValue ?? this.initialValue,
      options: options ?? this.options,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString(),
      'initialValue': initialValue.toString(),
      'options': options,
    };
  }
  
  factory Variable.fromJson(Map<String, dynamic> json) {
    VariableType type;
    switch(json['type']) {
      case 'VariableType.number':
        type = VariableType.number;
        break;
      case 'VariableType.text':
        type = VariableType.text;
        break;
      case 'VariableType.boolean':
        type = VariableType.boolean;
        break;
      case 'VariableType.selection':
        type = VariableType.selection;
        break;
      default:
        type = VariableType.number;
    }
    
    dynamic initialValue = json['initialValue'];
    if (type == VariableType.number) {
      initialValue = double.tryParse(json['initialValue']) ?? 0;
    } else if (type == VariableType.boolean) {
      initialValue = json['initialValue'] == 'true';
    }
    
    return Variable(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: type,
      initialValue: initialValue,
      options: json['options'] != null ? List<String>.from(json['options']) : null,
    );
  }
}

enum VariableType {
  number,
  text,
  boolean,
  selection
}
