class InputField {
  final String id;
  String label;
  String? description;
  String? variableId; // The variable this field is linked to
  bool showInCalculation;
  
  InputField({
    required this.id,
    required this.label,
    this.description,
    this.variableId,
    this.showInCalculation = true,
  });
  
  InputField copyWith({
    String? label,
    String? description,
    String? variableId,
    bool? showInCalculation,
  }) {
    return InputField(
      id: id,
      label: label ?? this.label,
      description: description ?? this.description,
      variableId: variableId ?? this.variableId,
      showInCalculation: showInCalculation ?? this.showInCalculation,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'description': description,
      'variableId': variableId,
      'showInCalculation': showInCalculation,
    };
  }
  
  factory InputField.fromJson(Map<String, dynamic> json) {
    return InputField(
      id: json['id'],
      label: json['label'],
      description: json['description'],
      variableId: json['variableId'],
      showInCalculation: json['showInCalculation'] ?? true,
    );
  }
}
