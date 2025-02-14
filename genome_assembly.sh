#!/bin/zsh

# Ensure the script stops on errors
set -e

# Display usage information
usage() {
  echo "Usage: $0 -i <input_dir> -o <output_dir>"
  echo "Note: Input directory must contain files in .fastq.gz format."
  exit 1
}

# Parse command-line arguments for input (-i) and output (-o) directories
while getopts "i:o:" opt; do
  case $opt in
    i) INPUT_DIR="$OPTARG" ;;  # Set the input directory
    o) OUTPUT_BASE_DIR="$OPTARG" ;;  # Set the output directory
    *) usage ;;
  esac
done

# Check if the input and output directories are provided
if [[ -z "$INPUT_DIR" || -z "$OUTPUT_BASE_DIR" ]]; then
  echo "Error: Both -i <input_dir> and -o <output_dir> are required."
  usage
fi

# Ensure the input directory exists
if [[ ! -d "$INPUT_DIR" ]]; then
  echo "Error: Input directory '$INPUT_DIR' does not exist."
  exit 1
fi

# Validate input files
if ! ls "$INPUT_DIR"/*.fastq.gz >/dev/null 2>&1; then
  echo "Error: No files with .fastq.gz format found in the input directory '$INPUT_DIR'."
  echo "Ensure the input directory contains properly formatted files before running the script."
  exit 1
fi


# Use source to initialize conda with .zshrc
source ~/.zshrc

# Create conda environment
conda create -n spades_test -y

# Activate conda environment
conda activate spades_test

# Install software packages in the environment
conda install -c bioconda -c conda-forge spades -y

# Create the output base directory if it doesn't exist
mkdir -p "$OUTPUT_BASE_DIR"

# Loop through Read 1 files in the input directory
for READ1 in "$INPUT_DIR"/*_R1_001.fastq.gz; do
  # Derive the corresponding Read 2 file
  READ2="${READ1/_R1_001.fastq.gz/_R2_001.fastq.gz}"

  # Check if Read 2 file exists
  if [[ -f "$READ2" ]]; then
    # Extract the sample name from the file name (without "clean")
    SAMPLE_NAME=$(basename "$READ1" | sed 's/_R1_001.fastq.gz//')

    # Define the singleton file for the sample (without "clean")
    SINGLETONS_FILE="$INPUT_DIR/${SAMPLE_NAME}_singletons.fastq.gz"

    # Define the output directory for this sample
    mkdir -p "$OUTPUT_BASE_DIR/$SAMPLE_NAME"
    SAMPLE_OUTPUT_DIR="$OUTPUT_BASE_DIR/$SAMPLE_NAME"

    # Define log file paths
    STDOUT_FILE="$SAMPLE_OUTPUT_DIR/spades.stdout.txt"
    STDERR_FILE="$SAMPLE_OUTPUT_DIR/spades.stderr.txt"

    # Run SPAdes
    echo "Running SPAdes for $SAMPLE_NAME..."
    spades.py \
      -1 "$READ1" \
      -2 "$READ2" \
      $SINGLETONS_OPTION \
      -o "$SAMPLE_OUTPUT_DIR" \
      --isolate \
      --cov-cutoff 10 \
      > "$STDOUT_FILE" 2> "$STDERR_FILE"

    # Check for SPAdes success
    if [[ $? -eq 0 ]]; then
      echo "SPAdes completed for $SAMPLE_NAME."
    else
      echo "SPAdes failed for $SAMPLE_NAME. Check logs for details."
    fi
  else
    echo "Read 2 file not found for $READ1. Skipping..."
  fi
done

# Conda install Python 2.7 for Biopython
conda install python=2.7 biopython -y

# Download the Python script for filtering contigs/assemblies
curl -O https://raw.githubusercontent.com/bacterial-genomics/genomics_scripts/refs/heads/main/filter.contigs.py

# Make the script executable
chmod +x ./filter.contigs.py

# Process assemblies with the filtering script
ASSEMBLY_DIR="$OUTPUT_BASE_DIR"
for SAMPLE_NAME in $(ls $ASSEMBLY_DIR); do
  echo "Processing sample: $SAMPLE_NAME"

  # Define input, output, and log files
  INFILE="$ASSEMBLY_DIR/$SAMPLE_NAME/contigs.fasta"
  OUTFILE="$ASSEMBLY_DIR/$SAMPLE_NAME/filtered_assembly.fna"
  DISCARDED="$ASSEMBLY_DIR/$SAMPLE_NAME/removed-contigs.fa"
  STDOUT_LOG="$ASSEMBLY_DIR/$SAMPLE_NAME/contig-filtering.stdout.log"
  STDERR_LOG="$ASSEMBLY_DIR/$SAMPLE_NAME/contig-filtering.stderr.log"

  # Run the filter script
  ./filter.contigs.py --infile "$INFILE" --outfile "$OUTFILE" --discarded "$DISCARDED" > "$STDOUT_LOG" 2> "$STDERR_LOG"

  # Check for errors
  if [[ $? -ne 0 ]]; then
    echo "Error processing $SAMPLE_NAME. Check $STDERR_LOG for details."
  else
    echo "$SAMPLE_NAME processed successfully."
  fi
done

# Look at filtered contig stats
for SAMPLE_NAME in $(ls $ASSEMBLY_DIR); do
  STDERR_LOG="$ASSEMBLY_DIR/$SAMPLE_NAME/contig-filtering.stderr.log"

  if [[ -f "$STDERR_LOG" ]]; then
    echo "---- Last 20 lines of $STDERR_LOG for $SAMPLE_NAME ----"
    tail -n 20 "$STDERR_LOG"
    echo "--------------------------------------"
  else
    echo "Log file not found for $SAMPLE_NAME."
  fi
done

# Exit the conda environment
conda deactivate
