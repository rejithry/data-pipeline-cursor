FROM eclipse-temurin:11-jre

# Set environment variables
ENV HADOOP_VERSION=3.3.6
ENV HIVE_VERSION=3.1.3
ENV HADOOP_HOME=/opt/hadoop
ENV HIVE_HOME=/opt/hive
ENV PATH=$HIVE_HOME/bin:$HADOOP_HOME/bin:$PATH

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    netcat-openbsd \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Download and install Hadoop
RUN curl -fsSL https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    | tar -xz -C /opt \
    && mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME}

# Download and install Hive
RUN curl -fsSL https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz \
    | tar -xz -C /opt \
    && mv /opt/apache-hive-${HIVE_VERSION}-bin ${HIVE_HOME}

# Download PostgreSQL JDBC driver
RUN curl -fsSL https://jdbc.postgresql.org/download/postgresql-42.7.1.jar \
    -o ${HIVE_HOME}/lib/postgresql-42.7.1.jar

# Download AWS SDK for S3/MinIO support
RUN curl -fsSL https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar \
    -o ${HIVE_HOME}/lib/hadoop-aws-${HADOOP_VERSION}.jar \
    && curl -fsSL https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar \
    -o ${HIVE_HOME}/lib/aws-java-sdk-bundle-1.12.262.jar

# Copy Hadoop configuration to Hive
RUN cp ${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-aws-${HADOOP_VERSION}.jar ${HIVE_HOME}/lib/ 2>/dev/null || true

# Copy metastore configuration
COPY metastore-site.xml ${HIVE_HOME}/conf/hive-site.xml

# Create directories
RUN mkdir -p /user/hive/warehouse

# Set working directory
WORKDIR ${HIVE_HOME}

# Initialize schema and start metastore
CMD ["sh", "-c", "schematool -dbType postgres -initSchema --verbose || true; hive --service metastore"]

EXPOSE 9083
