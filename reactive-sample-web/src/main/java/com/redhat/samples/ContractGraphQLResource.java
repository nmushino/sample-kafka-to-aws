package com.redhat.samples;

import io.smallrye.mutiny.Uni;
import io.smallrye.mutiny.infrastructure.Infrastructure;
import jakarta.inject.Inject;
import org.eclipse.microprofile.graphql.*;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@GraphQLApi
@ApplicationScoped
public class ContractGraphQLResource {
    private static final Logger log = LoggerFactory.getLogger(ContractGraphQLResource.class);

    @Inject
    ContractRepository repository;

    @Query("allContracts")
    public Uni<List<Contract>> getAllContracts() {
        return repository.findAll().list(); // 修正: collect() → list()
    }

    @Mutation("createContract")
    public Uni<Contract> createContract(@Name("contractInput") ContractInput input) {
        Contract contract = new Contract();
    
        contract.setContractId(input.contractId != null ? input.contractId : UUID.randomUUID());
        contract.setCustomerId(input.customerId);
        contract.setProductId(input.productId);
        contract.setPrice(input.price);
        contract.setQuantity(input.quantity);
        contract.setCancelFlg(input.cancelFlg);
    
        DateTimeFormatter formatter = DateTimeFormatter.ISO_DATE_TIME;
    
        try {
            contract.setCreateDate(input.createDate != null
                    ? LocalDateTime.parse(input.createDate, formatter)
                    : LocalDateTime.now());
        } catch (DateTimeParseException e) {
            log.warn("createDateの形式が不正です: {}", input.createDate, e);
            contract.setCreateDate(LocalDateTime.now());
        }
    
        try {
            contract.setUpdateDate(input.updateDate != null
                    ? LocalDateTime.parse(input.updateDate, formatter)
                    : LocalDateTime.now());
        } catch (DateTimeParseException e) {
            log.warn("updateDateの形式が不正です: {}", input.updateDate, e);
            contract.setUpdateDate(LocalDateTime.now());
        }
    
        return io.quarkus.hibernate.reactive.panache.Panache.withTransaction(() -> repository.persist(contract))
            .replaceWith(contract)
            .onFailure().invoke(ex -> log.error("契約作成中にエラー発生", ex));
      }

    // DTO
    public static class ContractInput {
        public UUID contractId;
        public UUID customerId;
        public String productId;
        public BigDecimal price;
        public int quantity;
        public String cancelFlg;
        public String createDate;  // ISO形式の文字列
        public String updateDate;

        @Override
        public String toString() {
            return "ContractInput{" +
                    "contractId=" + contractId +
                    ", customerId=" + customerId +
                    ", productId='" + productId + '\'' +
                    ", price=" + price +
                    ", quantity=" + quantity +
                    ", cancelFlg='" + cancelFlg + '\'' +
                    ", createDate='" + createDate + '\'' +
                    ", updateDate='" + updateDate + '\'' +
                    '}';
        }
    }
}

/*
 *実行サンプル 
query {
    allContracts {
      contractId
      productId
      price
    }
}
query {
  allContracts {
    contractId
    customerId
    productId
    price
    quantity
    cancelFlg
    createDate
    updateDate
  }
}
 */