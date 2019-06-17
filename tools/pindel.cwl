cwlVersion: v1.0
class: CommandLineTool
id: pindel_run
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'migbro/sanger_suite:latest'
  - class: ResourceRequirement
    ramMin: 8000
    coresMin: 4
  - class: InlineJavascriptRequirement

baseCommand: []
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      echo "$(inputs.input_tumor_aligned.path)\t$(inputs.insert_length)\t$(inputs.input_tumor_name)\n$(inputs.input_normal_aligned.path)\t$(inputs.insert_length)\t$(inputs.input_normal_name)" > pindel_config.tsv
      
      export PINDEL_DIR="/pindel-0.2.5b9"
      
      export DATE=`date +"%Y%m%d"`

      $PINDEL_DIR/pindel -f $(inputs.reference_fasta.path) -i pindel_config.tsv  -o $(inputs.output_basename).$(inputs.tool_name) -T 4 -j $(inputs.wgs_calling_bed.path) -w 1 1>&2
      
      grep ChrID $(inputs.output_basename).$(inputs.tool_name)_SI > all.head
      
      grep ChrID $(inputs.output_basename).$(inputs.tool_name)_D >> all.head
      
      head -n 4 $PINDEL_DIR/somatic_filter/somatic.indel.filter.config > somatic.indel.filter.config
      
      echo "indel.filter.pindel2vcf = $PINDEL_DIR/pindel2vcf" >> somatic.indel.filter.config
      
      echo "indel.filter.reference =  $(inputs.reference_fasta.path)" >> somatic.indel.filter.config
      
      echo "indel.filter.referencename = $(inputs.genome_assembly)" >> somatic.indel.filter.config
      
      echo "indel.filter.referencedate = $DATE" >> somatic.indel.filter.config

      echo "indel.filter.output = $(inputs.output_basename).$(inputs.tool_name).PASS.vcf" >> somatic.indel.filter.config

      perl $PINDEL_DIR/somatic_filter/somatic_indelfilter.pl somatic.indel.filter.config 1>&2

      bgzip $(inputs.output_basename).$(inputs.tool_name).filtered_indel.vcf

      tabix $(inputs.output_basename).$(inputs.tool_name).filtered_indel.vcf.gz

      $PINDEL_DIR/pindel2vcf -P $(inputs.output_basename).$(inputs.tool_name) -r $(inputs.reference_fasta.path) -R $(inputs.genome_assembly) -d $DATE -v $(inputs.output_basename).$(inputs.tool_name).unfiltered.results.vcf 1>&2

      bgzip $(inputs.output_basename).$(inputs.tool_name).unfiltered.results.vcf

      tabix $(inputs.output_basename).$(inputs.tool_name).unfiltered.results.vcf.gz
inputs:
  input_tumor_aligned: {type: File, secondaryFiles: [^.bai]}
  input_tumor_name: string
  input_normal_aligned: {type: File, secondaryFiles: [^.bai]}
  input_normal_name: string
  reference_fasta: {type: File, secondaryFiles: [.fai]}
  wgs_calling_bed: File
  genome_assembly: string
  output_basename: string
  tool_name: string
  insert_length: {type: int, doc: "Predicted size of sequene between sequencing adapters. For instance, if read len is 150, insert should at least be 300."}
outputs:
  filtered_indel_vcf:
    type: File
    outputBinding:
      glob: '*.pindel.PASS.vcf'
    secondaryFiles: [.tbi]
  unfiltered_results_vcf:
    type: File
    outputBinding:
      glob: '*.unfiltered.results.vcf.gz'
    secondaryFiles: [.tbi]
  pindel_config:
    type: File
    outputBinding:
      glob: 'pindel_config.tsv'
  somatic_filter_config:
    type: File
    outputBinding:
      glob: 'somatic.indel.filter.config'
  sid_file:
    type: File
    outputBinding:
      glob: "all.head"
  
