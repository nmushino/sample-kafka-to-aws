package com.redhat.samples;

import jakarta.persistence.*;

import jakarta.persistence.Transient;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;
import io.quarkus.hibernate.reactive.panache.PanacheEntityBase;

@Entity
@Table(name = "contract")
public class Contract extends PanacheEntityBase {

    @Id
    @Column(name = "contract_id", nullable = false)
    private UUID contractId;

    @Column(name = "customer_id", nullable = false)
    private UUID customerId;

    @Column(name = "product_id", nullable = false, length = 30)
    private String productId;

    @Column(name = "price", nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @Column(name = "quantity", nullable = false)
    private int quantity;

    @Column(name = "cancel_flg", length = 2)
    private String cancelFlg;

    @Column(name = "create_date", nullable = false)
    public LocalDateTime createDate;

    @Column(name = "update_date", nullable = false)
    public LocalDateTime updateDate;

    @Transient
    public UUID id;

    @Transient
    public String name;

    @Transient
    public String status;

    // --- ゲッターとセッター ---

    public UUID getContractId() {
        return contractId;
    }

    public void setContractId(UUID contractId) {
        this.contractId = contractId;
    }

    public UUID getCustomerId() {
        return customerId;
    }

    public void setCustomerId(UUID customerId) {
        this.customerId = customerId;
    }

    public String getProductId() {
        return productId;
    }

    public void setProductId(String productId) {
        this.productId = productId;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    public String getCancelFlg() {
        return cancelFlg;
    }

    public void setCancelFlg(String cancelFlg) {
        this.cancelFlg = cancelFlg;
    }

    public LocalDateTime getCreateDate() {
        return createDate;
    }

    public void setCreateDate(LocalDateTime createDate) {
        this.createDate = createDate;
    }

    public LocalDateTime getUpdateDate() {
        return updateDate;
    }

    public void setUpdateDate(LocalDateTime updateDate) {
        this.updateDate = updateDate;
    }

    public void setTimestamps() {
        LocalDateTime now = LocalDateTime.now();
        this.createDate = now;
        this.updateDate = now;
    }

    public void ensureId() {
        if (this.contractId == null) {
            this.contractId = UUID.randomUUID();
        }
    }
}