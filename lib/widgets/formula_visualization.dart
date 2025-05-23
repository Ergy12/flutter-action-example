import 'package:flutter/material.dart';
import '../models/formula_model.dart';
import '../models/variable_model.dart';
import '../providers/calculator_provider.dart';
import '../services/formula_interpreter.dart';

class FormulaVisualization extends StatefulWidget {
  final Formula formula;
  final List<Variable> variables;
  final Map<String, dynamic> currentValues;

  const FormulaVisualization({
    super.key,
    required this.formula,
    required this.variables,
    required this.currentValues,
  });

  @override
  State<FormulaVisualization> createState() => _FormulaVisualizationState();
}

class _FormulaVisualizationState extends State<FormulaVisualization> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  Map<String, dynamic> _testValues = {};
  Map<String, dynamic> _evaluationResults = {};
  int? _activeConditionIndex;
  final FormulaInterpreter _interpreter = FormulaInterpreter();

  @override
  void initState() {
    super.initState();
    _interpreter.initialize();
    _testValues = Map.from(widget.currentValues);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _evaluateFormula();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FormulaVisualization oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.formula.id != widget.formula.id ||
        oldWidget.currentValues != widget.currentValues) {
      _testValues = Map.from(widget.currentValues);
      _evaluateFormula();
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _evaluateFormula() {
    setState(() {
      _evaluationResults = {};
      _activeConditionIndex = null;
    });

    // Prepare context with variable values
    Map<String, dynamic> context = {};
    for (var variable in widget.variables) {
      final value = _testValues[variable.id] ?? variable.initialValue;
      context[variable.name] = value;
    }

    try {
      if (!widget.formula.isConditional) {
        // Evaluate standard formula
        if (widget.formula.expression != null) {
          final result = _interpreter.evaluate(widget.formula.expression!, context);
          setState(() {
            _evaluationResults['result'] = result;
          });
        }
      } else {
        // Evaluate each condition
        bool conditionMet = false;
        int conditionIndex = 0;

        if (widget.formula.conditions != null) {
          for (var condition in widget.formula.conditions!) {
            final conditionResult = _interpreter.evaluate(condition.condition, context);
            _evaluationResults['condition_$conditionIndex'] = conditionResult;

            if (conditionResult == true) {
              final result = _interpreter.evaluate(condition.resultExpression, context);
              _evaluationResults['result_$conditionIndex'] = result;
              _evaluationResults['result'] = result;
              conditionMet = true;
              setState(() {
                _activeConditionIndex = conditionIndex;
              });
              break;
            }
            conditionIndex++;
          }
        }

        // Use default expression if no condition is met
        if (!conditionMet && widget.formula.defaultExpression != null) {
          final result = _interpreter.evaluate(widget.formula.defaultExpression!, context);
          _evaluationResults['default_result'] = result;
          _evaluationResults['result'] = result;
        }
      }
    } catch (e) {
      setState(() {
        _evaluationResults['error'] = e.toString();
      });
    }
  }

  void _updateTestValue(String variableId, dynamic value) {
    setState(() {
      _testValues[variableId] = value;
    });
    _evaluateFormula();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header and result card
          _buildResultCard(theme),
          
          const SizedBox(height: 16),
          
          // Variable test inputs
          _buildVariableTestInputs(theme),
          
          const SizedBox(height: 24),
          
          // Formula flow visualization
          if (widget.formula.isConditional)
            _buildConditionalFlowVisualization(theme)
          else
            _buildSimpleFormulaVisualization(theme),
        ],
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme) {
    final resultValue = _evaluationResults['result'];
    final hasError = _evaluationResults.containsKey('error');

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: hasError ? theme.colorScheme.errorContainer : theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasError ? Icons.error_outline : Icons.functions,
                  color: hasError ? theme.colorScheme.error : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.formula.name,
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                if (!hasError)
                  Chip(
                    label: Text(
                      'Résultat: ${_formatValue(resultValue)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (hasError)
              Text(
                'Erreur: ${_evaluationResults['error']}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariableTestInputs(ThemeData theme) {
    final relevantVariables = widget.variables.where((v) => 
      widget.formula.isConditional ? 
        // For conditional formulas, show all variables that might be used
        true : 
        // For standard formulas, only show variables used in the expression
        widget.formula.expression != null && widget.formula.expression!.contains(v.name)
    ).toList();

    if (relevantVariables.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tester avec différentes valeurs',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: relevantVariables.map((variable) {
            return _buildVariableTestInput(variable, theme);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVariableTestInput(Variable variable, ThemeData theme) {
    final currentValue = _testValues[variable.id] ?? variable.initialValue;

    switch (variable.type) {
      case VariableType.number:
        return SizedBox(
          width: 180,
          child: TextField(
            decoration: InputDecoration(
              labelText: variable.name,
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: () => _updateTestValue(variable.id, variable.initialValue),
                tooltip: 'Réinitialiser',
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            controller: TextEditingController(text: currentValue.toString()),
            onChanged: (value) {
              double? numValue = double.tryParse(value);
              if (numValue != null) {
                _updateTestValue(variable.id, numValue);
              }
            },
          ),
        );

      case VariableType.boolean:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(variable.name),
            const SizedBox(width: 8),
            Switch(
              value: currentValue == true,
              onChanged: (value) {
                _updateTestValue(variable.id, value);
              },
            ),
          ],
        );

      case VariableType.selection:
        return variable.options != null && variable.options!.isNotEmpty
            ? SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: variable.name,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  value: currentValue.toString(),
                  items: variable.options!.map((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _updateTestValue(variable.id, value);
                    }
                  },
                ),
              )
            : const SizedBox();

      case VariableType.text:
      default:
        return SizedBox(
          width: 180,
          child: TextField(
            decoration: InputDecoration(
              labelText: variable.name,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            controller: TextEditingController(text: currentValue.toString()),
            onChanged: (value) {
              _updateTestValue(variable.id, value);
            },
          ),
        );
    }
  }

  Widget _buildConditionalFlowVisualization(ThemeData theme) {
    if (widget.formula.conditions == null || widget.formula.conditions!.isEmpty) {
      return const Text('Pas de conditions définies');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Flux de logique conditionnelle',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 16),
        ...List.generate(widget.formula.conditions!.length, (index) {
          final condition = widget.formula.conditions![index];
          final isActive = _activeConditionIndex == index;
          final conditionResult = _evaluationResults['condition_$index'];
          final resultValue = _evaluationResults['result_$index'];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildConditionStep(
              theme: theme,
              index: index,
              condition: condition.condition,
              resultExpression: condition.resultExpression,
              isActive: isActive,
              conditionResult: conditionResult,
              resultValue: resultValue,
            ),
          );
        }),
        
        // Default result
        if (widget.formula.defaultExpression != null)
          _buildDefaultResultStep(
            theme: theme,
            defaultExpression: widget.formula.defaultExpression!,
            isActive: _activeConditionIndex == null,
            resultValue: _evaluationResults['default_result'],
          ),
      ],
    );
  }

  Widget _buildConditionStep({
    required ThemeData theme,
    required int index,
    required String condition,
    required String resultExpression,
    required bool isActive,
    required dynamic conditionResult,
    required dynamic resultValue,
  }) {
    final conditionMet = conditionResult == true;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isActive
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Condition header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: isActive
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Condition ${index + 1}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isActive
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (conditionResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: conditionMet
                          ? Colors.green
                          : Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      conditionMet ? 'Vrai' : 'Faux',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Condition expression
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Si:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Text(
                    condition,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                Text(
                  'Alors:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Text(
                    resultExpression,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                if (isActive && resultValue != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calculate,
                          color: theme.colorScheme.onSecondaryContainer,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Résultat: ${_formatValue(resultValue)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultResultStep({
    required ThemeData theme,
    required String defaultExpression,
    required bool isActive,
    required dynamic resultValue,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isActive
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Default header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: isActive
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Valeur par défaut',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isActive
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Actif',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Default expression
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sinon:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Text(
                    defaultExpression,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                if (isActive && resultValue != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calculate,
                          color: theme.colorScheme.onSecondaryContainer,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Résultat: ${_formatValue(resultValue)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleFormulaVisualization(ThemeData theme) {
    if (widget.formula.expression == null) {
      return const Text('Aucune formule définie');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expression de la formule',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Text(
            widget.formula.expression!,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calculate,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Text(
                'Résultat: ${_formatValue(_evaluationResults['result'])}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) {
      return 'Non défini';
    } else if (value is double) {
      // Format double to 2 decimal places if needed
      return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    } else {
      return value.toString();
    }
  }
}
