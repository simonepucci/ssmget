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

AZ=$(curl -f http://169.254.169.254/latest/meta-data/placement/availability-zone 2> /dev/null);
REGION=${AZ:0:${#AZ} - 1};

aws ssm get-parameters-by-path --path ${PARAMPATH} --recursive --region ${REGION} | JSON.sh -b > ${EC2SSM}
cat ${EC2SSM} | awk '{print $1}' | cut -f '2' -d ',' | grep -o '[0-9]*' | sort -n | uniq > ${EC2SSMIDX};

cat ${EC2SSMIDX} | while read line;
do
    #Extract interesting stuff
    # ["Parameters",0,"Name"]
    NAMEKEYNUM=$(grep -E "\[\"Parameters\"\,$line\,\"Name\"" ${EC2SSM} |tr -s '[:blank:]' ' '| cut -f '2' -d ' ' | sed 's/"//g');
    NAMEKEYVAL=$(grep -E "\[\"Parameters\"\,$line\,\"Value\"" ${EC2SSM}|tr -s '[:blank:]' ' '| cut -f '2' -d ' ');
    VARCUR=$(basename ${NAMEKEYNUM});
    VARCONT=${NAMEKEYVAL};
    echo export $VARCUR=$VARCONT
done
rm -f ${EC2SSM};
rm -f ${EC2SSMIDX};
rmdir ${TMPDIR};
