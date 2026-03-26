package com.example.orderservice.service;

import com.example.orderservice.dto.OrderRequest;
import com.example.orderservice.dto.OrderResponse;
import com.example.orderservice.entity.Order;
import com.example.orderservice.entity.OrderItem;
import com.example.orderservice.entity.Product;
import com.example.orderservice.exception.ResourceNotFoundException;
import com.example.orderservice.repository.CustomerRepository;
import com.example.orderservice.repository.OrderRepository;
import com.example.orderservice.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final CustomerRepository customerRepository;
    private final ProductRepository productRepository;
    private final RestTemplate restTemplate;

    @Value("${notification.service.url}")
    private String notificationServiceUrl;

    @Transactional(readOnly = true)
    public List<OrderResponse> findAll() {
        return orderRepository.findAll().stream()
            .map(OrderResponse::from)
            .toList();
    }

    @Transactional(readOnly = true)
    public OrderResponse findById(Long id) {
        Order order = orderRepository.findByIdWithCustomer(id)
            .orElseThrow(() -> new ResourceNotFoundException("受注が見つかりません: id=" + id));
        return OrderResponse.from(order);
    }

    /**
     * 受注登録
     * 1. 顧客存在チェック
     * 2. 商品ごとに悲観的ロックで在庫引当
     * 3. 受注明細・合計金額を計算して保存
     */
    @Transactional
    public OrderResponse create(OrderRequest request) {
        var customer = customerRepository.findById(request.customerId())
            .orElseThrow(() -> new ResourceNotFoundException("顧客が見つかりません: id=" + request.customerId()));

        Order order = new Order();
        order.setCustomer(customer);

        for (OrderRequest.OrderItemRequest itemReq : request.items()) {
            // 悲観的ロックで在庫を取得し、同時発注による在庫マイナスを防止
            Product product = productRepository.findByIdWithLock(itemReq.productId())
                .orElseThrow(() -> new ResourceNotFoundException("商品が見つかりません: id=" + itemReq.productId()));

            product.decreaseStock(itemReq.quantity());

            OrderItem item = new OrderItem();
            item.setOrder(order);
            item.setProduct(product);
            item.setQuantity(itemReq.quantity());
            item.setUnitPrice(product.getPrice()); // 受注時点の価格を確定
            order.getItems().add(item);
        }

        order.recalculateTotal();
        Order saved = orderRepository.save(order);
        log.info("受注登録完了: orderId={}, totalAmount={}", saved.getId(), saved.getTotalAmount());
        return OrderResponse.from(saved);
    }

    /**
     * 受注確定
     * PENDING → CONFIRMED に遷移し、notification-service に通知を依頼する
     */
    @Transactional
    public OrderResponse confirm(Long id) {
        Order order = orderRepository.findByIdWithCustomer(id)
            .orElseThrow(() -> new ResourceNotFoundException("受注が見つかりません: id=" + id));

        order.confirm();
        orderRepository.save(order);
        log.info("受注確定: orderId={}", id);

        sendNotification(id, "ORDER_CONFIRMED", "受注ID " + id + " が確定されました。");
        return OrderResponse.from(order);
    }

    /**
     * 受注キャンセル
     * 在庫を元に戻してキャンセル状態に遷移する
     */
    @Transactional
    public OrderResponse cancel(Long id) {
        Order order = orderRepository.findByIdWithCustomer(id)
            .orElseThrow(() -> new ResourceNotFoundException("受注が見つかりません: id=" + id));

        // 在庫を戻す
        for (OrderItem item : order.getItems()) {
            Product product = productRepository.findById(item.getProduct().getId())
                .orElseThrow(() -> new ResourceNotFoundException("商品が見つかりません"));
            product.setStockQuantity(product.getStockQuantity() + item.getQuantity());
        }

        order.cancel();
        orderRepository.save(order);
        log.info("受注キャンセル: orderId={}", id);

        sendNotification(id, "ORDER_CANCELLED", "受注ID " + id + " がキャンセルされました。");
        return OrderResponse.from(order);
    }

    private void sendNotification(Long orderId, String type, String message) {
        try {
            restTemplate.postForEntity(
                notificationServiceUrl + "/api/notifications",
                Map.of("orderId", orderId, "type", type, "message", message),
                Void.class
            );
        } catch (Exception e) {
            // 通知失敗は受注処理に影響させない（ログに残すのみ）
            log.warn("notification-service への通知に失敗しました: orderId={}, error={}", orderId, e.getMessage());
        }
    }
}
