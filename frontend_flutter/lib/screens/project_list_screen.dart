import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';
import 'evaluation_screen.dart';
import 'admin_dashboard_screen.dart';
import 'results_screen.dart';
import 'student_upload_screen.dart';
import 'rubric_management_screen.dart';
import 'login_screen.dart';

class ProjectListScreen extends StatefulWidget {
  final String role;
  const ProjectListScreen({super.key, this.role = 'Student'});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final ApiService _apiService = ApiService();
  List<Project> _allProjects = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    setState(() => _isLoading = true);
    try {
      // Demo logic: using hardcoded IDs for role-based view
      String? studentId = widget.role == 'Student' ? 'student_1' : null;
      String? teacherId = widget.role == 'Evaluator' ? 'teacher_1' : null;

      final projects = await _apiService.getProjects(
        studentId: studentId, 
        teacherId: teacherId
      );
      
      setState(() {
        _allProjects = projects;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar proyectos: $e')),
        );
      }
    }
  }

  List<Project> get _filteredProjects {
    return _allProjects.where((p) {
      final title = p.title ?? p.teamName ?? '';
      final matchesSearch = title.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesFilter = true;
      final isEvaluated = p.status?.toLowerCase() == 'evaluado';
      
      if (_selectedFilter == 'Pendientes') matchesFilter = !isEvaluated;
      if (_selectedFilter == 'Evaluados') matchesFilter = isEvaluated;
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Proyectos', style: Theme.of(context).textTheme.headlineMedium),
        backgroundColor: AppColors.backgroundOffWhite,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProjects,
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      floatingActionButton: (widget.role == 'Admin')
        ? FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            ),
            label: const Text('Admin Panel'),
            icon: const Icon(Icons.dashboard_customize),
            backgroundColor: AppColors.primaryYellow,
          )
        : null,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildSearchBar(),
              _buildFilterChips(),
              _buildProjectListCount(),
              Expanded(child: _buildProjectList()),
            ],
          ),
    );
  }

  Widget _buildProjectListCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('${_filteredProjects.length} resultados encontrados', 
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextFormField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Buscar proyectos...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.backgroundWhite,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          _buildFilterChip('Todos'),
          const SizedBox(width: 8),
          _buildFilterChip('Pendientes'),
          const SizedBox(width: 8),
          _buildFilterChip('Evaluados'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.textPrimary : AppColors.borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildProjectList() {
    final projects = _filteredProjects;
    if (projects.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final p = projects[index];
        return _buildProjectItem(context, p);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('No se encontraron proyectos'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchProjects,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
          if (widget.role == 'Student') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentUploadScreen(studentId: 'student_1'))),
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Subir Mi Proyecto'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryYellow, side: const BorderSide(color: AppColors.primaryYellow)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectItem(BuildContext context, Project p) {
    final title = p.title ?? p.teamName ?? 'Sin Título';
    final category = p.category ?? 'General';
    final isEvaluated = p.status?.toLowerCase() == 'evaluado';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () async {
          if (widget.role == 'Admin' || widget.role == 'Student') {
             // Maybe show details instead of evaluation?
             return;
          }
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EvaluationScreen(
                projectId: p.id,
                projectName: title,
              ),
            ),
          );

          if (result == true) {
            _fetchProjects();
          }
        },
        child: GlassmorphismCard(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildIcon(category),
              const SizedBox(width: 16),
              Expanded(child: _buildDetails(context, title, category, isEvaluated, p.technologies)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(String category) {
    IconData icon = Icons.computer;
    if (category.contains('Mobile')) icon = Icons.phone_android;
    if (category.contains('Hardware') || category.contains('IoT')) icon = Icons.settings_input_component;
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Icon(icon, color: AppColors.primaryYellow),
    );
  }

  Widget _buildDetails(BuildContext context, String title, String category, bool isEvaluated, List<String>? tech) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(title, 
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
            ),
            _buildStatusBadge(isEvaluated),
          ],
        ),
        const SizedBox(height: 8),
        if (tech != null && tech.isNotEmpty)
          Wrap(
            spacing: 8,
            children: tech.map((t) => Chip(
              label: Text(t, style: const TextStyle(fontSize: 10)),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          )
        else
          Text(category, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildStatusBadge(bool isEvaluated) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isEvaluated ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isEvaluated ? 'Evaluado' : 'Pendiente',
        style: TextStyle(fontSize: 10, color: isEvaluated ? Colors.green[800] : Colors.orange[800], fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(context),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Inicio'),
            onTap: () => Navigator.pop(context),
          ),
          if (widget.role == 'Student')
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('Subir Mi Proyecto'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentUploadScreen(studentId: 'student_1'))),
            ),
          if (widget.role == 'Evaluator')
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Mis Rúbricas'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RubricManagementScreen(teacherId: 'teacher_1'))),
            ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Resultados Live'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultsScreen())),
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: const BoxDecoration(color: AppColors.primaryYellow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: AppColors.primaryYellow, size: 40),
          ),
          const SizedBox(height: 12),
          Text('Kritik User', style: Theme.of(context).textTheme.titleLarge),
          Text('Rol: ${widget.role}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
