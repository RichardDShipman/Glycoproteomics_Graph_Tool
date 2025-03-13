// BFX_DATABASES CYPHER statements

// CONSTRAINTS

CREATE CONSTRAINT IF NOT EXISTS FOR (d:DOID) REQUIRE d.do_id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (d:MONDO) REQUIRE d.mondo_id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (d:MIM) REQUIRE d.mim_id IS UNIQUE;

CREATE CONSTRAINT IF NOT EXISTS FOR (ua:UBERONAnatomical) REQUIRE ua.uberon_anatomical_id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (ud:UBERONDevelopmental) REQUIRE ud.uberon_developmental_id IS UNIQUE;

CREATE CONSTRAINT IF NOT EXISTS FOR (bg:Bgee) REQUIRE bg.bgee_id IS UNIQUE;

CREATE CONSTRAINT IF NOT EXISTS FOR (cdd:ConservedDomain) REQUIRE cdd.cdd_id IS UNIQUE;

// DISEASE DATABASE NODES AND RELATIONSHIPS

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_disease_uniprotkb.csv' AS row
WITH row WHERE row.do_id IS NOT NULL AND trim(row.do_id) <> ""
MERGE (n:DOID {do_id: row.do_id})
ON CREATE SET
    n.do_id = row.do_id
ON MATCH SET
    n.do_id = row.do_id;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_expression_disease.csv' AS row
WITH row WHERE row.do_id IS NOT NULL AND trim(row.do_name) <> ""
MERGE (n:DOID {do_id: row.do_id})
ON CREATE SET
    n.do_id = row.do_id,
    n.do_name = row.do_name
ON MATCH SET
    n.do_id = row.do_id,
    n.do_name = row.do_name;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_disease_uniprotkb.csv' AS row
WITH row WHERE row.mondo_id IS NOT NULL AND trim(row.mondo_id) <> ""
MERGE (n:MONDO {mondo_id: row.mondo_id})
ON CREATE SET
    n.mondo_id = row.mondo_id
ON MATCH SET
    n.mondo_id = row.mondo_id;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_disease_uniprotkb.csv' AS row
WITH row WHERE row.mim_id IS NOT NULL AND trim(row.mim_id) <> ""
MERGE (n:MIM {mim_id: row.mim_id})
ON CREATE SET
    n.mim_id = row.mim_id
ON MATCH SET
    n.mim_id = row.mim_id;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_disease_uniprotkb.csv' AS row 
WITH row WHERE row.do_id IS NOT NULL AND trim(row.do_id) <> ""
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:DOID {do_id: row.do_id})
MERGE (n1)-[r1:ASSOCIATED_WITH]->(n2);

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_disease_uniprotkb.csv' AS row 
WITH row WHERE row.mondo_id IS NOT NULL AND trim(row.mondo_id) <> ""
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:MONDO {mondo_id: row.mondo_id})
MERGE (n1)-[r1:ASSOCIATED_WITH]->(n2);

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_disease_uniprotkb.csv' AS row 
WITH row WHERE row.mim_id IS NOT NULL AND trim(row.mim_id) <> ""
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:MIM {mim_id: row.mim_id})
MERGE (n1)-[r1:ASSOCIATED_WITH]->(n2);

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_disease_uniprotkb.csv' AS row 
WITH row 
WHERE row.do_id IS NOT NULL AND row.mim_id IS NOT NULL AND trim(row.do_id) <> "" AND trim(row.mim_id) <> ""
MATCH (n1:DOID {do_id: row.do_id})
MATCH (n2:MIM {mim_id: row.mim_id})
MERGE (n1)-[r1:IS]-(n2);

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_disease_uniprotkb.csv' AS row 
WITH row 
WHERE row.mim_id IS NOT NULL AND row.do_id IS NOT NULL AND trim(row.mim_id) <> "" AND trim(row.mondo_id) <> ""
MATCH (n1:MIM {mim_id: row.mim_id})
MATCH (n2:MONDO {mondo_id: row.mondo_id})
MERGE (n1)-[r1:IS]-(n2);

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_disease_uniprotkb.csv' AS row 
WITH row 
WHERE row.mondo_id IS NOT NULL AND row.do_id IS NOT NULL AND trim(row.mondo_id) <> "" AND trim(row.do_id) <> ""
MATCH (n1:MONDO {mondo_id: row.mondo_id})
MATCH (n2:DOID {do_id: row.do_id})
MERGE (n1)-[r1:IS]-(n2);

