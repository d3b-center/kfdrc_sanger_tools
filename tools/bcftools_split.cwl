cwlVersion: v1.0
class: CommandLineTool
id: bcftools_split
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'kfdrc/bvcftools'
  - class: ResourceRequirement
    ramMin: 4000
    coresMin: 2
  - class: InlineJavascriptRequirement

baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -euxo pipefail

      zcat $(inputs.input_vcf.path) | grep -E "^#" > header.txt

      zcat $(inputs.input_vcf.path) | grep -Ev "^#" > body.vcf

      cat header.txt > $(inputs.input_vcf.nameroot).hi_depth.vcf

      cat body.vcf | cut -f 8 | cut -f 1 -d ";" | perl -e 'while(<>){chomp $_; @a = split /=/, $_;$t += $a[1];$f +=1;}print ($t/$f)."\n";' > avg.txt

      perl -e 'open(AVG, "<", "avg.txt"); $avg = <AVG>; chomp $avg; $cutoff=($avg + (sqrt($avg) * 4)); print STDERR "Hi depth cutfoff is $cutoff\n"; open(VCF, "<", "body.vcf"); open(HI, ">>", "$(inputs.input_vcf.nameroot).hi_depth.vcf"); while(<VCF>){@line = split /\t/, $_; @info = split /;/, $line[7]; @dp_info = split /=/, $info[0]; if($dp_info[1] <= $cutoff){print $_;} else{print HI $_;}} close HI;' > depth_passed.vcf

      split -n l/$(inputs.split_size) depth_passed.vcf

      ls x* | xargs -IFN sh -c "cat header.txt FN > FN.split.vcf; bgzip FN.split.vcf; tabix FN.split.vcf.gz"

      bgzip $(inputs.input_vcf.nameroot).hi_depth.vcf;

      tabix $(inputs.input_vcf.nameroot).hi_depth.vcf.gz;

inputs:
  input_vcf: {type: File, secondaryFiles: [.tbi]}
  split_size: {type: int, doc: "At least 64"}
outputs:
  split_vcfs:
    type: File[]
    outputBinding:
      glob: '*.split.vcf.gz'
    secondaryFiles: ['.tbi']
  hi_depth_vcf:
    type: File
    outputBinding:
      glob: $(inputs.input_vcf.nameroot).hi_depth.vcf.gz
    secondaryFiles: ['.tbi']
