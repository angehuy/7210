#!/bin/zsh

# Parse command-line arguments
while getopts "i:o:" opt; do
  case $opt in
    i) input_dir="$OPTARG" ;;  # Input directory for Step 1
    o) output_dir="$OPTARG" ;; # Output directory for Step 2
    *) 
      echo "Usage: $0 -i <input_directory> -o <output_directory>"
      exit 1
      ;;
  esac
done

# Check if both arguments are provided
if [[ -z "$input_dir" || -z "$output_dir" ]]; then
  echo "Error: Both -i and -o arguments are required."
  echo "Usage: $0 -i <input_directory> -o <output_directory>"
  exit 1
fi

# Create intermediate cleaned reads directory
cleaned_reads_dir="./cleaned_reads"

# Step 1: Conduct read cleaning
echo "Running read cleaning with input: $input_dir and output: $cleaned_reads_dir"
./read_clean.sh -i "$input_dir" -o "$cleaned_reads_dir"

# Step 2: Conduct genome assembly
echo "Running genome assembly with input: $cleaned_reads_dir and output: $output_dir"
./genome_assembly.sh -i "$cleaned_reads_dir" -o "$output_dir"
