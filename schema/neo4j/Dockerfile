FROM neo4j:5.26.21-enterprise

WORKDIR /workspace/schema/neo4j

COPY constraints.cypher ./constraints.cypher
COPY indexes.cypher ./indexes.cypher
COPY run-schema-test.sh ./run-schema-test.sh

RUN chmod +x ./run-schema-test.sh

ENTRYPOINT ["/workspace/schema/neo4j/run-schema-test.sh"]
