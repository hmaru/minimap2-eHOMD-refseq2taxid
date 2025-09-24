# eHOMD Tools: Version 16.03

This directory contains the scripts and instructions specifically for processing **eHOMD version 16.03**.

## 📝 Version-Specific Notes
**Important**: This version of the eHOMD data still contains some entries with missing or incorrect TaxIDs. The `make_eHOMD_refseq2taxid.sh` script includes the necessary hardcoded fixes to resolve these issues.

After running the shell script, all sequences are successfully mapped to a TaxID. This means the exclusion list for filtering is empty, and therefore, running the `filter_dropped.py` script is **not necessary** for this data version. This script is kept for consistency with other versions, but it may be removed in a future update (e.g., for v16.04).

## 🚀 Usage

1.  **Download eHOMD v16.03 Files**:
    Download the required files from the [eHOMD website](https://www.homd.org/downloads) and place them in a `HOMD_download` directory.

    * **16S rRNA RefSeq FASTA**:
        * Find and download `HOMD_16S_rRNA_RefSeq_V16.03_full.fasta`.

    * **Taxon Table**:
        * Navigate through **Downloads > Batch HOMD data > Batch taxonomy data**.
        * Download the **Taxon table ("tab delimited txt (save to file)")**.

2.  **Generate the Mapping File**:
    From within the `v16.03/` directory, run the shell script. This performs all necessary corrections and generates the final mapping file. It is also possible to execute the commands inside the script step-by-step for debugging.
    ```bash
    bash make_eHOMD_refseq2taxid.sh
    ```

## 📂 Outputs and Validation
The output files have been validated and confirmed to work correctly with the **EPI2ME 16S workflow** (ONT).

### 🗺️ TaxID Mapping File
* **File**: `HOMD_Refseq2taxid.tsv`
* **Description**: The primary output. This is a two-column, tab-separated file that links each RefSeq ID to its corresponding NCBI Taxonomy ID.
* **EPI2ME Usage**: Use this for the **"File linking reference IDs to specific taxids"** option in the "Reference options".

### 🧬 Reference FASTA File
* **File**: `HOMD_download/HOMD_16S_rRNA_RefSeq_V16.03_full.fasta`
* **Description**: Since no sequences were excluded in this version, the original downloaded FASTA file serves as the final reference.
* **EPI2ME Usage**: Use this for the **"Minimap2 reference"** option in the "Reference options".