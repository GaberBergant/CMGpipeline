version 1.0

workflow ExpansionHunter {
  input {
    String sample_id
    File bam_file
    File reference_fasta
    File ?variant_catalog_file
    String ?expansion_hunter_docker

    File ?repeats_file
  }

  parameter_meta {
    sample_id: "sample name. Outputs will be sample_name + '.vcf'"
    bam_file: ".bam file to search for repeat expansions."
    reference_fasta: ".fasta file with reference used to align bam file"
    variant_catalog_file: "JSON array whose entries specify individual loci that the program will analyze"
    expansion_hunter_docker: "[optional] array of event types for Delly to search for. Defaults to ['DEL', 'DUP', 'INV']."
  }

  meta {
      author: "Gaber Bergant and Aleš Maver"
      email: "cmg.kimg@kclj.si"
  }

  File variant_catalog_file = select_first([variant_catalog_file, "/repeat-specs/hg19/variant_catalog.json"])
  File expansion_hunter_docker = select_first([expansion_hunter_docker, "gbergant/expansionhunter:latest"])
  File repeats_file = select_first([repeats_file, "/stranger/stranger/resources/variant_catalog_hg19.json"])

  call RunExpansionHunter {
      input:
        sample_id = sample_id,
        bam_file = bam_file,
        reference_fasta = reference_fasta,
        variant_catalog_file = variant_catalog_file,
        expansion_hunter_docker = expansion_hunter_docker
    }

  call AnnotateExpansionHunter {
      input:
        sample_id = sample_id
    }
}

task RunExpansionHunter {
  input {
    String sample_id
    File bam_file
    File reference_fasta
    File variant_catalog_file
    String expansion_hunter_docker
  }

  output {
    File vcf = "${sample_id}.vcf"
  }
  command <<<

    echo "[ RUNNING ] expansion hunter on sample ~{sample_id}"
    ExpansionHunter \
      --reads "~{bam_file}" \
      --reference "~{reference_fasta}" \
      --variant-catalog "~{variant_catalog_file}" \
      --output-prefix "~{sample_id}"

  >>>
  runtime {
    docker: expansion_hunter_docker
    maxRetries: 3
    requested_memory_mb_per_core: 1000
    cpu: 1
    runtime_minutes: 10
  }

}

task AnnotateExpansionHunter {
  input {
    String sample_id
    File repeats_file
  }

  output {
    File annotated_vcf = "${sample_id}.annotated.vcf"
  }
  command <<<

    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8
    annotated_vcf = "${sample_id}.annotated.vcf"

    echo "[ RUNNING ] expansion hunter vcf annotation on sample ~{sample_id}"
    stranger \
      --repeats-file "~{variant_catalog_file}" \
      "~{sample_id}.vcf > annotated_vcf"

  >>>
  runtime {
    docker: expansion_hunter_docker
  }

}