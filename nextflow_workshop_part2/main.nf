// Declare syntax version
nextflow.enable.dsl=2

include { HIFIASM } from './modules/hifiasm/main.nf'
include { QUAST } from './modules/quast/main.nf'

workflow {

        fastq_file = [
                [ id:'test_run', single_end: true],
                [ file(params.fastq_file, checkIfExists: true)]
        ]
	
   HIFIASM(fastq_file)
   QUAST(HIFIASM.out.assembly_fa)
}
