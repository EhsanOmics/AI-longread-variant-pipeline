rule ml_filtering:
    input:
        vcf="results/variants/merged.vcf",
        model=config["ml_model"]
    output:
        filtered="results/variants/filtered_variants.tsv"
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
