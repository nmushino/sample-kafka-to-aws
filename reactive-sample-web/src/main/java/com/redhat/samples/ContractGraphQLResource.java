package com.redhat.samples;

import io.smallrye.mutiny.Uni;
import jakarta.inject.Inject;
import org.eclipse.microprofile.graphql.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@GraphQLApi
public class ContractGraphQLResource {

    @Inject
    ContractRepository repository;

    @Query("allContracts")
    public Uni<List<Contract>> getAllContracts() {
        return repository.listAll();
    }

    @Mutation("createContract")
    public Uni<Contract> createContract(@Name("contractInput") ContractInput input) {
        Contract contract = new Contract();
        contract.setContractId(UUID.randomUUID());
        contract.setCustomerId(input.customerId);
        contract.setProductId(input.productId);
        contract.setPrice(input.price);
        contract.setQuantity(input.quantity);
        contract.setCancelFlg(input.cancelFlg);
        contract.setCreateDate(LocalDateTime.now());
        contract.setUpdateDate(LocalDateTime.now());

        // DB保存後にバックログ処理を非同期で呼び出す
        return repository.persist(contract)
            .flatMap(voidRes -> contractLogService.logContractCreationAsync(contract))
            .replaceWith(contract);
    }

    // 入力用 DTO
    public static class ContractInput {
        public UUID customerId;
        public String productId;
        public java.math.BigDecimal price;
        public int quantity;
        public String cancelFlg;
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