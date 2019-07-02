cwlVersion: v1.0
class: CommandLineTool
id: caveman_split
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'kfdrc/sanger_suite:latest'
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
      -t $(inputs.input_tumor_aligned.path)
      -n $(inputs.input_normal_aligned.path)
      -r $(inputs.indexed_reference_fasta.path).fai
      -g $(inputs.blacklist.path)

      for chrom in `seq 1 24`; do
        echo "/CaVEMan-$SWV/bin/caveman split -f caveman.cfg.ini -i $chrom" >> split_cmd_list.txt;
      done

      cat split_cmd_list.txt | xargs -ICMD -P 16 sh -c "CMD"

      cat splitList.chr* > merged_split.txt && split merged_split.txt -n l/16

inputs:
  input_tumor_aligned: 
    type: File
    secondaryFiles: |
      ${
        var dpath = self.location.replace(self.basename, "")
        if(self.nameext == '.bam'){
          return {"location": dpath+self.nameroot+".bai", "class": "File"}
        }
        else{
          return {"location": dpath+self.basename+".crai", "class": "File"}
        }
      }
    doc: "tumor BAM or CRAM"

  input_normal_aligned:
    type: File
    secondaryFiles: |
      ${
        var dpath = self.location.replace(self.basename, "")
        if(self.nameext == '.bam'){
          return {"location": dpath+self.nameroot+".bai", "class": "File"}
        }
        else{
          return {"location": dpath+self.basename+".crai", "class": "File"}
        }
      }
    doc: "normal BAM or CRAM"
  indexed_reference_fasta: {type: File, secondaryFiles: ['.fai']}
  blacklist: {type: File, doc: "Bed style, but 1-based coords"}
outputs:
  splitList:
    type: File[]
    outputBinding:
      glob: 'xa*'
  config_file:
    type: File
    outputBinding:
      glob: '*.ini'
  alg_bean:
    type: File
    outputBinding:
      glob: 'alg_bean'
