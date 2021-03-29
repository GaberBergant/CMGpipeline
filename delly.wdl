version 1.0

workflow Delly {
  input {
    String sample_id
    File bam_file
    File bai_file
    File excl_file
    File reference_fasta
    String delly_docker
    
    Directory delly_results = "/home/ales/CENTRAL/ARCHIVE/DELLY/ORIGINAL_BCF/"
  }

  parameter_meta {
    sample_id: "sample name"
    bam_file: ".bam file to search for CNVs"
    bai_file: ".bai file to search for CNVs"
    excl_file: "bed file including excluded regions for delly analysis"
    reference_fasta: ".fasta file with reference used to align bam file"
    delly_docker: "delly docker"
    delly_results: "Path to directory with delly bcfs"
  }

  meta {
      author: "Gaber Bergant and Aleš Maver"
      email: "cmg.kimg@kclj.si"
  }
  
  call RunDelly {
      input:
        sample_id = sample_id,
        bam_file = bam_file,
        bai_file = bai_file,
        excl_file = excl_file,
        reference_fasta = reference_fasta,
        delly_docker = delly_docker,
        delly_results = delly_results
    }

  output {
    File? delly_bcf = RunDelly.delly_bcf
  }

}

task RunDelly {
  input {
    String sample_id
    File bam_file
    File bai_file
    File excl_file
    File reference_fasta
    String delly_docker
    
    Directory delly_results
  }

  output {
    File delly_bcf = "~{sample_id}.bcf"
  }

  command <<<

    echo "[ RUNNING ] delly on sample ~{sample_id}"
    echo "delly call -x ~{excl_file} -o ~{sample_id}.bcf -g ~{reference_fasta} ~{bam_file}"
    
    echo "[ RUNNING ] merge N samples"
    echo "delly merge -o sites.bcf"
    
    echo "[ RUNNING ] genotyping merged SV site list across all samples"
    echo "delly call -g hg19.fa -v sites.bcf -o s1.geno.bcf -x hg19.excl s1.bam"
    
    echo "[ RUNNING ] merge N genotyped samples"
    echo "bcftools merge -m id -O b -o merged.bcf s1.geno.bcf s2.geno.bcf ... sN.geno.bcf"
    
    echo "[ RUNNING ] apply the germline SV filter if over 20 samples"
    echo "delly filter -f germline -o germline.bcf merged.bcf"

  >>>
  
  runtime {
    docker: delly_docker
    maxRetries: 1
    requested_memory_mb_per_core: 1000
    cpu: 1
    runtime_minutes: 30
  }

}
