using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NotificationService.Data;
using NotificationService.DTOs;
using NotificationService.Models;

namespace NotificationService.Controllers;

[ApiController]
[Route("api/notifications")]
[Produces("application/json")]
public class NotificationController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ILogger<NotificationController> _logger;

    public NotificationController(AppDbContext db, ILogger<NotificationController> logger)
    {
        _db = db;
        _logger = logger;
    }

    /// <summary>通知ログ一覧取得</summary>
    [HttpGet]
    public async Task<IEnumerable<NotificationResponse>> GetAll()
    {
        var notifications = await _db.Notifications
            .OrderByDescending(n => n.CreatedAt)
            .ToListAsync();
        return notifications.Select(NotificationResponse.From);
    }

    /// <summary>受注IDで通知ログ取得</summary>
    [HttpGet("order/{orderId}")]
    public async Task<IEnumerable<NotificationResponse>> GetByOrderId(long orderId)
    {
        var notifications = await _db.Notifications
            .Where(n => n.OrderId == orderId)
            .OrderByDescending(n => n.CreatedAt)
            .ToListAsync();
        return notifications.Select(NotificationResponse.From);
    }

    /// <summary>
    /// 通知受信（order-service から呼ばれる）
    /// 受注確定・キャンセル時のイベントをログとして保存する
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] NotificationRequest request)
    {
        var notification = new Notification
        {
            OrderId = request.OrderId,
            Type    = request.Type,
            Message = request.Message,
        };

        _db.Notifications.Add(notification);
        await _db.SaveChangesAsync();

        _logger.LogInformation("通知保存: OrderId={OrderId} Type={Type}", request.OrderId, request.Type);

        return CreatedAtAction(
            nameof(GetByOrderId),
            new { orderId = notification.OrderId },
            NotificationResponse.From(notification)
        );
    }
}
