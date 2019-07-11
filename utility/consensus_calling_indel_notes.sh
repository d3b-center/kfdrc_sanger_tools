# merge and call indel

readonly EXECUTABLE_PATH=${USE_EXECUTABLE_PATH:-"/usr/local/bin"}
readonly MODEL_PATH=${USE_MODEL_PATH:-"/usr/local/models"}
mkdir ./TMP
readonly TMPDIR=${USE_TMPDIR:-"./TMP"}
readonly TAB=$'\t'

function add_header_and_sort {
    local file=$1
    local header=$2
    local grep_or_zgrep=grep
    if [[ $file == *.gz ]]
    then
        local grep_or_zgrep=zgrep
    fi

    ${grep_or_zgrep} "^##" "$file"
    if [[ ! -z "$header" ]] 
    then
        echo "$header"
    fi
    ${grep_or_zgrep} -v "^##" "$file" \
        | sort -k1,1 -k2,2n
}

readonly TAB=$'\t'

function cleanup {
    # normalize, and get rid of known broad and sanger weirdnesses
    local file=$1
    vt decompose -s "$file" \
        | vt normalize -r "$REFERENCE" - \
        | sed -e "s/${TAB}${TAB}${TAB}$/${TAB}.${TAB}.${TAB}./" \
        | grep -v '=$' 
}

function make_cleaned {
    local file=$1
    local outfile=$2
    if [[ -f "$file" ]] 
    then
        cleanup "${file}" \
            | bgzip > "${outfile}"
        tabix -p vcf "${outfile}"
    fi
}



mutect2file=876e5a01-ffd2-47b4-af93-3d3b2428e613.mutect2.PASS.indel_only.pcawg_annotated.vcf.gz
strelka2file=e233671d-f3fe-4ca6-9f9f-5a0a08ac1199.strelka2.PASS.indel_only.pcawg_annotated.vcf.gz
lancetfile=ea28dfe5-4f39-48ce-a8ea-7c49e7b6f69d.lancet.PASS.indel_only.pcawg_annotated.vcf.gz
vardictfile=a0b04089-dded-42c6-a040-8eed96ac5b3a.vardict.PASS.indel_only.pcawg_annotated.vcf.gz
pindelfile=ea28dfe5-4f39-48ce-a8ea-7c49e7b6f69d.lancet.PASS.indel_only.pcawg_annotated.vcf.gz

sample=DO11441
outfile=$sample\_consensus.indel.vcf

REFERENCE=${USE_REFERENCE:-"/dbs/reference/genome.fa.gz"}
MERGEDFILE=${TMPDIR}/$sample\_merged.vcf
MERGEDSORTEDFILE=${TMPDIR}/$sample\_merged.sorted.vcf

for caller in "mutect2" "strelka2" "lancet" "vardict" "pindel"
do
    declare oldfilename=${caller}file
    declare newfilename=cleaned_${caller}file
    declare $newfilename=${TMPDIR}/${caller}.indel.vcf.gz
    make_cleaned "${!oldfilename}" "${!newfilename}"
done

mergevcf -l mutect2,strelka2,lancet,vardict,pindel \
        $cleaned_mutect2file \
        $cleaned_strelka2file \
        $cleaned_lancetfile \
        $cleaned_vardictfile \
        $cleaned_pindelfile \
        --ncallers \
> "${MERGEDFILE}"

add_header_and_sort "${MERGEDFILE}" \
    | grep -v "Callers=broad;" \
    | bgzip > "${MERGEDSORTEDFILE}.gz"
tabix -p vcf "${MERGEDSORTEDFILE}.gz"
rm -f "${MERGEDFILE}"

TEMPLATE="${TMPDIR}/vaf.annotate.single.conf"

cat > "${TEMPLATE}" << EOF
[[annotation]]
file="@@FILE@@"
fields = ["TumorVAF", "NormalVAF", "TumorVarDepth", "TumorTotalDepth", "NormalVarDepth", "NormalTotalDepth", "RepeatRefCount"]
names = ["TumorVAF", "NormalVAF", "TumorVarDepth", "TumorTotalDepth", "NormalVarDepth", "NormalTotalDepth", "RepeatRefCount"]
ops = ["self", "self", "self", "self", "self", "self", "self"]
EOF

readonly ANNOTATION_CONF="${TMPDIR}/vaf.indel.$$.conf"
rm -f "${ANNOTATION_CONF}"

for input_file in $cleaned_mutect2file $cleaned_lancet $cleaned_vardictfile $cleaned_pindelfile
do
    if [[ -f "$input_file" ]]
    then
        sed -e "s#@@FILE@@#$input_file#" "${TEMPLATE}" >> "${ANNOTATION_CONF}"
        echo " " >> "${ANNOTATION_CONF}"
    fi
done

rm -f "${TEMPLATE}"

vcfanno -p 1 "${ANNOTATION_CONF}" "${MERGEDSORTEDFILE}.gz" \
    | sed -e 's/\tFORMAT.*$//' \
    | sed -e 's/^##INFO=<ID=TumorVAF,.*$/##INFO=<ID=TumorVAF,Number=1,Type=Float,Description="VAF of variant in tumor from sga">/' \
    | sed -e 's/^##INFO=<ID=TumorVarDepth,.*$/##INFO=<ID=TumorVarDepth,Number=1,Type=Integer,Description="Tumor alt count from sga">/' \
    | sed -e 's/^##INFO=<ID=TumorTotalDepth,.*$/##INFO=<ID=TumorTotalDepth,Number=1,Type=Integer,Description="Tumor total read depth from sga">/' \
    | sed -e 's/^##INFO=<ID=NormalVAF,.*$/##INFO=<ID=NormalVAF,Number=1,Type=Float,Description="VAF of variant in normal from sga">/' \
    | sed -e 's/^##INFO=<ID=NormalVarDepth,.*$/##INFO=<ID=NormalVarDepth,Number=1,Type=Integer,Description="Normal alt count from sga">/' \
    | sed -e 's/^##INFO=<ID=NormalTotalDepth,.*$/##INFO=<ID=NormalTotalDepth,Number=1,Type=Integer,Description="Normal total read depth from sga">/' \
    > "${outfile}"
bgzip -f "${outfile}"
tabix -p vcf "${outfile}.gz"

## lines below are tool-specific.  don't work for our callers, stop with results above

# readonly MERGED="${TMPDIR}/merged.vaf.$$.indel.vcf"
# readonly ANNOTATED="${TMPDIR}/annotated.indel.$$.vcf"

# dbsnp_args=("${MERGED}.gz" "indel" "${ANNOTATED}")
# "${EXECUTABLE_PATH}"/dbsnp_annotate_one.sh  "${dbsnp_args[@]}"

# MODELFILE="${MODEL_PATH}/stacked-logistic-all-four.RData"
# readonly INTERMEDIATE="${TMPDIR}/intermediate.indel.$$.vcf"
# readonly MODEL_THRESHOLD=0.71
# "${EXECUTABLE_PATH}"/apply_model.sh "${MODELFILE}" "${ANNOTATED}.gz" "${INTERMEDIATE}" "${outfile}" "$MODEL_THRESHOLD" 
