#!/bin/bash

#================================================================================
# Script to Generate eHOMD RefSeq-to-TaxID Mapping File (refseq2taxid)
#
# Purpose:
#   To generate a mapping file that associates RefSeq IDs with NCBI TaxIDs,
#   based on the FASTA and taxonomy table files downloaded from HOMD.
#   Notably, this script includes a step to manually correct TaxIDs
#   that are missing in the source data.
#
# Version Info:
#   - Taxonomy V4.1
#   - 16S rRNA V16.03
#
# Date Created: 2025/9/19
#================================================================================

# --- CONFIGURATION ---
# Please specify the paths to your input files here.
# These variables will be used throughout the script.

FASTA_FILE="HOMD_download/HOMD_16S_rRNA_RefSeq_V16.03_full.fasta"
TAXON_TABLE_FILE="HOMD_download/HOMD_taxon_table2025-09-19_1758256465.txt"
#================================================================================

# --- Initialization ---
# Create a temporary working directory if it doesn't exist
mkdir -p temp
echo -e "\n✅ Step 0: Temporary directory 'temp' is ready."


# --- Preliminary Checks ---
# (Informational) Count the total number of sequences in the input FASTA file.
echo -e "\nINFO: Counting sequences in FASTA file..."
grep "^>" "$FASTA_FILE" | wc -l
#> 6600

# --- STEP 1: Extract and Format Sequence Headers from FASTA ---
echo -e "\nSTEP 1: Extracting and formatting sequence headers..."

# Extract only the header lines (starting with '>') from the input FASTA file.
grep "^>" "$FASTA_FILE" > "./temp/1.fasta_header.txt"

# Format the header information into "RefSeq ID <tab> HMT-ID <tab> Organism Name".
awk '
    {
        # Remove the leading ">" from the identifier ($1).
        gsub(">", "", $1);
        # [Safety measure] Remove any potential spaces within the identifier ($1)
        # as a precaution for non-standard FASTA formats.
        gsub(" +", "", $1);
        # Print the formatted output.
        print $1 "\t" $2 "\t" $3, $4
    }
' temp/1.fasta_header.txt > temp/2.Refseq_HMT_number.txt

# Count the lines to verify all headers were processed.
wc -l temp/2.Refseq_HMT_number.txt
#> 6600


# --- STEP 2: Process and Clean the Taxonomy Table ---
echo -e "\nSTEP 2: Processing and cleaning the taxonomy table..."

# (Informational) Count the total number of lines in the input taxonomy table.
echo "INFO: Counting lines in taxonomy table..."
wc "$TAXON_TABLE_FILE"
#> 901

# (For debugging/logging) Create a list of taxa marked as "DROPPED Taxon".
# This file is not used by the script itself but can be useful for manual review.
awk -F '\t' '
{
    if ($2 == "DROPPED Taxon") print $1 "\t" $2
}' "$TAXON_TABLE_FILE" > temp/3.HOMD_taxon_table_dropped.txt

# Create a clean version of the taxonomy table by removing "DROPPED Taxon" entries.
awk -F '\t' '$2 != "DROPPED Taxon"' \
    "$TAXON_TABLE_FILE" > temp/3.HOMD_taxon_table_without-dropped.txt
wc -l temp/3.HOMD_taxon_table_without-dropped.txt
#> 838

# From the clean table, extract only the required columns for the join operation.
# (1:HMT-ID, 7:Genus, 8:Species, 16:NCBI TaxID).
awk -F '\t' '{print $1 "\t" $7 "\t" $8 "\t" $16}' temp/3.HOMD_taxon_table_without-dropped.txt > temp/4.HOMD_taxon_table.txt
wc -l temp/4.HOMD_taxon_table.txt
#> 838


# --- STEP 3: Join Sequence Info with Taxonomy Info ---
echo -e "\nSTEP 3: Joining sequence and taxonomy data..."

