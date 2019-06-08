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
  # input_tumor_name: string
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
  # input_normal_name: string
  output_basename: string
  reference_dict: File
  # vep_cache: {type: File, label: tar gzipped cache from ensembl/local converted cache}
  threads: int
  indexed_reference_fasta: {type: File, secondaryFiles: [.fai]}
  blacklist: {type: File, doc: "Bed style, but 1-based coords"}
  genome_assembly: {type: string, doc: "Species assembly (eg 37/GRCh37)"}
  species: {type: string, doc: "Species name (eg Human)" }

outputs:
  caveman_snps_vcf: {type: File, outputSource: sort_merge_caveman_snps_vcf/merged_vcf}
  caveman_muts_vcf: {type: File, outputSource: sort_merge_caveman_muts_vcf/merged_vcf}
  caveman_snps_skipped: {type: File, outputSource: sort_merge_caveman_snps_vcf/merged_vcf}
  caveman_muts_skipped: {type: File, outputSource: sort_merge_caveman_muts_vcf/merged_vcf}

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
        value: m4.10xlarge;ebs-gp2;500
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

  sort_merge_caveman_snps_vcf:
    run: ../tools/gatk_sortvcf.cwl
    label: GATK Sort & Merge snps
    in:
      input_vcfs: caveman_step/snps_vcf
      output_basename: output_basename
      reference_dict: reference_dict
      tool_name:
        valueFrom: ${return "caveman_snps"}
    out: [merged_vcf,skipped_vcf]

  sort_merge_caveman_muts_vcf:
    run: ../tools/gatk_sortvcf.cwl
    label: GATK Sort & Merge muts
    in:
      input_vcfs: caveman_step/muts_vcf
      output_basename: output_basename
      reference_dict: reference_dict
      tool_name:
        valueFrom: ${return "caveman_muts"}
    out: [merged_vcf, skipped_vcf]

$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: 'sbg:maxNumberOfParallelInstances'
    value: 4