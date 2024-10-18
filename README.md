# GlycoproteomicsGraphTool_release
Neo4j-based Glycoproteomics Graph Tool

Richard Shipman -- 13AUG2024, Release: 18 OCT 2024

- (https://github.com/RichardDShipman)

This is going to serve as the core module in the glycoproteomics knowledge graph. The general purpose of this graph is to store glycoproteomic (glyoconjugates) records in relationship to common biological entities and processes. The development of this graph was inspired by the GlyGen workshop titled: GlyGen Virtual Training Workshop 2024. (https://wiki.glygen.org/GlyGen_CFDE_Biocuration2024_Workshop) GlyGen also serves as a data source for the glycoproteomics data used in this knowledge graph.

## Introduction

The Glycoproteomics Graph Tool leverages Neo4j, a graph database management system, to construct a comprehensive and interactive graph model based on GlyGen data. (https://www.glygen.org/) GlyGen is a data integration and dissemination project for glycomics and glycobiology research, providing extensive datasets on glycans, proteins, genes, and associated biological entities. At the moment, the graph stores glycoproteomics related data from humans and mice.

This tool facilitates the creation and manipulation of a graph database to model complex biological relationships. It uses a series of Cypher queries to load, update, and manage nodes and relationships in the Neo4j graph database. The graph model includes various types of nodes such as proteins, glycans, genes, motifs, and enzymes, as well as relationships that capture the biological interactions between these entities.

The following sections of the readme provide detailed instructions and Cypher queries for setting up constraints, loading data from CSV files, and establishing nodes and relationships within the graph database. This enables researchers to explore and analyze the intricate web of interactions in glycomics data, thereby advancing our understanding of glycan structures and their biological roles.

## Future Plans

This graph acts as a core for glycoproteomics projects, with GlyGen as the primary data source. In the future, additional data sources may be integrated to expand the coverage of proteins, glycans, and beyond to other related compounds and reactions. The stored graph topology of glycoproteomics data could also support applications in ML/AI. Additional glycoproteomes from other species could be added as well.

# Step-by-Step User Guide

1. Download the GlycoproteomicsGraphTool_release github repository with required ZIP File containing CSVs and neo4j.config.

2. Extract and Place CSV Files in the Import Folder of your Neo4j Database

Extract the contents of the ZIP file (graph_data.zip). Move all the CSV files into the import directory of your Neo4j database. The import directory is typically located within the Neo4j installation directory. This step is crucial for Neo4j to access the data files directly. 

3. Copy the neo4j.config File From the data Folder Into the Neo4j Config Folder 

Or add the following parameters to your neo4j.config file with a text editor at the bottom of the file:

dbms.memory.heap.initial_size=2G
dbms.memory.heap.max_size=8G
dbms.memory.pagecache.size=4G

Note: System requirements: 8Gb+ RAM.

4. Run Cypher Queries in the core_graph_statements.cypher File in the Neo4j Browser

Open the Neo4j browser from the App or the web.

- http://localhost:7474/browser/

Follow the order of the Cypher queries as outlined in the Cypher file (core_graph_statements.cypher). Each section corresponds to a specific type of node or relationship within the graph model. Execute these queries in your Neo4j browser or using a Neo4j client.

5. Explore the Glycoproteomics Graph Tool

Use the following use cases and test examples to explore the knowledge graph.

## Use Cases and Test Examples

- Test the following cypher to see if glycan to monosaccharide relationships loaded properly. 

```cypher
MATCH p=(g:Glycan {glytoucan_ac: 'G00025HU'})-[r:has_structure]-()-[r2:linkage*]-()
RETURN p;
```

![Alt text](/examples/graph1.png)

- of a set of glycans from a glycoproteins collection of glycans

```cypher
UNWIND ["G00025YC", "G00026MO", "G00030MO"] AS value
MATCH path=(g:Glycan{glytoucan_ac: value})-[]-(e:Enzyme)-[]-(p:Protein)-[]-(ge:Gene)
return path limit 100

```
![Alt text](/examples/graph2.png)

- Greater than 2 dHex in composition. dHex =< 2 

```cypher
UNWIND ["2", "3", "4", "5"] AS value
MATCH path=(g:Glycan{dHex: value})-[]-(e:Enzyme)-[]-(p:Protein)-[]-(ge:Gene)
return path limit 100;

```

![Alt text](/examples/graph3.png)

- find all glycans from humans that are synthesized by FUT8

```cypher
MATCH p=(n:Enzyme{species:'Homo sapiens', gene_name:'FUT8'})-[]-(g:Glycan{glytoucan_type:'Saccharide'}) 
RETURN g.glytoucan_ac;

```

```
	g.glytoucan_ac
"G32212NQ"
"G00888JR"
"G88365LW"
"G24782UB"
"G62145FH"
...
```

- Map Glycogenes and Enzymes to Chromosome ID (Gene to Chromosome Mapping) “Which genes of Homo sapiens are associated with proteins that are also enzymes, and what are their gene names, chromosome IDs, and species, ordered by chromosome ID in ascending order? Which chromosomes are glycogenes of interest found on?”

```cypher
MATCH x=(g:Gene{species:'Homo sapiens'})--(p:Protein)--(e:Enzyme)
RETURN g.ensembl_gene_id,
p.uniprotkb_canonical_ac,
p.gene_name,
g.chromosome_id,
g.start_pos,
g.species
ORDER BY g.chromosome_id ASC,
g.start_pos;

```

g.ensembl_gene_id	p.uniprotkb_canonical_ac	p.gene_name	g.chromosome_id	g.start_pos	g.species
"ENSG00000158850"	"O60512-1"	"B4GALT3"	"1"	"161171310"	"Homo sapiens"
"ENSG00000162630"	"O43825-1"	"B3GALT2"	"1"	"193178730"	"Homo sapiens"
"ENSG00000143641"	"Q10471-1"	"GALNT2"	"1"	"230057990"	"Homo sapiens"
"ENSG00000184389"	"U3KPV4-1"	"A3GALT2"	"1"	"33306766"	"Homo sapiens"
"ENSG00000126091"	"Q11203-1"	"ST3GAL3"	"1"	"43705824"	"Homo sapiens"

- "What are all the paths starting from a Gene with the symbol ‘ATRN’ and ending at any Monosaccharide, including all intermediate nodes and relationships between two Glycan nodes, limited to 100 results?”

```cypher
MATCH x=(n:Gene{gene_symbol:'ATRN'})--(p:Protein)--(gs:GlycosylationSite)--(gc:Glycoconjugate)--(gl:Glycan)--(gl2:Glycan)--(m:Monosaccharide)-[l:linkage*]-() RETURN x limit 100
```

![Alt text](/examples/graph4.png)

# Reference Source Materials 

GlyGen: Computational and Informatics Resources for Glycoscience, Glycobiology, Volume 30, Issue 2, February 2020, Pages 72–73, https://doi.org/10.1093/glycob/cwz080

