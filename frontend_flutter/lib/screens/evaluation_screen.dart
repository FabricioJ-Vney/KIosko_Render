import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

import '../services/api_service.dart';
import '../models/evaluation_model.dart';
import '../models/rubric_model.dart';

class EvaluationScreen extends StatefulWidget {
  final String? projectId;
  final String projectName;
  final String? evaluatorId;

  const EvaluationScreen({super.key, this.projectId, required this.projectName, this.evaluatorId});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _commentController = TextEditingController();
  
  List<Rubric> _rubrics = [];
  Rubric? _selectedRubric;
  Map<String, int> _detailedScores = {};
  
  String? _evidencePath;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadRubrics();
  }

  Future<void> _loadRubrics() async {
    final rubrics = await _apiService.getRubrics();
    if (mounted) {
      setState(() {
        _rubrics = rubrics;
        if (_rubrics.isNotEmpty) {
          _selectedRubric = _rubrics.first;
          _initializeScores();
        }
      });
    }
  }

  void _initializeScores() {
    if (_selectedRubric != null) {
      final items = _selectedRubric!.items;
      _detailedScores = { for (var item in items) item.criteria : item.maxPoints };
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Optimize size
      );
      
      if (photo != null) {
        setState(() {
          _evidencePath = photo.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir la cámara: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (widget.projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se encontró el ID del proyecto')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? base64Photo;
      if (_evidencePath != null) {
        final bytes = await File(_evidencePath!).readAsBytes();
        base64Photo = base64Encode(bytes);
      }

      if (!mounted) return;
      final evaluation = Evaluation(
        projectId: widget.projectId,
        evaluatorId: widget.evaluatorId ?? "evaluator_unknown",
        rubricId: _selectedRubric?.id,
        scores: {"General": _detailedScores.values.fold(0, (a, b) => a + b)}, 
        detailedScores: _detailedScores,
        feedback: _commentController.text,
        evidencePhotoBase64: base64Photo,
      );

      final success = await _apiService.submitEvaluation(evaluation);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Evaluación enviada con éxito!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar la evaluación')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluar Proyecto'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isSubmitting 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.projectName, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 24),
                  
                  // Rubric Selection
                  const Text('Lista de Cotejo / Rúbrica', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Rubric>(
                    value: _selectedRubric,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: _rubrics.map<DropdownMenuItem<Rubric>>((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.name ?? 'Sin nombre'),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedRubric = val;
                        _initializeScores();
                      });
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  if (_selectedRubric != null) ...[
                    const Text('Criterios de Evaluación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    ..._selectedRubric!.items.map((item) {
                      final criteria = item.criteria;
                      final maxPoints = item.maxPoints;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(criteria, style: const TextStyle(fontWeight: FontWeight.w600))),
                              Text('${_detailedScores[criteria] ?? 0} / $maxPoints', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Slider(
                            value: (_detailedScores[criteria] ?? 0).toDouble(),
                            min: 0,
                            max: maxPoints.toDouble(),
                            divisions: maxPoints,
                            onChanged: (val) => setState(() => _detailedScores[criteria] = val.toInt()),
                          ),
                          Text(item.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 20),
                        ],
                      );
                    }),
                  ] else ...[
                    const Center(child: Text('Cargando rúbricas...')),
                  ],

                  const SizedBox(height: 16),
                  const Text('Evidencia y Comentarios', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildPhotoSection(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Retroalimentación para el alumno...', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryYellow, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Confirmar Calificación', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    if (_evidencePath != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
                image: DecorationImage(
                  image: FileImage(File(_evidencePath!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              right: -8,
              top: -8,
              child: GestureDetector(
                onTap: () => setState(() => _evidencePath = null),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _takePhoto,
      icon: const Icon(Icons.camera_alt_outlined),
      label: const Text('Tomar Foto de Evidencia'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
