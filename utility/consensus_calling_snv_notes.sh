# merge snv

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
        echo $header
    fi
    ${grep_or_zgrep} -v "^##" "$file" \
        | sort -k1,1 -k2,2n
}

function cleanup {
    local file=$1
    add_header_and_sort "$file" \
        | grep -v '=$' \
        | sed -e 's/Tier[0-9]/PASS/' 
}

mutect2=876e5a01-ffd2-47b4-af93-3d3b2428e613.mutect2.PASS.snv_only.pcawg_annotated.vcf.gz
strelka2=e233671d-f3fe-4ca6-9f9f-5a0a08ac1199.strelka2.PASS.snv_only.pcawg_annotated.vcf.gz
lancet=ea28dfe5-4f39-48ce-a8ea-7c49e7b6f69d.lancet.PASS.snv_only.pcawg_annotated.vcf.gz
vardict=a0b04089-dded-42c6-a040-8eed96ac5b3a.vardict.PASS.snv_only.pcawg_annotated.vcf.gz
caveman=8b3a96c3-4265-4886-8afa-819aed6d2f0a.caveman_somatic.PASSED.pcawg_annotated.vcf.gz
sample=DO11441
MERGEDFILE=$sample\_merged.vcf
outfile=$sample\_merged.oxog.vcf
mergevcf -l mutect2,strelka2,lancet,vardict,caveman \
        <( cleanup "${mutect2}" ) \
        <( cleanup "${strelka2}" ) \
        <( cleanup "${lancet}" ) \
        <( cleanup "${vardict}" ) \
        <( cleanup "${caveman}" ) \
        --ncallers --mincallers 2 \
> $sample\_merged.vcf

OXOGCONF=/tmp/oxog.conf
touch ${OXOGCONF}
for file in "${mutect2}" "${strelka2}" "${lancet}" "${vardict}" "${caveman}"
do
    cat >> ${OXOGCONF} <<EOF
[[annotation]]
file = "$file"
fields = ["OXOG_Fail"]
names = ["OXOG_Fail"]
ops = ["self"]


EOF
done

vcfanno -p 1 ${OXOGCONF} ${MERGEDFILE}.gz 2> /dev/null \
    > ${outfile} 
bgzip -f ${outfile}
tabix -p vcf ${outfile}.gz

