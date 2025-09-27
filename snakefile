configfile: "config/config.yaml"

rule all:
    input:
        expand("results/variants/{sample}_filtered.vcf", sample=config["samples"])

rule fastqc:
    input:
        "data/raw/{sample}.fastq"
    output:
        "data/qc/{sample}_fastqc.html"
    shell:
        "fastqc {input} -o data/qc/"

rule align_reads:
    input:
        fastq="data/raw/{sample}.fastq",
        ref=config["reference"]
    output:
        bam="data/aligned/{sample}.bam"
    shell:
        "minimap2 -t {config[threads]} -a {input.ref} {input.fastq} | samtools sort -o {output.bam}"

rule call_snps:
    input:
        bam="data/aligned/{sample}.bam",
        ref=config["reference"]
    output:
        vcf="data/variants/{sample}_snps.vcf"
    shell:
        "clair3 call --bam {input.bam} --ref {input.ref} --output {output.vcf}"

rule call_svs:
    input:
        bam="data/aligned/{sample}.bam"
    output:
        vcf="data/variants/{sample}_svs.vcf"
    shell:
        "sniffles --input {input.bam} --vcf {output.vcf}"

rule merge_variants:
    input:
        snps="data/variants/{sample}_snps.vcf",
        svs="data/variants/{sample}_svs.vcf"
    output:
        merged="results/variants/{sample}_merged.vcf"
    shell:
        "bcftools merge {input.snps} {input.svs} -o {output.merged} -O v"

rule annotate_variants:
    input:
        vcf="results/variants/{sample}_merged.vcf"
    output:
        annotated="results/variants/{sample}_annotated.vcf"
    params:
        cache=config["vep_cache"],
        ref=config["reference"]
    shell:
        """
        vep --input_file {input.vcf} \
            --output_file {output.annotated} \
            --cache --dir_cache {params.cache} \
            --fasta {params.ref} \
            --vcf --force_overwrite
        """

rule ml_filtering:
    input:
        vcf="results/variants/{sample}_annotated.vcf",
        model=config["ml_model"]
    output:
        filtered="results/variants/{sample}_filtered.vcf"
    params:
        script="scripts/ml_filtering.py"
    threads: config["threads"]
    shell:
        """
        python {params.script} \
            --vcf {input.vcf} \
            --model {input.model} \
            --out {output.filtered}
        """
