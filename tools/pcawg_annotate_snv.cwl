cwlVersion: v1.0
class: CommandLineTool
id: pcawg_annot_snv
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
      
      READCOUNTSBIN=/usr/bin/bam-readcounts

      NORMAL_BAM=$(inputs.input_normal_variant_bam.basename)

      ln -s $(inputs.input_normal_variant_bam.path) .; ln -s $(inputs.input_normal_variant_bam.secondaryFiles[0].path) ./$(inputs.input_normal_variant_bam.basename).bai

      TUMOUR_BAM=$(inputs.input_tumor_variant_bam.basename)

      ln -s $(inputs.input_tumor_variant_bam.path) .; ln -s $(inputs.input_tumor_variant_bam.secondaryFiles[0].path) ./$(inputs.input_tumor_variant_bam.basename).bai

      CLEAN_VCF=cleaned.vcf
      
      zcat $(inputs.input_snv_vcf.path) | /deps/vcflib/bin/vcfbreakmulti | grep -v "^##.*=$" > $CLEAN_VCF

      awk '$1 !~ /^#/{ printf "%s\t%d\t%d\n",$1,$2,$2+1 }' $CLEAN_VCF > regions.txt

      echo "/usr/bin/bam-readcount --reference-fasta $DEFREF --site-list regions.txt --max-count 8000 $NORMAL_BAM > norm.rc" > bam_rc_cmd.txt

      echo "/usr/bin/bam-readcount --reference-fasta $DEFREF --site-list regions.txt --max-count 8000 $TUMOUR_BAM > tumor.rc" >> bam_rc_cmd.txt

      cat bam_rc_cmd.txt | xargs -ICMD -P 4 sh -c "CMD"

      BEFORE_REHEADERING_VCF=to_reheader.vcf

      /usr/local/bin/annotate_from_readcounts.py $CLEAN_VCF norm.rc tumor.rc > $BEFORE_REHEADERING_VCF

      FINAL=${
          var fn=inputs.input_snv_vcf.nameroot.replace(".vcf","");
          var final = fn + ".pcawg_annotated.vcf";
          return final;
      }

      sed -n -e '1,/^#CHROM/p' $BEFORE_REHEADERING_VCF | head -n -1 > $FINAL

      cat /usr/local/share/snv.header >> $FINAL

      sed -n -e '/^#CHROM/,$p' $BEFORE_REHEADERING_VCF >> $FINAL

      bgzip $FINAL && tabix $FINAL.gz

inputs:
  input_snv_vcf: {type: File, secondaryFiles: [.tbi]}
  bgzipped_reference_fasta: {type: File, secondaryFiles: [.fai], doc: "Be sure reference is bgzipped before loading, index with samtools after"}
  input_tumor_variant_bam: {type: File, secondaryFiles: ['^.bai']}
  input_normal_variant_bam: {type: File, secondaryFiles: ['^.bai']}
outputs:
  annotated_snv_vcf:
    type: File
    outputBinding:
      glob: '*.vcf.gz'
    secondaryFiles: [.tbi]
