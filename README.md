# HOMD RefSeq-to-TaxID Mapping Tool

## 📖 Overview
This project provides a toolset to generate a mapping file between 16S rRNA RefSeq sequences from the **eHOMD (extended Human Oral Microbiome Database)** and their corresponding **NCBI Taxonomy IDs (TaxIDs)**.

Since the data and required processing steps can change between HOMD versions, this repository is organized into version-specific directories.

## 📂 Available Versions
Please choose the directory that corresponds to the HOMD data version you are using. For detailed instructions, refer to the `README.md` file inside each directory.

* **[v16.01/](v16.01/)**: Tools for HOMD version 16.01. Includes manual corrections for missing TaxIDs in the source data.

## 🛠️ General Prerequisites
The following are required for all versions. Please see the version-specific `README` for any additional requirements.

* An environment such as **WSL, Linux, or macOS**.
* **Python 3.x**.
* The **Biopython** library (`pip install biopython`).

## 📄 License
This project is licensed under the MIT License.