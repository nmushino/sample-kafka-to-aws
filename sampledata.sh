#!/bin/bash

# 出力先ファイル
OUTFILE="data.sql"

generate_uuid() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen
  else
    cat /proc/sys/kernel/random/uuid
  fi
}

random_date() {
  days_ago=$((RANDOM % 365))
  date -v -${days_ago}d +"%Y-%m-%d %H:%M:%S"
}

for i in $(seq 1 100); do
  contract_id=$(generate_uuid)
  customer_id=$(generate_uuid)
  product_num=$(printf "%03d" $((RANDOM % 1000)))
  product_id="PROD-${product_num}"
  price=$(awk -v seed=$RANDOM 'BEGIN { srand(seed); printf("%.2f\n", rand() * 10000) }')
  quantity=$(( (RANDOM % 10) + 1 ))
  cancel_flg=$((RANDOM % 10 < 2 ? 1 : 0))
  create_date=$(random_date)
  update_date=$(date +"%Y-%m-%d %H:%M:%S")

  echo "INSERT INTO contract (contract_id, customer_id, product_id, price, quantity, cancel_flg, create_date, update_date) VALUES ('${contract_id}', '${customer_id}', '${product_id}', ${price}, ${quantity}, ${cancel_flg}, '${create_date}', '${update_date}');"
done > "$OUTFILE"

echo "100件のINSERT文を $OUTFILE に出力しました。"