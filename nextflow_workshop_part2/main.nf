// Declare syntax version
nextflow.enable.dsl=2

include { HIFIASM } from './modules/hifiasm/main.nf'
include { GFA_TO_FA } from './modules/gfa_to_fa/main.nf
include { QUAST } from './modules/quast/main.nf'

workflow {

        fastq_file = [
                [ id:'test_run', single_end: true],
                [ file(params.fastq_file, checkIfExists: true)]
        ]
	
   HIFIASM(BAM2FASTX.out.reads)
   GFA_TO_FA(HIFIASM.out.assembly)
   QUAST(GFA_TO_FA.out.assembly)
}