# Use awk to join the two files based on the HMT number (column 2 in the second file).
# It reads the taxonomy table (file 1) into memory as a lookup array.
# Then, it iterates through the sequence header table (file 2) and appends the
# corresponding TaxID. If no match is found, it appends "N/A".
awk -F '\t' '
NR==FNR {taxon[$1] = $4; next} {if ($2 in taxon) print $0, taxon[$2]; else print $0, "N/A"}
' temp/4.HOMD_taxon_table.txt temp/2.Refseq_HMT_number.txt > temp/5.Refseq_HMT_taxid.txt
wc -l temp/5.Refseq_HMT_taxid.txt
#> 6600

# --- STEP 4: Create Initial Mapping File & Identify Missing Data ---
echo -e "\nSTEP 4: Creating initial mapping file and identifying missing data..."

# Extract just the RefSeq ID (column 1) and the TaxID (column 5) to create the initial mapping table.
awk  '{print $1 "\t" $5}' temp/5.Refseq_HMT_taxid.txt > temp/HOMD_Refseq2taxid.tsv
wc -l temp/HOMD_Refseq2taxid.tsv
#> 6600

##--TEMP--
## zero values in the taxid column caused error when runnning wf-16S
## temporary, replaced "0" with "69014" (Thermococcus kodakarensis) in the taxid column
awk -F '\t' '{
    if ($2 == "0") $2 = "69014"; 
    print $1 "\t" $2
}' temp/HOMD_Refseq2taxid.tsv > temp/HOMD_Refseq2taxid_fake_Thermococcus_test.tsv
wc temp/HOMD_Refseq2taxid_fake_Thermococcus_test.tsv
#> 6600
## there are also empty taxid. manually fixed. script should be fixed.
##---------

# Count how many entries in the initial mapping file have a missing TaxID (either "0" or empty).
awk -F '\t' '
{
    if ($2 == "0") {zero_count++}
    else if ($2 == "") {empty_count++}
}
END {
    print "zero_count: " zero_count
    print "empty_count: " empty_count
}' temp/HOMD_Refseq2taxid.tsv
#> zero_count: 671
#> empty_count: 

# (For debugging) Print the lines that have a missing TaxID.
echo -e "\nDEBUG: Displaying entries with missing TaxIDs ('0' or empty) before manual fixing..."
awk -F '\t' '
{
    if ($2 == "0" || $2 == "") print $0
}' temp/HOMD_Refseq2taxid.tsv

# --- STEP 5: Manually Fix Known Missing TaxIDs ---
echo -e "\nSTEP 5: Manually fixing known missing TaxIDs..."

