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

baseCommand: [bcftools, sort]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      -o $(inputs.unsorted_vcf.nameroot).sorted.vcf.gz
      -O z
      $(inputs.unsorted_vcf.path)

      tabix $(inputs.unsorted_vcf.nameroot).sorted.vcf.gz

inputs:
  unsorted_vcf: File[]

outputs:
  sorted_vcf:
    type: File
    outputBinding:
      glob: '*.sorted.vcf.gz'
    secondary_files: ['.tbi']
