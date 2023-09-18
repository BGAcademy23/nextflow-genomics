process BAM2FASTX {

    conda "bioconda::pbtk==3.1.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pbtk:3.1.0--h9ee0642_0':
        'quay.io/biocontainers/pbtk' }"
        
  input:
    tuple val(meta), path(bam)
    tuple val(meta), path(index)

  output:
    tuple val(meta), path('*.fastq.gz'), emit: reads

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"    
    """
    bam2fastq \\
        -o ${prefix} \\
        $bam \\
        > ${prefix}.bam2fastx.log
    """
}
