package com.redhat.samples;

import io.smallrye.mutiny.Uni;
import jakarta.inject.Inject;
import org.eclipse.microprofile.graphql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@GraphQLApi
public class ContractGraphQLResource {

    private static final Logger log = LoggerFactory.getLogger(ContractGraphQLResource.class);

    @Inject
    ContractRepository repository;

    @Query("allContracts")
    public Uni<List<Contract>> getAllContracts() {
        log.info("全契約を取得します");
        return repository.listAll();
    }

    @Mutation("createContract")
    public Uni<Contract> createContract(@Name("contractInput") ContractInput input) {
        log.info("契約作成開始: {}", input);

        Contract contract = new Contract();
        contract.setContractId(UUID.randomUUID());
        contract.setCustomerId(input.customerId);
        contract.setProductId(input.productId);
        contract.setPrice(input.price);
        contract.setQuantity(input.quantity);
        contract.setCancelFlg(input.cancelFlg);
        contract.setCreateDate(LocalDateTime.now());
        contract.setUpdateDate(LocalDateTime.now());

        return repository.persist(contract).replaceWith(contract);
    }

    // DTO
    public static class ContractInput {
        public UUID customerId;
        public String productId;
        public java.math.BigDecimal price;
        public int quantity;
        public String cancelFlg;

        @Override
        public String toString() {
            return "ContractInput{" +
                    "customerId=" + customerId +
                    ", productId='" + productId + '\'' +
                    ", price=" + price +
                    ", quantity=" + quantity +
                    ", cancelFlg='" + cancelFlg + '\'' +
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