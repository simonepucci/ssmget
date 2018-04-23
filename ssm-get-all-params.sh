#!/bin/bash
#
#
# Required tools:
#   JSON.sh aws-cli awk coreutils grep sed
#
# Read aws ssm parameters and print them on std output, starting from the supplied ssm /PATH
# 
[ $# -eq 1 ] && PARAMPATH="$1" || PARAMPATH="/";

TMPDIR="/tmp/Ec2ssm";
EC2SSM="${TMPDIR}/ec2-ssm.tmp";
EC2SSMIDX="${TMPDIR}/ec2-ssm-idx.tmp";
mkdir -p ${TMPDIR};

[ -f "${EC2SSM}" ] && rm -f ${EC2SSM};


aws ssm get-parameters-by-path --path ${PARAMPATH} --recursive | JSON.sh -b > ${EC2SSM}
cat ${EC2SSM} | awk '{print $1}' | cut -f '2' -d ',' | grep -o '[0-9]*' | sort -n | uniq > ${EC2SSMIDX};

cat ${EC2SSMIDX} | while read line;
do
    #Extract interesting stuff
    # ["Parameters",0,"Name"]
    NAMEKEYNUM=$(egrep "\[\"Parameters\"\,$line\,\"Name\"" ${EC2SSM} |tr -s '[:blank:]' ' '| cut -f '2' -d ' ' | sed 's/"//g')
    NAMEKEYVAL=$(egrep "\[\"Parameters\"\,$line\,\"Value\"" ${EC2SSM}|tr -s '[:blank:]' ' '| cut -f '2' -d ' ');# | sed 's/"//g')
    #echo ${NAMEKEYNUM}
    VARCUR=$(basename ${NAMEKEYNUM});
    VARCONT=${NAMEKEYVAL};
    #VARCONT=$(aws ssm get-parameter --name ${PARAMPATH}/${VARCUR} --query Parameter.Value);
    echo export $VARCUR=$VARCONT
done
