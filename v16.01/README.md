# HOMD Tools: Version 16.01

This directory contains the scripts and instructions specifically for processing **HOMD version 16.01**.

## 📝 Version-Specific Notes
**Important**: The HOMD v16.01 data release is missing a significant number of TaxIDs. The `make_HOMD_refseq2taxid.sh` script in this directory contains **hardcoded fixes** to manually assign the correct TaxIDs for these entries. This manual step is necessary for this version.

*(For a future version like v16.03, this section might say: "As of HOMD v16.03, the missing TaxIDs have been corrected in the source data. Therefore, the scripts in this directory **do not** contain the manual fixes found in earlier versions.")*

## 🚀 Usage

1.  **Download HOMD v16.01 Files**:
    Download the required files from the [HOMD website](https://www.homd.org/downloads) and place them in a `HOMD_download` directory inside `v16.01/`.

    * **16S rRNA RefSeq FASTA**:
        * Find and download the relevant version (e.g., `HOMD_16S_rRNA_RefSeq_V16.01_full.fasta`).

    * **Taxon Table**:
        * Navigate through **Downloads > Batch HOMD data > Batch taxonomy data**.
        * Download the **Taxon table ("tab delimited txt (save to file)")**. (e.g., `HOMD_16S_rRNA_RefSeq_V16.01_full_filter_log_20250520_160848.txt`)

2.  **Generate the Mapping File**:
    From within the `v16.01/` directory, run the shell script.
    ```bash
    bash make_HOMD_refseq2taxid.sh
    ```

3.  **Filter the FASTA File**:
    Next, run the Python script.
    ```bash
    python3 filter_dropped.py
    ```

## 📂 Generated Files & Usage
The outputs are designed for use in downstream analysis tools like the EPI2ME 16S workflow.

* **`HOMD_Refseq2taxid_fixed2.tsv`**
    * **Description**: A two-column, tab-separated file that links each RefSeq ID to its corresponding NCBI Taxonomy ID.
    * **EPI2ME Usage**: Use in the **"File linking reference IDs to specific taxids"** option (in "Rerefence options").

* **`HOMD_16S_rRNA_RefSeq_V16.01_full_filtered.fasta`**
    * **Description**: The clean FASTA file containing reference sequences. Sequences with unknown TaxIDs have been removed.
    * **EPI2ME Usage**: Use in the **"Minimap2 reference"** option (in "Reference options").