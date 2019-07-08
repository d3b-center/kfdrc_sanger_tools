cwlVersion: v1.0
class: CommandLineTool
id: pcawg_annot_indel
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'migbro/migbro/pcawg_annotator'
  - class: ResourceRequirement
    ramMin: 32000
    coresMin: 8
  - class: InlineJavascriptRequirement

baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -euxo pipefail

      DEFREF=$(inputs.reference_fasta.path)
      
      DEFNTHREADS=8
      
      SGABIN=/usr/local/bin/sga

      INPUT_VCF=$(inputs.input_snv_vcf.path)

      NORMAL_BAM=$(inputs.input_normal_variant_bam.path)

      TUMOUR_BAM=$(inputs.input_tumor_variant_bam.path)

      NTHREADS=8

      CLEAN_VCF=cleaned.vcf
      
      zcat $(inputs.input_snv_vcf.path) | /deps/vcflib/bin/vcfbreakmulti | grep -v "^##.*=$" > $CLEAN_VCF

      BEFORE_REHEADERING_VCF=to_reheader.vcf

      $SGABIN somatic-variant-filters --annotate-only --threads=$NTHREADS --tumor-bam=$TUMOUR_BAM --normal-bam=$NORMAL_BAM --reference=$REFERENCE $CLEAN_VCF > $BEFORE_REHEADERING_VCF

      ${
          var fn=inputs.input_snv_vcf.nameroot.replace(".vcf","");
          inputs.final = fn + "pcawg_annotated.vcf";
      }

      sed -n -e '1,/^#CHROM/p' $BEFORE_REHEADERING_VCF | head -n -1 > $(inputs.final)

      cat /usr/local/share/indel.header >> $(inputs.final)

      sed -n -e '/^#CHROM/,$p' $BEFORE_REHEADERING_VCF >> $(inputs.final)

      bgzip $(inputs.final) && tabix $(inputs.final).gz

inputs:
  input_indel_vcf: {type: File, secondaryFiles: [^.tbi]}
  reference_fasta: {type: File, secondaryFiles: [.fai]}
  input_tumor_variant_bam: {type: File, secondaryFiles: ['^.bai']}
  input_normal_variant_bam: {type: File, secondaryFiles: ['^.bai']}
outputs:
  annotated_indel_vcf:
    type: File
    outputBinding:
      glob: '*.vcf.gz'
    secondaryFiles: [.tbi]
