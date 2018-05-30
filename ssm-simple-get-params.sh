#!/bin/bash
#
#
# Required tools:
#   JSON.sh aws-cli awk coreutils grep sed
#
# Read aws ssm parameters and print them on std output, starting from the supplied ssm /PATH
# 
[ $# -eq 1 ] && PARAMPATH="$1" || unset PARAMPATH;
REGION="eu-west-1";

[ -d /dev/shm ] && TMPCACHEFOLD="/dev/shm" || TMPCACHEFOLD="/tmp";
TMPDIR="${TMPCACHEFOLD}/Ec2ssm";
EC2SSM="${TMPDIR}/ec2-ssm.tmp";
EC2SSMIDX="${TMPDIR}/ec2-ssm-idx.tmp";
mkdir -p ${TMPDIR};

PARAMPATH=${PARAMPATH:-/};

#aws ssm get-parameters-by-path --max-items 100 --path ${PARAMPATH} --recursive --region ${REGION} | JSON.sh -b > ${EC2SSM};
aws ssm get-parameters --names ${PARAMPATH} --region ${REGION} | JSON.sh -b > ${EC2SSM}; 
cat ${EC2SSM} | awk '{print $1}' | cut -f '2' -d ',' | grep -o '[0-9]*' | sort -n | uniq > ${EC2SSMIDX};

cat ${EC2SSMIDX} | while read line;
do
    #Extract interesting stuff
    # ["Parameters",0,"Name"]
    NAMEKEYNUM=$(grep -E "\[\"Parameters\"\,$line\,\"Name\"" ${EC2SSM} | tr -s '[:blank:]' ' '| cut -f '2' -d ' ' | sed 's/"//g');
    NAMEKEYVAL=$(grep -E "\[\"Parameters\"\,$line\,\"Value\"" ${EC2SSM} | tr -s '[:blank:]' ' '| cut -f '2' -d ' ');
    VARCUR=$(basename ${NAMEKEYNUM});
    VARCONT=${NAMEKEYVAL};
    echo export $VARCUR=$VARCONT
done
rm -f ${EC2SSM};
rm -f ${EC2SSMIDX};
rmdir ${TMPDIR};
