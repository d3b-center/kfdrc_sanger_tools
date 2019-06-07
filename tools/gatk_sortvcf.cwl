cwlVersion: v1.0
class: CommandLineTool
id: gatk4_mergevcfs
label: GATK Merge VCF
doc: "Merge input vcfs"
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
        var gatk_cmd = "/gatk SortVcf --java-options \"-Xmx6g\" --SEQUENCE_DICTIONARY " + inputs.reference_dict.path;
        var set_len = inputs.input_vcfs.length;
        for (var i = 0; i< set_len; i++){
          run_cmd += gatk_cmd;
          var vcf_len = inputs.input_vcfs[i];
          for (var j = 0; j < vcf_len; j++){
            run_cmd += " -I " + inputs.input_vcfs[i][j].path;
          }
          run_cmd += " -O " + inputs.output_basename + ".set" + i.toString() + ".merge.vcf.gz;";
        }
        run_cmd += gatk_cmd;
        for (i = 0; i< set_len; i++){
          run_cmd += " -I " + + inputs.output_basename + ".set" + i.toString() + ".merge.vcf.gz";
        }
        run_cmd += " -O " + inputs.input_vcfs.output_basename + "." + inputs.tool_name + ".merged.vcf.gz;";
        return run_cmd;
      }
inputs:
  input_vcfs:
    type:
      type: array
      items:
        type: array
        items: File
    secondaryFiles: [.tbi]
  reference_dict: File
  tool_name: string
  output_basename: string
outputs:
  merged_vcf:
    type: File
    outputBinding:
      glob: '*.merged.vcf.gz'
    secondaryFiles: [.tbi]
