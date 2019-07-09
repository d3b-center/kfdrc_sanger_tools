cwlVersion: v1.0
class: CommandLineTool
id: pcawg_variant_bam
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'migbro/pcawg_variant_bam'
  - class: ResourceRequirement
    ramMin: 16000
    coresMin: 8
  - class: InlineJavascriptRequirement

baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -euxo pipefail
    
      variant -i $(inputs.input_bam_aligned.path) -t 4 -l $(inputs.snv_vcf.path) -l $(inputs.indel_vcf.path) -T $(inputs.reference_fasta.path) -r "{\"snv\":{\"region\":\"$(inputs.snv_vcf.path)\",\"pad\":10},\"indel\":{\"region\":\"$(inputs.indel_vcf.path)\",\"pad\":93}}" | samtools view -bhS -@ 4 - > $(inputs.input_bam_aligned.nameroot).$(inputs.tool_name).variant_only.bam
      
      samtools index -@ 8 $(inputs.input_bam_aligned.nameroot).$(inputs.tool_name).variant_only.bam $(inputs.input_bam_aligned.nameroot).$(inputs.tool_name).variant_only.bai

      echo Done 1>&2

      exit 0

inputs:
  input_bam_aligned: {type: File, secondaryFiles: [^.bai]}
  tool_name: string
  reference_fasta: {type: File, secondaryFiles: [.fai]}
  snv_vcf: {type: File, secondaryFiles: ['.tbi']}
  indel_vcf: {type: File, secondaryFiles: ['.tbi']}
outputs:
  variant_bam:
    type: File
    outputBinding:
      glob: '*.bam'
    secondaryFiles: [^.bai]
