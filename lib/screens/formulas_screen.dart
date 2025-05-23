import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/formula_model.dart';
import '../models/variable_model.dart';
import '../providers/calculator_provider.dart';
import '../widgets/formula_editor.dart';
import '../widgets/formula_visualization.dart';

class FormulasScreen extends StatelessWidget {
  const FormulasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        final formulas = provider.formulas;
        return Scaffold(
          body: formulas.isEmpty
              ? _buildEmptyState(context)
              : _buildFormulasList(context, provider),
          floatingActionButton: FloatingActionButton(
            heroTag: 'addFormula',
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            onPressed: () => _openFormulaEditor(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.functions_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune formule définie',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Cliquez sur le bouton + pour ajouter votre première formule',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormulasList(BuildContext context, CalculatorProvider provider) {
    final formulas = provider.formulas;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: formulas.length,
      itemBuilder: (context, index) {
        final formula = formulas[index];
        return _buildFormulaCard(context, formula, provider);
      },
    );
  }

  Widget _buildFormulaCard(BuildContext context, Formula formula, CalculatorProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openFormulaEditor(context, formula),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Show formula visualization in a collapsible panel
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('Visualiser'),
                      onPressed: () => _showFormulaVisualization(context, formula, provider),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                    onPressed: () => _openFormulaEditor(context, formula),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () => _confirmDelete(context, formula, provider),
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  formula.isConditional ? 'Formule conditionnelle' : 'Formule simple',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!formula.isConditional && formula.expression != null)
                _buildExpressionBlock(
                  context, 
                  'Expression:', 
                  formula.expression!,
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
              if (formula.isConditional && formula.conditions != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conditions:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...formula.conditions!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final condition = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.2),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Si:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                            _buildExpressionBlock(
                              context,
                              null,
                              condition.condition,
                              Theme.of(context).colorScheme.error.withOpacity(0.1),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Alors:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            _buildExpressionBlock(
                              context,
                              null,
                              condition.resultExpression,
                              Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    if (formula.defaultExpression != null) ...[  
                      const SizedBox(height: 8),
                      Text(
                        'Par défaut:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      _buildExpressionBlock(
                        context,
                        null,
                        formula.defaultExpression!,
                        Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 8),
              if (provider.results.containsKey(formula.name)) ...[  
                Row(
                  children: [
                    Text(
                      'Résultat:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        provider.results[formula.name].toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpressionBlock(BuildContext context, String? label, String expression, Color backgroundColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) 
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            expression,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  Future<void> _openFormulaEditor(BuildContext context, [Formula? formula]) async {
    final provider = Provider.of<CalculatorProvider>(context, listen: false);
    if (provider.variables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez d\'abord créer des variables avant de pouvoir créer des formules'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    await showDialog(
      context: context,
      builder: (context) => FormulaEditor(formula: formula),
    );
  }

    Future<void> _showFormulaVisualization(BuildContext context, Formula formula, CalculatorProvider provider) async {
    // Get the current input values for visualization
    Map<String, dynamic> currentValues = provider.inputValues;
    List<Variable> variables = provider.variables;
    
    // Show the visualization in a dialog
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Visualisation de ${formula.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: FormulaVisualization(
                    formula: formula,
                    variables: variables,
                    currentValues: currentValues,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Formula formula, CalculatorProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer la formule "${formula.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await provider.deleteFormula(formula.id);
    }
  }
}
