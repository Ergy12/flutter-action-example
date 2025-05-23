import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/input_field_model.dart';
import '../models/variable_model.dart';
import '../providers/calculator_provider.dart';

class InputFieldEditor extends StatefulWidget {
  final InputField? inputField;

  const InputFieldEditor({super.key, this.inputField});

  @override
  State<InputFieldEditor> createState() => _InputFieldEditorState();
}

class _InputFieldEditorState extends State<InputFieldEditor> {
  late TextEditingController _labelController;
  late TextEditingController _descriptionController;
  String? _selectedVariableId;
  bool _showInCalculation = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _isEditing = widget.inputField != null;
    _labelController = TextEditingController(text: widget.inputField?.label ?? '');
    _descriptionController = TextEditingController(text: widget.inputField?.description ?? '');
    _selectedVariableId = widget.inputField?.variableId;
    _showInCalculation = widget.inputField?.showInCalculation ?? true;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalculatorProvider>(context);
    final variables = provider.variables;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le champ' : 'Nouveau champ'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Enregistrer',
            onPressed: _saveInputField,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildForm(variables),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _isEditing ? 'Modifier le champ d\'entrée' : 'Créer un nouveau champ d\'entrée',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildForm(List<Variable> variables) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label field
            TextFormField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: 'Étiquette du champ',
                hintText: 'Ex: Salaire mensuel',
                prefixIcon: Icon(
                  Icons.label_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Ce champ est requis' : null,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 16),
            
            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (optionnelle)',
                hintText: 'Ex: Salaire brut mensuel',
                prefixIcon: Icon(
                  Icons.description_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            
            // Variable selection
            _buildVariableSelector(variables),
            const SizedBox(height: 24),
            
            // Show in calculation toggle
            SwitchListTile(
              title: const Text('Afficher dans le calcul'),
              subtitle: const Text('Ce champ apparaîtra dans l\'écran de calcul principal'),
              value: _showInCalculation,
              activeColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onChanged: (value) {
                setState(() {
                  _showInCalculation = value;
                });
              },
            ),
            const SizedBox(height: 24),
            
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildVariableSelector(List<Variable> variables) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Variable liée',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (variables.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: const Center(
              child: Text(
                'Aucune variable disponible. Créez une variable d\'abord.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Sélectionner une variable (optionnel)'),
                value: _selectedVariableId,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Aucune variable liée'),
                  ),
                  ...variables.map((variable) {
                    return DropdownMenuItem<String>(
                      value: variable.id,
                      child: Row(
                        children: [
                          Icon(
                            _getIconForVariableType(variable.type),
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(variable.name),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedVariableId = value;
                  });
                },
              ),
            ),
          ),
        if (_selectedVariableId != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildVariableInfo(variables),
          ),
      ],
    );
  }

  Widget _buildVariableInfo(List<Variable> variables) {
    final variable = variables.firstWhere(
      (v) => v.id == _selectedVariableId,
      orElse: () => Variable(
        id: '',
        name: '',
        type: VariableType.text,
        initialValue: '',
      ),
    );
    
    if (variable.id.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIconForVariableType(variable.type),
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                variable.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (variable.description != null && variable.description!.isNotEmpty) ...[  
            const SizedBox(height: 4),
            Text(
              variable.description!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Type: ${_getTypeLabel(variable.type)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          if (variable.type == VariableType.selection && variable.options != null && variable.options!.isNotEmpty) ...[  
            const SizedBox(height: 8),
            Text(
              'Options: ${variable.options!.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
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

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.cancel),
          label: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Enregistrer'),
          onPressed: _saveInputField,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  void _saveInputField() {
    if (_labelController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('L\'étiquette du champ est requise')),
      );
      return;
    }
    
    final provider = Provider.of<CalculatorProvider>(context, listen: false);
    
    InputField inputField;
    if (_isEditing && widget.inputField != null) {
      inputField = widget.inputField!.copyWith(
        label: _labelController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        variableId: _selectedVariableId,
        showInCalculation: _showInCalculation,
      );
      provider.updateInputField(inputField);
    } else {
      inputField = provider.createNewInputField(
        label: _labelController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        variableId: _selectedVariableId,
        showInCalculation: _showInCalculation,
      );
      provider.addInputField(inputField);
    }
    
    Navigator.of(context).pop();
  }
}