// UBERON ANATOMICAL AND DEVELOPMENTAL NODES AND RELATIONSHIPS

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_expression_normal.csv' AS row
WITH row WHERE row.uberon_anatomical_id IS NOT NULL 
MERGE (n:UBERONAnatomical {uberon_anatomical_id: row.uberon_anatomical_id})
ON CREATE SET
    n.uberon_anatomical_id = row.uberon_anatomical_id,
    n.uberon_anatomical_name = row.uberon_anatomical_name
ON MATCH SET
    n.uberon_anatomical_id = row.uberon_anatomical_id,
    n.uberon_anatomical_name = row.uberon_anatomical_name;


LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_expression_normal.csv' AS row
WITH row WHERE row.uberon_anatomical_id IS NOT NULL
MERGE (n:UBERONDevelopmental {uberon_developmental_id: row.uberon_developmental_id})
ON CREATE SET
    n.uberon_developmental_id = row.uberon_developmental_id,
    n.uberon_developmental_name = row.uberon_developmental_name
ON MATCH SET
    n.uberon_developmental_id = row.uberon_developmental_id,
    n.uberon_developmental_name = row.uberon_developmental_name;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_expression_normal.csv' AS row 
WITH row 
WHERE row.uberon_anatomical_id IS NOT NULL
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:UBERONAnatomical {uberon_anatomical_id: row.uberon_anatomical_id})
MERGE (n1)-[r1:ASSOCIATED_WITH]->(n2)
ON CREATE SET
    r1.expression_level_gene_relative = row.expression_level_gene_relative,
    r1.expression_level_anatomical_relative = row.expression_level_anatomical_relative,
    r1.call_quality = row.call_quality,
    r1.expression_rank_score = row.expression_rank_score,
    r1.expression_score = row.expression_score
ON MATCH SET
    r1.expression_level_gene_relative = row.expression_level_gene_relative,
    r1.expression_level_anatomical_relative = row.expression_level_anatomical_relative,
    r1.call_quality = row.call_quality,
    r1.expression_rank_score = row.expression_rank_score,
    r1.expression_score = row.expression_score;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_expression_normal.csv' AS row 
WITH row 
WHERE row.uberon_developmental_id IS NOT NULL
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:UBERONDevelopmental {uberon_developmental_id: row.uberon_developmental_id})
MERGE (n1)-[r1:ASSOCIATED_WITH]->(n2)
ON CREATE SET
    r1.expression_level_gene_relative = row.expression_level_gene_relative,
    r1.expression_level_anatomical_relative = row.expression_level_anatomical_relative,
    r1.call_quality = row.call_quality,
    r1.expression_rank_score = row.expression_rank_score,
    r1.expression_score = row.expression_score
ON MATCH SET
    r1.expression_level_gene_relative = row.expression_level_gene_relative,
    r1.expression_level_anatomical_relative = row.expression_level_anatomical_relative,
    r1.call_quality = row.call_quality,
    r1.expression_rank_score = row.expression_rank_score,
    r1.expression_score = row.expression_score;

// BGEE NODES AND RELATIONSHIPS

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_xref_bgee.csv' AS row
WITH row WHERE row.xref_id IS NOT NULL 
MERGE (n:Bgee {bgee_id: row.xref_id})
ON CREATE SET
    n.bgee_label = row.xref_label
ON MATCH SET
    n.uberon_anatomical_id = row.uberon_anatomical_id;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_xref_bgee.csv' AS row 
WITH row 
WHERE row.xref_id IS NOT NULL
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:Bgee {bgee_id: row.xref_id})
MERGE (n1)-[r1:EXPRESSED_IN]->(n2)
ON CREATE SET
    r1.bgee_label = row.xref_label
ON MATCH SET
    r1.bgee_label = row.xref_label;


// CDD (CONSERVEDDOMAIN) NODES AND RELATIONSHIPS

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_xref_cdd.csv' AS row
WITH row WHERE row.xref_id IS NOT NULL 
MERGE (n:ConservedDomain {cdd_id: row.xref_id})
ON CREATE SET
    n.cdd_label = row.xref_label
ON MATCH SET
    n.cdd_label = row.xref_label;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/bfx_databases/human_protein_xref_cdd.csv' AS row 
WITH row 
WHERE row.xref_id IS NOT NULL
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:ConservedDomain {cdd_id: row.xref_id})
MERGE (n1)-[r1:CONTAINS]->(n2)
ON CREATE SET
    r1.cdd_label = row.xref_label
ON MATCH SET
    r1.cdd_label = row.xref_label;
