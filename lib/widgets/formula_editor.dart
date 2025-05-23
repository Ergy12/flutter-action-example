import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/formula_model.dart';
import '../models/variable_model.dart';
import '../providers/calculator_provider.dart';
import '../services/formula_interpreter.dart';
import 'intelligent_formula_builder.dart';
import 'formula_visualization.dart';

class FormulaEditor extends StatefulWidget {
  final Formula? formula;

  const FormulaEditor({super.key, this.formula});

  @override
  State<FormulaEditor> createState() => _FormulaEditorState();
}

class _FormulaEditorState extends State<FormulaEditor> {
  late TextEditingController _nameController;
  late TextEditingController _expressionController;
  late TextEditingController _defaultExpressionController;
  bool _isConditional = false;
  List<Condition> _conditions = [];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _isEditing = widget.formula != null;
    
    if (_isEditing) {
      _nameController = TextEditingController(text: widget.formula!.name);
      _isConditional = widget.formula!.isConditional;
      
      if (_isConditional) {
        _conditions = widget.formula!.conditions?.toList() ?? [];
        _defaultExpressionController = TextEditingController(text: widget.formula!.defaultExpression ?? '');
      } else {
        _expressionController = TextEditingController(text: widget.formula!.expression ?? '');
      }
    } else {
      _nameController = TextEditingController();
      _expressionController = TextEditingController();
      _defaultExpressionController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _expressionController.dispose();
    _defaultExpressionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calculatorProvider = Provider.of<CalculatorProvider>(context);
    final variables = calculatorProvider.variables;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la formule' : 'Nouvelle formule'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildBasicInfo(),
              const SizedBox(height: 16),
              _buildFormulaTypeToggle(),
              const SizedBox(height: 16),
              _isConditional
                  ? _buildConditionalFormula(variables)
                  : _buildSimpleFormula(variables),
              const SizedBox(height: 24),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditing ? 'Modifier la formule' : 'Créer une nouvelle formule',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Les formules permettent de calculer des valeurs basées sur vos variables',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildBasicInfo() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nom de la formule',
        hintText: 'Ex: Prime d\'ancienneté',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.functions),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer un nom';
        }
        return null;
      },
    );
  }

  Widget _buildFormulaTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de formule',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(value: false, label: Text('Simple'), icon: Icon(Icons.calculate)),
            ButtonSegment<bool>(value: true, label: Text('Conditionnelle'), icon: Icon(Icons.rule)),
          ],
          selected: {_isConditional},
          onSelectionChanged: (Set<bool> newSelection) {
            setState(() {
              _isConditional = newSelection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSimpleFormula(List<Variable> variables) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expression',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Utilisez les variables et opérateurs pour créer votre formule',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        IntelligentFormulaBuilder(
          formulaController: _expressionController,
          variables: variables,
          isCondition: false,
          onSuggestionSelected: _insertTextAtCursor,
        ),
        const SizedBox(height: 16),
        // Live formula visualization with sample values
        if (_isEditing && _expressionController.text.isNotEmpty)
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Prévisualisation de la formule',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFormulaPreview(variables),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        // Legacy buttons for backward compatibility
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            children: [
              _buildVariableButtonsForController(variables, _expressionController),
              _buildOperatorButtonsForController(_expressionController),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Hidden text field for backward compatibility
        Offstage(
          offstage: true,
          child: TextFormField(
            controller: _expressionController,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  // Add a formula preview widget
  Widget _buildFormulaPreview(List<Variable> variables) {
    final formula = Formula(
      id: widget.formula?.id ?? 'preview',
      name: _nameController.text.isNotEmpty ? _nameController.text : 'Preview',
      expression: _isConditional ? null : _expressionController.text,
      isConditional: _isConditional,
      conditions: _isConditional ? _conditions : null,
      defaultExpression: _isConditional ? _defaultExpressionController.text : null,
    );
    
    // Create a map of sample values for visualization
    final Map<String, dynamic> sampleValues = {};
    for (var variable in variables) {
      sampleValues[variable.id] = variable.initialValue;
    }
    
    return FormulaVisualization(
      formula: formula,
      variables: variables,
      currentValues: sampleValues,
    );
  }

  Widget _buildConditionalFormula(List<Variable> variables) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Conditions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Ajouter condition'),
              onPressed: () => _addCondition(variables),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _conditions.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.rule,
                        size: 48,
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune condition définie',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cliquez sur "Ajouter condition" pour créer une règle conditionnelle',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _conditions.length,
                itemBuilder: (context, index) {
                  return _buildConditionCard(index, variables);
                },
              ),
        const SizedBox(height: 16),
        Text(
          'Expression par défaut (si aucune condition n\'est remplie)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        IntelligentFormulaBuilder(
          formulaController: _defaultExpressionController,
          variables: variables,
          isCondition: false,
          onSuggestionSelected: (text) => _insertTextToController(text, _defaultExpressionController),
        ),
      ],
    );
  }

  Widget _buildConditionCard(int index, List<Variable> variables) {
    final condition = _conditions[index];
    final conditionTextController = TextEditingController(text: condition.condition);
    final resultTextController = TextEditingController(text: condition.resultExpression);

    // Update condition when text changes
    conditionTextController.addListener(() {
      condition.condition = conditionTextController.text;
    });

    resultTextController.addListener(() {
      condition.resultExpression = resultTextController.text;
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  child: Text('${index + 1}'),
                ),
                const SizedBox(width: 12),
                Text(
                  'Condition',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () => _removeCondition(index),
                  tooltip: 'Supprimer cette condition',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Si',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            IntelligentFormulaBuilder(
              formulaController: conditionTextController,
              variables: variables,
              isCondition: true,
              onSuggestionSelected: (text) => _insertTextToController(text, conditionTextController),
            ),
            const SizedBox(height: 16),
            Text(
              'Alors',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            IntelligentFormulaBuilder(
              formulaController: resultTextController,
              variables: variables,
              isCondition: false,
              onSuggestionSelected: (text) => _insertTextToController(text, resultTextController),
            ),
          ],
        ),
      ),
    );
  }

  // Create a new method for variable buttons that inserts text into a specific controller
  Widget _buildVariableButtonsForController(List<Variable> variables, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5))),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: variables.map((variable) {
          return ActionChip(
            label: Text(variable.name),
            avatar: Icon(
              _getIconForVariableType(variable.type),
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
            onPressed: () {
              _insertTextToController(variable.name, controller);
            },
          );
        }).toList(),
      ),
    );
  }

  // We'll keep the original method for backward compatibility and delegate to the new method
  Widget _buildVariableButtons(List<Variable> variables) {
    return _buildVariableButtonsForController(variables, _isConditional ? _defaultExpressionController : _expressionController);
  }

  IconData _getIconForVariableType(VariableType type) {
    switch (type) {
      case VariableType.number:
        return Icons.numbers;
      case VariableType.text:
        return Icons.text_fields;
      case VariableType.boolean:
        return Icons.toggle_on_outlined;
      case VariableType.selection:
        return Icons.list_alt;
    }
  }

  // Create a controller-specific version of operators
  Widget _buildOperatorButtonsForController(TextEditingController controller) {
    final operators = [
      {'+': 'Addition'},
      {'-': 'Soustraction'},
      {'*': 'Multiplication'},
      {'/': 'Division'},
      {'%': 'Modulo (reste de division)'},
      {'(': 'Parenthèse ouvrante'},
      {')': 'Parenthèse fermante'},
      {'"': 'Guillemet (pour les chaînes)'},
      {"'": 'Apostrophe (pour les chaînes)'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5))),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: operators.map((op) {
          final operator = op.keys.first;
          final description = op.values.first;
          return Tooltip(
            message: description,
            child: InkWell(
              onTap: () {
                _insertTextToController(operator, controller);
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Text(
                  operator,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Keep the original method and delegate
  Widget _buildOperatorButtons() {
    return _buildOperatorButtonsForController(_isConditional ? _defaultExpressionController : _expressionController);
  }

  // Create a controller-specific version of logical operators
  Widget _buildLogicalOperatorButtonsForController(TextEditingController controller) {
    final operators = [
      {'==': 'Égal à'},
      {'!=': 'Différent de'},
      {'<': 'Inférieur à'},
      {'>': 'Supérieur à'},
      {'<=': 'Inférieur ou égal à'},
      {'>=': 'Supérieur ou égal à'},
      {'&&': 'ET logique'},
      {'||': 'OU logique'},
      {'!': 'NON logique'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5))),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: operators.map((op) {
          final operator = op.keys.first;
          final description = op.values.first;
          return Tooltip(
            message: description,
            child: InkWell(
              onTap: () {
                _insertTextToController(operator, controller);
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Text(
                  operator,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Keep the original method and delegate
  Widget _buildLogicalOperatorButtons() {
    return _buildLogicalOperatorButtonsForController(_defaultExpressionController);
  }

  // New method to insert text into a specific controller
  void _insertTextToController(String text, TextEditingController controller) {
    final selection = controller.selection;
    final currentText = controller.text;
    final newText = currentText.replaceRange(
      selection.baseOffset >= 0 ? selection.baseOffset : currentText.length,
      selection.extentOffset >= 0 ? selection.extentOffset : currentText.length,
      text,
    );
    
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (selection.baseOffset >= 0 ? selection.baseOffset : currentText.length) + text.length,
      ),
    );
  }

  // Keep the original method for compatibility
  void _insertTextAtCursor(String text) {
    // Determine which text controller is active based on the current state
    TextEditingController activeController;
    
    if (_isConditional) {
      // If editing a condition, check which field has focus
      final focusedNode = FocusManager.instance.primaryFocus;
      if (focusedNode != null && focusedNode.context != null) {
        final state = focusedNode.context!.findAncestorStateOfType<EditableTextState>();
        if (state != null) {
          // Get the actual controller from the current focus
          activeController = state.widget.controller;
        } else {
          // Default to the default expression controller if no specific field is focused
          activeController = _defaultExpressionController;
        }
      } else {
        activeController = _defaultExpressionController;
      }
    } else {
      // For simple formula, always use the expression controller
      activeController = _expressionController;
    }
    
    // Now insert the text into the active controller
    final selection = activeController.selection;
    final currentText = activeController.text;
    final newText = currentText.replaceRange(
      selection.baseOffset >= 0 ? selection.baseOffset : currentText.length,
      selection.extentOffset >= 0 ? selection.extentOffset : currentText.length,
      text,
    );
    
    activeController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (selection.baseOffset >= 0 ? selection.baseOffset : currentText.length) + text.length,
      ),
    );
  }

  Future<void> _addCondition(List<Variable> variables) async {
    setState(() {
      _conditions.add(Condition(condition: '', resultExpression: ''));
    });
  }

  void _removeCondition(int index) {
    setState(() {
      _conditions.removeAt(index);
    });
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _saveFormula,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: Text(_isEditing ? 'Mettre à jour' : 'Enregistrer'),
        ),
      ],
    );
  }

  void _saveFormula() {
    // Check required fields
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom pour la formule')),
      );
      return;
    }
    
    if (_isConditional) {
      // For conditional formula, check that at least one condition is defined
      if (_conditions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez ajouter au moins une condition')),
        );
        return;
      }
      
      // Check that all conditions have both parts filled
      for (int i = 0; i < _conditions.length; i++) {
        if (_conditions[i].condition.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Veuillez compléter la condition #${i + 1}')),
          );
          return;
        }
        if (_conditions[i].resultExpression.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Veuillez compléter le résultat pour la condition #${i + 1}')),
          );
          return;
        }
      }
    } else {
      // For simple formula, check that expression is provided
      if (_expressionController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez entrer une expression pour la formule')),
        );
        return;
      }
    }
    
    final calculatorProvider = Provider.of<CalculatorProvider>(context, listen: false);
    
    if (_isEditing) {
      // Update existing formula
      Formula updatedFormula = widget.formula!.copyWith(
        name: _nameController.text,
        isConditional: _isConditional,
      );
      
      if (_isConditional) {
        updatedFormula = updatedFormula.copyWith(
          expression: null, // Clear the expression for conditional formulas
          conditions: _conditions,
          defaultExpression: _defaultExpressionController.text.isNotEmpty 
              ? _defaultExpressionController.text 
              : null,
        );
      } else {
        updatedFormula = updatedFormula.copyWith(
          expression: _expressionController.text,
          conditions: null, // Clear conditions for simple formulas
          defaultExpression: null, // Clear default expression for simple formulas
        );
      }
      
      calculatorProvider.updateFormula(updatedFormula);
    } else {
      // Create new formula
      Formula newFormula;
      
      if (_isConditional) {
        newFormula = calculatorProvider.createNewFormula(
          name: _nameController.text,
          isConditional: true,
          conditions: _conditions,
          defaultExpression: _defaultExpressionController.text.isNotEmpty 
              ? _defaultExpressionController.text 
              : null,
        );
      } else {
        newFormula = calculatorProvider.createNewFormula(
          name: _nameController.text,
          expression: _expressionController.text,
        );
      }
      
      calculatorProvider.addFormula(newFormula);
    }
    
    Navigator.pop(context);
  }
}
