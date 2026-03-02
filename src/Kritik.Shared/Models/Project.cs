using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace Kritik.Shared.Models;

public class Project
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string? Id { get; set; }

    public string TeamName { get; set; } = null!;
    public string Category { get; set; } = null!;
    public List<string> Technologies { get; set; } = new();
    public string Description { get; set; } = null!;
    public List<string> Members { get; set; } = new();
    public string FairLocation { get; set; } = null!;

    public string? StudentId { get; set; }
    public string? AssignedTeacherId { get; set; }

    public List<Video> Videos { get; set; } = new();
    public List<Document> Documents { get; set; } = new();
    public string ImageUrl { get; set; } = "https://via.placeholder.com/150";
    public string? CoverImageUrl { get; set; }
}
