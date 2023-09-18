process QUAST {

    conda 'bioconda::quast=5.2.0'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/quast:5.2.0--py39pl5321h2add14b_1' :
        'quay.io/biocontainers/quast:5.2.0--py39pl5321h2add14b_1' }"

    input:
    tuple val(meta), path (fasta)

    output:
    path 'report.tsv'        , emit: tsv

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    quast.py \\
        --output-dir $prefix \\
        $args \\
        $fasta
        
    mv ${prefix}/report.tsv report.tsv
    """
}
