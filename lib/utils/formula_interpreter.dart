import 'package:flutter/material.dart';
import 'package:petitparser/petitparser.dart';
import '../models/variable_model.dart';

class FormulaInterpreter {
  // Singleton pattern
  static final FormulaInterpreter _instance = FormulaInterpreter._internal();
  factory FormulaInterpreter() => _instance;
  FormulaInterpreter._internal();
  
  late Parser _expressionParser;
  bool _isInitialized = false;
  
  // Initialize the parser
  void initialize() {
    if (_isInitialized) return;
    
    final builder = ExpressionBuilder();
    
    // Define literals
    builder.group()
      ..primitive(digit().plus().seq(char('.').seq(digit().plus()).optional())
          .flatten().trim().map((value) => double.parse(value)))
      ..primitive(string('true').flatten().trim().map((_) => true))
      ..primitive(string('false').flatten().trim().map((_) => false))
      ..primitive(char('"').seq(any().starLazy(char('"'))).seq(char('"'))
          .flatten().trim().map((value) => value.substring(1, value.length - 1)))
      ..primitive(char('\'').seq(any().starLazy(char('\''))).seq(char('\''))
          .flatten().trim().map((value) => value.substring(1, value.length - 1)))
      ..primitive(letter().seq(word().star()).flatten().trim());
    
    // Define parentheses
    builder.group()
      ..wrapper(char('(').trim(), char(')').trim(), (_, value, __) => value);
    
    // Define operators with precedence
    // Unary operators
    builder.group()
      ..prefix(char('-').trim(), (op, value) => -value)
      ..prefix(char('!').trim(), (op, value) => !value);
    
    // Multiplicative operators
    builder.group()
      ..left(char('*').trim(), (a, _, b) => a * b)
      ..left(char('/').trim(), (a, _, b) => a / b)
      ..left(char('%').trim(), (a, _, b) => a % b);
    
    // Additive operators
    builder.group()
      ..left(char('+').trim(), (a, _, b) => a + b)
      ..left(char('-').trim(), (a, _, b) => a - b);
    
    // Relational operators
    builder.group()
      ..left(string('<=').trim(), (a, _, b) => _compare(a, b) <= 0)
      ..left(string('>=').trim(), (a, _, b) => _compare(a, b) >= 0)
      ..left(char('<').trim(), (a, _, b) => _compare(a, b) < 0)
      ..left(char('>').trim(), (a, _, b) => _compare(a, b) > 0);
    
    // Equality operators
    builder.group()
      ..left(string('==').trim(), (a, _, b) => _equals(a, b))
      ..left(string('!=').trim(), (a, _, b) => !_equals(a, b));
    
    // Logical AND
    builder.group()
      ..left(string('&&').trim(), (a, _, b) => a && b);
    
    // Logical OR
    builder.group()
      ..left(string('||').trim(), (a, _, b) => a || b);
    
    _expressionParser = builder.build().end();
    _isInitialized = true;
  }
  
  // Evaluate a formula expression with a context of variables
  dynamic evaluate(String expression, Map<String, dynamic> context) {
    if (!_isInitialized) initialize();
    
    try {
      final result = _expressionParser.parse(expression);
      if (result.isSuccess) {
        return _evaluateNode(result.value, context);
      } else {
        throw Exception('Invalid formula syntax: ${result.message}');
      }
    } catch (e) {
      throw Exception('Error evaluating formula: ${e.toString()}');
    }
  }
  
  // Helper method to evaluate a parsed node with variable substitution
  dynamic _evaluateNode(dynamic node, Map<String, dynamic> context) {
    if (node is num || node is bool || node is String) {
      return node;
    } else if (node is String) {
      // If the node is a variable name, look it up in the context
      if (context.containsKey(node)) {
        return context[node];
      }
      return node; // Return as string if not a variable
    } else {
      // This shouldn't happen with our parser
      throw Exception('Unknown node type: ${node.runtimeType}');
    }
  }
  
  // Validate a formula expression
  ValidationResult validate(String expression, List<Variable> availableVariables) {
    if (!_isInitialized) initialize();
    
    try {
      final result = _expressionParser.parse(expression);
      if (result.isSuccess) {
        // Check for undefined variables
        final Set<String> variableNames = {};
        for (var variable in availableVariables) {
          variableNames.add(variable.name);
        }
        
        final undefinedVariables = _findUndefinedVariables(result.value, variableNames);
        if (undefinedVariables.isNotEmpty) {
          return ValidationResult(
            isValid: false,
            message: 'Undefined variables: ${undefinedVariables.join(', ')}',
            undefinedVariables: undefinedVariables.toList(),
          );
        }
        
        return ValidationResult(isValid: true);
      } else {
        return ValidationResult(
          isValid: false,
          message: 'Invalid syntax: ${result.message}',
        );
      }
    } catch (e) {
      return ValidationResult(
        isValid: false,
        message: 'Validation error: ${e.toString()}',
      );
    }
  }
  
