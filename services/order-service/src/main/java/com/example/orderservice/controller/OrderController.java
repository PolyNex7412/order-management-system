package com.example.orderservice.controller;

import com.example.orderservice.dto.OrderRequest;
import com.example.orderservice.dto.OrderResponse;
import com.example.orderservice.service.OrderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
@Tag(name = "Orders", description = "受注管理")
public class OrderController {

    private final OrderService orderService;

    @GetMapping
    @Operation(summary = "受注一覧取得")
    public List<OrderResponse> findAll() {
        return orderService.findAll();
    }

    @GetMapping("/{id}")
    @Operation(summary = "受注詳細取得")
    public OrderResponse findById(@PathVariable Long id) {
        return orderService.findById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "受注登録（在庫引当）")
    public OrderResponse create(@Valid @RequestBody OrderRequest request) {
        return orderService.create(request);
    }

    @PostMapping("/{id}/confirm")
    @Operation(summary = "受注確定（PENDING → CONFIRMED）")
    public OrderResponse confirm(@PathVariable Long id) {
        return orderService.confirm(id);
    }

    @PostMapping("/{id}/cancel")
    @Operation(summary = "受注キャンセル（在庫戻し）")
    public OrderResponse cancel(@PathVariable Long id) {
        return orderService.cancel(id);
    }
}
