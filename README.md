# Glycoproteomics_Graph_Tool

Richard Shipman -- 13AUG2024, Released: 18OCT2024, Updated: 13MAR2025

- More projects on at: (https://github.com/RichardDShipman)

# Glycoproteomics Graph Tool

The Glycoproteomics Graph Tool was developed using Neo4j to create a centralized graph database that captures the intricate relationships in glycoproteomics, linking glycan structures, proteins, genes, and biological processes. By leveraging Neo4j and integrating public data from GlyGen, this tool models glycoproteomics data in a graph format, making it easier to explore and analyze the complex biological interactions of glycoeptides within the context of the proteome, glycome, glycoproteome, and beyond.

## Why Use Graphs for Glycoproteomics?

Graphs are an ideal approach because glycoproteomics sits at the intersection of multiple omics fields (proteomics, genomics, glycomics). This graph tool allows for the integration of multi-omics data, enabling the representation of biological knowledge in a contextualized manner. It facilitates the study of glycoconjugates (glycopeptides) and their connections to key biological entities, enhancing our understanding of glycosylation and its implications in health and disease. The structure makes it highly suitable for future applications in machine learning and artificial intelligence, where understanding relationships between biological components is key.

This Glycoproteomics_Graph_Tool repository serves as the core module in the construction of a glycoproteomics knowledge graph. The primary purpose of this graph is to store glycoproteomic (glycoconjugates) records in relationship to common biological entities and processes. The development of this graph was inspired by the GlyGen workshop titled GlyGen Virtual Training Workshop 2024. (https://wiki.glygen.org/GlyGen_CFDE_Biocuration2024_Workshop) GlyGen data repository also serves as a data source for the glycoproteomics data used in the construction of this knowledge graph.

![Graph Data Model](/examples/CoreGraphDataModel.png)

Graph data model of the GlycoproteomicsGraphTool_release made with the Neo4j provide Arrows.app tool. (https://arrows.app)

## Introduction

The Glycoproteomics Graph Tool leverages Neo4j, a graph database management system, to construct a comprehensive and interactive graph model based on GlyGen data. (https://www.glygen.org/) GlyGen is a data integration and dissemination project for glycomics and glycobiology research, providing extensive datasets on glycans, proteins, genes, and associated biological entities. At the moment, the graph stores glycoproteomics related data from humans and mice.

This tool facilitates the creation and manipulation of a graph database to model complex biological relationships. It uses a series of Cypher queries to load, update, and manage nodes and relationships in the Neo4j graph database. The graph model includes various types of nodes such as proteins, glycans, genes, motifs, and enzymes, as well as relationships that capture the biological interactions between these entities.

The following sections of the readme provide detailed instructions and Cypher queries for setting up constraints, loading data from CSV files, and establishing nodes and relationships within the graph database. This enables researchers to explore and analyze the intricate web of interactions in glycomics data, thereby advancing our understanding of glycan structures and their biological roles.

## Future Plans

This graph acts as a core for glycoproteomics projects, with GlyGen as the primary data source. In the future, additional data sources may be integrated to expand the coverage of proteins, glycans, and beyond to other related compounds and reactions. The stored graph topology of glycoproteomics data could also support applications in ML/AI. Additional glycoproteomes from other species could be added as well. Note: Curation steps are also needed find and fix errors in the graph, current release does contain bugs that will be resolved in future releases.

# Step-by-Step User Guide

1. Clone the Glycoproteomics_Graph_Tool github repository with required ZIP File containing CSVs, Cypher statements, and neo4j.config.

```shell
git clone https://github.com/RichardDShipman/Glycoproteomics_Graph_Tool.git
```

2. Extract and Place CSV Files in the Import Folder of your Neo4j Database

```shell
unzip graph_data.zip
```

Extract the contents of the ZIP file (graph_data.zip). Move all the CSV files into the import directory of your Neo4j database. The import directory is typically located within the Neo4j installation directory. This step is crucial for Neo4j to access the data files directly. 

3. Copy the neo4j.config File From the data Folder Into the Neo4j Config Folder 

Or add the following parameters to your neo4j.config file with a text editor at the bottom of the file:

dbms.memory.heap.initial_size=2G

dbms.memory.heap.max_size=8G

dbms.memory.pagecache.size=4G

Note: System requirements: 8Gb+ RAM.

4. Run Cypher Queries in the core_graph_statements.cypher File in the Neo4j Browser

Open the Neo4j browser from the App or the web.

- (http://localhost:7474/browser/)

Follow the order of the Cypher queries as outlined in the Cypher file (core_graph_statements.cypher). Each section corresponds to a specific type of node or relationship within the graph model. Execute these queries in your Neo4j browser or using a Neo4j client.

5. Explore the Glycoproteomics Graph Tool

Use the following use cases and test examples to explore the knowledge graph.

## Use Cases and Test Examples

- Display groups of glycans that are related to one another by composition and structure and display monosaccharide and has linkage subgraph.

```
MATCH p=(g:Glycan)-[r1:HAS_LINKAGE]-()-[r2:LINKAGE*]-() 
RETURN p LIMIT 100
```

![Alt text](/examples/graph0.png)

- Test the following cypher to see if glycan to monosaccharide relationships loaded properly. 

```cypher
MATCH p=(g:Glycan {glytoucan_ac: 'G00025HU'})-[r:HAS_LINKAGE]-()-[r2:LINKAGE*]-()
RETURN p;
```

![Alt text](/examples/graph1.png)

- Which enzymes synthesize this set of glycans?

```cypher
UNWIND ["G00025YC", "G00026MO", "G00030MO"] AS value
MATCH PATH=(g:Glycan{glytoucan_ac: value})-[]-(e:Enzyme)-[]-(p:Protein)-[]-(ge:Gene)
RETURN PATH LIMIT 100

```
![Alt text](/examples/graph2.png)

- Greater than 2 dHex in composition. dHex =< 2. 

```cypher
UNWIND ["2", "3", "4", "5"] AS value
MATCH path=(g:Glycan{dHex: value})-[]-(e:Enzyme)-[]-(p:Protein)-[]-(ge:Gene)
RETURN PATH LIMIT 100;

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

- Which glycans are associated with protein uniprot accession P00450-1 (Ceruloplasmin)?

```cypher
MATCH x=(p:Protein{uniprotkb_canonical_ac:'P00450-1'})--(gs:GlycosylationSite)--(gc:Glycoconjugate)--(g:Glycan)
RETURN x;

MATCH x=(p:Protein{uniprotkb_canonical_ac:'P00450-1'})--(gs:GlycosylationSite)--(gc:Glycoconjugate)--(g:Glycan)
RETURN  g.glytoucan_ac;
```

![Alt text](/examples/graph4.png)

g.glytoucan_ac

"G00912UN"

"G94917XT"

"G88374WZ"

"G10486CT"

"G15038BD"
...

# Dockerfile

Docker Setup for Neo4j Graph Database

1. Unzip the Data Files

First, unzip the graph_data.zip. This zip file contains the necessary Cypher statements and CSV files required for the data loading step.

```shell
unzip graph_data.zip
```

2. Build the Docker Image

To build the Docker image for Neo4j, use the following command:

```shell
docker build -t glycoproteomics-graph-tool .
```
3. Run the Docker Image

Once the image is built, you can run the container with the following command:

```shell
docker run -d \
  --name glyco-neo4j \
  -p7474:7474 -p7687:7687 \
  -v "$(pwd)/data":/var/lib/neo4j/import \
  -v neo4j-data:/data \
  glycoproteomics-graph-tool
  ```

- This command maps ports 7474 and 7687 for the Neo4j browser and bolt connection.
- It also mounts the data directory on your local machine to the container’s Neo4j import directory.

4. Run the Docker Image Using Docker Compose

Alternatively, you can use Docker Compose to simplify running the container:

```shell
docker compose up -d
```
To stop the container, use:

```shell
docker compose down
```

5. Access Neo4j Through the Browser

After starting the container, you can access the Neo4j browser interface at:

[Neo4j Web Broswer Link](http://localhost:7474/browser/)

6. Execute Cypher Queries

To execute Cypher queries from your core_graph_statements.cypher file, use the following command:

Or paste them in the browser query window if missing file errors occur.

```shell
docker exec -i glycoproteomics-graph-tool cypher-shell -u neo4j -p your_password --file /var/lib/neo4j/import/core_graph_statements_docker.cypher
```

- Make sure to replace your_password with the actual password for your Neo4j instance.

```yaml
    environment:
      - NEO4J_AUTH=neo4j/your_password  # Set username and password
```

## Docker Terminal Access

docker exec -it glycoproteomics-graph-tool bash

# Reference Source Materials 

Graph database management software:

- Neo4j Graph Databases: [Link](https://neo4j.com/)

Data sources:

- GlyGen: Computational and Informatics Resources for Glycoscience, Glycobiology, Volume 30, Issue 2, February 2020, Pages 72–73, https://doi.org/10.1093/glycob/cwz080

- Mazein, Ilya, Adrien Rougny, Alexander Mazein, Ron Henkel, Lea Gütebier, Lea Michaelis, Marek Ostaszewski, et al. “Graph Databases in Systems Biology: A Systematic Review.” Briefings in Bioinformatics 25, no. 6 (November 1, 2024): bbae561. https://doi.org/10.1093/bib/bbae561.

- Ashburner, Michael, Catherine A. Ball, Judith A. Blake, David Botstein, Heather Butler, J. Michael Cherry, Allan P. Davis, et al. “Gene Ontology: Tool for the Unification of Biology.” Nature Genetics 25, no. 1 (May 2000): 25–29. https://doi.org/10.1038/75556.

- Wang J, Chitsaz F, Derbyshire MK, Gonzales NR, Gwadz M, Lu S, Marchler GH, Song JS, Thanki N, Yamashita RA, Yang M, Zhang D, Zheng C, Lanczycki CJ, Marchler-Bauer A.The conserved domain database in 2023. Nucleic Acids Res. 2022 Jan 6;51(D1):D384-D388. doi: 10.1093/nar/gkac1096. [PubMed PMID: 36477806] 

- Mungall, Christopher J., Carlo Torniai, Georgios V. Gkoutos, Suzanna E. Lewis, and Melissa A. Haendel. “Uberon, an Integrative Multi-Species Anatomy Ontology.” Genome Biology 13, no. 1 (January 31, 2012): R5. https://doi.org/10.1186/gb-2012-13-1-r5.

- Schriml LM, Arze C, Nadendla S, Chang YW, Mazaitis M, Felix V, Feng G, Kibbe WA. Disease Ontology: a backbone for disease semantic integration. Nucleic Acids Res. 2012 Jan;40(Database issue):D940-6. doi: 10.1093/nar/gkr972. Epub 2011 Nov 12. PMID: 22080554; PMCID: PMC3245088.

- Patel S, Topping A, Ye X, Zhang H, Canaud B, Carioni P, Marelli C, Guinsburg A, Power A, Duncan N, Kooman J, van der Sande F, Usvyat LA, Wang Y, Xu X, Kotanko P, Raimann JG; the MONDO Initiative. Association between Heights of Dialysis Patients and Outcomes: Results from a Retrospective Cohort Study of the International MONitoring Dialysis Outcomes (MONDO) Database Initiative. Blood Purif. 2018;45(1-3):245-253. doi: 10.1159/000485162. Epub 2018 Jan 26. PMID: 29478048.

- Hamosh A, Scott AF, Amberger J, Valle D, McKusick VA. Online Mendelian Inheritance in Man (OMIM). Hum Mutat. 2000;15(1):57-61. doi: 10.1002/(SICI)1098-1004(200001)15:1<57::AID-HUMU12>3.0.CO;2-G. PMID: 10612823.

- Bastian FB, Roux J, Niknejad A, Comte A, Fonseca Costa SS, de Farias TM, Moretti S, Parmentier G, de Laval VR, Rosikiewicz M, Wollbrett J, Echchiki A, Escoriza A, Gharib WH, Gonzales-Porta M, Jarosz Y, Laurenczy B, Moret P, Person E, Roelli P, Sanjeev K, Seppey M, Robinson-Rechavi M. The Bgee suite: integrated curated expression atlas and comparative transcriptomics in animals. Nucleic Acids Res. 2021 Jan 8;49(D1):D831-D847. doi: 10.1093/nar/gkaa793. PMID: 33037820; PMCID: PMC7778977.

- Cantarel BL, Coutinho PM, Rancurel C, Bernard T, Lombard V, Henrissat B. The Carbohydrate-Active EnZymes database (CAZy): an expert resource for Glycogenomics. Nucleic Acids Res. 2009 Jan;37(Database issue):D233-8. doi: 10.1093/nar/gkn663. Epub 2008 Oct 5. PMID: 18838391; PMCID: PMC2686590.

- Szklarczyk, Damian, Rebecca Kirsch, Mikaela Koutrouli, Katerina Nastou, Farrokh Mehryary, Radja Hachilif, Annika L. Gable, et al. “The STRING Database in 2023: Protein-Protein Association Networks and Functional Enrichment Analyses for Any Sequenced Genome of Interest.” Nucleic Acids Research 51, no. D1 (January 6, 2023): D638–46. https://doi.org/10.1093/nar/gkac1000.

- Fabregat, Antonio, Konstantinos Sidiropoulos, Guilherme Viteri, Oscar Forner, Pablo Marin-Garcia, Vicente Arnau, Peter D’Eustachio, Lincoln Stein, and Henning Hermjakob. “Reactome Pathway Analysis: A High-Performance in-Memory Approach.” BMC Bioinformatics 18, no. 1 (March 2, 2017): 142. https://doi.org/10.1186/s12859-017-1559-2.


## License

This project is licensed under the GPL-3.0 license.
