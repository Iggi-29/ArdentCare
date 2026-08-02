### Basic snakefile
import pandas as pd
from shutil import copyfile
import os, glob, re, sys

### config file importation
configfile: "config/config.yaml"

## get variables
raw_data_base_path = config["raw_data_base_path"]
results_base_path = config["results_base_path"]
logs_and_bmk_base_path = config["logs_and_bmk_base_path"]

## get the sample names
samples = [s for s in config["samples"]]

## reference files
genome = config["genome"]
genome_unc = config["genome_unc"]

### get the rules
include: "rules/qc_analysis.smk"
include: "rules/bam_generation.smk"
include: "rules/variant_calling.smk"

rule all:
    input:
        rules.trigger_qc_analysis.input,
        rules.trigger_bam_generation.input,
        rules.trigger_vcf_generation.input