cwlVersion: v1.0
class: CommandLineTool
id: bcftools_split
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'kfdrc/bvcftools'
  - class: ResourceRequirement
    ramMin: 4000
    coresMin: 2
  - class: InlineJavascriptRequirement

baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -euxo pipefail

      zcat $(inputs.input_vcf.path) | grep -E "^#" > header.txt

      zcat $(inputs.input_vcf.path) | grep -Ev "^#" > body.vcf

      split -n l/$(inputs.split_size) body.vcf

      ls x* | xargs -IFN sh -c "cat header.txt FN > FN.split.vcf; bgzip FN.split.vcf; tabix FN.split.vcf.gz"

inputs:
  input_vcf: {type: File, secondaryFiles: [.tbi]}
  split_size: {type: int, doc: "At least 64"}
outputs:
  split_vcfs:
    type: File[]
    outputBinding:
      glob: '*.split.vcf.gz'
    secondaryFiles: ['.tbi']
