# make HOMD Refseq2taxid table
## 2025/5/15
## Version: Taxonomy V4.0, 16S rRNA V16.01, Genomic RefSeq V11.01
## download HOMD_16S_rRNA_RefSeq_V16.01_full.fasta from HOMD website (v4)
## run this script in WSL

## extract sequece names from fasta header 
### count sequence headers
grep "^>" HOMD_download/HOMD_16S_rRNA_RefSeq_V16.01_full.fasta | wc -l
###> 6880
### There are much more sequences in the fasta file than in the previous v15.23 file (1015).

## extract sequence names from FASTA file and save it to a text file
mkdir temp
grep "^>" HOMD_download/HOMD_16S_rRNA_RefSeq_V16.01_full.fasta > "./temp/1.fasta_header.txt"

## Remove ">" from the 1st row. Remove "HMT-" and white spaces from the 3rd row. Print the 1st and 3rd row.
awk '
    {
        gsub(">", "", $1); \
        gsub(" +", "", $1); \
        # use tab as delimiter
        {print $1 "\t" $2 "\t" $3, $4} \
    }
' temp/1.fasta_header.txt > temp/2.Refseq_HMT_number.txt
## count lines
wc temp/2.Refseq_HMT_number.txt
###> 6880

## Download HOMD taxon table from HOMD website. (Downloads > Batch HOMD data > Batch taxonomy data > Taxon table ("tab delimited txt (save to file)")
## count lines in taxon table
wc HOMD_download/HOMD_taxon_table2025-05-15_1747298168.txt
#> 899

## Extract HMT number of DROPPED Taxon.
## grep "DROPPED Taxon" in the 2nd column and print the 1st and 2nd column.
awk -F '\t' '
{
    if ($2 == "DROPPED Taxon") print $1 "\t" $2
}' HOMD_download/HOMD_taxon_table2025-05-15_1747298168.txt > temp/3.HOMD_taxon_table_dropped.txt

## Remove lines with "DROPPED Taxon" in the 2nd column or no taxid in the 8th column.
awk -F '\t' '$2 != "DROPPED Taxon"' \
    HOMD_download/HOMD_taxon_table2025-05-15_1747298168.txt > temp/3.HOMD_taxon_table_without-dropped.txt
wc temp/3.HOMD_taxon_table_without-dropped.txt
#> 836

## extract information from taxon table
# awk -F '\t' '{print $1, $7, $8, $16}' HOMD_taxon_table2025-05-15_1747298168.txt > temp/3.HOMD_taxon_table.txt
awk -F '\t' '{print $1 "\t" $7 "\t" $8 "\t" $16}' temp/3.HOMD_taxon_table_without-dropped.txt > temp/4.HOMD_taxon_table.txt
wc temp/4.HOMD_taxon_table.txt
#> 836

## Join the fasta header file with the taxon table using the HMT number as the key.
## The output will be a tab-separated file with the HMT number and the taxid.
awk -F '\t' '
NR==FNR {taxon[$1] = $4; next} {if ($2 in taxon) print $0, taxon[$2]; else print $0, "N/A"}
' temp/4.HOMD_taxon_table.txt temp/2.Refseq_HMT_number.txt > temp/5.Refseq_HMT_taxid.txt

wc temp/5.Refseq_HMT_taxid.txt
#> 6880

## Extract Refseq number and taxid and output as tab space. 
awk  '{print $1 "\t" $5}' temp/5.Refseq_HMT_taxid.txt > temp/HOMD_Refseq2taxid.tsv
wc temp/HOMD_Refseq2taxid.tsv
#> 6880

##--TEMP--
## zero values in the taxid column caused error when runnning wf-16S
## temporary, replaced "0" with "69014" (Thermococcus kodakarensis) in the taxid column
awk -F '\t' '{
    if ($2 == "0") $2 = "69014"; 
    print $1 "\t" $2
}' temp/HOMD_Refseq2taxid.tsv > temp/HOMD_Refseq2taxid_fake_Thermococcus_test.tsv
wc temp/HOMD_Refseq2taxid_fake_Thermococcus_test.tsv
#> 6880
## there are also empty taxid. manually fixed. script should be fixed.
##---------


## count how many lines in the taxid column in HOMD_Refseq2taxid.tsv is "0" or empty, and print separately.
awk -F '\t' '
{
    if ($2 == "0") {zero_count++}
    else if ($2 == "") {empty_count++}
}
END {
    print "zero_count: " zero_count
    print "empty_count: " empty_count
}' temp/HOMD_Refseq2taxid.tsv
#> zero_count: 677
#> empty_count: 29

## print the lines with "0" or empty taxid.
awk -F '\t' '
{
    if ($2 == "0" || $2 == "") print $0
}' temp/HOMD_Refseq2taxid.tsv

## Fix the "0" and empty taxid.
## 1. If the first column starts with "HMT-464", set the taxid to 2686067 (Fusobacterium watanabei). and so on.
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
#> 6880

## remove the lines with "0" or empty taxid.
awk -F '\t' '
{
    if ($2 != "0" && $2 != "") print $0
}' temp/HOMD_Refseq2taxid_fixed.tsv | sort -k1,1 > HOMD_Refseq2taxid_fixed2.tsv

wc HOMD_Refseq2taxid_fixed2.tsv

### -----repeat the process until all "0" and empty taxid are fixed. ------------
## count how many lines in the taxid column in HOMD_Refseq2taxid.tsv is "0" or empty, and print separately.
awk -F '\t' '
{
    if ($2 == "0") {zero_count++}
    else if ($2 == "") {empty_count++}
}
END {
    print "zero_count: " zero_count
    print "empty_count: " empty_count
}' temp/HOMD_Refseq2taxid_fixed.tsv

## print the lines with "0" or empty taxid, sorted by the first column.
awk -F '\t' '
{
    if ($2 == "0" || $2 == "") print $0
}' temp/HOMD_Refseq2taxid_fixed.tsv | sort -k1,1
### ---------------------------------------------

## print and save the lines with empty taxid, sorted by the first column. (these are dropped sequences)
awk -F '\t' '
{
    if ($2 == "") print $0
}' HOMD_Refseq2taxid_fixed.tsv | sort -k1,1 > temp/HOMD_16S_dropped_header.txt
wc temp/HOMD_16S_dropped_header.txt
#> 29

## from here, use the python script "filter_dropped.py" to filter out the dropped sequences from the fasta file.
## run the script in WSL
python3 filter_dropped.py \

