import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../providers/calculator_provider.dart';
import '../models/variable_model.dart';
import '../models/formula_model.dart';
import '../models/input_field_model.dart';
import '../services/pdf_service.dart';
import '../widgets/input_field_editor.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        if (provider.variables.isEmpty && provider.formulas.isEmpty && provider.inputFields.isEmpty) {
          return _buildEmptyState(context);
        }
        
        return _buildCalculatorContent(context, provider);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calculate_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Bienvenue dans le Calculateur de Décompte Final',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Pour commencer, créez des variables, des formules, et des champs d\'entrée.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.category),
                label: const Text('Créer des variables'),
                onPressed: () {
                  DefaultTabController.of(context).animateTo(2); // Switch to Variables tab
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorContent(BuildContext context, CalculatorProvider provider) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInputSection(context, provider),
              const SizedBox(height: 24),
              _buildResultsSection(context, provider),
            ],
          ),
        ),
        _buildBottomActions(context, provider),
      ],
    );
  }

  Widget _buildInputSection(BuildContext context, CalculatorProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.input_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Données',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Show input fields configured to appear in calculation screen
            ...provider.inputFields
                .where((field) => field.showInCalculation)
                .map((field) {
                  // Get the variable if this field is linked to one
                  Variable? linkedVariable;
                  if (field.variableId != null) {
                    try {
                      linkedVariable = provider.variables.firstWhere(
                        (v) => v.id == field.variableId,
                      );
                    } catch (e) {
                      // Variable not found
                      linkedVariable = null;
                    }
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildCustomInputField(context, field, linkedVariable, provider),
                  );
                }).toList(),
                
            // Show directly all variables that aren't linked to any input field
            ...provider.variables
                .where((variable) => !provider.inputFields
                    .where((field) => field.showInCalculation)
                    .any((field) => field.variableId == variable.id))
                .map((variable) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildVariableInput(context, variable, provider),
                  );
                }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVariableInput(BuildContext context, Variable variable, CalculatorProvider provider) {
    final currentValue = provider.inputValues[variable.id] ?? variable.initialValue;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIconForVariableType(variable.type),
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variable.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (variable.description != null && variable.description!.isNotEmpty) ...[  
                      const SizedBox(height: 4),
                      Text(
                        variable.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputFieldByType(context, variable, currentValue, provider),
        ],
      ),
    );
  }

  Widget _buildCustomInputField(BuildContext context, InputField field, Variable? linkedVariable, CalculatorProvider provider) {
    if (linkedVariable == null) {
      // If there's no linked variable or it was deleted, show an error message
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  field.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              field.variableId == null
                  ? 'Ce champ n\'est lié à aucune variable'
                  : 'La variable liée a été supprimée',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      );
    }

    // Otherwise, get the current value and build the appropriate input widget
    final currentValue = provider.inputValues[linkedVariable.id] ?? linkedVariable.initialValue;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIconForVariableType(linkedVariable.type),
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (field.description != null && field.description!.isNotEmpty) ...[  
                      const SizedBox(height: 4),
                      Text(
                        field.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputFieldByType(context, linkedVariable, currentValue, provider),
        ],
      ),
    );
  }

  IconData _getIconForVariableType(VariableType type) {
    switch (type) {
      case VariableType.number:
        return Icons.pin;
      case VariableType.text:
        return Icons.text_fields;
      case VariableType.boolean:
        return Icons.toggle_on;
      case VariableType.selection:
        return Icons.list;
    }
  }
  
  Widget _buildInputFieldByType(BuildContext context, Variable variable, dynamic currentValue, CalculatorProvider provider) {
    switch (variable.type) {
      case VariableType.number:
        return TextFormField(
          initialValue: currentValue?.toString() ?? '0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: 'Entrez un nombre',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          onChanged: (value) {
            final numValue = double.tryParse(value);
            if (numValue != null) {
              provider.setInputValue(variable.id, numValue);
            }
          },
        );
        
      case VariableType.text:
        return TextFormField(
          initialValue: currentValue?.toString() ?? '',
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: 'Entrez du texte',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          onChanged: (value) {
            provider.setInputValue(variable.id, value);
          },
        );
        
      case VariableType.boolean:
        return SwitchListTile(
          title: const Text('Valeur'),
          value: currentValue is bool ? currentValue : currentValue == 'true',
          activeColor: Theme.of(context).colorScheme.primary,
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onChanged: (value) {
            provider.setInputValue(variable.id, value);
          },
        );
        
      case VariableType.selection:
        if (variable.options == null || variable.options!.isEmpty) {
          return const Text('Aucune option disponible');
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Sélectionner une option'),
              value: currentValue?.toString(),
              items: variable.options!.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  provider.setInputValue(variable.id, value);
                }
              },
            ),
          ),
        );
    }
  }

  Widget _buildResultsSection(BuildContext context, CalculatorProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Résultats',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            provider.formulas.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.functions_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune formule définie',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter une formule'),
                            onPressed: () {
                              DefaultTabController.of(context).animateTo(1); // Switch to Formulas tab
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              foregroundColor: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: provider.formulas.map((formula) {
                      final result = provider.results[formula.name];
                      return ListTile(
                        title: Text(
                          formula.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          formula.isConditional
                              ? 'Formule conditionnelle'
                              : formula.expression ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            result != null ? result.toString() : 'Non calculé',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, CalculatorProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            context: context,
            icon: Icons.refresh,
            label: 'Recalculer',
            color: Theme.of(context).colorScheme.primary,
            onTap: () {
              provider.calculateResults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calculs mis à jour')),
              );
            },
          ),
          if (provider.formulas.isNotEmpty)
            _buildActionButton(
              context: context,
              icon: Icons.picture_as_pdf,
              label: 'Exporter PDF',
              color: Theme.of(context).colorScheme.secondary,
              onTap: () => _exportPdf(context, provider),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, CalculatorProvider provider) async {
    // Get a reference to the PdfService
    final pdfService = PdfService();
    
    try {
      // Generate the PDF document
      final pdfBytes = await pdfService.generatePdf(
        title: 'Rapport de Décompte Final',
        inputValues: provider.inputValues,
        results: provider.results,
        variables: provider.variables,
        formulas: provider.formulas,
        inputFields: provider.inputFields,
      );
      
      // Show options to share or print
      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PDF Généré avec Succès',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      context: context,
                      icon: Icons.share,
                      label: 'Partager',
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () {
                        Navigator.pop(context);
                        pdfService.sharePdf(pdfBytes, 'decompte_final.pdf');
                      },
                    ),
                    _buildActionButton(
                      context: context,
                      icon: Icons.print,
                      label: 'Imprimer',
                      color: Theme.of(context).colorScheme.secondary,
                      onTap: () {
                        Navigator.pop(context);
                        pdfService.printPdf(pdfBytes);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la génération du PDF: $e')),
      );
    }
  }
}
