FROM confluentinc/cp-kafka-connect:7.5.0

# Set environment variables for Iceberg connector
ENV CONNECT_PLUGIN_PATH=/usr/share/java,/usr/share/confluent-hub-components

USER root

# Install unzip
RUN microdnf install -y unzip && microdnf clean all

# Create directory for Iceberg connector
RUN mkdir -p /usr/share/confluent-hub-components/iceberg-sink

# Download Iceberg Kafka Connect from Tabular.io releases
RUN curl -fsSL -L https://github.com/tabular-io/iceberg-kafka-connect/releases/download/v0.6.19/iceberg-kafka-connect-runtime-0.6.19.zip \
    -o /tmp/iceberg-kafka-connect.zip \
    && unzip /tmp/iceberg-kafka-connect.zip -d /tmp/iceberg-extract/ \
    && mv /tmp/iceberg-extract/*/* /usr/share/confluent-hub-components/iceberg-sink/ \
    && rm -rf /tmp/iceberg-kafka-connect.zip /tmp/iceberg-extract

# Download Iceberg Hive Metastore catalog JAR (required for Hive catalog type)
RUN curl -fsSL https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-hive-metastore/1.5.2/iceberg-hive-metastore-1.5.2.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/iceberg-hive-metastore-1.5.2.jar

# Download Hive Standalone Metastore (contains the API classes)
RUN curl -fsSL https://repo1.maven.org/maven2/org/apache/hive/hive-standalone-metastore/3.1.3/hive-standalone-metastore-3.1.3.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/hive-standalone-metastore-3.1.3.jar

# Download Hive Metastore client dependencies
RUN curl -fsSL https://repo1.maven.org/maven2/org/apache/hive/hive-metastore/3.1.3/hive-metastore-3.1.3.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/hive-metastore-3.1.3.jar \
    && curl -fsSL https://repo1.maven.org/maven2/org/apache/thrift/libthrift/0.9.3/libthrift-0.9.3.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/libthrift-0.9.3.jar \
    && curl -fsSL https://repo1.maven.org/maven2/org/apache/thrift/libfb303/0.9.3/libfb303-0.9.3.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/libfb303-0.9.3.jar

# Download Hive exec and serde (additional Hive dependencies)
RUN curl -fsSL https://repo1.maven.org/maven2/org/apache/hive/hive-exec/3.1.3/hive-exec-3.1.3-core.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/hive-exec-3.1.3-core.jar \
    && curl -fsSL https://repo1.maven.org/maven2/org/apache/hive/hive-serde/3.1.3/hive-serde-3.1.3.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/hive-serde-3.1.3.jar \
    && curl -fsSL https://repo1.maven.org/maven2/org/apache/hive/hive-common/3.1.3/hive-common-3.1.3.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/hive-common-3.1.3.jar \
    && curl -fsSL https://repo1.maven.org/maven2/org/apache/hive/hive-storage-api/2.8.1/hive-storage-api-2.8.1.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/hive-storage-api-2.8.1.jar

# Download Hadoop dependencies
RUN curl -fsSL https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-common/3.3.6/hadoop-common-3.3.6.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/hadoop-common-3.3.6.jar \
    && curl -fsSL https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-hdfs-client/3.3.6/hadoop-hdfs-client-3.3.6.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/hadoop-hdfs-client-3.3.6.jar \
    && curl -fsSL https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-mapreduce-client-core/3.3.6/hadoop-mapreduce-client-core-3.3.6.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/hadoop-mapreduce-client-core-3.3.6.jar \
    && curl -fsSL https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-auth/3.3.6/hadoop-auth-3.3.6.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/hadoop-auth-3.3.6.jar \
    && curl -fsSL https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-client-api/3.3.6/hadoop-client-api-3.3.6.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/hadoop-client-api-3.3.6.jar \
    && curl -fsSL https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-client-runtime/3.3.6/hadoop-client-runtime-3.3.6.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/hadoop-client-runtime-3.3.6.jar

# Download Apache Commons dependencies (required by Hadoop/Hive)
RUN curl -fsSL https://repo1.maven.org/maven2/org/apache/commons/commons-configuration2/2.8.0/commons-configuration2-2.8.0.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/commons-configuration2-2.8.0.jar \
    && curl -fsSL https://repo1.maven.org/maven2/commons-logging/commons-logging/1.2/commons-logging-1.2.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/commons-logging-1.2.jar \
    && curl -fsSL https://repo1.maven.org/maven2/org/apache/commons/commons-text/1.10.0/commons-text-1.10.0.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/commons-text-1.10.0.jar \
    && curl -fsSL https://repo1.maven.org/maven2/commons-lang/commons-lang/2.6/commons-lang-2.6.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/commons-lang-2.6.jar

# Download AWS SDK for S3/MinIO support
RUN curl -fsSL https://repo1.maven.org/maven2/software/amazon/awssdk/bundle/2.21.29/bundle-2.21.29.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/aws-bundle-2.21.29.jar \
    && curl -fsSL https://repo1.maven.org/maven2/software/amazon/awssdk/url-connection-client/2.21.29/url-connection-client-2.21.29.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/url-connection-client-2.21.29.jar

# Download Hadoop AWS for S3A filesystem support
RUN curl -fsSL https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/hadoop-aws-3.3.6.jar \
    && curl -fsSL https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar \
    -o /usr/share/confluent-hub-components/iceberg-sink/lib/aws-java-sdk-bundle-1.12.262.jar

# List the installed JARs for debugging
RUN ls -la /usr/share/confluent-hub-components/iceberg-sink/lib/

# Copy connector registration script
COPY register-connector.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/register-connector.sh

USER appuser
