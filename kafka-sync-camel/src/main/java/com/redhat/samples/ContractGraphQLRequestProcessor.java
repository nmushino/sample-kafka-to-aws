package com.example;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.Random;

public class ContractGraphQLRequestProcessor implements Processor {

    private final Random random = new Random();

    // ISO8601形式のフォーマッターを定義
    private static final DateTimeFormatter formatter = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    @Override
    public void process(Exchange exchange) throws Exception {
        Map<String, Object> body = exchange.getIn().getBody(Map.class);
        Map<String, Object> after = (Map<String, Object>) body.get("after");

        String contractId = (String) after.get("contract_id");
        String customerId = (String) after.get("customer_id");
        String productId = (String) after.get("product_id");

        // quantityはInteger型想定
        int quantity = (Integer) after.get("quantity");

        String cancelFlg = (String) after.get("cancel_flg");
        String createDate = after.get("create_date").toString();
        String updateDate = after.get("update_date").toString();

        // priceをランダムDecimalで生成（例：0.00〜9999.99）
        BigDecimal price = BigDecimal.valueOf(random.nextDouble() * 10000)
                                    .setScale(2, RoundingMode.HALF_UP);

        // 現在日時をISO8601形式でセット
        String now = LocalDateTime.now().format(formatter);

        // GraphQLリクエストJSON文字列
        String graphql = String.format(
        "{\"query\": \"mutation { createContract(contractInput: { contractId: \\\"%s\\\", customerId: \\\"%s\\\", productId: \\\"%s\\\", price: %s, quantity: %d, cancelFlg: \\\"%s\\\", createDate: \\\"%s\\\", updateDate: \\\"%s\\\" }) { contractId } }\"}",
        contractId, customerId, productId, price.toPlainString(), quantity, cancelFlg, now, now);

        exchange.getIn().setBody(graphql);
        exchange.getIn().setHeader("Content-Type", "application/json");
    }
}