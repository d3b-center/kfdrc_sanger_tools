cwlVersion: v1.0
class: CommandLineTool
id: caveman_step
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'migbro/caveman:1.13.15'
  - class: ResourceRequirement
    ramMin: 144000
    coresMin: 36
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing: |
      ${
        var listing = []
        listing.push(inputs.config_file);
        listing.push(inputs.alg_bean);
        return listing;
      }


baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -euxo pipefail

      SWV=1.13.15

      cp $(inputs.splitList.path) splitList

      SLEN=`wc -l splitList | cut -f 1 -d " "` 
      
      cat caveman.cfg.ini | sed -E "s@CWD.*@CWD=$PWD@" | sed -E "s@ALG_FILE.*@ALG_FILE=$PWD/alg_bean@" > temp && mv temp caveman.cfg.ini

      for chrom in `seq 1 $SLEN`; do
        echo "/CaVEMan-$SWV/bin/caveman mstep -f $(inputs.config_file.path) -i $chrom || exit 1" >> mstep_cmd_list.txt;
      done
      
      cat mstep_cmd_list.txt | xargs -ICMD -P $(inputs.threads) sh -c "CMD"

      /CaVEMan-$SWV/bin/caveman merge -f $(inputs.config_file.path)
      
      for chrom in `seq 1 $SLEN`; do
        echo "/CaVEMan-$SWV/bin/caveman estep -f $(inputs.config_file.path) -i $chrom -k 0.1 -n 2 -t 5 --species $(inputs.species) --species-assembly $(inputs.genome_assembly) || exit 1" >> estep_cmd_list.txt;
      done

      cat estep_cmd_list.txt | xargs -ICMD -P $(inputs.threads) sh -c "CMD"

      find results -name '*.gz' | xargs -IGZ -P $(inputs.threads) gzip -d GZ &&
      find results -name '*.vcf' | xargs -IVCF -P $(inputs.threads) bgzip VCF &&
      find results -name '*.gz' | xargs -IGZ -P $(inputs.threads) tabix GZ &&
      find results -name '*.gz*' | xargs -IGZ mv GZ ./

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
  threads: int
  indexed_reference_fasta: {type: File, secondaryFiles: ['.fai']}
  config_file: File
  alg_bean: File
  blacklist: {type: File, doc: "Bed style, but 1-based coords"}
  splitList: File
  genome_assembly: {type: string, doc: "Species assembly (eg 37/GRCh37)"}
  species: {type: string, doc: "Species name (eg Human)" }

outputs:
  snps_vcf:
    type: File[]
    outputBinding:
      glob: '*.snps.vcf.gz'
    secondaryFiles: ['.tbi']
  muts_vcf:
    type: File[]
    outputBinding:
      glob: '*.muts.vcf.gz'
    secondaryFiles: ['.tbi']
