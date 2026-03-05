using Kritik.Backend.Services;
using Kritik.Shared.Models;
using Microsoft.AspNetCore.Mvc;

namespace Kritik.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AssignmentsController : ControllerBase
{
    private readonly AssignmentService _assignmentService;

    public AssignmentsController(AssignmentService assignmentService)
    {
        _assignmentService = assignmentService;
    }

    [HttpGet]
    public async Task<List<Assignment>> Get([FromQuery] string? teacherId)
    {
        if (!string.IsNullOrEmpty(teacherId))
            return await _assignmentService.GetByTeacherAsync(teacherId);
        return await _assignmentService.GetAsync();
    }

    [HttpGet("{id:length(24)}")]
    public async Task<ActionResult<Assignment>> GetById(string id)
    {
        var assignment = await _assignmentService.GetAsync(id);
        if (assignment is null) return NotFound();
        return assignment;
    }

    [HttpGet("code/{code}")]
    public async Task<ActionResult<Assignment>> GetByCode(string code)
    {
        var assignment = await _assignmentService.GetByAccessCodeAsync(code);
        if (assignment is null) return NotFound();
        return assignment;
    }

    [HttpPost]
    public async Task<IActionResult> Post(Assignment newAssignment)
    {
        await _assignmentService.CreateAsync(newAssignment);
        return CreatedAtAction(nameof(Get), new { id = newAssignment.Id }, newAssignment);
    }

    [HttpPut("{id:length(24)}")]
    public async Task<IActionResult> Update(string id, Assignment updatedAssignment)
    {
        var assignment = await _assignmentService.GetAsync(id);
        if (assignment is null) return NotFound();
        
        updatedAssignment.Id = assignment.Id;
        await _assignmentService.UpdateAsync(id, updatedAssignment);
        return NoContent();
    }

    [HttpDelete("{id:length(24)}")]
    public async Task<IActionResult> Delete(string id)
    {
        var assignment = await _assignmentService.GetAsync(id);
        if (assignment is null) return NotFound();
        
        await _assignmentService.RemoveAsync(id);
        return NoContent();
    }
}
