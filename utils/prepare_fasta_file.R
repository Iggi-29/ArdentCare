#######################################################
### Prepare the genome fasta fie to work, filter it ###
#######################################################

### libraries
library(Biostrings)

fasta_data <- "/home/ignasi/Desktop/DNA_pipeline/ressources/GRCh38.primary_assembly.genome.fa.gz"
fasta_data <- Biostrings::readDNAStringSet(
  filepath = fasta_data, 
  format = "fasta")

### Get the data from the cromosomes I want
chrs_to_keep <- c("chr17 17",
                  "chr21 21",
                  "chrX X",
                  "chrY Y")
fasta_data <- fasta_data[names(fasta_data) %in% chrs_to_keep]
Biostrings::writeXStringSet(
  x = fasta_data,
  filepath = "/home/ignasi/Desktop/DNA_pipeline/ressources/Human_filtered_chr21_chr17_chrX_chrY.fa")