  // Find undefined variables in an expression
  Set<String> _findUndefinedVariables(dynamic node, Set<String> definedVariables) {
    // Implement recursive traversal to find variables
    // This is a placeholder - would need actual implementation
    return {};
  }
  
  // Generate suggestions for formula completion
  List<Suggestion> generateSuggestions(String partialExpression, List<Variable> availableVariables) {
    final List<Suggestion> suggestions = [];
    
    // Determine context - are we in a condition, value expression, etc.
    final context = _determineContext(partialExpression);
    
    // Add variable suggestions based on context
    for (var variable in availableVariables) {
      if (context == ExpressionContext.condition && variable.type == VariableType.boolean) {
        suggestions.add(Suggestion(
          text: variable.name,
          type: SuggestionType.variable,
          description: variable.description ?? 'Boolean variable',
          priority: 10,
        ));
      } else if (context == ExpressionContext.numeric && 
                (variable.type == VariableType.number)) {
        suggestions.add(Suggestion(
          text: variable.name,
          type: SuggestionType.variable,
          description: variable.description ?? 'Numeric variable',
          priority: 10,
        ));
      } else {
        // Add all other variables with lower priority
        suggestions.add(Suggestion(
          text: variable.name,
          type: SuggestionType.variable,
          description: variable.description ?? 'Variable',
          priority: 5,
        ));
      }
    }
    
    // Add operators based on context
    if (context == ExpressionContext.numeric) {
      _addOperatorSuggestions(suggestions, [
        '+', '-', '*', '/', '%'
      ]);
    } else if (context == ExpressionContext.condition) {
      _addOperatorSuggestions(suggestions, [
        '&&', '||', '!', '==', '!=', '<', '>', '<=', '>='
      ]);
    } else {
      // Add all operators for general context
      _addOperatorSuggestions(suggestions, [
        '+', '-', '*', '/', '%', '&&', '||', '!', '==', '!=', '<', '>', '<=', '>='
      ]);
    }
    
    // Sort suggestions by priority
    suggestions.sort((a, b) => b.priority.compareTo(a.priority));
    
    return suggestions;
  }
  
  // Helper to add operator suggestions
  void _addOperatorSuggestions(List<Suggestion> suggestions, List<String> operators) {
    for (var op in operators) {
      String description;
      switch (op) {
        case '+': description = 'Addition'; break;
        case '-': description = 'Subtraction'; break;
        case '*': description = 'Multiplication'; break;
        case '/': description = 'Division'; break;
        case '%': description = 'Modulo'; break;
        case '&&': description = 'Logical AND'; break;
        case '||': description = 'Logical OR'; break;
        case '!': description = 'Logical NOT'; break;
        case '==': description = 'Equal to'; break;
        case '!=': description = 'Not equal to'; break;
        case '<': description = 'Less than'; break;
        case '>': description = 'Greater than'; break;
        case '<=': description = 'Less than or equal to'; break;
        case '>=': description = 'Greater than or equal to'; break;
        default: description = op;
      }
      
      suggestions.add(Suggestion(
        text: op,
        type: SuggestionType.operator,
        description: description,
        priority: 8,
      ));
    }
  }
  
  // Determine context based on partial expression
  ExpressionContext _determineContext(String partialExpression) {
    // This would analyze the expression to determine if we're in a
    // numeric context, condition context, etc.
    // For now, we'll use a simple heuristic
    if (partialExpression.contains('==') || 
        partialExpression.contains('!=') || 
        partialExpression.contains('<') || 
        partialExpression.contains('>') || 
        partialExpression.contains('&&') || 
        partialExpression.contains('||')) {
      return ExpressionContext.condition;
    } else if (partialExpression.contains('+') || 
               partialExpression.contains('-') || 
               partialExpression.contains('*') || 
               partialExpression.contains('/')) {
      return ExpressionContext.numeric;
    }
    
    return ExpressionContext.general;
  }
  
  // Helper for comparing possibly different types
  int _compare(dynamic a, dynamic b) {
    if (a is num && b is num) {
      return a.compareTo(b);
    } else if (a is String && b is String) {
      return a.compareTo(b);
    } else {
      return a.toString().compareTo(b.toString());
    }
  }
  
  // Helper for equality check
  bool _equals(dynamic a, dynamic b) {
    if (a is num && b is num) {
      // Handle numerical precision issues
      if ((a - b).abs() < 1e-10) return true;
    }
    return a == b;
  }
}

// Validation result class
class ValidationResult {
  final bool isValid;
  final String? message;
  final List<String>? undefinedVariables;
  
  ValidationResult({
    required this.isValid,
    this.message,
    this.undefinedVariables,
  });
}

// Suggestion class for formula auto-completion
class Suggestion {
  final String text;
  final SuggestionType type;
  final String description;
  final int priority; // Higher values are shown first
  
  Suggestion({
    required this.text,
    required this.type,
    required this.description,
    required this.priority,
  });
}

// Suggestion types
enum SuggestionType {
  variable,
  operator,
  function,
  template
}

// Expression context for better suggestions
enum ExpressionContext {
  general,
  numeric,
  condition,
  string
}
