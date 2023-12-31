// Declare syntax version
nextflow.enable.dsl=2

process PBINDEX {

    conda "bioconda::pbtk==3.1.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pbtk:3.1.0--h9ee0642_0':
        'quay.io/biocontainers/pbtk' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path('*.bam.pbi'), emit: index

    script:
    """
    pbindex \\
        $bam
    """
}


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

process SAMTOOLS_FAIDX {

    conda "bioconda::samtools=1.17"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.17--h00cdaf9_0' :
        'biocontainers/samtools:1.17--h00cdaf9_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path ("*.fai")        , emit: fai, optional: true

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    samtools faidx \\
        $fasta \\
        $args
    """
}

workflow {

	pacbio_bam_file = [
		[ id:'test_run', single_end: true],
		[ file(params.pacbio_bam, checkIfExists: true)]
	]

	fastq_file = [
		[ id:'test_run', single_end: true],
		[ file(params.fastq_file, checkIfExists: true)]
	]
	
   PBINDEX(pacbio_bam_file)
   BAM2FASTX(pacbio_bam_file, PBINDEX.out.index)
   HIFIASM(BAM2FASTX.out.reads)
   SAMTOOLS_FAIDX(HIFIASM.out.assembly)
}
