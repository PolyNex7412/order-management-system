package com.example.orderservice.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;

public record ProductRequest(
    @NotBlank(message = "商品名は必須です")
    String name,

    @NotNull(message = "価格は必須です")
    @PositiveOrZero(message = "価格は0以上で入力してください")
    BigDecimal price,

    @NotNull(message = "在庫数は必須です")
    @Min(value = 0, message = "在庫数は0以上で入力してください")
    Integer stockQuantity
) {}
