package com.redhat.examples;

import org.apache.camel.Exchange;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Named;
import org.jboss.logging.Logger;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@ApplicationScoped
@Named("contractMapper")
public class ContractMapper {

    private static final Logger LOGGER = Logger.getLogger(ContractMapper.class);

    public void mapToJdbcParams(Exchange exchange) {
        Map<String, Object> body = exchange.getIn().getBody(Map.class);
        LOGGER.infof("ContractMapper に受信したデータ: %s", body);

        Map<String, Object> after = (Map<String, Object>) body.get("after");
        if (after == null) {
            throw new IllegalArgumentException("'after' フィールドが存在しません");
        }

        Map<String, Object> params = new HashMap<>();
        params.put("1", UUID.fromString((String) after.get("contract_id")));
        params.put("2", UUID.fromString((String) after.get("customer_id")));
        params.put("3", after.get("product_id"));

        try {
            params.put("4", new BigDecimal((String) after.get("price")));
        } catch (Exception e) {
            LOGGER.warnf("price の変換に失敗しました: %s", after.get("price"));
            params.put("4", BigDecimal.ZERO); // フォールバック
        }

        Object quantityRaw = after.get("quantity");
        int quantity = (quantityRaw instanceof Number)
            ? ((Number) quantityRaw).intValue()
            : Integer.parseInt(quantityRaw.toString());
        params.put("5", quantity);

        params.put("6", after.get("cancel_flg") != null ? Integer.parseInt(after.get("cancel_flg").toString()) : 0);

        long createMicros = ((Number) after.get("create_date")).longValue();
        long updateMicros = ((Number) after.get("update_date")).longValue();

        params.put("7", new Timestamp(createMicros / 1000)); // マイクロ秒→ミリ秒
        params.put("8", new Timestamp(updateMicros / 1000));

        LOGGER.infof("JDBC パラメータ: %s", params);

        exchange.getIn().setHeader("CamelJdbcParameters", params);
    }
}

/**
これは、サンプルデータになります
{
   "before": null,
   "after": {
      "contract_id": "321181c5-2eff-4db7-916e-9ad389b1231f",
      "customer_id": "d3a2db9f-fc87-4e65-927d-acfda62ed89d",
      "product_id": "RES-4350",
      "price": "ALyK",
      "quantity": 1,
      "cancel_flg": "0",
      "create_date": 1753615162052322,
      "update_date": 1753615162052322
   },
   "source": {
      "version": "3.2.0.Final",
      "connector": "postgresql",
      "name": "system",
      "ts_ms": 1753617913929,
      "snapshot": "first",
      "db": "systemdb",
      "sequence": "[null,\"301989984\"]",
      "ts_us": 1753617913929096,
      "ts_ns": 1753617913929096000,
      "schema": "system",
      "table": "contract",
      "txId": 800,
      "lsn": 301989984,
      "xmin": null
   },
   "transaction": null,
   "op": "r",
   "ts_ms": 1753617914120,
   "ts_us": 1753617914120770,
   "ts_ns": 1753617914120770600
}
 */