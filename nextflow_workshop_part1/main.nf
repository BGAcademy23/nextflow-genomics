// Declare syntax version
nextflow.enable.dsl=2

workflow {

	fastq_file = [
		[ id:'test_run', single_end: true],
		[ file(params.fastq_file, checkIfExists: true)]
	]

   HIFIASM(fastq_file)
}

process HIFIASM {

    conda "bioconda::hifiasm=0.18.5"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hifiasm:0.18.5--h5b5514e_0' :
        'biocontainers/hifiasm:0.18.5--h5b5514e_0' }"

  input:
    tuple val(meta), path(reads)

  output:
    tuple val(meta), path("*.gfa"), emit: assembly_gfa
    tuple val(meta), path("*.fa"), emit: assembly_fa

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    hifiasm \\
	$args \\
        -o ${prefix}.asm \\
        -t $task.cpus \\
        $reads

    #Transform gfa to fa
    awk '/^S/{print ">"\$2;print \$3}' ${prefix}.asm.bp.hap1.p_ctg.gfa > ${prefix}.fa
    """
}
