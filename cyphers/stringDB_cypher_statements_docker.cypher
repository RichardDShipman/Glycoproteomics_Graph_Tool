// string db cypher upload statements

// STRING DB PROTEIN_PROTEIN_INTERACTION NODES AND RELATIONSHIPS

// CONSTRAINT

CREATE CONSTRAINT IF NOT EXISTS FOR (ppi:ProteinProteinInteraction) REQUIRE ppi.string_protein_id IS UNIQUE;

// INFO - PPI NODE CREAATION AND ANNOTATION

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/stringDB/9606.protein.info.v12.0.txt' AS row FIELDTERMINATOR '\t'
MERGE (n:ProteinProteinInteraction {string_protein_id: row.`#string_protein_id`})
ON CREATE SET
    n.stringDB_annotation = row.annotation,
    n.protein_size = row.protein_size
ON MATCH SET
    n.stringDB_annotation = row.annotation,
    n.protein_size = row.protein_size;

// PPI RELATAIONSHIPS

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/stringDB/9606.protein.links.v12.0.txt' AS row FIELDTERMINATOR '\u0020'
MATCH (n1:ProteinProteinInteraction {string_protein_id: row.protein1})
MATCH (n2:ProteinProteinInteraction {string_protein_id: row.protein2})
MERGE (n1)-[r1:INTERACTS_WITH {combined_score: row.combined_score}]->(n2);

// ALIASES

// ERROR: The allocation of an extra 192.0 MiB would use more than the limit 2.8 GiB. Currently using 2.8 GiB. dbms.memory.transaction.total.max threshold reached.

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/stringDB/9606.protein.aliases.v12.0.txt' AS row FIELDTERMINATOR '\t'
WITH row WHERE row.source = 'UniProt_AC'
MATCH (n1:ProteinProteinInteraction {string_protein_id: row.protein1})
MATCH (n2:Protein {string_protein_id: row.alias + '-1'})
MERGE (n1)-[r1:ASSOCIATED_WITH ]-(n2);
