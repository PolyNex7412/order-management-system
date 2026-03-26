package com.example.orderservice.dto;

import com.example.orderservice.entity.Product;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record ProductResponse(
    Long id,
    String name,
    BigDecimal price,
    Integer stockQuantity,
    LocalDateTime createdAt,
    LocalDateTime updatedAt
) {
    public static ProductResponse from(Product p) {
        return new ProductResponse(p.getId(), p.getName(), p.getPrice(),
            p.getStockQuantity(), p.getCreatedAt(), p.getUpdatedAt());
    }
}
