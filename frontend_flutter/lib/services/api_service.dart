// lib/services/api_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/assignment_model.dart';
import '../models/project_model.dart';
import '../models/rubric_model.dart';
import '../models/evaluation_model.dart';
import '../models/criterion_model.dart';

class ApiService {
  final Dio _dio;

  static String get _baseUrl {
    // URL de producción en Render
    return 'https://kiosko-render.onrender.com';
  }

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: '$_baseUrl/api',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

  Future<User?> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  Future<List<Project>> getProjects({String? studentId, String? teacherId, String? assignmentId, String? search}) async {
    try {
      final response = await _dio.get('/projects', queryParameters: {
        if (studentId != null) 'studentId': studentId,
        if (teacherId != null) 'teacherId': teacherId,
        if (assignmentId != null) 'assignmentId': assignmentId,
        if (search != null) 'search': search,
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Project.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get projects error: $e');
      return [];
    }
  }

  Future<Rubric?> getRubricById(String id) async {
    try {
      final response = await _dio.get('/rubrics/$id');
      if (response.statusCode == 200) {
        return Rubric.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Get rubric by id error: $e');
      return null;
    }
  }

  Future<Evaluation?> getEvaluationByProjectId(String projectId) async {
    try {
      final response = await _dio.get('/evaluations/project/$projectId');
      if (response.statusCode == 200) {
        return Evaluation.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Get evaluation error: $e');
      return null;
    }
  }

  Future<bool> assignTeacher(String projectId, String teacherId) async {
    try {
      final response = await _dio.post('/projects/$projectId/assign/$teacherId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Assign teacher error: $e');
      return false;
    }
  }

  Future<List<Rubric>> getRubrics({String? creatorId}) async {
    try {
      final response = await _dio.get('/rubrics', queryParameters: {
        if (creatorId != null) 'creatorId': creatorId,
      });
      if (response.statusCode == 200) {
        return (response.data as List).map((x) => Rubric.fromJson(x)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get rubrics error: $e');
      return [];
    }
  }

  Future<bool> createRubric(Map<String, dynamic> rubric) async {
    try {
      final response = await _dio.post('/rubrics', data: rubric);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Create rubric error: $e');
      return false;
    }
  }

  Future<bool> createProjectsBatch(List<Project> projects) async {
    try {
      final response = await _dio.post(
        '/projects/batch',
        data: projects.map((p) => p.toJson()).toList(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Batch create error: $e');
      return false;
    }
  }

  Future<List<Criterion>> getCriteria() async {
    try {
      final response = await _dio.get('/criteria');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Criterion.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get criteria error: $e');
      return [];
    }
  }

  Future<bool> submitEvaluation(Evaluation data) async {
    try {
      final response = await _dio.post('/evaluations', data: data.toJson());
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Submit evaluation error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getRankings() async {
    try {
      final response = await _dio.get('/projects/rankings');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('Get rankings error: $e');
      return [];
    }
  }

  Future<String?> uploadFile(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post('/Upload', data: formData);
      if (response.statusCode == 200) {
        return response.data['url'];
      }
      return null;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  // Assignments
  Future<List<Assignment>> getAssignments({String? teacherId}) async {
    try {
      final response = await _dio.get('/Assignments', queryParameters: teacherId != null ? {'teacherId': teacherId} : null);
      if (response.statusCode == 200) {
        return (response.data as List).map((x) => Assignment.fromJson(x)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get assignments error: $e');
      return [];
    }
  }

  Future<Assignment?> getAssignmentByCode(String code) async {
    try {
      final response = await _dio.get('/Assignments/code/$code');
      if (response.statusCode == 200) {
        return Assignment.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Get assignment by code error: $e');
      return null;
    }
  }

  Future<bool> createAssignment(Assignment assignment) async {
    try {
      final response = await _dio.post('/Assignments', data: assignment.toJson());
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Create assignment error: $e');
      return false;
    }
  }
}
