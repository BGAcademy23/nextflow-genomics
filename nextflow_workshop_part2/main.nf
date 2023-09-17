// Declare syntax version
nextflow.enable.dsl=2

include { PBINDEX } from './modules//pbindex/main.nf'
include { BAM2FASTX } from './modules/bam2fastx/main.nf'
include { HIFIASM } from './modules/hifiasm/main.nf'
include { QUAST } from './modules/quast/main.nf'

workflow {

	pacbio_bam_file = [
		[ id:'test_run', single_end: true],
		[ file(params.pacbio_bam, checkIfExists: true)]
	]
	
   PBINDEX(pacbio_bam_file)
   BAM2FASTX(pacbio_bam_file, PBINDEX.out.index)
   HIFIASM(BAM2FASTX.out.reads)
   QUAST(HIFIASM.out.assembly)
}