# This is the main data cleaning step. It uses a series of if/else statements
# to assign the correct, known TaxID to entries that are missing them in the
# source HOMD data, based on their HMT-ID prefix.
awk -F '\t' '
{
    if ($1 ~ /^HMT-464/) $2 = "2686067"; # Fusobacterium watanabei
    else if ($1 ~ /^HMT-043/) $2 = "544580"; # Actinomyces oris clade-043
    else if ($1 ~ /^HMT-079/) $2 = "544580"; # Actinomyces oris clade-079
    else if ($1 ~ /^HMT-144/) $2 = "544580"; # Actinomyces oris clade-144
    else if ($1 ~ /^HMT-147/) $2 = "43675"; # Rothia mucilaginosa
    else if ($1 ~ /^HMT-156/) $2 = "2682456"; # Veillonella nakazawae
    else if ($1 ~ /^HMT-240/) $2 = "2691889"; # Unclassified Schaalia
    else if ($1 ~ /^HMT-399/) $2 = "2171991"; # Candidatus Nanogingivalis
    else if ($1 ~ /^HMT-400/) $2 = "2171991"; # Candidatus Nanogingivalis
    else if ($1 ~ /^HMT-403/) $2 = "2083009"; # Actinomyces sp. Marseille-P3109
    else if ($1 ~ /^HMT-405/) $2 = "1522312"; # Kingella negevensis
    else if ($1 ~ /^HMT-409/) $2 = "2490857"; # Lautropia dentalis
    else if ($1 ~ /^HMT-410/) $2 = "2638335"; # unclassified Prevotella
    else if ($1 ~ /^HMT-413/) $2 = "2624623"; # unclassified Alloprevotella
    else if ($1 ~ /^HMT-415/) $2 = "1234680"; # Streptococcus rubneri
    else if ($1 ~ /^HMT-421/) $2 = "1110546"; # Veillonella tobetsuensis
    else if ($1 ~ /^HMT-425/) $2 = "257758"; # Streptococcus pseudopneumoniae
    else if ($1 ~ /^HMT-426/) $2 = "2025884"; # Aggregatibacter kilianii
    else if ($1 ~ /^HMT-427/) $2 = "2608917"; # Unclassified Abiotrophia
    else if ($1 ~ /^HMT-428/) $2 = "2799636"; # Catonella massiliensis
    else if ($1 ~ /^HMT-429/) $2 = "2663009"; # Fusobacterium pseudoperiodonticum
    else if ($1 ~ /^HMT-432/) $2 = "69710"; # Treponema vincentii
    else if ($1 ~ /^HMT-433/) $2 = "199"; # Campylobacter concisus
    else if ($1 ~ /^HMT-434/) $2 = "1379"; # Gemella haemolysans
    else if ($1 ~ /^HMT-438/) $2 = "53419"; # Treponema socranskii
    else if ($1 ~ /^HMT-440/) $2 = "53419"; # Treponema socranskii
    else if ($1 ~ /^HMT-441/) $2 = "2625085"; # Unclassified Lachnoanaerobaculum
    else if ($1 ~ /^HMT-444/) $2 = "68892"; # Streptococcus infantis
    else if ($1 ~ /^HMT-445/) $2 = "169292"; # Corynebacterium aurimucosum
    else if ($1 ~ /^HMT-447/) $2 = "855"; # Fusobacterium simiae
    else if ($1 ~ /^HMT-450/) $2 = "169292"; # Corynebacterium aurimucosum
    else if ($1 ~ /^HMT-454/) $2 = "2913501"; # Corynebacterium macclintockiae
    else if ($1 ~ /^HMT-456/) $2 = "2382163"; # Streptococcus koreensis
    else if ($1 ~ /^HMT-460/) $2 = "2490855"; # Lachnoanaerobaculum gingivalis
    else if ($1 ~ /^HMT-710/) $2 = "3050224"; # Schaalia dentiphila
    else if ($1 ~ /^HMT-779/) $2 = "2630086"; # unclassified Veillonella
    else if ($1 ~ /^HMT-783/) $2 = "1979527"; # Corynebacterium kefirresidentii
    else if ($1 ~ /^HMT-784/) $2 = "1673725"; # Peptoniphilus lacydonensis
    else if ($1 ~ /^HMT-789/) $2 = "33028"; # Staphylococcus saccharolyticus
    else if ($1 ~ /^HMT-791/) $2 = "1574624"; # Cutibacterium namnetense
    else if ($1 ~ /^HMT-792/) $2 = "1755241"; # Anaerococcus nagyae
    else if ($1 ~ /^HMT-797/) $2 = "419005"; # Prevotella	amnii
    else if ($1 ~ /^HMT-798/) $2 = "386414"; # Hoylesella timonensis (Prevotella timonensis)
    else if ($1 ~ /^HMT-799/) $2 = "134821"; # Ureaplasma	parvum
    else if ($1 ~ /^HMT-846/) $2 = "2792977"; # Gardnerella piotii
    else if ($1 ~ /^HMT-867/) $2 = "2792978"; # Gardnerella leopoldii
    else if ($1 ~ /^HMT-868/) $2 = "2792979"; # Gardnerella swidsinskii
    else if ($1 ~ /^HMT-960/) $2 = "39491"; # Agathobacter rectalis
    else if ($1 ~ /^HMT-961/) $2 = "853"; # Faecalibacterium prausnitzii
    else if ($1 ~ /^HMT-962/) $2 = "2981726"; # Hominimerdicola aceti
    else if ($1 ~ /^HMT-963/) $2 = "239935"; # Akkermansia muciniphila
    else if ($1 ~ /^HMT-964/) $2 = "328813"; # Alistipes onderdonkii
    else if ($1 ~ /^HMT-965/) $2 = "28117"; # Alistipes putredinis
    else if ($1 ~ /^HMT-966/) $2 = "328814"; # Alistipes shahii
    else if ($1 ~ /^HMT-967/) $2 = "47678"; # Bacteroides caccae
    else if ($1 ~ /^HMT-968/) $2 = "28116"; # Bacteroides ovatus
    else if ($1 ~ /^HMT-969/) $2 = "46506"; # Bacteroides stercoris
    else if ($1 ~ /^HMT-970/) $2 = "818"; # Bacteroides thetaiotaomicron
    else if ($1 ~ /^HMT-971/) $2 = "971"; # Bacteroides	uniformis
    else if ($1 ~ /^HMT-972/) $2 = "371601"; # Bacteroides xylanisolvens 
    else if ($1 ~ /^HMT-973/) $2 = "823"; # Parabacteroides	distasonis
    else if ($1 ~ /^HMT-978/) $2 = "821"; # Phocaeicola vulgatus
    else if ($1 ~ /^HMT-974/) $2 = "46503"; # Parabacteroides merdae
    else if ($1 ~ /^HMT-975/) $2 = "357176"; # Phocaeicola dorei
    else if ($1 ~ /^HMT-976/) $2 = "204516"; # Phocaeicola massiliensis
    else if ($1 ~ /^HMT-977/) $2 = "310297"; # Phocaeicola plebeius
    else if ($1 ~ /^HMT-978/) $2 = "821"; # Phocaeicola vulgatus
    else if ($1 ~ /^HMT-979/) $2 = "165179"; # Prevotella	copri (Segatella)
    #else if ($1 ~ /^HMT-/) $2 = ""; # 
    print $1 "\t" $2
}' temp/HOMD_Refseq2taxid.tsv > temp/HOMD_Refseq2taxid_fixed.tsv

