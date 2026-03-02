import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/assignment_model.dart';
import '../models/rubric_model.dart';
import '../theme/app_theme.dart';

class AssignmentCreationScreen extends StatefulWidget {
  final String teacherId;
  const AssignmentCreationScreen({super.key, required this.teacherId});

  @override
  State<AssignmentCreationScreen> createState() => _AssignmentCreationScreenState();
}

class _AssignmentCreationScreenState extends State<AssignmentCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  List<Rubric> _rubrics = [];
  String? _selectedRubricId;
  bool _isLoadingRubrics = true;
  bool _isSaving = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchRubrics();
  }

  Future<void> _fetchRubrics() async {
    try {
      final rubrics = await _apiService.getRubrics();
      setState(() {
        _rubrics = rubrics;
        _isLoadingRubrics = false;
      });
    } catch (e) {
      debugPrint('Error fetching rubrics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar rúbricas: $e')),
        );
      }
      setState(() => _isLoadingRubrics = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final assignment = Assignment(
        title: _titleController.text,
        description: _descriptionController.text,
        teacherId: widget.teacherId,
        rubricId: _selectedRubricId,
        dueDate: _selectedDate,
      );

      final success = await _apiService.createAssignment(assignment);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Convocatoria creada con éxito!')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al crear la convocatoria')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Convocatoria')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Crea una nueva convocatoria para que tus alumnos puedan subir sus proyectos.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título (ej: Feria de Ciencias 2024)',
                  prefixIcon: Icon(Icons.campaign),
                ),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción / Instrucciones',
                  alignLabelWithHint: true,
                ),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 24),
              _isLoadingRubrics 
                ? const LinearProgressIndicator()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRubricId,
                        decoration: InputDecoration(
                          labelText: 'Seleccionar Rúbrica de Evaluación',
                          prefixIcon: const Icon(Icons.rule),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _fetchRubrics,
                          ),
                        ),
                        items: _rubrics.map((r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(r.name ?? 'Rúbrica sin nombre'),
                        )).toList(),
                        onChanged: _rubrics.isEmpty ? null : (val) => setState(() => _selectedRubricId = val),
                        validator: (val) => val == null ? 'Selecciona una rúbrica' : null,
                      ),
                      if (_rubrics.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Aviso: Debes crear al menos una rúbrica antes de publicar una convocatoria.',
                            style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
              const SizedBox(height: 24),
              ListTile(
                title: Text(_selectedDate == null 
                  ? 'Fecha de Entrega (Opcional)' 
                  : 'Entrega: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                leading: const Icon(Icons.calendar_today),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectDate(context),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveAssignment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primaryYellow,
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Publicar Convocatoria', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
