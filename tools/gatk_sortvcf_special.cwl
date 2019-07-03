cwlVersion: v1.0
class: CommandLineTool
id: gatk4_mergevcfs_special
doc: "Merge input vcfs and hi depth vcf"
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: DockerRequirement
    dockerPull: 'kfdrc/gatk:4.1.1.0'
  - class: ResourceRequirement
    ramMin: 6000
    coresMin: 4
baseCommand: []
arguments:
  - position: 0
    shellQuote: false
    valueFrom: >-
      ${
        var run_cmd = "";
        var gatk_cmd = "/gatk SortVcf --java-options \"-Xmx6g\" -O " + inputs.output_basename + "." + inputs.tool_name + ".merged.vcf.gz --SEQUENCE_DICTIONARY " + inputs.reference_dict.path;
        var flen = inputs.input_vcfs.length;
        var cat_cmd = "cat "
        if (inputs.input_vcfs[0].nameext == ".gz"){
          cat_cmd = "zcat "
        }
        for (var i=0; i<flen; i++){
          run_cmd += cat_cmd + inputs.input_vcfs[i].path + " | perl -e 'while(<>){@a = split /\t/, $_; if(substr($_,0,1) eq \"#\"){print $_;} else{if ($a[3] eq $a[4]){print STDERR $_;} else{print $_;}}}' > temp" + i.toString() + ".vcf 2>> " + inputs.output_basename + "." + inputs.tool_name + ".skipped.vcf;";
          gatk_cmd += " -I temp" + i.toString() + ".vcf";
        }

        run_cmd += cat_cmd + inputs.input_vcfs[0].path + " | grep -E '^#' > temp_added.vcf;";
        run_cmd += cat_cmd + inputs.added_vcf.path + " | grep -Ev '^#' | perl -e 'while(<>){@a = split /\t/, $_; if(substr($_,0,1) eq \"#\"){print $_;} else{if ($a[3] eq $a[4]){print STDERR $_;} else{print $_;}}}' >> temp_added.vcf 2>> " + inputs.output_basename + "." + inputs.tool_name + ".skipped.vcf;";
        gatk_cmd += " -I temp_added.vcf";
        
        run_cmd += gatk_cmd;
        return run_cmd;
      }

inputs:
  input_vcfs: File[]
  added_vcf: File
  reference_dict: File
  tool_name: string
  output_basename: string
outputs:
  merged_vcf:
    type: File
    outputBinding:
      glob: '*.merged.vcf.gz'
    secondaryFiles: [.tbi]
  skipped_vcf:
    type: File
    outputBinding:
      glob: '*.skipped.vcf'