wc temp/HOMD_Refseq2taxid_fixed.tsv
#> 6600

# --- STEP 6: Generate Final Files ---
echo -e "\nSTEP 6: Generating final output files..."

# Create the final, clean mapping file by removing any entries that *still*
# have a missing TaxID after the manual fix, and then sorting the result.
awk -F '\t' '
{
    if ($2 != "0" && $2 != "") print $0
}' temp/HOMD_Refseq2taxid_fixed.tsv | sort -k1,1 > HOMD_Refseq2taxid_fixed2.tsv
echo -e "\nINFO: Final mapping file 'HOMD_Refseq2taxid_fixed2.tsv' created."
wc -l HOMD_Refseq2taxid_fixed2.tsv
#> 6598


# This block is for iteratively checking if any missing TaxIDs remain after a fix.
### -----repeat the process until all "0" and empty taxid are fixed. ------------
awk -F '\t' '
{
    if ($2 == "0") {zero_count++}
    else if ($2 == "") {empty_count++}
}
END {
    print "zero_count: " zero_count
    print "empty_count: " empty_count
}' temp/HOMD_Refseq2taxid_fixed.tsv
#> zero_count: 2
#> empty_count: 0

awk -F '\t' '
{
    if ($2 == "0" || $2 == "") print $0
}' temp/HOMD_Refseq2taxid_fixed.tsv | sort -k1,1
#> HMT-471_16S006489       0
#> HMT-796_16S003636       0

### ---------------------------------------------

# Create the exclusion list for the next step in the workflow.
# This file lists the headers of sequences that could not be assigned a TaxID.
# It will be read by the Python script to filter the main FASTA file.
awk -F '\t' '
{
    if ($2 == "") print $0
}' HOMD_Refseq2taxid_fixed.tsv | sort -k1,1 > temp/HOMD_16S_dropped_header.txt
echo -e "\nINFO: Exclusion list 'temp/HOMD_16S_dropped_header.txt' created."
wc -l temp/HOMD_16S_dropped_header.txt
#> 29

# --- Next Step ---
# The workflow now passes control to the Python script to perform the FASTA filtering.
echo -e "\n🚀 All steps complete. Please run 'filter_dropped.py' next."
python3 filter_dropped.py