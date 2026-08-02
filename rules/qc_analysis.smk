#########################################
## QC Analysis for DNA Sequencing data ##
#########################################

rule seq_quality:
    input: 
        R1 = lambda wc: config["samples"][wc.sample]["R1"],
        R2 = lambda wc: config["samples"][wc.sample]["R2"],
        trimmedR1 = results_base_path + "{sample}/trimmed_reads/{sample}_FP.fastq.gz",
        trimmedR2 = results_base_path + "{sample}/trimmed_reads/{sample}_RP.fastq.gz",
    params:
        place_of_the_raw_files_analysis = results_base_path + "{sample}/QC/raw_reads",
        place_of_the_trimmed_files_analysis = results_base_path + "{sample}/QC/trimmed_reads" 
    output:
        raw_reads_1 = results_base_path + "{sample}/QC/raw_reads/{sample}_1_fastqc.html",
        raw_reads_2 = results_base_path + "{sample}/QC/raw_reads/{sample}_2_fastqc.html",
        trimmed_reads1 = results_base_path + "{sample}/QC/trimmed_reads/{sample}_FP_fastqc.html",
        trimmed_reads2 = results_base_path + "{sample}/QC/trimmed_reads/{sample}_RP_fastqc.html"
    container:
        config["images"]["fastqc_singularity"]
    benchmark:
        logs_and_bmk_base_path + "benchmarks/{sample}_seq_quality.bmk"
    log:
        qc_log_raw_files = logs_and_bmk_base_path + "log/{sample}_seq_quality_raw_data.log",
        qc_log_trimmed_files = logs_and_bmk_base_path + "log/{sample}_seq_quality_after_trimming.log"
    threads: 2
    shell:"""
        mkdir -p {params.place_of_the_raw_files_analysis}
        mkdir -p {params.place_of_the_trimmed_files_analysis}
        fastqc -t {threads} {input.R1} {input.R2} -o {params.place_of_the_raw_files_analysis} 2>> {log.qc_log_raw_files}
        fastqc -t {threads} {input.trimmedR1} {input.trimmedR2} -o {params.place_of_the_trimmed_files_analysis} 2>> {log.qc_log_trimmed_files}
        """

rule find_qcs:
    input:
        expand(results_base_path + "{sample}/QC/raw_reads/{sample}_1_fastqc.html",
        results_base_path = results_base_path, sample = samples),
        expand(results_base_path + "{sample}/QC/raw_reads/{sample}_2_fastqc.html",
        results_base_path = results_base_path, sample = samples),
        expand(results_base_path + "{sample}/QC/trimmed_reads/{sample}_FP_fastqc.html",
        results_base_path = results_base_path, sample = samples),
        expand(results_base_path + "{sample}/QC/trimmed_reads/{sample}_RP_fastqc.html",
        results_base_path = results_base_path, sample = samples)
    output:
        file_list_output_raw_data = results_base_path + "Run/QC/list_of_raw_QC.txt",
        file_list_output_trimmed_data = results_base_path + "Run/QC/list_of_trimmed_QC.txt"
    params:
        results_base_path = results_base_path
    benchmark:
        logs_and_bmk_base_path + "benchmarks/find_qcs.bmk"
    log:
        logs_and_bmk_base_path + "log/find_qcs.log"
    threads: 2
    shell:"""
        find {params.results_base_path} -type f | grep ".zip" | grep "QC/raw_reads" > {output.file_list_output_raw_data}
        find {params.results_base_path} -type f | grep ".zip" | grep "QC/trimmed_reads" > {output.file_list_output_trimmed_data}
        """

rule muiltiQC_raw_reads:
    input:
        file_list_output_raw_data = results_base_path + "Run/QC/list_of_raw_QC.txt",
        file_list_output_trimmed_data = results_base_path + "Run/QC/list_of_trimmed_QC.txt"
    output:
        multiqc_results_raw_data = results_base_path + "Run/QC/multiQC_raw_reads.html",
        multiqc_results_trimmed = results_base_path + "Run/QC/multiQC_trimmed_reads.html"
    params:
        results_path = results_base_path + "Run/QC/"
    benchmark:
        logs_and_bmk_base_path + "benchmarks/multiqc.bmk"
    log:
        raw_data = logs_and_bmk_base_path + "log/multiqc_raw_reads.log",
        trimmed_data = logs_and_bmk_base_path + "log/multiqc_trimmed_reads.log"
    threads: 2
    container: 
        config["images"]["multiqc_singularity"]
    shell:"""
        multiqc --file-list {input.file_list_output_raw_data} \
        --outdir {params.results_path} -n multiQC_raw_reads 2>> {log.raw_data}

        multiqc --file-list {input.file_list_output_trimmed_data} \
        --outdir {params.results_path} -n multiQC_trimmed_reads 2>> {log.trimmed_data}
        """

rule trigger_qc_analysis:
    input:
        # expand(results_base_path + "{sample}/QC/raw_reads/{sample}_1_fastqc.html",
        # results_base_path = results_base_path, sample = samples),
        # expand(results_base_path + "{sample}/QC/raw_reads/{sample}_2_fastqc.html",
        # results_base_path = results_base_path, sample = samples),
        # results_base_path + "/Run/QC/list_of_raw_QC.txt"
        results_base_path + "Run/QC/multiQC_raw_reads.html",
        results_base_path + "Run/QC/multiQC_trimmed_reads.html"

        