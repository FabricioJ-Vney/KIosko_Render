namespace Kritik.Shared.Models;

public class Document
{
    public string Title { get; set; } = null!;
    public string Url { get; set; } = null!; // Link to PDF or file path
    public string Type { get; set; } = "PDF"; // PDF, DOCX, etc.
}
