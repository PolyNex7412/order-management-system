namespace NotificationService.Models;

public class Notification
{
    public long Id { get; set; }

    // Flyway (order-service) が作成した orders テーブルへの外部キー
    public long OrderId { get; set; }

    // ORDER_CONFIRMED / ORDER_CANCELLED など
    public string Type { get; set; } = string.Empty;

    public string? Message { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
