cwlVersion: v1.0
class: CommandLineTool
id: pcawg_variant_bam
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'migbro/pcawg_variant_bam'
  - class: ResourceRequirement
    ramMin: 72000
    coresMin: 36
  - class: InlineJavascriptRequirement

baseCommand: []
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      variant -i $(inputs.input_bam_aligned.path) -t 36 -b -o $(inputs.input_bam_aligned.nameroot).variant_only.bam -l $(inputs.snv_vcf.path) -l $(inputs.indel_vcf.path) -T $(inputs.reference_fasta.path) -r "{\"snv\":{\"region\":\"$(inputs.snv_vcf.path)\",\"pad\":10},\"indel\":{\"region\":\"$(inputs.indel_vcf.path)\",\"pad\":93}}" &&
      samtools index $(inputs.input_bam_aligned.nameroot).variant_only.bam $(inputs.input_bam_aligned.nameroot).variant_only.bai
inputs:
  input_bam_aligned: {type: File, secondaryFiles: [^.bai]}
  reference_fasta: {type: File, secondaryFiles: [.fai]}
  snv_vcf: {type: File, secondaryFiles: ['.tbi']}
  indel_vcf: {type: File, secondaryFiles: ['.tbi']}
outputs:
  variant_bam:
    type: File
    outputBinding:
      glob: '*.bam'
    secondaryFiles: [^.bai]
