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

baseCommand: [bcftools, view]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      -f .,PASS
      -o $(inputs.output_basename).$(inputs.tool_name).PASSED.vcf.gz
      -O z
      $(inputs.merged_vcf.path)

inputs:
  merged_vcf: File
  output_basename: string
  tool_name: string

outputs:
  passed_vcf:
    type: File
    outputBinding:
      glob: '*.PASSED.vcf.gz'
