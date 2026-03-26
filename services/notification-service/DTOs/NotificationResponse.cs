using NotificationService.Models;

namespace NotificationService.DTOs;

public record NotificationResponse(
    long Id,
    long OrderId,
    string Type,
    string? Message,
    DateTime CreatedAt
)
{
    public static NotificationResponse From(Notification n) =>
        new(n.Id, n.OrderId, n.Type, n.Message, n.CreatedAt);
}
