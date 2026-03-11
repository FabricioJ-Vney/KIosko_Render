namespace Kritik.Shared.Models;

public class Video
{
    public string Title { get; set; } = null!;
    public string Url { get; set; } = null!; // YouTube link or file path
    public string Description { get; set; } = null!;
}
