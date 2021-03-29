version 1.0

workflow Delly {
  input {
    String sample_id
    File bam_file
    File bai_file
    File excl_file
    File reference_fasta
    String delly_docker
  }

  parameter_meta {
    sample_id: "sample name"
    bam_file: ".bam file to search for CNVs"
    bai_file: ".bai file to search for CNVs"
    excl_file: "bed file including excluded regions for delly analysis"
    reference_fasta: ".fasta file with reference used to align bam file"
    delly_docker: "delly docker"
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
        delly_docker = delly_docker
    }

  output {
    File? delly.bcf = RunDelly.delly_bcf
  }

}

task RunDelly {
  input {
    String sample_id
    File bam_file
    File bai_file
    File = excl_file
    File reference_fasta
    String delly_docker
  }

  output {
    File delly_bcf = "~{sample_id}.bcf"
  }

  command <<<

    echo "[ RUNNING ] delly on sample ~{sample_id}"
    cat /proc/self/cgroup | head -1 | tr --delete ‘10:memory:/docker/’
    delly call -x ~{excl_file} -o ~{sample_id}.bcf -g ~{reference_fasta} ~{bam_file}

  >>>
  
  runtime {
    docker: delly_docker
    maxRetries: 1
    requested_memory_mb_per_core: 1000
    cpu: 1
    runtime_minutes: 30
  }

}
