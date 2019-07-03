cwlVersion: v1.0
class: CommandLineTool
id: caveman_flag
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'kfdrc/sanger_suite:latest'
  - class: ResourceRequirement
    ramMin: 2000
    coresMin: 1
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

      TBAM=$(inputs.input_tumor_aligned.path)

      NBAM=$(inputs.input_normal_aligned.path)

      ${
        var cmd = "tar -xzf " + inputs.bed_refs_tar.path + ";"
        if(inputs.samtools_ref_cache != null){
          cmd += "tar -xzf " + inputs.samtools_ref_cache.path + ";"
        }
        if (inputs.input_tumor_aligned.nameext == ".bam"){
          cmd += "TBAM=" + inputs.input_tumor_aligned.basename + "; NBAM=" + inputs.input_normal_aligned.basename + ";";
          cmd += "ln -s " + inputs.input_tumor_aligned.path + " .; ln -s " + inputs.input_tumor_aligned.secondaryFiles[0].path + " ./" + inputs.input_tumor_aligned.basename + ".bai;";
          cmd += "ln -s " + inputs.input_normal_aligned.path + " .; ln -s " + inputs.input_normal_aligned.secondaryFiles[0].path + " ./" + inputs.input_normal_aligned.basename + ".bai;";
        }
        return cmd;
      }

      OUT=$(inputs.called_vcf.nameroot).flagged.vcf

      /cgpCaVEManPostProcessing-1.8.8/bin/cgpFlagCaVEMan.pl
      -i $(inputs.called_vcf.path)
      -o $OUT
      -s $(inputs.species)
      -c $(inputs.flag_config.path)
      -v $(inputs.flag_convert.path)
      -t $(inputs.assay_type)
      -n $NBAM
      -m $TBAM
      --reference $(inputs.indexed_reference_fasta.path).fai
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
  samtools_ref_cache: {type: ['null', File], doc: "samtools ref cache for working with cram input"}

outputs:
  flagged_vcf:
    type: File
    outputBinding:
      glob: '*.flagged.vcf.gz'
    secondaryFiles: ['.tbi']

