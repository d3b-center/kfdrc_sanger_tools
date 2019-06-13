cwlVersion: v1.0
class: Workflow
id: caveman_snv_wf
requirements:
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  input_tumor_aligned:
    type: File
    secondaryFiles: |
      ${
        var dpath = self.location.replace(self.basename, "")
        if(self.nameext == '.bam'){
          return {"location": dpath+self.nameroot+".bai", "class": "File"}
        }
        else{
          return {"location": dpath+self.basename+".crai", "class": "File"}
        }
      }
    doc: "tumor BAM or CRAM"
  input_tumor_name: string
  input_normal_aligned:
    type: File
    secondaryFiles: |
      ${
        var dpath = self.location.replace(self.basename, "")
        if(self.nameext == '.bam'){
          return {"location": dpath+self.nameroot+".bai", "class": "File"}
        }
        else{
          return {"location": dpath+self.basename+".crai", "class": "File"}
        }
      }
    doc: "normal BAM or CRAM"
  input_normal_name: string
  output_basename: string
  # reference_dict: File
  vep_cache: {type: File, label: tar gzipped cache from ensembl/local converted cache}
  threads: int
  indexed_reference_fasta: {type: File, secondaryFiles: [.fai]}
  blacklist: {type: File, doc: "Bed style, but 1-based coords"}
  genome_assembly: {type: string, doc: "Species assembly (eg 37/GRCh37)"}
  species: {type: string, doc: "Species name (eg Human)" }
  assay_type: {type: string, doc: "Type of assay called, options are WGS, WXS, AMPLICON, RNASEQ, TARGETED"}
  bed_refs_tar: {type: File, doc: "tar gzipped bed files with bed refs specified in flag_config"}
  samtools_ref_cache: {type: File, doc: "samtools ref cache for working with cram input"}
  flag_config: {type: File, doc: "Config file with param type, flag list, bedfiles"}
  flag_convert: {type: File, doc: "Flag description file"}

outputs:
  caveman_somatic_prepass_vcf: {type: File, outputSource: bcftools_merge_somatic_vcfs/merged_vcf}
  caveman_vep_vcf: {type: File, outputSource: vep_annot_caveman/output_vcf}
  caveman_vep_tbi: {type: File, outputSource: vep_annot_caveman/output_tbi}
  caveman_germline_unfiltered_vcf: {type: File, outputSource: bcftools_merge_germline_vcfs/merged_vcf}

steps:
  caveman_split:
    run: ../tools/caveman_split.cwl
    in:
      input_tumor_aligned: input_tumor_aligned
      input_normal_aligned: input_normal_aligned
      indexed_reference_fasta: indexed_reference_fasta
      blacklist: blacklist

    out: [splitList, config_file, alg_bean]

  caveman_step:
    hints:
      - class: 'sbg:AWSInstanceType'
        value: m5.12xlarge;ebs-gp2;500
    run: ../tools/caveman_step.cwl
    in:
      input_tumor_aligned: input_tumor_aligned
      input_normal_aligned: input_normal_aligned
      threads: threads
      indexed_reference_fasta: indexed_reference_fasta
      blacklist: blacklist
      genome_assembly: genome_assembly
      species: species
      splitList: caveman_split/splitList
      config_file: caveman_split/config_file
      alg_bean: caveman_split/alg_bean
    scatter: splitList
    out: [snps_vcf, muts_vcf]

  bctools_sort_caveman_somatic_vcf:
    hints:
      - class: 'sbg:AWSInstanceType'
        value: c5.4xlarge;ebs-gp2;250
    run: ../tools/bcftools_sort.cwl
    label: BCFTOOLS sort somatic
    in:
      unsorted_vcf: caveman_step/muts_vcf
    scatter: unsorted_vcf
    out: [sorted_vcf]

  bctools_sort_caveman_germline_vcf:
    hints:
      - class: 'sbg:AWSInstanceType'
        value: c5.4xlarge;ebs-gp2;250
    run: ../tools/bcftools_sort.cwl
    label: BCFTOOLS sort germline
    in:
      unsorted_vcf: caveman_step/snps_vcf
    scatter: unsorted_vcf
    out: [sorted_vcf]

  bcftools_merge_germline_vcfs:
    run: ../tools/bcftools_concat.cwl
    in:
      input_vcfs: bctools_sort_caveman_germline_vcf/sorted_vcf
      tool_name:
        valueFrom: ${return "caveman_germline"}
      output_basename: output_basename
      input_normal_name: input_normal_name
      input_tumor_name: input_tumor_name
    out: [merged_vcf]

  caveman_flag_somatic:
    hints:
      - class: 'sbg:AWSInstanceType'
        value: c5.9xlarge;ebs-gp2;500
    run: ../tools/caveman_flag.cwl
    in:
      input_tumor_aligned: input_tumor_aligned
      input_normal_aligned: input_normal_aligned
      indexed_reference_fasta: indexed_reference_fasta
      species: species
      assay_type: assay_type
      bed_refs_tar: bed_refs_tar
      samtools_ref_cache: samtools_ref_cache
      flag_config: flag_config
      flag_convert: flag_convert
      called_vcf: bctools_sort_caveman_somatic_vcf/sorted_vcf
    scatter: called_vcf
    out: [flagged_vcf]

  bcftools_merge_somatic_vcfs:
    run: ../tools/bcftools_concat.cwl
    in:
      input_vcfs: caveman_flag_somatic/flagged_vcf
      tool_name:
        valueFrom: ${return "caveman_somatic"}
      output_basename: output_basename
      input_normal_name: input_normal_name
      input_tumor_name: input_tumor_name
    out: [merged_vcf]

  bcftools_pass_somatic_vcf:
    run: ../tools/bcftools_pass.cwl
    in:
      merged_vcf: bcftools_merge_somatic_vcfs/merged_vcf
      tool_name:
        valueFrom: ${return "caveman_somatic"}
      output_basename: output_basename
    out: [passed_vcf]

  vep_annot_caveman:
    run: ../tools/vep_vcf2maf.cwl
    in:
      input_vcf: bcftools_pass_somatic_vcf/passed_vcf
      output_basename: output_basename
      tumor_id: input_tumor_name
      normal_id: input_normal_name
      tool_name:
        valueFrom: ${return "caveman_somatic"}
      reference: indexed_reference_fasta
      cache: vep_cache
    out: [output_vcf, output_tbi, output_maf, warn_txt]


$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: 'sbg:maxNumberOfParallelInstances'
    value: 4