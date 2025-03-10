// Glycoproteomics Graph Tool 
// Author: Richard Shipman, 15AUG2024
// Function: Neo4j Cypher statements to build the Glycoproteomics Graph Tool's graph database, 2nd draft.

// Ensure that each property of each node is unique
CREATE CONSTRAINT IF NOT EXISTS FOR (o:Organism) REQUIRE o.taxid IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (g:Gene) REQUIRE g.ensembl_gene_id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (gl:Glycan) REQUIRE gl.glytoucan_ac IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (m:Monosaccharide) REQUIRE m.residue_id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (m:Motif) REQUIRE m.motif_ac IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (p:Protein) REQUIRE p.uniprotkb_canonical_ac IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (p:Enzyme) REQUIRE p.uniprotkb_canonical_ac IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (g:GlycosylationSite) REQUIRE g.protein_glycosylation_site IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (gc:Glycoconjugate) REQUIRE gc.glycoconjugate_sequence IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (go:GeneOntology) REQUIRE go.go_term_id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (ci:Citation) REQUIRE ci.title IS UNIQUE;

// PROTEIN NODES AND RELATIONSHIPS

// Load mouse protein data from a CSV file and merge it into the Protein nodes, ensuring unique entries based on 'uniprotkb_canonical_ac'
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/mouse_protein_masterlist.csv' AS row
MERGE (n:Protein {
    uniprotkb_canonical_ac: row.uniprotkb_canonical_ac,
    status: row.status,
    gene_name: row.gene_name,
    species: 'Mus musculus'
});

// Load human protein data from a CSV file and merge it into the Protein nodes, ensuring unique entries based on 'uniprotkb_canonical_ac'
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_protein_masterlist.csv' AS row
MERGE (n:Protein {
    uniprotkb_canonical_ac: row.uniprotkb_canonical_ac,
    status: row.status,
    gene_name: row.gene_name,
    species: 'Homo sapiens'
});

