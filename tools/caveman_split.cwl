cwlVersion: v1.0
class: CommandLineTool
id: caveman_split
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'migbro/caveman:1.13.15'
  - class: ResourceRequirement
    ramMin: 32000
    coresMin: 16
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

inputs:
  input_tumor_aligned: File
  input_normal_aligned: File
  threads: int
  fasta_index: File
  blacklist: {type: File, doc: "Bed style, but 1-based coords"}
outputs:
  splitList:
    type: File[]
    outputBinding:
      glob: 'splitList.*'
  config_file:
    type: File
    outputBinding:
      glob: '*.ini'
