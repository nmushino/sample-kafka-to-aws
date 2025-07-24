package com.redhat.examples;

import org.apache.camel.Exchange;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Named;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@ApplicationScoped
@Named("contractMapper")
public class ContractMapper {

    public void mapToJdbcParams(Exchange exchange) {
        Map<String, Object> body = exchange.getIn().getBody(Map.class);
        Map<String, Object> params = new HashMap<>();

        params.put("1", UUID.fromString((String) body.get("contract_id")));
        params.put("2", UUID.fromString((String) body.get("customer_id")));
        params.put("3", body.get("product_id"));
        params.put("4", body.get("price"));
        params.put("5", body.get("quantity"));
        params.put("6", body.get("cancel_flg"));
        params.put("7", java.sql.Timestamp.valueOf((String) body.get("create_date")));
        params.put("8", java.sql.Timestamp.valueOf((String) body.get("update_date")));

        exchange.getIn().setHeader("CamelJdbcParameters", params);
    }
}