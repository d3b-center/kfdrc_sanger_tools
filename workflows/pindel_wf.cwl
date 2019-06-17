cwlVersion: v1.0
class: Workflow
id: pindel_wf
requirements:
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  input_tumor_aligned: {type: File, secondaryFiles: [^.bai]}
  input_tumor_name: string
  input_normal_aligned: {type: File, secondaryFiles: [^.bai]}
  input_normal_name: string
  reference_fasta: {type: File, secondaryFiles: [.fai]}
  exome_flag: string
  wgs_calling_bed: File
  genome_assembly: string
  output_basename: string
  insert_length: {type: int, doc: "Predicted size of sequene between sequencing adapters. For instance, if read len is 150, insert should at least be 300."}
  reference_dict: File
  # vep_cache: {type: File, label: tar gzipped cache from ensembl/local converted cache}
  # threads: int

outputs:
  filtered_indel_vcf: {type: File, outputSource: bctools_sort_filtered_vcfs/sorted_vcf}
  unfiltered_results_vcf: {type: File, outputSource: bctools_sort_unfiltered_vcfs/sorted_vcf}

steps:
  gatk_intervallisttools:
    run: ../tools/gatk_intervallisttool.cwl
    in:
      interval_list: wgs_calling_bed
      reference_dict: reference_dict
      exome_flag: exome_flag
      scatter_ct:
        valueFrom: ${return 50}
      bands:
        valueFrom: ${return 80000000}
    out: [output]

  pindel_run:
    hints:
      - class: 'sbg:AWSInstanceType'
        value: c5.9xlarge;ebs-gp2;500
    run: ../tools/pindel.cwl
    in:
      input_tumor_aligned: input_tumor_aligned
      input_tumor_name: input_tumor_name
      input_normal_aligned: input_normal_aligned
      input_normal_name: input_normal_name
      reference_fasta: reference_fasta
      wgs_calling_bed: gatk_intervallisttools/output
      genome_assembly: genome_assembly
      output_basename: output_basename
      tool_name: 
        valueFrom: ${return "pindel"}
      insert_length: insert_length
      reference_dict: reference_dict
    scatter: wgs_calling_bed
    out: [filtered_indel_vcf, unfiltered_results_vcf, pindel_config, somatic_filter_config, sid_file]

  bcftools_merge_unfiltered_vcfs:
    run: ../tools/bcftools_concat.cwl
    in:
      input_vcfs: pindel_run/unfiltered_results_vcf
      tool_name:
        valueFrom: ${return "pindel_unfiltered"}
      output_basename: output_basename
      input_normal_name: input_normal_name
      input_tumor_name: input_tumor_name
    out: [merged_vcf]

  bcftools_merge_filtered_vcfs:
    run: ../tools/bcftools_concat.cwl
    in:
      input_vcfs: pindel_run/filtered_indel_vcf
      tool_name:
        valueFrom: ${return "pindel_filtered"}
      output_basename: output_basename
      input_normal_name: input_normal_name
      input_tumor_name: input_tumor_name
    out: [merged_vcf]

  bctools_sort_unfiltered_vcfs:
    run: ../tools/bcftools_sort.cwl
    in:
      unsorted_vcf: bcftools_merge_unfiltered_vcfs/merged_vcf
    scatter: unsorted_vcf
    out: [sorted_vcf]

  bctools_sort_filtered_vcfs:
    run: ../tools/bcftools_sort.cwl
    in:
      unsorted_vcf: bcftools_merge_filtered_vcfs/merged_vcf
    out: [sorted_vcf]

$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: 'sbg:maxNumberOfParallelInstances'
    value: 4