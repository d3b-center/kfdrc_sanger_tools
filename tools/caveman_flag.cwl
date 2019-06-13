cwlVersion: v1.0
class: CommandLineTool
id: caveman_step
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'migbro/sanger_suite:latest'
  - class: ResourceRequirement
    ramMin: 4000
    coresMin: 2
  - class: InlineJavascriptRequirement
  - class: EnvVarRequirement
    envDef:
      "REF_CACHE": "./REF_CACHE/hts-ref/%2s/%2s/%s"

baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -euxo pipefail

      tar -xzf $(inputs.bed_refs_tar.path)

      tar -xzf $(inputs.samtools_ref_cache.path)

      OUT=$(inputs.called_vcf.nameroot).flagged.vcf

      /cgpCaVEManPostProcessing-1.8.8/bin/cgpFlagCaVEMan.pl
      -i $(inputs.called_vcf.path)
      -o $OUT
      -s $(inputs.species)
      -c $(inputs.flag_config.path)
      -v $(inputs.flag_convert.path)
      -t $(inputs.assay_type)
      -n $(inputs.input_normal_aligned.path)
      -m $(inputs.input_tumor_aligned.path)
      --reference $(inputs.indexed_reference_fasta.basename).fai
      -b $PWD/BED_REFS

      bgzip $OUT && tabix $OUT.gz

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
  indexed_reference_fasta: {type: File, secondaryFiles: ['.fai']}
  flag_config: {type: File, doc: "Config file with param type, flag list, bedfiles"}
  flag_convert: {type: File, doc: "Flag description file"}
  called_vcf: File
  species: {type: string, doc: "Species of calls, i.e. human"}
  assay_type: {type: string, doc: "Type of assay called, options are WGS, WXS, AMPLICON, RNASEQ, TARGETED"}
  bed_refs_tar: {type: File, doc: "tar gzipped bed files with bed refs specified in flag_config"}
  samtools_ref_cache: {type: File, doc: "samtools ref cache for working with cram input"}

outputs:
  flagged_vcf:
    type: File
    outputBinding:
      glob: '*.flagged.vcf.gz'
    secondaryFiles: ['.tbi']

