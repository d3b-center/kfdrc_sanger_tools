cwlVersion: v1.0
class: Workflow
id: kfdrc_pindel_benchmark_wf
requirements:
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  input_tumor_aligned: {type: File, secondaryFiles: [^.bai]}
  input_tumor_name: string
  input_normal_aligned: {type: File, secondaryFiles: [^.bai]}
  input_normal_name: string
  reference_fasta: {type: File, secondaryFiles: [.fai]}
  exome_flag: {type: string, doc: "Y if exome, N if not"}
  wgs_calling_bed: File
  genome_assembly: string
  output_basename: string
  insert_length: {type: int, doc: "Predicted size of sequene between sequencing adapters. For instance, if read len is 150, insert should at least be 300."}
  reference_dict: File

outputs:
  pindel_filtered_vcf: {type: File, outputSource: gatk_merge_sort_filtered_vcfs/merged_vcf}
  unfiltered_results_vcf: {type: File, outputSource: gatk_merge_sort_unfiltered_vcfs/merged_vcf}

steps:

  gatk_intervallisttools:
    run: ../../tools/gatk_intervallisttool.cwl
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
    run: ../../tools/pindel.cwl
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
    scatter: wgs_calling_bed
    out: [filtered_indel_vcf, unfiltered_results_vcf, pindel_config, somatic_filter_config, sid_file]

  ubuntu_filter_empty_vcf:
    run: ../../tools/ubuntu_filter_empty_vcf.cwl
    in:
      input_vcfs: pindel_run/filtered_indel_vcf
    out: [non_empty_vcfs]

  gatk_merge_sort_unfiltered_vcfs:
    run: ../../tools/gatk_sortvcf.cwl
    in:
      input_vcfs: pindel_run/unfiltered_results_vcf
      output_basename: output_basename
      reference_dict: reference_dict
      tool_name:
        valueFrom: ${return "pindel_unfiltered"}
    out: [merged_vcf]

  gatk_merge_sort_filtered_vcfs:
    run: ../../tools/gatk_sortvcf.cwl
    in:
      input_vcfs: ubuntu_filter_empty_vcf/non_empty_vcfs
      output_basename: output_basename
      reference_dict: reference_dict
      tool_name:
        valueFrom: ${return "pindel_filtered"}
    out: [merged_vcf]

$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: 'sbg:maxNumberOfParallelInstances'
    value: 4