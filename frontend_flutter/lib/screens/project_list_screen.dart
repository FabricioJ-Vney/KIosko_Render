import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';
import 'evaluation_screen.dart';
import 'admin_dashboard_screen.dart';
import 'results_screen.dart';
import 'student_upload_screen.dart';
import 'assignment_creation_screen.dart';
import 'rubric_management_screen.dart';
import 'login_screen.dart';

class ProjectListScreen extends StatefulWidget {
  final String role;
  final String? userId;
  final String? userFullName;

  const ProjectListScreen({
    super.key, 
    this.role = 'Student',
    this.userId,
    this.userFullName,
  });

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
      // Use actual IDs from widget instead of hardcoded ones
      String? studentId = widget.role.toLowerCase() == 'student' ? widget.userId : null;
      String? teacherId = widget.role.toLowerCase() == 'evaluator' ? widget.userId : null;

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

  Widget build(BuildContext context) {
    bool isEvaluator = widget.role.toLowerCase() == 'evaluator';

    return DefaultTabController(
      length: isEvaluator ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Proyectos', style: Theme.of(context).textTheme.headlineMedium),
          backgroundColor: AppColors.backgroundOffWhite,
          elevation: 0,
          bottom: isEvaluator 
            ? const TabBar(
                tabs: [
                  Tab(text: 'Proyectos Recibidos'),
                  Tab(text: 'Mis Convocatorias'),
                ],
                labelColor: AppColors.textPrimary,
                indicatorColor: AppColors.primaryYellow,
              )
            : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchProjects,
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        floatingActionButton: (widget.role.toLowerCase() == 'admin' || widget.role.toLowerCase() == 'student' || widget.role.toLowerCase() == 'evaluator')
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) {
                    if (widget.role.toLowerCase() == 'admin') return const AdminDashboardScreen();
                    if (widget.role.toLowerCase() == 'evaluator') return AssignmentCreationScreen(teacherId: widget.userId ?? 'teacher_1');
                    return StudentUploadScreen(studentId: widget.userId ?? 'student_1');
                  },
                ),
              ).then((_) => _fetchProjects()),
              label: Text(_getFabLabel()),
              icon: Icon(_getFabIcon()),
              backgroundColor: AppColors.primaryYellow,
            )
          : null,
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : isEvaluator
            ? TabBarView(
                children: [
                   _buildProjectTab(),
                   _buildAssignmentTab(),
                ],
              )
            : _buildProjectTab(),
      ),
    );
  }

  Widget _buildProjectTab() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterChips(),
        _buildProjectListCount(),
        Expanded(child: _buildProjectList()),
      ],
    );
  }

  Widget _buildAssignmentTab() {
    return FutureBuilder<List<Assignment>>(
      future: _apiService.getAssignments(teacherId: widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final assignments = snapshot.data ?? [];
        if (assignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No has creado ninguna convocatoria aún'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => AssignmentCreationScreen(teacherId: widget.userId!))
                  ).then((_) => setState(() {})),
                  child: const Text('Crear Primera Convocatoria'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final a = assignments[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Código: ${a.accessCode ?? "---"}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showAssignmentDetails(a),
              ),
            );
          },
        );
      },
    );
  }

  void _showAssignmentDetails(Assignment a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(a.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(a.description, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryYellow),
              ),
              child: Column(
                children: [
                  const Text('Comparte este código con tus alumnos:', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(a.accessCode ?? 'N/A', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Alumnos que han entregado:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Project>>(
                future: _apiService.getProjects(assignmentId: a.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) return const Center(child: Text('Nadie ha entregado todavía', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)));
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(list[index].teamName ?? 'Alumno sin nombre'),
                      subtitle: Text(list[index].category ?? 'Proyecto'),
                      onTap: () {
                         Navigator.pop(context);
                         Navigator.push(context, MaterialPageRoute(builder: (_) => EvaluationScreen(projectId: list[index].id, projectName: list[index].title ?? 'Proyecto')));
                      },
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFabIcon() {
    if (widget.role.toLowerCase() == 'admin') return Icons.dashboard_customize;
    if (widget.role.toLowerCase() == 'evaluator') return Icons.add_task;
    return Icons.cloud_upload;
  }

  String _getFabLabel() {
    if (widget.role.toLowerCase() == 'admin') return 'Admin Panel';
    if (widget.role.toLowerCase() == 'evaluator') return 'Nueva Convocatoria';
    return 'Subir Proyecto';
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
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentUploadScreen(studentId: widget.userId ?? 'student_1'))),
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
        color: AppColors.primaryYellow.withValues(alpha: 0.1),
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
        color: isEvaluated ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
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
          if (widget.role.toLowerCase() == 'student')
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('Subir Mi Proyecto'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentUploadScreen(studentId: widget.userId ?? 'student_1'))),
            ),
          if (widget.role.toLowerCase() == 'evaluator')
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Mis Rúbricas'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RubricManagementScreen(teacherId: widget.userId ?? 'teacher_1'))),
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
