package com.redhat.samples;

import io.quarkus.hibernate.reactive.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "contract")
public class Contract extends PanacheEntityBase {

    @Id
    @Column(name = "contract_id", nullable = false)
    public UUID contractId;

    @Column(name = "customer_id", nullable = false)
    public UUID customerId;

    @Column(name = "product_id", length = 30, nullable = false)
    public String productId;

    @Column(name = "price", precision = 10, scale = 2, nullable = false)
    public BigDecimal price;

    @Column(name = "quantity", nullable = false)
    public int quantity;

    @Column(name = "cancel_flg", length = 2)
    public String cancelFlg; // "Y" / "N" の形式を想定

    @Column(name = "create_date", nullable = false)
    public LocalDateTime createDate;

    @Column(name = "update_date", nullable = false)
    public LocalDateTime updateDate;

    @PrePersist
    void onCreate() {
        this.createDate = LocalDateTime.now();
        this.updateDate = LocalDateTime.now();
    }

    @PreUpdate
    void onUpdate() {
        this.updateDate = LocalDateTime.now();
    }
}