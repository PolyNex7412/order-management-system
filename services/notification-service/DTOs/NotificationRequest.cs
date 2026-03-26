using System.ComponentModel.DataAnnotations;

namespace NotificationService.DTOs;

public record NotificationRequest(
    [Required] long OrderId,
    [Required][MaxLength(50)] string Type,
    string? Message
);
