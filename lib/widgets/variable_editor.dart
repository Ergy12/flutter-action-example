import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/variable_model.dart';
import '../providers/calculator_provider.dart';

class VariableEditor extends StatefulWidget {
  final Variable? variable;

  const VariableEditor({super.key, this.variable});

  @override
  State<VariableEditor> createState() => _VariableEditorState();
}

class _VariableEditorState extends State<VariableEditor> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _initialValueController;
  late VariableType _selectedType;
  List<String> _options = [];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.variable != null;
    _initializeControllers();
  }

  void _initializeControllers() {
    if (_isEditing) {
      _nameController = TextEditingController(text: widget.variable!.name);
      _descriptionController = TextEditingController(text: widget.variable!.description ?? '');
      _selectedType = widget.variable!.type;
      _initialValueController = TextEditingController(text: _getInitialValueAsString());
      _options = widget.variable!.options ?? [];
    } else {
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedType = VariableType.number;
      _initialValueController = TextEditingController(text: '0');
      _options = [];
    }
  }

  String _getInitialValueAsString() {
    final initialValue = widget.variable!.initialValue;
    if (_selectedType == VariableType.boolean) {
      return (initialValue is bool && initialValue) || initialValue.toString() == 'true' ? 'true' : 'false';
    }
    return initialValue.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _initialValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildForm(),
              const SizedBox(height: 24),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.category_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        const SizedBox(width: 12),
        Text(
          _isEditing ? 'Modifier la Variable' : 'Nouvelle Variable',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name Field
        Text(
          'Nom de la variable',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Ex: Salaire de base',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.label_outline),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),

        // Description Field
        Text(
          'Description (optionnelle)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'Ex: Montant du salaire mensuel brut',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.description_outlined),
          ),
          minLines: 1,
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Type Selector
        Text(
          'Type de variable',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildTypeSelector(),
        const SizedBox(height: 16),

        // Initial Value
        Text(
          'Valeur initiale',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildInitialValueField(),
        const SizedBox(height: 16),

        // Options for Selection Type
        if (_selectedType == VariableType.selection)
          _buildOptionsSection(),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<VariableType>(
            value: _selectedType,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            items: VariableType.values.map((type) {
              IconData icon;
              String label;

              switch (type) {
                case VariableType.number:
                  icon = Icons.numbers;
                  label = 'Nombre';
                  break;
                case VariableType.text:
                  icon = Icons.text_fields;
                  label = 'Texte';
                  break;
                case VariableType.boolean:
                  icon = Icons.toggle_on_outlined;
                  label = 'Booléen (Oui/Non)';
                  break;
                case VariableType.selection:
                  icon = Icons.list_alt;
                  label = 'Sélection (Options)';
                  break;
              }

              return DropdownMenuItem<VariableType>(
                value: type,
                child: Row(
                  children: [
                    Icon(icon, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(label),
                  ],
                ),
              );
            }).toList(),
            onChanged: (newType) {
              if (newType != null) {
                setState(() {
                  _selectedType = newType;
                  // Reset initial value based on new type
                  _resetInitialValue();
                });
              }
            },
          ),
        ),
      ),
    );
  }

  void _resetInitialValue() {
    switch (_selectedType) {
      case VariableType.number:
        _initialValueController.text = '0';
        break;
      case VariableType.text:
        _initialValueController.text = '';
        break;
      case VariableType.boolean:
        _initialValueController.text = 'false';
        break;
      case VariableType.selection:
        _options = [];
        _initialValueController.text = '0'; // Index of first option
        break;
    }
  }

  Widget _buildInitialValueField() {
    switch (_selectedType) {
      case VariableType.number:
        return TextFormField(
          controller: _initialValueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.numbers),
          ),
        );

      case VariableType.text:
        return TextFormField(
          controller: _initialValueController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.text_fields),
          ),
        );

      case VariableType.boolean:
        bool initialValue = _initialValueController.text == 'true';
        return SwitchListTile(
          title: Text(initialValue ? 'Oui' : 'Non'),
          value: initialValue,
          onChanged: (value) {
            setState(() {
              _initialValueController.text = value.toString();
            });
          },
          activeColor: Theme.of(context).colorScheme.primary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        );

      case VariableType.selection:
        if (_options.isEmpty) {
          return const SizedBox.shrink();
        }
        int selectedIndex = int.tryParse(_initialValueController.text) ?? 0;
        if (selectedIndex >= _options.length) {
          selectedIndex = 0;
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedIndex,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: List.generate(_options.length, (index) {
                return DropdownMenuItem<int>(
                  value: index,
                  child: Text(_options[index]),
                );
              }),
              onChanged: (index) {
                if (index != null) {
                  setState(() {
                    _initialValueController.text = index.toString();
                  });
                }
              },
            ),
          ),
        );
    }
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Options',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: Theme.of(context).colorScheme.primary,
              onPressed: _addOption,
              tooltip: 'Ajouter une option',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _options.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Aucune option définie, cliquez sur + pour ajouter',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: _options.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(_options[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () => _removeOption(index),
                      ),
                      onTap: () => _editOption(index),
                    ),
                  );
                },
              ),
      ],
    );
  }

  void _addOption() async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une option'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nom de l\'option'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _options.add(result);
        // If this is the first option, set initial value to 0
        if (_options.length == 1) {
          _initialValueController.text = '0';
        }
      });
    }
  }

  void _editOption(int index) async {
    final TextEditingController controller = TextEditingController(text: _options[index]);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'option'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nom de l\'option'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _options[index] = result;
      });
    }
  }

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
      // If the initial value was pointing to this option, reset it
      int currentValueIndex = int.tryParse(_initialValueController.text) ?? 0;
      if (currentValueIndex >= _options.length) {
        _initialValueController.text = '0';
      }
    });
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saveVariable,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  void _saveVariable() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom de la variable est requis')),
      );
      return;
    }

    if (_selectedType == VariableType.selection && _options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez ajouter au moins une option')),
      );
      return;
    }

    final provider = Provider.of<CalculatorProvider>(context, listen: false);
    
    // Parse initial value based on type
    dynamic initialValue;
    switch (_selectedType) {
      case VariableType.number:
        initialValue = double.tryParse(_initialValueController.text) ?? 0;
        break;
      case VariableType.text:
        initialValue = _initialValueController.text;
        break;
      case VariableType.boolean:
        initialValue = _initialValueController.text == 'true';
        break;
      case VariableType.selection:
        initialValue = int.tryParse(_initialValueController.text) ?? 0;
        break;
    }

    if (_isEditing) {
      // Update existing variable
      final updatedVariable = widget.variable!.copyWith(
        name: _nameController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        type: _selectedType,
        initialValue: initialValue,
        options: _selectedType == VariableType.selection ? _options : null,
      );
      provider.updateVariable(updatedVariable);
    } else {
      // Create new variable
      final newVariable = provider.createNewVariable(
        name: _nameController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        type: _selectedType,
        initialValue: initialValue,
        options: _selectedType == VariableType.selection ? _options : null,
      );
      provider.addVariable(newVariable);
    }

    Navigator.pop(context, true);
  }
}
