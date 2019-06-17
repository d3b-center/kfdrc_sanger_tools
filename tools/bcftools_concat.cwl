cwlVersion: v1.0
class: CommandLineTool
id: bcftools_concat
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'kfdrc/bvcftools'
  - class: ResourceRequirement
    ramMin: 4000
    coresMin: 2
  - class: InlineJavascriptRequirement

baseCommand: []
arguments:
  - position: 0
    shellQuote: false
    valueFrom: >-
      ${
        var flist_cmd "";
        for (var i=0; i<inputs.input_vcfs.length; i++){
          if (inputs.input_vcfs.gz == "gz"){
            flist_cmd += "gunzip -c " + inputs.input_vcfs[0].path + " > " + inputs.input_vcfs[0].basename + ";echo " + inputs.input_vcfs[0].basename + " >> all_vcfs.txt;"
          }
          else{
            flist_cmd += "echo " + inputs.input_vcfs[0].path + " >> all_vcfs.txt;";
          }
        }
        return flist_cmd;
      }

      cat all_vcfs.txt | xargs -IFN grep -E "^chr" -m 1 FN /dev/null | cut -f 1 -d ":" > non_empty_vcfs.txt

      bcftools concat
      -a
      -f non_empty_vcfs.txt
      -o $(inputs.output_basename).concat.vcf.gz
      -O z

      echo $(inputs.input_normal_name) > sample_list.txt &&
      echo $(inputs.input_tumor_name) >> sample_list.txt &&
      bcftools reheader -s sample_list.txt $(inputs.output_basename).concat.vcf.gz > $(inputs.output_basename).$(inputs.tool_name).PREPASS.vcf.gz &&
      tabix $(inputs.output_basename).$(inputs.tool_name).PREPASS.vcf.gz

inputs:
  input_vcfs:
    type: File[]
    secondaryFiles: [.tbi]
  tool_name: string
  output_basename: string
  input_normal_name: string
  input_tumor_name: string

outputs:
  merged_vcf:
    type: File
    outputBinding:
      glob: '*.PREPASS.vcf.gz'
    secondaryFiles: ['.tbi']