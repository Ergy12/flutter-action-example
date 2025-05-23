import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/variable_model.dart';
import '../models/formula_model.dart';
import '../providers/calculator_provider.dart';
import '../services/formula_interpreter.dart';

class IntelligentFormulaBuilder extends StatefulWidget {
  final TextEditingController formulaController;
  final List<Variable> variables;
  final bool isCondition;
  final Function(String)? onSuggestionSelected;

  const IntelligentFormulaBuilder({
    super.key,
    required this.formulaController,
    required this.variables,
    this.isCondition = false,
    this.onSuggestionSelected,
  });

  @override
  State<IntelligentFormulaBuilder> createState() => _IntelligentFormulaBuilderState();
}

class _IntelligentFormulaBuilderState extends State<IntelligentFormulaBuilder> {
  final FormulaInterpreter _interpreter = FormulaInterpreter();
  List<Suggestion> _suggestions = [];
  ValidationResult? _validationResult;
  bool _showSuggestions = false;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _interpreter.initialize();
    widget.formulaController.addListener(_onFormulaChanged);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _updateSuggestions();
        setState(() {
          _showSuggestions = true;
        });
      } else {
        setState(() {
          _showSuggestions = false;
        });
      }
    });
  }

  @override
  void dispose() {
    widget.formulaController.removeListener(_onFormulaChanged);
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFormulaChanged() {
    _updateSuggestions();
    _validateFormula();
  }

  void _updateSuggestions() {
    final currentText = widget.formulaController.text;
    final suggestions = _interpreter.generateSuggestions(
      currentText,
      widget.variables,
    );

    setState(() {
      _suggestions = suggestions;
    });
  }

  void _validateFormula() {
    final currentText = widget.formulaController.text;
    if (currentText.isEmpty) {
      setState(() {
        _validationResult = null;
      });
      return;
    }

    final result = _interpreter.validate(currentText, widget.variables);
    setState(() {
      _validationResult = result;
    });
  }

  void _insertSuggestion(Suggestion suggestion) {
    final currentText = widget.formulaController.text;
    final selection = widget.formulaController.selection;
    
    // Handle different types of suggestions
    String textToInsert = suggestion.text;
    if (suggestion.type == SuggestionType.operator) {
      // Add spaces around operators
      if (!["!", "(", ")"].contains(textToInsert)) {
        textToInsert = " $textToInsert ";
      }
    } else if (suggestion.type == SuggestionType.function) {
      textToInsert = "${textToInsert}(";
    }
    
    // Insert the text
    final newText = currentText.substring(0, selection.start) + 
                   textToInsert + 
                   currentText.substring(selection.end);
    
    // Update the controller
    widget.formulaController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + textToInsert.length,
      ),
    );
    
    // Notify parent if needed
    if (widget.onSuggestionSelected != null) {
      widget.onSuggestionSelected!(textToInsert);
    }
    
    // Update suggestions and validation
    _updateSuggestions();
    _validateFormula();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Formula text field with syntax highlighting
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _validationResult == null || _validationResult!.isValid
                  ? theme.colorScheme.outline
                  : theme.colorScheme.error,
              width: 1,
            ),
          ),
          child: TextField(
            controller: widget.formulaController,
            focusNode: _focusNode,
            style: theme.textTheme.bodyLarge,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: widget.isCondition 
                  ? 'Entrez une condition (ex: age > 18 && statut == "actif")' 
                  : 'Entrez une formule (ex: salaire_base * (1 + bonus))',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
              isDense: true,
            ),
          ),
        ),
        
        // Validation error message
        if (_validationResult != null && !_validationResult!.isValid)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: Text(
              _validationResult!.message ?? 'Invalid formula',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        
        // Quick access buttons for variables and operators
        const SizedBox(height: 12),
        Text(
          'Variables',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: widget.variables.map((variable) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  avatar: Icon(
                    _getIconForVariableType(variable.type),
                    size: 16,
                    color: theme.colorScheme.onPrimary,
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  label: Text(
                    variable.name,
                    style: TextStyle(color: theme.colorScheme.onPrimary),
                  ),
                  onPressed: () {
                    _insertSuggestion(Suggestion(
                      text: variable.name,
                      type: SuggestionType.variable,
                      description: variable.description ?? '',
                      priority: 10,
                    ));
                  },
                  tooltip: variable.description,
                ),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 12),
        Text(
          widget.isCondition ? 'Opérateurs logiques' : 'Opérateurs',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _buildOperatorChips(theme),
          ),
        ),
        
        // Suggestions list when typing
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: Icon(_getIconForSuggestion(suggestion)),
                  title: Text(suggestion.text),
                  subtitle: Text(
                    suggestion.description,
                    style: theme.textTheme.bodySmall,
                  ),
                  onTap: () {
                    _insertSuggestion(suggestion);
                    // Hide suggestions after selection
                    setState(() {
                      _showSuggestions = false;
                    });
                    // Keep focus on the text field
                    _focusNode.requestFocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  List<Widget> _buildOperatorChips(ThemeData theme) {
    final operatorGroups = widget.isCondition 
        ? [
            ['==', '!=', '<', '>', '<=', '>='],
            ['&&', '||', '!'],
            ['(', ')'],
          ]
        : [
            ['+', '-', '*', '/'],
            ['(', ')'],
          ];
    
    final List<Widget> chips = [];
    
    for (var group in operatorGroups) {
      for (var op in group) {
        chips.add(
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              backgroundColor: theme.colorScheme.secondary,
              label: Text(
                op,
                style: TextStyle(color: theme.colorScheme.onSecondary),
              ),
              onPressed: () {
                _insertSuggestion(Suggestion(
                  text: op,
                  type: SuggestionType.operator,
                  description: _getOperatorDescription(op),
                  priority: 8,
                ));
              },
              tooltip: _getOperatorDescription(op),
            ),
          ),
        );
      }
      
      // Add separator between groups
      if (group != operatorGroups.last) {
        chips.add(const VerticalDivider(width: 16, indent: 8, endIndent: 8));
      }
    }
    
    return chips;
  }

  IconData _getIconForVariableType(VariableType type) {
    switch (type) {
      case VariableType.number:
        return Icons.numbers;
      case VariableType.text:
        return Icons.text_fields;
      case VariableType.boolean:
        return Icons.check_circle_outline;
      case VariableType.selection:
        return Icons.list_alt;
      default:
        return Icons.category;
    }
  }

  IconData _getIconForSuggestion(Suggestion suggestion) {
    switch (suggestion.type) {
      case SuggestionType.variable:
        return Icons.data_array;
      case SuggestionType.operator:
        return Icons.calculate;
      case SuggestionType.function:
        return Icons.functions;
      case SuggestionType.template:
        return Icons.auto_awesome;
      default:
        return Icons.code;
    }
  }

  String _getOperatorDescription(String op) {
    switch (op) {
      case '+': return 'Addition';
      case '-': return 'Soustraction';
      case '*': return 'Multiplication';
      case '/': return 'Division';
      case '%': return 'Modulo';
      case '&&': return 'ET logique';
      case '||': return 'OU logique';
      case '!': return 'NON logique';
      case '==': return 'Égal à';
      case '!=': return 'Différent de';
      case '<': return 'Inférieur à';
      case '>': return 'Supérieur à';
      case '<=': return 'Inférieur ou égal à';
      case '>=': return 'Supérieur ou égal à';
      case '(': return 'Parenthèse ouvrante';
      case ')': return 'Parenthèse fermante';
      default: return op;
    }
  }
}
