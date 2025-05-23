import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/variable_model.dart';
import '../providers/calculator_provider.dart';
import '../widgets/variable_editor.dart';

class VariablesScreen extends StatelessWidget {
  const VariablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        final variables = provider.variables;
        return Scaffold(
          body: variables.isEmpty
              ? _buildEmptyState(context)
              : _buildVariablesList(context, provider),
          floatingActionButton: FloatingActionButton(
            heroTag: 'addVariable',
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () => _openVariableEditor(context),
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
            Icons.category_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune variable définie',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Cliquez sur le bouton + pour ajouter votre première variable',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVariablesList(BuildContext context, CalculatorProvider provider) {
    final variables = provider.variables;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: variables.length,
      itemBuilder: (context, index) {
        final variable = variables[index];
        return _buildVariableCard(context, variable, provider);
      },
    );
  }

  Widget _buildVariableCard(BuildContext context, Variable variable, CalculatorProvider provider) {
    String valueText;
    switch (variable.type) {
      case VariableType.number:
        valueText = variable.initialValue.toString();
        break;
      case VariableType.text:
        valueText = '"${variable.initialValue}"';
        break;
      case VariableType.boolean:
        valueText = (variable.initialValue is bool && variable.initialValue) || 
                   variable.initialValue.toString() == 'true' 
                   ? 'Oui' : 'Non';
        break;
      case VariableType.selection:
        if (variable.options != null && variable.options!.isNotEmpty) {
          final index = variable.initialValue is int 
              ? variable.initialValue 
              : int.tryParse(variable.initialValue.toString()) ?? 0;
          valueText = index < variable.options!.length 
              ? variable.options![index] 
              : 'Option invalide';
        } else {
          valueText = 'Pas d\'options';
        }
        break;
    }

    IconData typeIcon;
    Color iconColor = Theme.of(context).colorScheme.primary;
    switch (variable.type) {
      case VariableType.number:
        typeIcon = Icons.numbers;
        break;
      case VariableType.text:
        typeIcon = Icons.text_fields;
        break;
      case VariableType.boolean:
        typeIcon = Icons.toggle_on;
        break;
      case VariableType.selection:
        typeIcon = Icons.list_alt;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openVariableEditor(context, variable),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: iconColor.withOpacity(0.1),
                    child: Icon(typeIcon, color: iconColor),
                  ),
                  const SizedBox(width: 12),
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
                        if (variable.description != null && variable.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              variable.description!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openVariableEditor(context, variable);
                      } else if (value == 'delete') {
                        _confirmDelete(context, variable, provider);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getTypeLabel(variable.type),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Valeur initiale:',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    valueText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (variable.type == VariableType.selection && variable.options != null && variable.options!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Options:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: variable.options!.map((option) {
                          return Chip(
                            label: Text(option),
                            backgroundColor: Theme.of(context).colorScheme.surface,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(VariableType type) {
    switch (type) {
      case VariableType.number:
        return 'Nombre';
      case VariableType.text:
        return 'Texte';
      case VariableType.boolean:
        return 'Booléen';
      case VariableType.selection:
        return 'Sélection';
    }
  }

  Future<void> _openVariableEditor(BuildContext context, [Variable? variable]) async {
    await showDialog(
      context: context,
      builder: (context) => VariableEditor(variable: variable),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Variable variable, CalculatorProvider provider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer la variable "${variable.name}" ?'),
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

    if (result == true) {
      provider.deleteVariable(variable.id);
    }
  }
}
