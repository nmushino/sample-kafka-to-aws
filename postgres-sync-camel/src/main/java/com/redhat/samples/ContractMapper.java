package com.redhat.examples;

import org.apache.camel.Exchange;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Named;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@ApplicationScoped
@Named("contractMapper")
public class ContractMapper {

    public void mapToJdbcParams(Exchange exchange) {
        Map<String, Object> body = exchange.getIn().getBody(Map.class);
        
        // "detail" を取り出す
        Map<String, Object> detail = (Map<String, Object>) body.get("detail");
        if (detail == null) {
            throw new IllegalArgumentException("detail が存在しません");
        }

        // "data" を取り出す
        Map<String, Object> data = (Map<String, Object>) detail.get("data");
        if (data == null) {
            throw new IllegalArgumentException("detail.data が存在しません");
        }

        Map<String, Object> params = new HashMap<>();
        params.put("1", UUID.fromString((String) body.get("contractId")));
        params.put("2", UUID.fromString((String) body.get("customerId")));
        params.put("3", body.get("productId"));
        params.put("4", new BigDecimal((String) body.get("price"))); 
        params.put("5", Integer.valueOf((String) body.get("quantity"))); 
        params.put("6", 0); 
        params.put("7", Timestamp.valueOf((String) body.get("create_date")));
        params.put("8", Timestamp.valueOf((String) body.get("update_date")));

        exchange.getIn().setHeader("CamelJdbcParameters", params);
    }
}

/**
これは、サンプルデータになります
{
   "version": "0",
   "id": "6c29be11-c620-a2df-62ea-568fedc52747",
   "detail-type": "MyDetailType",
   "source": "eventbridge.app",
   "account": "972544472588",
   "time": "2025-07-26T00:13:02Z",
   "region": "ap-southeast-1",
   "resources": [],
   "detail": {
      "data": {
         "contractId": "898d5561-a89f-4e00-aa00-cd3fc73ec41f",
         "customerId": "9f34a117-7d99-4f3c-9fb2-be6b67010541",
         "productId": "PROD-0001",
         "price": "0.00",
         "quantity": "1",
         "create_date": "2025-07-26 08:46:24",
         "update_date": "2025-07-26 08:46:24"
      }
   }
}
 */