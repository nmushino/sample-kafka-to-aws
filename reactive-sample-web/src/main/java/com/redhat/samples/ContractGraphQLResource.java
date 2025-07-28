package com.redhat.samples;

import io.smallrye.mutiny.Uni;
import jakarta.inject.Inject;
import org.eclipse.microprofile.graphql.*;
import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.List;
import java.util.UUID;
import java.time.LocalDateTime;

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
        log.info("全契約を取得します");
        return repository.listAll();
    }

    @Mutation("createContract")
    @Transactional
    public Contract createContract(@Name("contractInput") ContractInput input) {
        log.info("契約作成開始: {}", input);
    
        Contract contract = new Contract();
        contract.setContractId(input.contractId);
        contract.setCustomerId(input.customerId);
        contract.setProductId(input.productId);
        contract.setPrice(input.price);
        contract.setQuantity(input.quantity);
        contract.setCancelFlg(input.cancelFlg);
        contract.setCreateDate(input.createDate);
        contract.setUpdateDate(input.updateDate);
    
        repository.persist(contract);
        return contract;
    }

    // DTO
    public static class ContractInput {
        public UUID contractId;
        public UUID customerId;
        public String productId;
        public BigDecimal price;
        public int quantity;
        public String cancelFlg;
        public LocalDateTime createDate;
        public LocalDateTime updateDate;

        @Override
        public String toString() {
            return "ContractInput{" +
                    "contractId=" + contractId +
                    ", customerId=" + customerId +
                    ", productId='" + productId + '\'' +
                    ", price=" + price +
                    ", quantity=" + quantity +
                    ", cancelFlg='" + cancelFlg + '\'' +
                    ", createDate=" + createDate +
                    ", updateDate=" + updateDate +
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