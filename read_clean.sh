#!/bin/zsh

# Ensure the script stops on errors
set -e

# Display usage information
usage() {
  echo "Usage: $0 -i <input_dir> -o <output_dir>"
  echo "Note: Input directory must contain files in .fastq.gz format."
  exit 1
}

# Parse command-line arguments
while getopts "i:o:" opt; do
  case $opt in
    i) input_dir="$OPTARG" ;;
    o) output_dir="$OPTARG" ;;
    *) usage ;;
  esac
done

# Check if both input and output directories are provided
if [ -z "$input_dir" ] || [ -z "$output_dir" ]; then
  usage
fi

# Ensure input directory exists
if [ ! -d "$input_dir" ]; then
  echo "Error: Input directory '$input_dir' does not exist."
  exit 1
fi

# Check if there are .fastq.gz files in the input directory
if ! ls "$input_dir"/*.fastq.gz >/dev/null 2>&1; then
  echo "Error: No files with .fastq.gz format found in '$input_dir'."
  echo "Please ensure the input directory contains files in the correct format."
  exit 1
fi

# Use source to initialize conda with .zshrc
source ~/.zshrc


# Create and activate conda environment
CONDA_SUBDIR=osx-64 conda create -n rc_2 -y
conda activate rc_2

# Install required software in the conda environment
conda install -c bioconda -c conda-forge entrez-direct sra-tools fastp pigz tree -y

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Loop through all FASTQ files in the input directory
for file in "$input_dir"/*_R1_001.fastq.gz; do
  # Get the base name of the file
  base=$(basename "$file" _R1_001.fastq.gz)

  # Define input and output file names
  read1="$input_dir/${base}_R1_001.fastq.gz"
  read2="$input_dir/${base}_R2_001.fastq.gz"
  output_read1="$output_dir/${base}_clean_R1_001.fastq.gz"
  output_read2="$output_dir/${base}_clean_R2_001.fastq.gz"
  out_uread1="$output_dir/${base}_clean_R1_001_unpaired.fastq.gz"
  out_uread2="$output_dir/${base}_clean_R2_001_unpaired.fastq.gz"

  # Define log file names
  stdout_log="${output_dir}/${base}_fastp_std.out.txt"
  stderr_log="${output_dir}/${base}_fastp_std.err.txt"

  # Run fastp for quality control and log outputs
  fastp -i "$read1" -I "$read2" -o "$output_read1" -O "$output_read2" \
    --unpaired1 "$out_uread1" --unpaired2 "$out_uread2" \
    --trim_front1 15 --trim_front2 15 \
    -l 50 --average_qual 30 --trim_poly_x \
    -h "$output_dir/${base}_fastp.html" \
    -j "$output_dir/${base}_fastp.json" \
    > "$stdout_log" 2> "$stderr_log"

  # Combine unpaired reads into a single file
  cat "$out_uread1" "$out_uread2" > "$output_dir/${base}_singletons.fastq.gz"

  # Remove unpaired files after combining them
  rm "$out_uread1" "$out_uread2"
done

# Deactivate conda environment
conda deactivate

