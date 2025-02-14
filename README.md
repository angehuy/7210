## 💻 System and package requirements:
* osx-64 platform
* Rosetta2 installed
* conda
### Installing required packages
* If using an Apple Silicon (arm64) system, install the Rosetta emulator to enable compatibility with the osx-64 compiler. All scripts have appropriate conda environment setups.

## 🔗 Overview
This repository contains the dataset, intermediate analysis files, and output files (including logs) from the cleaning and assembly of 34 paired sequences collected from an unknown bacterial isolate.
Our pipeline runs in the zsh shell environment and conducts pre-processing of raw sample reads for Illumina short reads with fastp v0.22.0, visualizes quality control measures with both fastp v0.22.0 and multiqc v1.2.0, assembles the reads with SPAdes v4.0.0, and filters the assemblies with filter.contigs.py (Python 2.7) for downstream analysis. For this unknown bacterial isolate, this was the pipeline that produced the best quality of results when compared to different combinations of tools such as trimmomatic v0.36, cutadapt v1.18, SKESA v2.5.1, and Velvet v1.2.10.
This repository will also contains the various statistics we used to analyze our data at each step such as N50 values, percent coverage, CPUs, and the time it took to run each tool in the pipeline. 

## 📂 Data
* [Link to Raw Data](https://gtvault.sharepoint.com/:f:/s/TeamABIOL7210Spring2025/EiFIkZHRFLVCi22YN8Q4NpsBEdd27F11Z1wzWAH8WJ0rIg?e=5ydcab)
* [Link to Clean Data](https://gtvault.sharepoint.com/:f:/s/TeamABIOL7210Spring2025/EhCzQY-4azdJsjhs34hyJuIBCj0m-M4_Y-8gXSlbKJ49OA?e=46i28z)
* [Link to Assemblies](https://gtvault.sharepoint.com/:f:/s/TeamABIOL7210Spring2025/Erh9u1iPGNFFow3mSgCIbBsBLuvKnvCIKsVzFUNNHI97Yw?e=vSHnzm)
* [Link to BUSCO output files](https://gtvault.sharepoint.com/:f:/s/TeamABIOL7210Spring2025/EqjfTIx4b5hHiaesBk72QiYBH2DyUy-_NQbLrDDj81rRHw?e=67haHe)

## 📂 Files
**Final pipeline wrapper script**
* `rc_ga_final_pipe.sh` is the script used to take raw reads, clean them with the read_clean.sh, and create genome assemblies using the genome_assembly.sh

**Helper scripts** (scripts used directly in wrapper)
* `read_clean.sh` is the script used to clean the raw data reads using fastp for the final results
* `genome_assembly.sh` is the script used to assemble genomes from the cleaned reads using spades for the final result

## 🧬 Running the final pipeline
```
#This pipeline is compatible with a osx-64 platform on a Mac computer using zsh.
#Ensure that you have downloaded or cloned the Final_Pipeline folder from this repository onto your Mac computer.
#Navigate into the Final_Pipeline folder using cd
cd ~/Final_Pipeline

#Make sure these 3 shell scripts are within the folder using ls: read_clean.sh, genome_assembly.sh, and rc_ga_final_pipe.sh

#Create a directory and navigate to it in your computer's file explorer. Use the "Link to Raw Data" above to download your raw reads into this directory. Keep reads in .fastq.gz format after downloading.
mkdir raw_data 

#Give yourself permissions to run all 3 shell scripts in the Final_Pipeline folder.
chmod u+x read_clean.sh genome_assembly.sh rc_ga_final_pipe.sh

#Use the rc_ga_final_pipe.sh script to take your raw reads, clean them, and create a genome assembly. For this script -i is the argument to provide your input directory with raw reads (raw_data) and -o is the argument to provide your output directory where your assemblies will go.
#Usage ./rc_ga_final_pipe.sh -i <input directory. -o <output directory>
#If you would like to create a log file for the script you can run: ./rc_ga_final_pipe.sh -i raw_reads -o genome_assemblies > pipeline.log 2>&1

./rc_ga_final_pipe.sh -i raw_reads -o genome_assemblies

```
