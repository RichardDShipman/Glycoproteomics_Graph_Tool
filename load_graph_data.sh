#!/bin/bash
# Script Name: load_graph_data.sh
# Description: This script loads graph data for the Glycoproteomics Graph Tool.
# Author: Richard Shipman

# Set the variables
USERNAME="neo4j"
PASSWORD="your_password"
CONTAINER="glycoproteomics-graph-tool"

# let user know whats going on.
echo "Checking for graph_data folder."

# Check if the graph_data folder has been unzipped, unzip if needed
if [ ! -d "./graph_data" ]; then
    echo "Unzipping graph_data.zip..."
    unzip ./graph_data.zip -d /graph_data
else
    echo "graph_data folder already exists."
fi

# Let the user know graph data loading has started
echo "Graph data loading started for glycoproteomics-graph-tool. Please wait. Check transaction history (SHOW TRANSACTIONS;) in Neo4j browser for progress."

# Load data
docker exec -i $CONTAINER cypher-shell -u $USERNAME -p $PASSWORD --file /var/lib/neo4j/import/core_graph_statements_docker.cypher

# Finish
echo "Graph data loading has finished."
