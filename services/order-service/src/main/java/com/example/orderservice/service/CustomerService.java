package com.example.orderservice.service;

import com.example.orderservice.dto.CustomerRequest;
import com.example.orderservice.dto.CustomerResponse;
import com.example.orderservice.entity.Customer;
import com.example.orderservice.exception.ResourceNotFoundException;
import com.example.orderservice.repository.CustomerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CustomerService {

    private final CustomerRepository customerRepository;

    @Transactional(readOnly = true)
    public List<CustomerResponse> findAll() {
        return customerRepository.findAll().stream()
            .map(CustomerResponse::from)
            .toList();
    }

    @Transactional(readOnly = true)
    public CustomerResponse findById(Long id) {
        return customerRepository.findById(id)
            .map(CustomerResponse::from)
            .orElseThrow(() -> new ResourceNotFoundException("顧客が見つかりません: id=" + id));
    }

    @Transactional
    public CustomerResponse create(CustomerRequest request) {
        Customer customer = new Customer();
        customer.setName(request.name());
        customer.setEmail(request.email());
        customer.setAddress(request.address());
        return CustomerResponse.from(customerRepository.save(customer));
    }

    @Transactional
    public CustomerResponse update(Long id, CustomerRequest request) {
        Customer customer = customerRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("顧客が見つかりません: id=" + id));
        customer.setName(request.name());
        customer.setEmail(request.email());
        customer.setAddress(request.address());
        return CustomerResponse.from(customerRepository.save(customer));
    }
}
