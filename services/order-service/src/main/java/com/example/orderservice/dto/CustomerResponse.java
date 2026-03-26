package com.example.orderservice.dto;

import com.example.orderservice.entity.Customer;

import java.time.LocalDateTime;

public record CustomerResponse(
    Long id,
    String name,
    String email,
    String address,
    LocalDateTime createdAt
) {
    public static CustomerResponse from(Customer c) {
        return new CustomerResponse(c.getId(), c.getName(), c.getEmail(),
            c.getAddress(), c.getCreatedAt());
    }
}
