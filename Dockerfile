# Use the official Neo4j Community edition image
FROM neo4j:5.12-community

# Install the Graph Data Science plugin
#ENV NEO4JLABS_PLUGINS='["graph-data-science", "apoc"]'
#ENV NEO4JLABS_PLUGINS='["apoc"]'

# Set memory configurations (adjust as needed)
ENV NEO4J_dbms_memory_heap_initial__size=1G
ENV NEO4J_dbms_memory_heap_max__size=4G
ENV NEO4J_dbms_memory_pagecache_size=2G

# Copy your CSV files into the Neo4j import folder
COPY graph_data /var/lib/neo4j/import

# (Optional) Copy your custom configuration if not using environment variables
# COPY neo4j.config /var/lib/neo4j/conf/neo4j.conf

# Expose the default Neo4j ports
EXPOSE 7474 7687
