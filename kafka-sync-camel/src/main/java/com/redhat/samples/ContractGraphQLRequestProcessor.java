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
    private static final DateTimeFormatter formatter = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    @Override
    public void process(Exchange exchange) throws Exception {
        Map<String, Object> body = exchange.getIn().getBody(Map.class);
        Map<String, Object> after = (Map<String, Object>) body.get("after");

        String contractId = (String) after.get("contract_id");
        String customerId = (String) after.get("customer_id");
        String productId = (String) after.get("product_id");
        int quantity = (Integer) after.get("quantity");
        String cancelFlg = (String) after.get("cancel_flg");

        // 日付の再生成（今の時間）
        String now = LocalDateTime.now().format(formatter);

        // 金額はランダムな Decimal
        BigDecimal price = BigDecimal.valueOf(random.nextDouble() * 10000)
                .setScale(2, RoundingMode.HALF_UP);

        String graphql = String.format(
            "{\"query\": \"mutation { createContract(contractInput: { contractId: \\\"%s\\\", customerId: \\\"%s\\\", productId: \\\"%s\\\", price: %s, quantity: %d, cancelFlg: \\\"%s\\\", createDate: \\\"%s\\\", updateDate: \\\"%s\\\" }) { contractId } }\"}",
            contractId, customerId, productId, price.toPlainString(), quantity, cancelFlg, now, now
        );

        System.out.println("✅ GraphQL Body: " + graphql);  // ← 一時的に出力して確認

        exchange.getIn().setBody(graphql);
        exchange.getIn().setHeader("Content-Type", "application/json");
    }
}