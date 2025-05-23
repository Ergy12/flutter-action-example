import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:expressions/expressions.dart' as expr;
import '../models/variable_model.dart';
import '../models/formula_model.dart';
import '../models/input_field_model.dart';
import '../services/formula_interpreter.dart';

class CalculatorProvider extends ChangeNotifier {
  List<Variable> _variables = [];
  List<Formula> _formulas = [];
  List<InputField> _inputFields = [];
  Map<String, dynamic> _inputValues = {};
  Map<String, dynamic> _results = {};
  final FormulaInterpreter _interpreter = FormulaInterpreter();
  
  List<Variable> get variables => _variables;
  List<Formula> get formulas => _formulas;
  List<InputField> get inputFields => _inputFields;
  Map<String, dynamic> get inputValues => _inputValues;
  Map<String, dynamic> get results => _results;
  
  CalculatorProvider() {
    _interpreter.initialize();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load variables
    final variablesJson = prefs.getString('variables');
    if (variablesJson != null) {
      final variablesList = jsonDecode(variablesJson) as List;
      _variables = variablesList.map((v) => Variable.fromJson(v)).toList();
    }
    
    // Load formulas
    final formulasJson = prefs.getString('formulas');
    if (formulasJson != null) {
      final formulasList = jsonDecode(formulasJson) as List;
      _formulas = formulasList.map((f) => Formula.fromJson(f)).toList();
    }
    
    // Load input fields
    final inputFieldsJson = prefs.getString('inputFields');
    if (inputFieldsJson != null) {
      final inputFieldsList = jsonDecode(inputFieldsJson) as List;
      _inputFields = inputFieldsList.map((i) => InputField.fromJson(i)).toList();
    }
    
    // Initialize input values with initial values from variables
    for (var variable in _variables) {
      _inputValues[variable.id] = variable.initialValue;
    }
    
    notifyListeners();
  }
  
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final variablesJson = jsonEncode(_variables.map((v) => v.toJson()).toList());
    await prefs.setString('variables', variablesJson);
    
    final formulasJson = jsonEncode(_formulas.map((f) => f.toJson()).toList());
    await prefs.setString('formulas', formulasJson);
    
