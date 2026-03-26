package com.example.orderservice.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.util.List;

public record OrderRequest(
    @NotNull(message = "顧客IDは必須です")
    Long customerId,

    @NotEmpty(message = "受注明細は1件以上必要です")
    @Valid
    List<OrderItemRequest> items
) {
    public record OrderItemRequest(
        @NotNull(message = "商品IDは必須です")
        Long productId,

        @NotNull(message = "数量は必須です")
        @Min(value = 1, message = "数量は1以上で入力してください")
        Integer quantity
    ) {}
}
