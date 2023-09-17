process HIFIASM {

    conda "bioconda::hifiasm=0.18.5"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hifiasm:0.18.5--h5b5514e_0' :
        'biocontainers/hifiasm:0.18.5--h5b5514e_0' }"

  input:
    tuple val(meta), path(reads)

  output:
    tuple val(meta), path("*.gfa"), emit: assembly

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    hifiasm \\
	$args \\
        -o ${prefix}.asm \\
        $reads
    """
}