    final inputFieldsJson = jsonEncode(_inputFields.map((i) => i.toJson()).toList());
    await prefs.setString('inputFields', inputFieldsJson);
  }
  
  // Variable management
  Future<void> addVariable(Variable variable) async {
    _variables.add(variable);
    _inputValues[variable.id] = variable.initialValue;
    await _saveData();
    notifyListeners();
  }
  
  Future<void> updateVariable(Variable variable) async {
    final index = _variables.indexWhere((v) => v.id == variable.id);
    if (index != -1) {
      _variables[index] = variable;
      _inputValues[variable.id] = variable.initialValue;
      await _saveData();
      notifyListeners();
    }
  }
  
  Future<void> deleteVariable(String id) async {
    _variables.removeWhere((v) => v.id == id);
    _inputValues.remove(id);
    await _saveData();
    notifyListeners();
  }
  
  // Formula management
  Future<void> addFormula(Formula formula) async {
    _formulas.add(formula);
    await _saveData();
    notifyListeners();
    calculateResults();
  }
  
  Future<void> updateFormula(Formula formula) async {
    final index = _formulas.indexWhere((f) => f.id == formula.id);
    if (index != -1) {
      _formulas[index] = formula;
      await _saveData();
      notifyListeners();
      calculateResults();
    }
  }
  
  Future<void> deleteFormula(String id) async {
    _formulas.removeWhere((f) => f.id == id);
    await _saveData();
    notifyListeners();
    calculateResults();
  }
  
  // Input value management
  void setInputValue(String variableId, dynamic value) {
    _inputValues[variableId] = value;
    notifyListeners();
    calculateResults();
  }
  
  // Formula calculation
  void calculateResults() {
    // Create a context with all variables
    Map<String, dynamic> context = {};
    
    // Add variable values to context map
    for (var variable in _variables) {
      dynamic value = _inputValues[variable.id] ?? variable.initialValue;
      
      if (variable.type == VariableType.number) {
        context[variable.name] = value is double ? value : double.tryParse(value.toString()) ?? 0.0;
      } else if (variable.type == VariableType.boolean) {
        context[variable.name] = value is bool ? value : value.toString() == 'true';
      } else {
        context[variable.name] = value.toString();
      }
    }
    
    // Evaluate each formula
    _results = {};
    for (var formula in _formulas) {
      try {
        if (!formula.isConditional) {
          // Evaluate normal formula
          if (formula.expression != null) {
            // Use the intelligent formula interpreter
            final result = _interpreter.evaluate(formula.expression!, context);
            _results[formula.name] = result;
            
            // Add formula result to context for use in subsequent formulas
            context[formula.name] = result;
          }
        } else {
          // Evaluate conditional formula
          dynamic result;
          bool conditionMet = false;
          
          if (formula.conditions != null) {
            for (var condition in formula.conditions!) {
              // Use the intelligent formula interpreter for condition
              final conditionResult = _interpreter.evaluate(condition.condition, context);
              
              if (conditionResult == true) {
                // Condition is true, evaluate the result expression
                result = _interpreter.evaluate(condition.resultExpression, context);
                conditionMet = true;
                break;
              }
            }
          }
          
          // If no condition was met, use default expression
          if (!conditionMet && formula.defaultExpression != null) {
            result = _interpreter.evaluate(formula.defaultExpression!, context);
          }
          
          _results[formula.name] = result;
          
          // Add formula result to context for use in subsequent formulas
          if (result != null) {
            context[formula.name] = result;
          }
        }
      } catch (e) {
        _results[formula.name] = 'Error: ${e.toString()}';
      }
    }
    
    notifyListeners();
  }
  
  // Helper for creating new variable
  Variable createNewVariable({
    required String name,
    String? description,
    required VariableType type,
    required dynamic initialValue,
    List<String>? options,
  }) {
    return Variable(
      id: const Uuid().v4(),
      name: name,
      description: description,
      type: type,
      initialValue: initialValue,
      options: options,
    );
  }
  
  // Helper for creating new formula
  Formula createNewFormula({
    required String name,
    String? expression,
    bool isConditional = false,
    List<Condition>? conditions,
    String? defaultExpression,
  }) {
    return Formula(
      id: const Uuid().v4(),
      name: name,
      expression: expression,
      isConditional: isConditional,
      conditions: conditions,
      defaultExpression: defaultExpression,
    );
  }
  
  // Input field management
  Future<void> addInputField(InputField inputField) async {
    _inputFields.add(inputField);
    await _saveData();
    notifyListeners();
  }
  
  Future<void> updateInputField(InputField inputField) async {
    final index = _inputFields.indexWhere((f) => f.id == inputField.id);
    if (index != -1) {
      _inputFields[index] = inputField;
      await _saveData();
      notifyListeners();
    }
  }
  
  Future<void> deleteInputField(String id) async {
    _inputFields.removeWhere((f) => f.id == id);
    await _saveData();
    notifyListeners();
  }
  
  // Helper for creating new input field
  InputField createNewInputField({
    required String label,
    String? description,
    String? variableId,
    bool showInCalculation = true,
  }) {
    return InputField(
      id: const Uuid().v4(),
      label: label,
      description: description,
      variableId: variableId,
      showInCalculation: showInCalculation,
    );
  }
  
  // New method to validate a formula
  ValidationResult validateFormula(String expression) {
    return _interpreter.validate(expression, _variables);
  }
  
  // New method to get suggestions for formula completion
  List<Suggestion> getFormulaSuggestions(String partialExpression) {
    return _interpreter.generateSuggestions(partialExpression, _variables);
  }
}
