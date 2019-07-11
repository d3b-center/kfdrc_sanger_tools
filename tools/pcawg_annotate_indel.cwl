cwlVersion: v1.0
class: CommandLineTool
id: pcawg_annot_indel
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'migbro/pcawg_annotator'
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

      DEFREF=$(inputs.bgzipped_reference_fasta.path)
      
      DEFNTHREADS=8
      
      SGABIN=/usr/local/bin/sga

      NORMAL_BAM=$(inputs.input_normal_variant_bam.basename)

      ln -s $(inputs.input_normal_variant_bam.path) .; ln -s $(inputs.input_normal_variant_bam.secondaryFiles[0].path) ./$(inputs.input_normal_variant_bam.basename).bai

      TUMOUR_BAM=$(inputs.input_tumor_variant_bam.basename)

      ln -s $(inputs.input_tumor_variant_bam.path) .; ln -s $(inputs.input_tumor_variant_bam.secondaryFiles[0].path) ./$(inputs.input_tumor_variant_bam.basename).bai

      NTHREADS=8

      CLEAN_VCF=cleaned.vcf
      
      zcat $(inputs.input_indel_vcf.path) | /deps/vcflib/bin/vcfbreakmulti | grep -v "^##.*=$" > $CLEAN_VCF

      BEFORE_REHEADERING_VCF=to_reheader.vcf

      $SGABIN somatic-variant-filters --annotate-only --threads=$NTHREADS --tumor-bam=$TUMOUR_BAM --normal-bam=$NORMAL_BAM --reference=$DEFREF $CLEAN_VCF > $BEFORE_REHEADERING_VCF

      FINAL=${
          var fn=inputs.input_indel_vcf.nameroot.replace(".vcf","");
          var final = fn + ".pcawg_annotated.vcf";
          return final;
      }

      sed -n -e '1,/^#CHROM/p' $BEFORE_REHEADERING_VCF | head -n -1 > $FINAL

      cat /usr/local/share/indel.header >> $FINAL

      sed -n -e '/^#CHROM/,$p' $BEFORE_REHEADERING_VCF >> $FINAL

      bgzip $FINAL && tabix $FINAL.gz

inputs:
  input_indel_vcf: {type: File, secondaryFiles: [.tbi]}
  bgzipped_reference_fasta: {type: File, secondaryFiles: [.fai], doc: "Be sure reference is bgzipped before loading, index with samtools after"}
  input_tumor_variant_bam: {type: File, secondaryFiles: ['^.bai']}
  input_normal_variant_bam: {type: File, secondaryFiles: ['^.bai']}
outputs:
  annotated_indel_vcf:
    type: File
    outputBinding:
      glob: '*.vcf.gz'
    secondaryFiles: [.tbi]
