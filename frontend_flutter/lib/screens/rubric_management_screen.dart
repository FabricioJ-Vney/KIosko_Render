import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class RubricManagementScreen extends StatefulWidget {
  final String teacherId;
  const RubricManagementScreen({super.key, required this.teacherId});

  @override
  State<RubricManagementScreen> createState() => _RubricManagementScreenState();
}

class _RubricManagementScreenState extends State<RubricManagementScreen> {
  final ApiService _apiService = ApiService();
  final _nameController = TextEditingController();
  
  List<dynamic> _rubrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRubrics();
  }

  Future<void> _loadRubrics() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getRubrics(creatorId: widget.teacherId);
    setState(() {
      _rubrics = data;
      _isLoading = false;
    });
  }

  void _showCreateDialog() {
    List<Map<String, dynamic>> items = [
      {'criteria': 'Innovación', 'points': 10, 'desc': 'Originalidad del proyecto.'}
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    builder: (mContext) => StatefulBuilder(
      builder: (sContext, setModalState) => Container(
        height: MediaQuery.of(mContext).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nueva Lista de Cotejo', style: Theme.of(mContext).textTheme.headlineSmall),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la Rúbrica'),
            ),
            const SizedBox(height: 20),
            const Text('Criterios', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (lContext, index) => Card(
                  child: ListTile(
                    title: Text(items[index]['criteria']),
                    subtitle: Text('${items[index]['points']} pts - ${items[index]['desc']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setModalState(() => items.removeAt(index)),
                    ),
                  ),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                setModalState(() {
                  items.add({'criteria': 'Criterio ${items.length + 1}', 'points': 10, 'desc': 'Descripción...'});
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Añadir Criterio'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isEmpty) return;
                final success = await _apiService.createRubric({
                  'name': _nameController.text,
                  'items': items,
                  'creatorId': widget.teacherId,
                  'isGlobal': false,
                });
                if (success) {
                  if (!mounted) return;
                  if (!mContext.mounted) return;
                  Navigator.pop(mContext);
                  _loadRubrics();
                  _nameController.clear();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryYellow),
              child: const Text('Guardar Rúbrica'),
            ),
          ],
        ),
      ),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Listas de Cotejo')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        label: const Text('Crear Nueva'),
        icon: const Icon(Icons.add_task),
        backgroundColor: AppColors.primaryYellow,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _rubrics.length,
            itemBuilder: (context, index) {
              final rubric = _rubrics[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(rubric['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${(rubric['items'] as List).length} criterios'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          ),
    );
  }
}
