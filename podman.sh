podman network create kafka-demo

podman run -d --name kafka-demo --network kafka-demo \
  -p 9092:9092 \
  -e KAFKA_CFG_PROCESS_ROLES=broker,controller \
  -e KAFKA_CFG_NODE_ID=1 \
  -e KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT \
  -e KAFKA_CFG_LISTENERS=PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093 \
  -e KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://host.containers.internal:9092 \
  -e KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER \
  -e KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@localhost:9093 \
  bitnami/kafka:latest

podman run -d \
  --name postgres-demo \
  --network kafka-demo \
  -e POSTGRES_USER=systemadmin \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=systemdb \
  -p 5432:5432 \
  postgres:latest

podman run -d --name kafdrop-demo \
  --network kafka-demo \
  -p 9000:9000 \
  -e KAFKA_BROKERCONNECT=kafka-demo:9092 \
  -e JVM_OPTS="-Xms32M -Xmx64M" \
  obsidiandynamics/kafdrop

podman run -d --name debezium-demo \
  --network kafka-demo \
  -p 8083:8083 \
  -e BOOTSTRAP_SERVERS=kafka-demo:9092 \
  -e GROUP_ID=1 \
  -e CONFIG_STORAGE_TOPIC=my_connect_configs \
  -e OFFSET_STORAGE_TOPIC=my_connect_offsets \
  -e STATUS_STORAGE_TOPIC=my_connect_statuses \
  quay.io/debezium/connect:latest