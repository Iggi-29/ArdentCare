#################################################
## variant calling for bam files with varscan ##
#################################################

rule variant_calling:
    input:
        mpileup_file = results_base_path + "{sample}/alignments/{sample}.mpileup"
    output:
        vcf_snps = results_base_path + "{sample}/Variants/{sample}.SNV.vcf",
        vcf_indel = results_base_path + "{sample}/Variants/{sample}.INDEL.vcf"
    params:
        out_dir = results_base_path + "{sample}/Variants"
    container:
        config["images"]["varscan_singularity"]
    threads:
        1
    benchmark:
        logs_and_bmk_base_path + "benchmarks/{sample}_variant_calling.bmk"
    log:
        snp_call = logs_and_bmk_base_path + "log/{sample}_variant_calling.log",
        indel_call = logs_and_bmk_base_path + "log/{sample}_variant_calling.log",
    shell:"""
        mkdir -p {params.out_dir}
        ## SNPs
        java -jar /opt/varscan/VarScan.jar mpileup2snp {input.mpileup_file} \
        --min-coverage 4 --min-reads2 2 --min-avg-qual 10 --min-var-freq 0.01 --min-freq-for-hom 0.9 \
        --p-value 0.1 --strand-filter 0 -output-vcf > {output.vcf_snps} 2>> {log.snp_call}
        
        ## INDELs
        java -jar /opt/varscan/VarScan.jar mpileup2indel {input.mpileup_file} \
        --min-coverage 4 --min-reads2 2 --min-avg-qual 10 --min-var-freq 0.01 --min-freq-for-hom 0.9 \
        --p-value 0.1 --strand-filter 0 -output-vcf > {output.vcf_indel} 2>> {log.indel_call}
        """
    
rule trigger_vcf_generation:
    input:
        expand(results_base_path + "{sample}/Variants/{sample}.SNV.vcf",
        results_base_path = results_base_path, sample = samples),
        expand(results_base_path + "{sample}/Variants/{sample}.INDEL.vcf",
        results_base_path = results_base_path, sample = samples)
