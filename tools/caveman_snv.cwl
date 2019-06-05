cwlVersion: v1.0
class: CommandLineTool
id: caveman_snv
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'migbro/caveman:1.13.15'
  - class: ResourceRequirement
    ramMin: 72000
    coresMin: 36
  - class: InlineJavascriptRequirement
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      SWV=1.13.15

      /CaVEMan-$SWV/bin/caveman setup
      -t $(inputs.tumor_align.path)
      -n $(inputs.normal_align.path)
      -r $(inputs.fasta_index.path)
      -g $(inputs.blacklist.path)

      for chrom in `seq 1 24`; do
        echo "/CaVEMan-$SWV/bin/caveman split -f caveman.cfg.ini -i $chrom" >> split_cmd_list.txt;
      done

      cat split_cmd_list.txt | xargs -ICMD -P $(inputs.threads) sh -c "CMD"

      cat splitList.chr* > temp && mv temp splitList

      SLEN=`wc -l splitList | cut -f 1 -d " "` 
      
      for chrom in `seq 1 $SLEN`; do
        echo "/CaVEMan-$SWV/bin/caveman mstep -f caveman.cfg.ini -i $chrom" >> mstep_cmd_list.txt;
      done
      
      cat mstep_cmd_list.txt | xargs -ICMD -P $(inputs.threads) sh -c "CMD"

      /CaVEMan-$SWV/bin/caveman merge -f caveman.cfg.ini
      
      for chrom in `seq 1 40`; do
        echo "/CaVEMan-$SWV/bin/caveman estep -f caveman.cfg.ini -i $chrom -k 0.1 -n 2 -t 5" >> estep_cmd_list.txt;
      done

      cat mstep_cmd_list.txt | xargs -ICMD -P $(inputs.threads) sh -c "CMD"
inputs:
  input_reads: File
  threads: int
  reference: File
outputs:
  bam_file:
    type: File
    outputBinding:
      glob: '*.bam'
    secondaryFiles: [^.bai]
