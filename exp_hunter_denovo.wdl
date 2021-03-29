version 1.0

workflow ExpansionHunter {
  input {
    String sample_id
    File bam_file
    File bai_file
    File reference_fasta
    String expansion_hunter_docker
  }

  parameter_meta {
    sample_id: "sample name"
    bam_file: ".bam file to search for repeat expansions"
    reference_fasta: ".fasta file with reference used to align bam file"
    expansion_hunter_docker: "expansion hunter docker including annotation software"
  }

  meta {
      author: "Gaber Bergant and Aleš Maver"
      email: "cmg.kimg@kclj.si"
  }
  
  call RunExpansionHunter {
      input:
        sample_id = sample_id,
        bam_file = bam_file,
        bai_file = bai_file,
        reference_fasta = reference_fasta,
        expansion_hunter_docker = expansion_hunter_docker
    }

  output {
    File? expansion_hunter_denovo_profile = RunExpansionHunter.expansion_hunter_denovo_profile
    File? expansion_hunter_denovo_locus = RunExpansionHunter.expansion_hunter_denovo_locus
    File? expansion_hunter_denovo_motif = RunExpansionHunter.expansion_hunter_denovo_motif
  }

}

task RunExpansionHunter {
  input {
    String sample_id
    File bam_file
    File bai_file
    File reference_fasta
    String expansion_hunter_docker
  }

  output {
    File expansion_hunter_denovo_profile = "~{sample_id}.str_profile.json"
    File expansion_hunter_denovo_locus = "~{sample_id}.locus.tsv"
    File expansion_hunter_denovo_motif = "~{sample_id}.motif.tsv"
  }

  command <<<

    echo "[ RUNNING ] expansion hunter denovo on sample ~{sample_id}"      
     ExpansionHunterDenovo profile \
        --reads ~{bam_file} \
        --reference ~{reference_fasta} \
        --output-prefix ~{sample_id} \
        --min-anchor-mapq 50 \
        --max-irr-mapq 40

  >>>
  
  runtime {
    docker: expansion_hunter_docker
    maxRetries: 1
    requested_memory_mb_per_core: 1000
    cpu: 1
    runtime_minutes: 30
  }

}
