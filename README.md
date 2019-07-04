# kfdrc_sanger_tools
Sanger tools ported over from https://github.com/genome and https://github.com/cancerit

##
Development project for Sanger tools CaVEMan and Pindel.

### CaVEMan
v1.13.15, snv caller (no indel), https://github.com/cancerit/CaVEMan
Followed instructions for simple repeats bed (https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6097605/) and centromeric repeats bed (https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6097606/) 

### Pindel
v0.2.5b9, indel and sv caller, docs here: http://gmt.genome.wustl.edu/packages/pindel/index.html, github here: https://github.com/genome/pindel

## CaVEMan Usage

### Inputs:
```yaml
  input_tumor_aligned: {type: File, doc: "tumor BAM or CRAM, also need approriate index file"}
  input_tumor_name: string
  input_normal_aligned: {type: File, doc: "normal BAM or CRAM, also need approriate index file"}
  input_normal_name: string
  output_basename: string
  reference_dict: File
  vep_cache: {type: File, label: tar gzipped cache from ensembl/local converted cache}
  threads: int
  indexed_reference_fasta: {type: File, secondaryFiles: [.fai]}
  blacklist: {type: File, doc: "Bed style, but 1-based coords"}
  genome_assembly: {type: string, doc: "Species assembly (eg 37/GRCh37)"}
  species: {type: string, doc: "Species name (eg Human)" }
  assay_type: {type: string, doc: "Type of assay called, options are WGS, WXS, AMPLICON, RNASEQ, TARGETED"}
  bed_refs_tar: {type: File, doc: "tar gzipped bed files with bed refs specified in flag_config"}
  samtools_ref_cache: {type: ['null', File], doc: "samtools ref cache for working with cram input"}
  flag_config: {type: File, doc: "Config file with param type, flag list, bedfiles"}
  flag_convert: {type: File, doc: "Flag description file"}
  split_size: {type: int, doc: "Number of pieces to split called vcf for flagging.  Recommend at least 64"}```
### Suggested inputs:
```text
  reference_dict: Homo_sapiens_assembly38.dict
  vep_cache: homo_sapiens_vep_93_GRCh38_convert_cache.tar.gz
  threads: 48
  indexed_reference_fasta: Homo_sapiens_assembly38.fasta
  blacklist: wgs_canonical_blacklist.hg38.tsv
  bed_refs_tar: caveman_hg38_bed_refs.merged.tar.gz
  samtools_ref_cache: samtools_hg38_ref_cache.tgz
  flag_config: caveman_flags_config.ini
  flag_convert: caveman_flag_convert.ini
```

### Outputs:
```yaml
outputs:
  caveman_somatic_prepass_vcf: {type: File, outputSource: rename_somatic_samples/reheadered_vcf}
  caveman_vep_vcf: {type: File, outputSource: vep_annot_caveman/output_vcf}
  caveman_vep_tbi: {type: File, outputSource: vep_annot_caveman/output_tbi}
  caveman_vep_maf: {type: File, outputSource: vep_annot_caveman/output_maf}
  caveman_germline_unfiltered_vcf: {type: File, outputSource: rename_germline_samples/reheadered_vcf}
```

## Pindel Usage

### Inputs:
```yaml
inputs:
  input_tumor_aligned: {type: File, secondaryFiles: [.crai]}
  input_tumor_name: string
  input_normal_aligned: {type: File, secondaryFiles: [.crai]}
  input_normal_name: string
  reference_fasta: {type: File, secondaryFiles: [.fai]}
  exome_flag: {type: string, doc: "Y if exome, N if not"}
  wgs_calling_bed: File
  genome_assembly: string
  output_basename: string
  insert_length: {type: int, doc: "Predicted size of sequene between sequencing adapters. For instance, if read len is 150, insert should at least be 300."}
  reference_dict: File
  vep_cache: {type: File, label: tar gzipped cache from ensembl/local converted cache}
```
### Suggested inputs:
```text
  reference_fasta: Homo_sapiens_assembly38.fasta
  wgs_calling_bed: wgs_canonical_calling_regions.hg38.bed
  reference_dict: Homo_sapiens_assembly38.dict
  vep_cache: homo_sapiens_vep_93_GRCh38_convert_cache.tar.gz
```

### Outputs:
```yaml
outputs:
  pindel_vep_vcf: {type: File, outputSource: vep_annot_pindel/output_vcf}
  pindel_vep_tbi: {type: File, outputSource: vep_annot_pindel/output_tbi}
  pindel_vep_maf: {type: File, outputSource: vep_annot_pindel/output_maf}
  unfiltered_results_vcf: {type: File, outputSource: gatk_merge_sort_unfiltered_vcfs/merged_vcf}
```