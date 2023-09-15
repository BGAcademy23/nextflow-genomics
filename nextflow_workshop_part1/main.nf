// Declare syntax version
nextflow.enable.dsl=2

process BAM2FASTX {

    conda "bioconda::pbtk==3.1.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pbtk:3.1.0--h9ee0642_0':
        'quay.io/biocontainers/pbtk' }"
        
  input:
    tuple val(meta), path(bam)

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
        -o ${prefix}.asm \\
        $reads
    """
}



workflow {

	pacbio_bam_file = [
		[ id:'test_run', single_end: true],
		[ file(params.pacbio_bam, checkIfExists: true)]
	]
	
   BAM2FASTX(pacbio_bam_file)
   HIFIASM(BAM2FASTX.out.reads)
}
