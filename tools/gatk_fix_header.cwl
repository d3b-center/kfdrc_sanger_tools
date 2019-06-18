cwlVersion: v1.0
class: CommandLineTool
id: gatk_fixvcfheader
label: GATK Fix VCF Header
doc: "Merge input vcfs"
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: DockerRequirement
    dockerPull: 'kfdrc/gatk:4.1.1.0'
  - class: ResourceRequirement
    ramMin: 6000
    coresMin: 4
baseCommand: []
arguments:
  - position: 0
    shellQuote: false
    valueFrom: >-
      ${
        var gatk_cmd = "/gatk FixVcfHeader -I ";
        var run_cmd = "";
        for (var i=0; i<inputs.input_vcfs.length;i++){
            run_cmd += gatk_cmd + inputs.input_vcfs[i].path + " -O ./" + inputs.input_vcfs[i].nameroot + ".fixed.vcf.gz;"
        }
        return run_cmd;
      }

inputs:
  input_vcfs: File[]
outputs:
  fixed_header_vcf:
    type: File[]
    outputBinding:
      glob: '*.fixed.vcf.gz'
    secondaryFiles: [.tbi]
