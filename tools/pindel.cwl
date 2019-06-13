cwlVersion: v1.0
class: CommandLineTool
id: pindel_run
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'migbro/sanger_suite:latest'
  - class: ResourceRequirement
    ramMin: 72000
    coresMin: 36
  - class: InlineJavascriptRequirement

baseCommand: []
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      echo "$(inputs.input_tumor_aligned.path)\t$(inputs.insert_length)\t$(inputs.input_tumor_name)\n$(inputs.input_normal_aligned.path)\t$(inputs.insert_length)\t$(inputs.input_normal_name)" > pindel_config.tsv
      
      /pindel-0.2.5b9/pindel -f $(inputs.reference_fasta) -i pindel_config.tsv  -o $(inputs.output_basename).$(inputs.tool_name) -T 36 -j $(inputs.wgs_calling_bed.path) -w 1 && \
      grep ChrID $(inputs.output_basename).$(inputs.tool_name)_SI > SI_D.head && \
      grep ChrID $(inputs.output_basename).$(inputs.tool_name)_D >> SI_D.head && \
      

inputs:
  input_tumor_aligned: {type: File, secondaryFiles: [^.bai]}
  input_tumor_name: string
  input_normal_aligned: {type: File, secondaryFiles: [^.bai]}
  input_normal_name: string
  reference_fasta: File
  wgs_calling_bed: File
  output_basename: string
  tool_name: string
  insert_length: {type: int, doc: "Predicted size of sequene between sequencing adapters. For instance, if read len is 150, insert should at least be 300."}
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
