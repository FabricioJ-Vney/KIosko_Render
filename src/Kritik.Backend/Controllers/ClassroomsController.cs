using Kritik.Backend.Services;
using Kritik.Shared.Models;
using Microsoft.AspNetCore.Mvc;

namespace Kritik.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ClassroomsController : ControllerBase
{
    private readonly ClassroomService _classroomService;
    private readonly EnrollmentService _enrollmentService;
    private readonly UserService _userService;

    public ClassroomsController(ClassroomService classroomService, EnrollmentService enrollmentService, UserService userService)
    {
        _classroomService = classroomService;
        _enrollmentService = enrollmentService;
        _userService = userService;
    }

    [HttpGet]
    public async Task<List<Classroom>> Get([FromQuery] string? teacherId, [FromQuery] string? studentId)
    {
        if (!string.IsNullOrEmpty(studentId))
        {
            var enrollments = await _enrollmentService.GetByStudentAsync(studentId);
            var activeClassIds = enrollments
                .Where(e => e.Status == "Accepted")
                .Select(e => e.ClassroomId)
                .ToList();
            
            var classrooms = new List<Classroom>();
            foreach (var id in activeClassIds)
            {
                var c = await _classroomService.GetAsync(id);
                if (c != null) classrooms.Add(c);
            }
            return classrooms;
        }

        if (string.IsNullOrEmpty(teacherId))
            return new List<Classroom>();

        var possibleIds = new List<string> { teacherId };

        // If teacherId is a mongo ObjectId string, also search by user email for backward compatibility
        if (teacherId.Length == 24)
        {
            var user = await _userService.GetAsync(teacherId);
            if (user != null && !string.IsNullOrEmpty(user.Email))
            {
                possibleIds.Add(user.Email);
            }
        }

        return await _classroomService.GetByTeacherIdsAsync(possibleIds);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Classroom>> GetById(string id)
    {
        var classroom = await _classroomService.GetAsync(id);
        if (classroom == null) return NotFound();
        return classroom;
    }

    [HttpGet("code/{code}")]
    public async Task<ActionResult<Classroom>> GetByCode(string code)
    {
        var classroom = await _classroomService.GetByCodeAsync(code);
        if (classroom == null) return NotFound();
        return classroom;
    }

    [HttpPost]
    public async Task<IActionResult> Post(Classroom newClassroom)
    {
        await _classroomService.CreateAsync(newClassroom);
        return Ok(newClassroom);
    }

    [HttpPost("enroll")]
    public async Task<IActionResult> Enroll(ClassEnrollment enrollment)
    {
        if (string.IsNullOrEmpty(enrollment.StudentId))
            return BadRequest("StudentId is required.");

        // If ClassroomId is missing but we have an accessCode provided (e.g. from frontend)
        // Note: ClassEnrollment model doesn't have AccessCode property, but it might be passed in JSON
        // Or the frontend might be putting the code in the ClassroomId field.
        // Let's make it robust.
        
        string targetClassroomId = enrollment.ClassroomId;
        
        // Check if the provided ClassroomId is actually an access code (usually short alphanumeric)
        // MongoDB ObjectIds are 24 chars.
        if (!string.IsNullOrEmpty(targetClassroomId) && targetClassroomId.Length != 24)
        {
            var classroom = await _classroomService.GetByCodeAsync(targetClassroomId.ToUpper());
            if (classroom != null)
            {
                targetClassroomId = classroom.Id!;
            }
            else
            {
                return NotFound("No se encontró ninguna clase con ese código.");
            }
        }

        if (string.IsNullOrEmpty(targetClassroomId))
            return BadRequest("ClassroomId or valid access code is required.");

        enrollment.ClassroomId = targetClassroomId;

        var existing = await _enrollmentService.GetAsync(enrollment.StudentId, enrollment.ClassroomId);
        if (existing != null) return BadRequest("Ya tienes una solicitud para esta clase.");
        
        await _enrollmentService.CreateAsync(enrollment);
        return Ok(enrollment);
    }

    [HttpGet("{id}/members")]
    public async Task<List<ClassEnrollment>> GetMembers(string id)
    {
        return await _enrollmentService.GetByClassAsync(id);
    }

    [HttpPatch("enroll/{enrollmentId}/status")]
    public async Task<IActionResult> UpdateEnrollmentStatus(string enrollmentId, [FromQuery] string status)
    {
        await _enrollmentService.UpdateStatusAsync(enrollmentId, status);
        return NoContent();
    }

    [HttpDelete("enroll/{studentId}/{classroomId}")]
    public async Task<IActionResult> LeaveClass(string studentId, string classroomId)
    {
        var enrollment = await _enrollmentService.GetAsync(studentId, classroomId);
        if (enrollment == null) return NotFound("Inscripción no encontrada.");
        
        await _enrollmentService.RemoveAsync(enrollment.Id!);
        return NoContent();
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(string id, Classroom updatedClassroom)
    {
        var classroom = await _classroomService.GetAsync(id);
        if (classroom is null) return NotFound();

        updatedClassroom.Id = classroom.Id;
        await _classroomService.UpdateAsync(id, updatedClassroom);
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        var classroom = await _classroomService.GetAsync(id);
        if (classroom is null) return NotFound();

        await _classroomService.RemoveAsync(id);
        return NoContent();
    }
}