// Load human protein reference sequence data from a CSV file and update the corresponding Protein nodes with additional RefSeq information
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_protein_info_refseq.csv' AS row
MATCH (n:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
SET n.p_refseq_ac_best_match = row.p_refseq_ac_best_match,
    n.refseq_protein_name = row.refseq_protein_name,
    n.refseq_protein_length = row.refseq_protein_length,
    n.refseq_protein_summary = row.refseq_protein_summary;

// Update Protein nodes with data from a CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/mouse_protein_info_uniprotkb.csv' AS row
MATCH (n:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
SET n.uniprotkb_id = row.uniprotkb_id,
    n.uniprotkb_protein_mass = row.uniprotkb_protein_mass,
    n.uniprotkb_protein_length = row.uniprotkb_protein_length;

// Update Protein nodes with data from the human protein CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_protein_info_uniprotkb.csv' AS row
MATCH (n:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
SET n.uniprotkb_id = row.uniprotkb_id,
    n.uniprotkb_protein_mass = row.uniprotkb_protein_mass,
    n.uniprotkb_protein_length = row.uniprotkb_protein_length;

// GLYCAN NODES AND RELATIONSHIPS

// Create or update Glycan nodes with data from the glycan master list CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_masterlist.csv' AS row
MERGE (n:Glycan {
    glytoucan_ac: row.glytoucan_ac,
    glytoucan_type: row.glytoucan_type,
    glycan_mass: row.glycan_mass,
    glycan_permass: row.glycan_permass,
    base_composition: row.base_composition,
    composition: row.composition,
    topology: row.topology,
    monosaccharides: row.monosaccharides,
    is_motif: row.is_motif,
    missing_score: row.missing_score
});

// Create or update relationships between Glycan nodes based on data from the subsumption CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_subsumption.csv' AS row
WITH row WHERE row.relationship IS NOT NULL AND row.relationship <> 'MissingScore' AND row.relationship <> 'Level'
MATCH (n1:Glycan {glytoucan_ac: row.glytoucan_ac})
MATCH (n2:Glycan {glytoucan_ac: row.related_accession})
MERGE (n1)-[r1:has]-(n2)
SET r1.relationship = row.relationship,
    r1.glytoucan_type = row.glytoucan_type;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_monosaccharide_composition.csv' AS row
MATCH (n:Glycan {glytoucan_ac: row.glytoucan_ac})
SET n.Hex = row.Hex,
    n.HexNAc = row.HexNAc,
    n.dHex = row.dHex,
    n.NeuAc = row.NeuAc,
    n.NeuGc = row.NeuGc,
    n.HexA = row.HexA,
    n.S = row.S,
    n.P = row.P,
    n.aldi = row.aldi,
    n.Xxx = row.Xxx,
    n.X = row.X,
    n.Count = row.Count;

// Update Glycan nodes with sequence data from the Byonic database, extracting the first part of the sequence before the ' %' delimiter
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_sequences_byonic.csv' AS row
MATCH (n:Glycan {glytoucan_ac: row.glytoucan_ac})
SET n.sequence_byonic = split(row.sequence_byonic, ' %')[0];

// Update Glycan nodes with Byonic sequence data, extracting the part of the sequence before the ' %' delimiter
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_type_n_linked_byonic.csv' AS row
MATCH (n:Glycan {glytoucan_ac: row.glytoucan_ac})
SET n.sequence_byonic = split(row.byonic, ' %')[0];

// Update Glycan nodes with detailed dictionary and reference information from the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_dictionary.csv' AS row
MATCH (n:Glycan {glytoucan_ac: row.glytoucan_ac})
SET n.term = row.term,
    n.term_in_sentence = row.term_in_sentence,
    n.publication = row.publication,
    n.definition = row.definition,
    n.synonymns = row.synonymns,
    n.function = row.function,
    n.disease_associations = row.disease_associations,
    n.wikipedia = row.wikipedia,
    n.essentials_of_glycobiology = row.essentials_of_glycobiology;

// Update Glycan nodes with IUPAC sequence data from the GlyCam database
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_sequences_glycam_iupac.csv' AS row
MATCH (n:Glycan {glytoucan_ac: row.glytoucan_ac})
SET n.sequence_glycam_iupac = row.sequence_glycam_iupac;

// Update Glycan nodes with term and term-in-sentence data from the GlycoCT sequences CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_sequences_glycoct.csv' AS row
MATCH (n:Glycan {glytoucan_ac: row.glytoucan_ac})
SET n.term = row.term,
n.term_in_sentence = row.term_in_sentence;

// Update Glycan nodes with InChI sequence and InChI key data from the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_sequences_inchi.csv' AS row
MATCH (n:Glycan {glytoucan_ac: row.glytoucan_ac})
SET n.sequence_inchi = row.sequence_inchi,
n.inchi_key = row.inchi_key;

// Update Glycan nodes with IUPAC sequence and IUPAC key data from the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_sequences_iupac_extended.csv' AS row
MATCH (n:Glycan {glytoucan_ac: row.glytoucan_ac})
SET n.sequence_iupac_extended = row.sequence_iupac_extended;

// Update Glycan nodes with SMILES isomeric sequence and PubChem ID from the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_sequences_smiles_isomeric.csv' AS row
MATCH (n:Glycan {glytoucan_ac: row.glytoucan_ac})
SET n.sequence_smiles_isomeric = row.sequence_smiles_isomeric,
n.pubchem_id = row.pubchem_id;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_sequences_wurcs.csv' AS row
MATCH (n:Glycan {glytoucan_ac: row.glytoucan_ac})
SET n.sequence_wurcs = row.sequence_wurcs;

// Update Glycan nodes with GWB sequence data from the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_sequences_gwb.csv' AS row
MATCH (n:Glycan {glytoucan_ac: row.glytoucan_ac})
SET n.sequence_gwb = row.sequence_gwb;

// Update Glycan nodes with name and domain information from the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_names.csv' AS row
MATCH (n:Glycan {glytoucan_ac: row.glytoucan_ac})
SET n.glycan_name = row.glycan_name,
n.glycan_name_domain = row.glycan_name_domain;

// MOTIF NODES AND RELATIONSHIPS

// Create or update Motif nodes with detailed information from the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_motif.csv' AS row
MERGE (n:Motif {
    motif_ac: row.motif_ac,
    motif_name: row.motif_name,
    alignment: row.alignment,
    collection_name: row.collection_name,
    collection_accession: row.collection_accession,
    alternative_name: row.alternative_name,
    aglycon: row.aglycon,
    motif_ac_xref: row.motif_ac_xref,
    reducing_end: row.reducing_end,
    pmid: row.pmid,
    keyword: row.keyword
});

// Create or update relationships between Motif and Glycan nodes based on motif and glycan identifiers from the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_motif.csv' AS row
MATCH (n1:Motif {motif_ac: row.motif_ac})
MATCH (n2:Glycan {glytoucan_ac: row.glytoucan_ac})
MERGE (n1)<-[r1:has]-(n2);

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_classification.csv' AS row
WITH row WHERE row.glycan_type_source = 'GlycoMotif'
MERGE (n:Motif {motif_ac: row.glycan_type_source_id})
ON CREATE SET
    n.glycan_type = row.glycan_type,
    n.go_term_category = row.go_term_category,
    n.eco_id = row.eco_id,
    n.pmid = row.pmid
ON MATCH SET
    n.glycan_type = row.glycan_type,
    n.go_term_category = row.go_term_category,
    n.eco_id = row.eco_id,
    n.pmid = row.pmid;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_classification.csv' AS row
WITH row WHERE row.glycan_type_source = 'GlycoMotif'
MATCH (n1:Motif {motif_ac: row.glycan_type_source_id})
MATCH (n2:Glycan {glytoucan_ac: row.glytoucan_ac})
MERGE (n1)<-[r1:has]-(n2);

// GENE NODES AND RELATIONSHIPS

// Create or update Gene nodes with genomic information from the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/mouse_protein_genelocus.csv' AS row
MERGE (n:Gene { ensembl_gene_id: row.ensembl_gene_id })
SET n.gene_symbol = row.gene_symbol,
    n.chromosome_id = row.chromosome_id,
    n.start_pos = row.start_pos,
    n.end_pos = row.end_pos,
    n.strand = row.strand,
    n.species = 'Mus musculus';

// Create or update Gene nodes with genomic information for human genes from the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_protein_genelocus.csv' AS row
MERGE (n:Gene { ensembl_gene_id: row.ensembl_gene_id })
SET n.gene_symbol = row.gene_symbol,
    n.chromosome_id = row.chromosome_id,
    n.start_pos = row.start_pos,
    n.end_pos = row.end_pos,
    n.strand = row.strand,
    n.species = 'Homo sapiens';

// Create or update 'encodes' relationships between Gene and Protein nodes based on the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/mouse_protein_genelocus.csv' AS row
MATCH (n1:Gene {ensembl_gene_id: row.ensembl_gene_id})
MATCH (n2:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MERGE (n1)-[r1:encodes]->(n2);

// Create or update 'encodes' relationships between Gene and Protein nodes based on the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_protein_genelocus.csv' AS row
MATCH (n1:Gene {ensembl_gene_id: row.ensembl_gene_id})
MATCH (n2:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MERGE (n1)-[r1:encodes]->(n2);

// ORGANISM NODES AND RELATIONSHIPS

// Create or update Organism nodes with taxonomy information from the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_species.csv' AS row
MERGE (n:Organism {
    taxid: row.tax_id,
    tax_name: row.tax_name
});

// Create or update 'has' relationships between Organism and Glycan nodes based on the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_species.csv' AS row
MATCH (n1:Organism {taxid: row.tax_id})
MATCH (n2:Glycan {glytoucan_ac: row.glytoucan_ac})
MERGE (n1)-[r1:has]->(n2);

// ENZYME NODES AND RELATIONSHIPS

// Create or update Enzyme nodes with detailed information from the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_enzyme.csv' AS row
MERGE (n:Enzyme {
    uniprotkb_canonical_ac: row.uniprotkb_canonical_ac,
    uniprotkb_ac: row.uniprotkb_ac,
    gene_name: row.gene_name,
    enzyme_type: row.enzyme_type,
    species: row.species,
    recommended_name_full: row.recommended_name_full
});

// Create or update 'is_a' relationships between Enzyme and Protein nodes based on the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_enzyme.csv' AS row 
MATCH (n1:Enzyme {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MERGE (n1)<-[r1:is_a]-(n2);

// Create or update 'synthesizes' relationships between Enzyme and Glycan nodes based on the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_enzyme.csv' AS row 
MATCH (n1:Enzyme {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:Glycan {glytoucan_ac: row.glytoucan_ac})
MERGE (n1)-[r1:synthesizes]->(n2);

// MONOSACCHRIDE NODES AND RELATIONSHIPS

// Load and update Monosaccharide nodes for the core glycan subgraph
// This subgraph represents the total structure of all possible glycan structures known in humans and mice
// Future modifications might include splitting by species
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_enzyme.csv' AS row
MERGE (n:Monosaccharide { residue_id: row.residue_id })
ON CREATE SET
  n.residue_identifier = row.residue_id,
  n.residue_name = row.residue_name,
  n.subgraph = 'core_glycan_subgraph'
ON MATCH SET
  n.residue_identifier = row.residue_id,
  n.residue_name = row.residue_name,
  n.subgraph = 'core_glycan_subgraph';

// Create or update Monosaccharide nodes with detailed information from the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_enzyme.csv' AS row
MERGE (n:Monosaccharide { residue_id: row.residue_id + '-' + row.glytoucan_ac })
ON CREATE SET
    n.residue_identifier = row.residue_id,
    n.residue_name = row.residue_name,
    n.glytoucan_ac = row.glytoucan_ac
ON MATCH SET
    n.residue_identifier = row.residue_id,
    n.residue_name = row.residue_name,
    n.glytoucan_ac = row.glytoucan_ac;

// Create or update 'linkage' relationships between Monosaccharide nodes based on the CSV file
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_enzyme.csv' AS row 
WITH row WHERE row.parent_residue_id <> '0'
MATCH (n1:Monosaccharide {residue_id: row.residue_id})
MATCH (n2:Monosaccharide {residue_id: row.parent_residue_id})
MERGE (n1)-[r1:linkage]->(n2);

// Load CSV file with headers
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_enzyme.csv' AS row 
WITH row WHERE row.parent_residue_id <> '0'
MATCH (n1:Monosaccharide {residue_id: row.residue_id + '-' + row.glytoucan_ac})
MATCH (n2:Monosaccharide {residue_id: row.parent_residue_id + '-' + row.glytoucan_ac})
MERGE (n1)-[r1:linkage]->(n2)
SET r1.glytoucan_ac = row.glytoucan_ac,
    r1.uniprotkb_canonical_ac = row.uniprotkb_canonical_ac,
    r1.gene_name = row.gene_name,
    r1.enzyme_type = row.enzyme_type,
    r1.species = row.species,
    r1.recommended_name_full = row.recommended_name_full;

// Load CSV file with headers, glycan has structure monosaccharides relationship.
LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_enzyme.csv' AS row 
// Filter rows where parent_residue_id is '0'
WITH row WHERE row.parent_residue_id = '0'
// Match Monosaccharide nodes based on residue_id and glytoucan_ac
MATCH (n1:Monosaccharide {residue_id: row.residue_id + '-' + row.glytoucan_ac})
MATCH (n2:Glycan {glytoucan_ac: row.glytoucan_ac})
// Merge 'has_structure' relationship between Monosaccharide and Glycan nodes
MERGE (n1)<-[r1:has_structure]-(n2)
SET r1.glytoucan_ac = row.glytoucan_ac;

// GLYCOSYLATIONSITES NODES AND RELATAIONSHIPS

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/mouse_proteoform_glycosylation_sites_uniprotkb.csv' AS row
MERGE (n:GlycosylationSite { protein_glycosylation_site: row.uniprotkb_canonical_ac + '-' + row.glycosylation_site_uniprotkb })
ON CREATE SET
    n.uniprotkb_canonical_ac = row.uniprotkb_canonical_ac,
    n.glycosylation_site_uniprotkb = row.glycosylation_site_uniprotkb,
    n.amino_acid = row.amino_acid,
    n.glycosylation_type = row.glycosylation_type,
    n.uniprotkb_glycosylation_annotation_comment = row.uniprotkb_glycosylation_annotation_comment,
    n.data_source = row.data_source,
    n.carb_name = row.carb_name,
    n.glycosylation_subtype = row.glycosylation_subtype,
    n.n_sequon = row.n_sequon,
    n.n_sequon_type = row.n_sequon_type,
    n.start_pos = row.start_pos,
    n.end_pos = row.end_pos,
    n.start_aa = row.start_aa,
    n.end_aa = row.end_aa,
    n.site_seq = row.site_seq
ON MATCH SET
    n.amino_acid = row.amino_acid,
    n.glycosylation_type = row.glycosylation_type,
    n.uniprotkb_glycosylation_annotation_comment = row.uniprotkb_glycosylation_annotation_comment,
    n.data_source = row.data_source,
    n.carb_name = row.carb_name,
    n.glycosylation_subtype = row.glycosylation_subtype,
    n.n_sequon = row.n_sequon,
    n.n_sequon_type = row.n_sequon_type,
    n.start_pos = row.start_pos,
    n.end_pos = row.end_pos,
    n.start_aa = row.start_aa,
    n.end_aa = row.end_aa,
    n.site_seq = row.site_seq;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_proteoform_glycosylation_sites_uniprotkb.csv' AS row
MERGE (n:GlycosylationSite { protein_glycosylation_site: row.uniprotkb_canonical_ac + '-' + row.glycosylation_site_uniprotkb })
ON CREATE SET
    n.uniprotkb_canonical_ac = row.uniprotkb_canonical_ac,
    n.glycosylation_site_uniprotkb = row.glycosylation_site_uniprotkb,
    n.amino_acid = row.amino_acid,
    n.glycosylation_type = row.glycosylation_type,
    n.uniprotkb_glycosylation_annotation_comment = row.uniprotkb_glycosylation_annotation_comment,
    n.data_source = row.data_source,
    n.carb_name = row.carb_name,
    n.glycosylation_subtype = row.glycosylation_subtype,
    n.n_sequon = row.n_sequon,
    n.n_sequon_type = row.n_sequon_type,
    n.start_pos = row.start_pos,
    n.end_pos = row.end_pos,
    n.start_aa = row.start_aa,
    n.end_aa = row.end_aa,
    n.site_seq = row.site_seq
ON MATCH SET
    n.amino_acid = row.amino_acid,
    n.glycosylation_type = row.glycosylation_type,
    n.uniprotkb_glycosylation_annotation_comment = row.uniprotkb_glycosylation_annotation_comment,
    n.data_source = row.data_source,
    n.carb_name = row.carb_name,
    n.glycosylation_subtype = row.glycosylation_subtype,
    n.n_sequon = row.n_sequon,
    n.n_sequon_type = row.n_sequon_type,
    n.start_pos = row.start_pos,
    n.end_pos = row.end_pos,
    n.start_aa = row.start_aa,
    n.end_aa = row.end_aa,
    n.site_seq = row.site_seq;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/mouse_proteoform_glycosylation_sites_uniprotkb.csv' AS row 
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:GlycosylationSite {protein_glycosylation_site: row.uniprotkb_canonical_ac + '-' + row.glycosylation_site_uniprotkb})
MERGE (n1)-[r1:has]->(n2);

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_proteoform_glycosylation_sites_uniprotkb.csv' AS row 
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:GlycosylationSite {protein_glycosylation_site: row.uniprotkb_canonical_ac + '-' + row.glycosylation_site_uniprotkb})
MERGE (n1)-[r1:has]->(n2);

// GLYCOCONJUGATES NODES AND RELATIONSHIPS -- Human Glycosylation Sites [GPTwiki]

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_proteoform_glycosylation_sites_gptwiki.csv' AS row
MERGE (n:Glycoconjugate {glycoconjugate_sequence: row.uniprotkb_canonical_ac + '-' + row.glycosylation_site_uniprotkb + '-' + row.composition})
ON CREATE SET
    n.uniprotkb_canonical_ac = row.uniprotkb_canonical_ac,
    n.glycosylation_site = row.glycosylation_site_uniprotkb,
    n.source = 'human_proteoform_glycosylation_sites_gptwiki',
    n.saccharide = row.saccharide,
    n.composition = row.composition
ON MATCH SET
    n.uniprotkb_canonical_ac = row.uniprotkb_canonical_ac,
    n.glycosylation_site = row.glycosylation_site,
    n.source = 'human_proteoform_glycosylation_sites_gptwiki,
    n.saccharide = row.saccharide',
    n.composition = row.composition;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_proteoform_glycosylation_sites_gptwiki.csv' AS row 
MATCH (n1:GlycosylationSite {protein_glycosylation_site: row.uniprotkb_canonical_ac + '-' + row.glycosylation_site_uniprotkb})
MATCH (n2:Glycoconjugate {glycoconjugate_sequence: row.uniprotkb_canonical_ac + '-' + row.glycosylation_site_uniprotkb + '-' + row.composition})
MERGE (n1)<-[r1:has]-(n2)
ON CREATE SET
    r1.glycan_xref_key = row.glycan_xref_key,
    r1.composition = row.composition
ON MATCH SET
    r1.glycan_xref_key = row.glycan_xref_key,
    r1.composition = row.composition;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_proteoform_glycosylation_sites_gptwiki.csv' AS row 
MATCH (n1:Glycoconjugate {glycoconjugate_sequence: row.uniprotkb_canonical_ac + '-' + row.glycosylation_site_uniprotkb + '-' + row.composition})
MATCH (n2:Glycan {glytoucan_ac: row.saccharide})
MERGE (n1)-[r1:has]->(n2)
ON CREATE SET
    r1.glycan_xref_key = row.glycan_xref_key,
    r1.composition = row.composition
ON MATCH SET
    r1.glycan_xref_key = row.glycan_xref_key,
    r1.composition = row.composition;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_proteoform_glycosylation_sites_gptwiki.csv' AS row 
MATCH (n1:GlycosylationSite {protein_glycosylation_site: row.uniprotkb_canonical_ac + '-' + row.glycosylation_site_uniprotkb})
MATCH (n2:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MERGE (n1)-[r1:has]->(n2)
ON CREATE SET
    r1.glycan_xref_key = row.glycan_xref_key,
    r1.composition = row.composition
ON MATCH SET
    r1.glycan_xref_key = row.glycan_xref_key,
    r1.composition = row.composition;

// GO - GENE ONTOLOGY NODES AND RELATIONSHIPS

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_protein_go_annotation.csv' AS row
MERGE (n:GeneOntology {go_term_id: row.go_term_id})
ON CREATE SET
    n.go_term_label = row.go_term_label,
    n.go_term_category = row.go_term_category,
    n.eco_id = row.eco_id,
    n.pmid = row.pmid
ON MATCH SET
    n.go_term_label = row.go_term_label,
    n.go_term_category = row.go_term_category,
    n.eco_id = row.eco_id,
    n.pmid = row.pmid;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/mouse_protein_go_annotation.csv' AS row
MERGE (n:GeneOntology {go_term_id: row.go_term_id})
ON CREATE SET
    n.go_term_label = row.go_term_label,
    n.go_term_category = row.go_term_category,
    n.eco_id = row.eco_id,
    n.pmid = row.pmid
ON MATCH SET
    n.go_term_label = row.go_term_label,
    n.go_term_category = row.go_term_category,
    n.eco_id = row.eco_id,
    n.pmid = row.pmid;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_protein_go_annotation.csv' AS row 
// Filter rows where go_term_category is 'molecular_function'
WITH row WHERE row.go_term_category = 'molecular_function'
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:GeneOntology {go_term_id: row.go_term_id})
MERGE (n1)-[r1:has_function]->(n2);

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_protein_go_annotation.csv' AS row 
// Filter rows where go_term_category is 'biological_process'
WITH row WHERE row.go_term_category = 'biological_process'
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:GeneOntology {go_term_id: row.go_term_id})
MERGE (n1)-[r1:involved_in]->(n2);

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_protein_go_annotation.csv' AS row 
// Filter rows where go_term_category is 'cellular_component'
WITH row WHERE row.go_term_category = 'cellular_component'
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:GeneOntology {go_term_id: row.go_term_id})
MERGE (n1)-[r1:located_in]->(n2);

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/mouse_protein_go_annotation.csv' AS row 
// Filter rows where go_term_category is 'molecular_function'
WITH row WHERE row.go_term_category = 'molecular_function'
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:GeneOntology {go_term_id: row.go_term_id})
MERGE (n1)-[r1:has_function]->(n2);

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/mouse_protein_go_annotation.csv' AS row 
// Filter rows where go_term_category is 'biological_process'
WITH row WHERE row.go_term_category = 'biological_process'
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:GeneOntology {go_term_id: row.go_term_id})
MERGE (n1)-[r1:involved_in]->(n2);

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/mouse_protein_go_annotation.csv' AS row 
// Filter rows where go_term_category is 'cellular_component'
WITH row WHERE row.go_term_category = 'cellular_component'
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:GeneOntology {go_term_id: row.go_term_id})
MERGE (n1)-[r1:located_in]->(n2);

// CITATIONS NODES AND RELATIONSHIPS 

// GLYCAN CITATIONS NODES AND RELATIONSHIPS

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_citations_glytoucan.csv' AS row
MERGE (n:Citation {title: row.title})
ON CREATE SET
    n.journal_name = row.journal_name,
    n.publication_date = row.publication_date,
    n.authors = row.authors,
    n.xref_key = row.xref_key,
    n.xref_id = row.xref_id
ON MATCH SET
    n.journal_name = row.journal_name,
    n.publication_date = row.publication_date,
    n.authors = row.authors,
    n.xref_key = row.xref_key,
    n.xref_id = row.xref_id;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/glycan_citations_glytoucan.csv' AS row 
MATCH (n1:Glycan {glytoucan_ac: row.glytoucan_ac})
MATCH (n2:Citation {title: row.title})
MERGE (n1)-[r1:referenced_in]->(n2);

// PROTEIN CITATIONS NODES AND RELATIONSHIPS

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_protein_citations_uniprotkb.csv' AS row
MERGE (n:Citation {title: row.title})
ON CREATE SET
    n.journal_name = row.journal_name,
    n.publication_date = row.publication_date,
    n.authors = row.authors,
    n.xref_key = row.xref_key,
    n.xref_id = row.xref_id
ON MATCH SET
    n.journal_name = row.journal_name,
    n.publication_date = row.publication_date,
    n.authors = row.authors,
    n.xref_key = row.xref_key,
    n.xref_id = row.xref_id;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_protein_citations_uniprotkb.csv' AS row 
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:Citation {title: row.title})
MERGE (n1)-[r1:referenced_in]->(n2);

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/mouse_protein_citations_uniprotkb.csv' AS row
MERGE (n:Citation {title: row.title})
ON CREATE SET
    n.journal_name = row.journal_name,
    n.publication_date = row.publication_date,
    n.authors = row.authors,
    n.xref_key = row.xref_key,
    n.xref_id = row.xref_id
