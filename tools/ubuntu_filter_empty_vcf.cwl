cwlVersion: v1.0
class: CommandLineTool
id: ubuntu_filter_empty_vcf
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'ubuntu:18.04'
  - class: ResourceRequirement
    ramMin: 4000
    coresMin: 2
  - class: InlineJavascriptRequirement

baseCommand: []
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      ${
        var cmd= "";
        for (var i=0;i<inputs.input_vcfs.length;i++){
            cmd += "grep -m 1 -Ev \"^#\" " + inputs.input_vcfs[i].path + " /dev/null | cut -f 1 -d \":\" >> non_empty_vcfs.txt;";
        }
        return cmd;
      }
      
      cat non_empty_vcfs.txt | xargs -IFN cp FN ./

inputs:
  input_vcfs: File[]

outputs:
  non_empty_vcfs:
    type: File[]
    outputBinding:
      glob: '*.vcf'
