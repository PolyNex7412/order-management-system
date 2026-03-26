package com.example.orderservice.dto;

import com.example.orderservice.entity.Order;
import com.example.orderservice.entity.OrderItem;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record OrderResponse(
    Long id,
    Long customerId,
    String customerName,
    String status,
    BigDecimal totalAmount,
    List<OrderItemResponse> items,
    LocalDateTime createdAt
) {
    public record OrderItemResponse(
        Long productId,
        String productName,
        Integer quantity,
        BigDecimal unitPrice,
        BigDecimal subtotal
    ) {
        public static OrderItemResponse from(OrderItem item) {
            return new OrderItemResponse(
                item.getProduct().getId(),
                item.getProduct().getName(),
                item.getQuantity(),
                item.getUnitPrice(),
                item.getSubtotal()
            );
        }
    }

    public static OrderResponse from(Order order) {
        return new OrderResponse(
            order.getId(),
            order.getCustomer().getId(),
            order.getCustomer().getName(),
            order.getStatus().name(),
            order.getTotalAmount(),
            order.getItems().stream().map(OrderItemResponse::from).toList(),
            order.getCreatedAt()
        );
    }
}
