import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import 'calculator_screen.dart';
import 'formulas_screen.dart';
import 'variables_screen.dart';
import 'input_fields_screen.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Tab> _tabs = [
    const Tab(icon: Icon(Icons.calculate), text: 'Calcul'),
    const Tab(icon: Icon(Icons.functions), text: 'Formules'),
    const Tab(icon: Icon(Icons.category), text: 'Variables'),
    const Tab(icon: Icon(Icons.input), text: 'Champs'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    
    // Initialize the calculator provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CalculatorProvider>(context, listen: false);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculateur de Décompte Final'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          indicatorColor: colorScheme.secondary,
          indicatorWeight: 3,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7),
          labelStyle: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CalculatorScreen(),
          FormulasScreen(),
          VariablesScreen(),
          InputFieldsScreen(),
        ],
      ),
    );
  }
}
