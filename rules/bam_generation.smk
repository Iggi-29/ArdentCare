#############################################
## bam generation and alignemtn processing ##
#############################################

rule trimming_trimmomatic:
    input: 
        R1 = lambda wc: config["samples"][wc.sample]["R1"],
        R2 = lambda wc: config["samples"][wc.sample]["R2"]
    params:
        avqual = 15,
        out_dir = results_base_path + "{sample}/trimmed_reads/"
    output:
        trimmedR1 = results_base_path + "{sample}/trimmed_reads/{sample}_FP.fastq.gz",
        trimmedR2 = results_base_path + "{sample}/trimmed_reads/{sample}_RP.fastq.gz",
        trimmed_rubish_R1 = temp(results_base_path + "{sample}/trimmed_reads/{sample}_FU.fastq.gz"),
        trimmed_rubish_R2 = temp(results_base_path + "{sample}/trimmed_reads/{sample}_RU.fastq.gz"),
    container:
        config["images"]["trimmomatic_singularity"]
    benchmark:
        logs_and_bmk_base_path + "benchmarks/{sample}_trimming.bmk"
    log:
        logs_and_bmk_base_path + "log/{sample}_trimming.log"
    threads: 1
    shell:"""
        mkdir -p {params.out_dir}
        trimmomatic PE \
        {input.R1} {input.R2} {output.trimmedR1} {output.trimmed_rubish_R1} {output.trimmedR2} {output.trimmed_rubish_R2} \
        AVGQUAL:{params.avqual} 2> {log}    
        """

rule bwa_alignment:
    input:
        trimmedR1 = results_base_path + "{sample}/trimmed_reads/{sample}_FP.fastq.gz",
        trimmedR2 = results_base_path + "{sample}/trimmed_reads/{sample}_RP.fastq.gz",
    params:
        out_dir = results_base_path + "{sample}/alignments/",
        sample = "{sample}",
        genome = genome
    output:
        sam = temp(results_base_path + "{sample}/alignments/{sample}.sam")
    container: config["images"]["bwa_singularity"]
    benchmark:
        logs_and_bmk_base_path + "benchmarks/{sample}_alignment.bmk"
    log:
        logs_and_bmk_base_path + "log/{sample}_alignment.log"
    threads: 5
    shell:"""
        mkdir -p {params.out_dir}
        bwa mem -t {threads} -R '@RG\\tID:{params.sample}\\tSM:{params.sample}' \
        {params.genome} {input.trimmedR1} {input.trimmedR2} > {output.sam} 2>> {log}
        """

rule samtools:
    input:
        sam = results_base_path + "{sample}/alignments/{sample}.sam"
    params:
        out_dir = results_base_path + "{sample}/alignments/",
        genome_unc = genome_unc
    output:
        bam = temp(results_base_path + "{sample}/alignments/{sample}.bam"),
        sorted_bam = results_base_path + "{sample}/alignments/{sample}_sorted.bam",
        sorted_bam_idx = results_base_path + "{sample}/alignments/{sample}_sorted.bam.bai",
        sorted_bam_stats = results_base_path + "{sample}/alignments/{sample}_sorted.bam.stats",
        mpileup_file = temp(results_base_path + "{sample}/alignments/{sample}.mpileup")
    container: 
        config["images"]["samtools_singularity"]
    benchmark:
        logs_and_bmk_base_path + "benchmarks/{sample}_samtools.bmk"
    log:
        samtools_view = logs_and_bmk_base_path + "log/{sample}_samtools_view.log",
        samtools_sort = logs_and_bmk_base_path + "log/{sample}_samtools_sort.log",
        samtools_index = logs_and_bmk_base_path + "log/{sample}_samtools_index.log",
        samtools_flagstat = logs_and_bmk_base_path + "log/{sample}_samtools_flagstat.log",
        samtools_pileup = logs_and_bmk_base_path + "log/{sample}_samtools_pileup.log"
    threads: 5
    shell:"""
        samtools view -@ {threads} -b -S {input.sam} > {output.bam} 2>> {log.samtools_view}
        samtools sort -m 4900M -@ {threads} {output.bam} -o {output.sorted_bam} 2>> {log.samtools_sort}
        samtools index {output.sorted_bam} -o {output.sorted_bam_idx} 2>> {log.samtools_index}
        samtools flagstat {output.sorted_bam} > {output.sorted_bam_stats} 2>> {log.samtools_flagstat}
        samtools mpileup -B -f {params.genome_unc} {output.sorted_bam} > {output.mpileup_file} 2>> {log.samtools_pileup}
        """

rule trigger_bam_generation:
    input:
        expand(results_base_path + "{sample}/alignments/{sample}_sorted.bam",
        results_base_path = results_base_path, sample = samples),
        expand(results_base_path + "{sample}/alignments/{sample}_sorted.bam.bai",
        results_base_path = results_base_path, sample = samples),
        expand(results_base_path + "{sample}/alignments/{sample}_sorted.bam.stats",
        results_base_path = results_base_path, sample = samples),
        
        