import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../models/assignment_model.dart';
import '../theme/app_theme.dart';

class StudentUploadScreen extends StatefulWidget {
  final String studentId;
  const StudentUploadScreen({super.key, required this.studentId});

  @override
  State<StudentUploadScreen> createState() => _StudentUploadScreenState();
}

class _StudentUploadScreenState extends State<StudentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  bool _isSubmitting = false;
  List<PlatformFile> _selectedFiles = [];
  List<Assignment> _assignments = [];
  String? _selectedAssignmentId;
  bool _isLoadingAssignments = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
    try {
      final assignments = await _apiService.getAssignments();
      setState(() {
        _assignments = assignments;
        _isLoadingAssignments = false;
      });
    } catch (e) {
      debugPrint('Error fetching assignments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar tareas: $e')),
        );
      }
      setState(() => _isLoadingAssignments = false);
    }
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedFiles = result.files;
      });
    }
  }

  Future<void> _submitProject() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isSubmitting = true);

    try {
      List<String> uploadedFileUrls = [];
      
      // 1. Upload files first
      for (var platformFile in _selectedFiles) {
        if (platformFile.path != null) {
          final url = await _apiService.uploadFile(File(platformFile.path!));
          if (url != null) {
            uploadedFileUrls.add(url);
          }
        }
      }

      final selectedAssignment = _assignments.firstWhere((a) => a.id == _selectedAssignmentId);

      // 2. Create project with file URLs and teacher link
      final newProject = Project(
        title: _titleController.text,
        teamName: "Equipo de ${_titleController.text}",
        category: _categoryController.text,
        description: _descriptionController.text,
        studentId: widget.studentId,
        assignmentId: _selectedAssignmentId,
        assignedTeacherId: selectedAssignment.teacherId,
        coverImageUrl: uploadedFileUrls.isNotEmpty ? uploadedFileUrls.first : null,
      );

      final response = await _apiService.createProjectsBatch([newProject]);

      if (mounted) {
        if (response) {
          messenger.showSnackBar(
            const SnackBar(content: Text('¡Proyecto y archivos subidos con éxito!')),
          );
          navigator.pop();
        } else {
          messenger.showSnackBar(
            const SnackBar(content: Text('Error al guardar el proyecto en la base de datos')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Mi Proyecto'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Completa los detalles de tu proyecto para que los docentes puedan calificarlo.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              _isLoadingAssignments
                ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedAssignmentId,
                        decoration: InputDecoration(
                          labelText: 'Tarea / Convocatoria',
                          prefixIcon: const Icon(Icons.assignment),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _fetchAssignments,
                          ),
                          helperText: _assignments.isEmpty ? 'No hay tareas publicadas' : null,
                          helperStyle: const TextStyle(color: Colors.red),
                        ),
                        items: _assignments.map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.title),
                        )).toList(),
                        onChanged: _assignments.isEmpty ? null : (val) => setState(() => _selectedAssignmentId = val),
                        validator: (val) => val == null ? 'Por favor selecciona una tarea' : null,
                      ),
                      if (_assignments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Aviso: Tu docente debe crear una convocatoria antes de que puedas subir tu proyecto.',
                            style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título del Proyecto',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _categoryController.text,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category),
                ),
                onChanged: (v) => _categoryController.text = v,
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Descripción detallada',
                  alignLabelWithHint: true,
                ),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 32),
              const Text('Documentación (PDF, Imágenes)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.attach_file),
                label: Text(_selectedFiles.isEmpty 
                  ? 'Seleccionar archivos' 
                  : '${_selectedFiles.length} archivos seleccionados'),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitProject,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primaryYellow.withOpacity(0.1),
                ),
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Enviar Proyecto', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
