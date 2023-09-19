# Introduction to NextFlow for genomics

This session is part of [**Biodiversity Genomics Academy 2023**](https://BGA23.org)

## Session Leader(s)

Solenne Correard  
I would like to acknowledge that I am living and working on the traditional, ancestral, and unceded territory of the Musqueam, Squamish and Tsleil-Waututh people.  

Canada Biogenome Project  
Canada's Michael Smith Genome Sciences Centre

I did my PhD in France studying the dog genome (mostly the non-coding part), followed by a post-doc on the Silent Genomes Project, a project aiming to reduce health care disparities and improve diagnostic success for children with rare genetic diseases from Indigenous populations in Canada. I am now leading the bioinformatic analysis for the Canadian BioGenome Project.

## Description

The session will last for about 1h30, and will be split in 2 parts of about 40 min each (we'll take a 10 min break in the middle).

Each part will include an introduction, some coding and hopefully many questions and discussion!

Outline of the session :

- Nextflow (Part 1) : What is it? When should I use it? How do I use it? 

Practice : Writing your first Nextflow pipeline to generate a contig assembly. 

- NF-core (Part 2): What is it? When should I use it? How do I use it? 

Practice : Use NF-core tools to assess the quality of the generated assembly. 

- Conclusion: Resources to learn more about Nextflow and NF-core and how to take part in the community.

By the end of this session you will be able to:

1. Read a nextflow pipeline and modify it
2. Write a basic nextflow pipeline
3. Use a nf-core pipeline
4. How to join the nextflow / nf-core community

The outline may change if I come up with a better idea while generating the material!

## Prerequisites

1. Expertise with linux command line basics (`cd`, `mv`, `rm`, `wget`, `curl` etc)
2. Understanding of bash scripts, and the need for bioinformatics workflows
3. Understand the general role and input/output files of the following tools : [hifiasm HiFi only](https://hifiasm.readthedocs.io/en/latest/pa-assembly.html), [Quast](https://github.com/ablab/quast), [multiQC](https://multiqc.info)

!!! warning "Please make sure you MEET THE PREREQUISITES and READ THE DESCRIPTION above"

    You will get the most out of this session if you meet the prerequisites above.

    Please also read the description carefully to see if this session is relevant to you.

## Tutorial

We will be using GitPod for this tutorial so [**SEND ME TO GITPOD!**](https://gitpod.io/#https://github.com/BGAcademy23/nextflow-genomics).

Do not use safari

Give it a minute to install nextflow and mamba...

!! Open a new terminal in gitpod !! 

(If you don't do that, nextflow and conda won't work)

### Part 1 

1. Launching your first pipeline (example with hifiasm)

```
cd nextflow-genomics/nextflow_workshop_part1/
```

You will see 2 files : nextflow.config and main.nf

Feel free to look at the files!

Launch your nextflow pipeline

```
nextflow_cmd run main.nf -profile mamba
```
    
2. Adding a module (example with Quast)

Try to do it on your own :

- in the main.nf file, Copy / paste a previous module as a template (for example hifiasm)

- Replace the conda and singularity info for the module of interest

- Identify the input and output files

- Include the code for the given module (often on the github of the tool)

- Include the newly generated process in the workflow

- Try and correct the errors
```
nextflow run main.nf –profile mamba -resume
```

<details>
<summary>Solution</summary>
There are several ways of coding a module, here is an example for the main.nf file to run hifiasm then quast :

```
// Declare syntax version
nextflow.enable.dsl=2

workflow {

	fastq_file = [
		[ id:'test_run', single_end: true],
		[ file(params.fastq_file, checkIfExists: true)]
	]

   HIFIASM(fastq_file)
   QUAST(HIFIASM.out.assembly_fa)
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
    awk '/^S/{print ">"\$2;print \$3}' ${prefix}.asm.gfa > ${prefix}.fa
    """
}

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
    prefix   = task.ext.prefix ?: 'quast'
    """
    quast.py \\
        --output-dir $prefix \\
        $args \\
        $fasta
        
    mv ${prefix}/report.tsv report.tsv
    """
}
```    
</details>


### Part 2

3. Add a module using nf-core

```
cd nextflow-genomics/nextflow_workshop_part2/
```

You will see a new folder : 'modules'

Feel free to look inside the folder and sub-folders!

Launch this nextflow pipeline

```
nextflow_cmd run main.nf -profile mamba
```

Now add the samtools_faidx module to your pipeline

<details>
<summary>Solution</summary>
Create the appropriate folder for samtools_faidx module

```
mkdir modules/samtools_faidx
```

Copy the nf-core/samtools_faidx process in this folder : https://github.com/nf-core/modules/blob/master/modules/nf-core/samtools/faidx/main.nf

```
vi modules/samtools_faidx/main.nf
```

Modify the workflow main.nf to include this new process

```
// Declare syntax version
nextflow.enable.dsl=2

include { HIFIASM } from './modules/hifiasm/main.nf'
include { QUAST } from './modules/quast/main.nf'
include { SAMTOOLS_FAIDX } from './modules/samtools_faidx/main.nf'

workflow {

        fastq_file = [
                [ id:'test_run', single_end: true],
                [ file(params.fastq_file, checkIfExists: true)]
        ]
	
   HIFIASM(fastq_file)
   QUAST(HIFIASM.out.assembly_fa)
   SAMTOOLS_FAIDX(HIFIASM.out.assembly_fa, [[],[]])
}
```






</details>


