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
  final _accessCodeController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  bool _isSubmitting = false;
  List<PlatformFile> _selectedFiles = [];
  List<Assignment> _assignments = [];
  String? _selectedAssignmentId;
  bool _isLoadingAssignments = true;
  Assignment? _joinedAssignment;
  bool _isSearchingCode = false;

  Rubric? _assignmentRubric;
  Evaluation? _existingEvaluation;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  Future<void> _onAssignmentChanged(String? id) async {
    if (id == null) return;
    
    setState(() {
      _selectedAssignmentId = id;
      _isLoadingDetails = true;
    });

    try {
      final assignment = _assignments.firstWhere((a) => a.id == id);
      
      // 1. Fetch Rubric if exists
      if (assignment.rubricId != null) {
        _assignmentRubric = await _apiService.getRubricById(assignment.rubricId!);
      } else {
        _assignmentRubric = null;
      }

      // 2. Check if student already has a project for this assignment
      final projects = await _apiService.getProjects(
        studentId: widget.studentId,
        assignmentId: id,
      );

      if (projects.isNotEmpty) {
        final project = projects.first;
        // 3. Fetch evaluation if exists
        _existingEvaluation = await _apiService.getEvaluationByProjectId(project.id!);
      } else {
        _existingEvaluation = null;
      }

    } catch (e) {
      debugPrint('Error fetching assignment details: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
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

  Future<void> _searchByCode() async {
    if (_accessCodeController.text.length < 6) return;
    
    setState(() => _isSearchingCode = true);
    try {
      final assignment = await _apiService.getAssignmentByCode(_accessCodeController.text.toUpperCase());
      if (mounted) {
        if (assignment != null) {
          setState(() {
            _joinedAssignment = assignment;
            _assignments = [assignment, ..._assignments.where((a) => a.id != assignment.id)];
          });
          await _onAssignmentChanged(assignment.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('¡Convocatoria encontrada: ${assignment.title}!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró ninguna convocatoria con ese código')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar código: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearchingCode = false);
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

  Widget _buildAssignmentDetails() {
    final assignment = _assignments.firstWhere((a) => a.id == _selectedAssignmentId);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(assignment.description, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (assignment.rubricId != null)
                TextButton.icon(
                  onPressed: () => _showRubricDialog(),
                  icon: const Icon(Icons.rule, size: 18),
                  label: const Text('Ver Rúbrica'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              const Spacer(),
              if (assignment.dueDate != null)
                Text(
                  'Entrega: ${assignment.dueDate!.day}/${assignment.dueDate!.month}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          if (_existingEvaluation != null) ...[
            const Divider(),
            const Text('Retroalimentación del Docente:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 4),
            Text(
              _existingEvaluation!.feedback ?? 'Sin comentarios por ahora.',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  void _showRubricDialog() {
    if (_assignmentRubric == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rúbrica: ${_assignmentRubric!.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _assignmentRubric!.items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final crit = _assignmentRubric!.items[index];
              return ListTile(
                title: Text(crit.criteria, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(crit.description),
                trailing: Text('${crit.maxPoints} pts', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                contentPadding: EdgeInsets.zero,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
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
                'Unete a una convocatoria usando el código que te dio tu docente o selecciona una de la lista.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _accessCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Código de Convocatoria',
                        hintText: 'Ej: AB1234',
                        prefixIcon: Icon(Icons.vpn_key),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSearchingCode ? null : _searchByCode,
                      child: _isSearchingCode 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Buscar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              _isLoadingAssignments
                ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedAssignmentId,
                        decoration: InputDecoration(
                          labelText: 'Tarea / Convocatoria',
                          prefixIcon: const Icon(Icons.assignment),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              setState(() => _isLoadingAssignments = true);
                              _fetchAssignments();
                            },
                          ),
                          hintText: _assignments.isEmpty ? 'No hay tareas disponibles' : 'Selecciona una tarea',
                        ),
                        items: _assignments.isNotEmpty 
                          ? _assignments.map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.title),
                            )).toList()
                          : [],
                        onChanged: _assignments.isEmpty ? null : (val) => _onAssignmentChanged(val),
                        validator: (val) => val == null ? 'Por favor selecciona una tarea' : null,
                      ),
                      if (_selectedAssignmentId != null && !_isLoadingDetails) ...[
                        const SizedBox(height: 16),
                        _buildAssignmentDetails(),
                      ],
                      if (_isLoadingDetails)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título de Proyecto / Tarea',
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
