# Install necessary packages if not already installed
install.packages(c("neo4r", "dplyr", "igraph", "tidygraph", "ggraph"))

# Load libraries
library(neo4r)     # Interface to Neo4j
library(dplyr)     # Data manipulation
library(igraph)    # Graph processing
library(tidygraph) # Tidy-style graph manipulation
library(ggraph)    # Graph visualization

# ---- Step 1: Connect to Neo4j ----
# Replace with your Neo4j credentials
con <- neo4j_api$new(
  url = "http://localhost:7474",  # Change if running Neo4j remotely
  user = "neo4j",
  password = "your_password"
)

# Test connection
if (is.null(con)) {
  stop("Failed to connect to Neo4j. Check your credentials and Neo4j status.")
}

# con$ping()

# ---- Step 2: Create a Sample Graph ----
create_query <- "
MATCH x=(p:Protein)--(s:Site)--(g:Glycan)
"

# Execute query to create nodes and relationships
con$call_neo4j(create_query, type = "row")

# ---- Step 3: Retrieve Nodes and Relationships ----
query_nodes <- "MATCH (p:Protein) RETURN p.name AS name, p.uniprot_id AS id"
proteins_df <- con$query(query_nodes) %>% as_tibble()

# Print proteins data
print(proteins_df)

query_edges <- "MATCH (a:Protein)-[r:INTERACTS_WITH]->(b:Protein) RETURN a.name AS source, b.name AS target"
edges_df <- con$query(query_edges) %>% as_tibble()

# Print edges data
print(edges_df)

# ---- Step 4: Convert to Graph Format ----
graph <- graph_from_data_frame(edges_df, directed = TRUE)

# ---- Step 5: Visualize Graph ----
ggraph(as_tbl_graph(graph), layout = "kk") +
  geom_edge_link(aes(edge_alpha = 0.5), arrow = arrow(length = unit(4, "mm"))) +
  geom_node_point(size = 6, color = "blue") +
  geom_node_text(aes(label = name), repel = TRUE, size = 5) +
  theme_minimal() +
  ggtitle("Protein Interaction Network")

# ---- Step 6: Clean Up (Optional) ----
# To delete the created nodes and relationships
cleanup_query <- "MATCH (n:Protein) DETACH DELETE n"
con$call_neo4j(cleanup_query, type = "row")

# Close the connection (no explicit function in neo4r, but good practice)
rm(con)