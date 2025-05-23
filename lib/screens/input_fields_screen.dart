import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/input_field_model.dart';
import '../models/variable_model.dart';
import '../providers/calculator_provider.dart';
import '../widgets/input_field_editor.dart';

class InputFieldsScreen extends StatelessWidget {
  const InputFieldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CalculatorProvider>(
        builder: (context, provider, child) {
          final inputFields = provider.inputFields;
          
          if (inputFields.isEmpty) {
            return _buildEmptyState(context);
          }
          
          return _buildInputFieldsList(context, provider);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openInputFieldEditor(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.view_list_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun champ d\'entrée',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Créez des champs d\'entrée pour collecter les données qui seront utilisées dans vos calculs.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputFieldsList(BuildContext context, CalculatorProvider provider) {
    final inputFields = provider.inputFields;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inputFields.length,
      itemBuilder: (context, index) {
        return _buildInputFieldCard(context, inputFields[index], provider);
      },
    );
  }

  Widget _buildInputFieldCard(BuildContext context, InputField inputField, CalculatorProvider provider) {
    // Find linked variable if any
    Variable? linkedVariable;
    if (inputField.variableId != null) {
      linkedVariable = provider.variables.firstWhere(
        (v) => v.id == inputField.variableId,
        orElse: () => Variable(
          id: '',
          name: 'Variable supprimée',
          type: VariableType.text,
          initialValue: '',
        ),
      );
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.input_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inputField.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (inputField.description != null) ...[  
                        const SizedBox(height: 4),
                        Text(
                          inputField.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openInputFieldEditor(context, inputField);
                    } else if (value == 'delete') {
                      _confirmDelete(context, inputField, provider);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPropertyChip(
                    context: context,
                    icon: Icons.visibility,
                    label: inputField.showInCalculation ? 'Visible dans le calcul' : 'Masqué dans le calcul',
                    color: inputField.showInCalculation
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                if (linkedVariable != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPropertyChip(
                      context: context,
                      icon: _getIconForVariableType(linkedVariable.type),
                      label: 'Lié à ${linkedVariable.name}',
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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

  Future<void> _openInputFieldEditor(BuildContext context, [InputField? inputField]) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: InputFieldEditor(inputField: inputField),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, InputField inputField, CalculatorProvider provider) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le champ'),
        content: Text('Êtes-vous sûr de vouloir supprimer le champ "${inputField.label}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.deleteInputField(inputField.id);
              Navigator.of(context).pop();
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