ON MATCH SET
    n.journal_name = row.journal_name,
    n.publication_date = row.publication_date,
    n.authors = row.authors,
    n.xref_key = row.xref_key,
    n.xref_id = row.xref_id;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/mouse_protein_citations_uniprotkb.csv' AS row 
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:Citation {title: row.title})
MERGE (n1)-[r1:referenced_in]->(n2);

// PROTEOFORM CITATIONS AND RELATIONSHIPS

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_proteoform_citations_glycosylation_sites_unicarbkb.csv' AS row
MERGE (n:Citation {title: row.title})
ON CREATE SET
    n.journal_name = row.journal_name,
    n.publication_date = row.publication_date,
    n.authors = row.authors,
    n.xref_key = row.xref_key,
    n.xref_id = row.xref_id
ON MATCH SET
    n.journal_name = row.journal_name,
    n.publication_date = row.publication_date,
    n.authors = row.authors,
    n.xref_key = row.xref_key,
    n.xref_id = row.xref_id;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_proteoform_citations_glycosylation_sites_unicarbkb.csv' AS row 
MATCH (n1:Glycan {glytoucan_ac: row.glytoucan_ac})
MATCH (n2:Citation {title: row.title})
MERGE (n1)-[r1:referenced_in]->(n2);

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/human_proteoform_citations_glycosylation_sites_unicarbkb.csv' AS row 
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:Citation {title: row.title})
MERGE (n1)-[r1:referenced_in]->(n2);

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/mouse_proteoform_citations_glycosylation_sites_unicarbkb.csv' AS row
MERGE (n:Citation {title: row.title})
ON CREATE SET
    n.journal_name = row.journal_name,
    n.publication_date = row.publication_date,
    n.authors = row.authors,
    n.xref_key = row.xref_key,
    n.xref_id = row.xref_id
ON MATCH SET
    n.journal_name = row.journal_name,
    n.publication_date = row.publication_date,
    n.authors = row.authors,
    n.xref_key = row.xref_key,
    n.xref_id = row.xref_id;

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/mouse_proteoform_citations_glycosylation_sites_unicarbkb.csv' AS row 
MATCH (n1:Glycan {glytoucan_ac: row.glytoucan_ac})
MATCH (n2:Citation {title: row.title})
MERGE (n1)-[r1:referenced_in]->(n2);

LOAD CSV WITH HEADERS FROM 'file:///var/lib/neo4j/import/mouse_proteoform_citations_glycosylation_sites_unicarbkb.csv' AS row 
MATCH (n1:Protein {uniprotkb_canonical_ac: row.uniprotkb_canonical_ac})
MATCH (n2:Citation {title: row.title})
MERGE (n1)-[r1:referenced_in]->(n2);
