cwlVersion: v1.0
class: CommandLineTool
id: bcftools_sort
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'kfdrc/bvcftools'
  - class: ResourceRequirement
    ramMin: 4000
    coresMin: 2
  - class: InlineJavascriptRequirement

baseCommand: [bcftools, concat]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: >-
      -o $(inputs.output_basename).concat.vcf.gz
      -O z

  - position: 2
    shellQuote: false
    valueFrom: >-
      $(inputs.input_normal_name) > sample_list.txt &&
      echo $(inputs.input_tumor_name) >> sample_list.txt &&
      bcftools reheader -s sample_list.txt $(inputs.output_basename).concat.vcf.gz > $(inputs.output_basename).$(inputs.tool_name).PREPASS.vcf.gz &&
      tabix $(inputs.output_basename).$(inputs.tool_name).PREPASS.vcf.gz

inputs:
  input_vcfs:
    type:
      type: array
      items: File
    secondaryFiles: [.tbi]
    inputBinding:
      position: 1
  tool_name: string
  output_basename: string
  input_normal_name: string
  input_tumor_name: string


outputs:
  merged_vcf:
    type: File
    outputBinding:
      glob: '*.PREPASS.vcf.gz'
    secondaryFiles: ['.tbi']