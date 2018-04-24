#!/bin/bash
#
#
# Required tools:
#   JSON.sh aws-cli awk coreutils grep sed
#
# Read aws ssm parameters and print them on std output, starting from the supplied ssm /PATH
# 
[ $# -eq 1 ] && PARAMPATH="$1" || unset PARAMPATH;

TMPDIR="/tmp/Ec2ssm";
EC2SSM="${TMPDIR}/ec2-ssm.tmp";
EC2SSMIDX="${TMPDIR}/ec2-ssm-idx.tmp";
ECSMETA="${TMPDIR}/ec2-ecsmeta.tmp";
ECSTASKS="${TMPDIR}/ec2-ecstasks.tmp";
mkdir -p ${TMPDIR};

#Read current region from docker-host metadata
AZ=$(curl -f http://169.254.169.254/latest/meta-data/placement/availability-zone 2> /dev/null);
REGION=${AZ:0:${#AZ} - 1};

#Get Cluster name from docker-host metadata
HOSTIP=$(curl -f http://169.254.169.254/latest/meta-data/local-ipv4 2> /dev/null);
curl http://${HOSTIP}:51678/v1/metadata | JSON.sh -b > ${ECSMETA} 2> /dev/null;
CLUSTERECS=$(grep -E "\[\"Cluster\"" ${ECSMETA} |tr -s '[:blank:]' ' '| cut -f '2' -d ' ' | sed 's/"//g');

#Find task def family in order to build PARAMPATH dynamically
curl http://${HOSTIP}:51678/v1/tasks | JSON.sh -b > ${ECSTASKS} 2> /dev/null;
TASKID=$(grep ${HOSTNAME} ${ECSTASKS} | awk '{print $1}' | cut -f '2' -d ',' | grep -o '[0-9]*');
TASKFAMILY=$(grep -E "\[\"Tasks\"\,$TASKID\,\"Family\"" ${ECSTASKS} | tr -s '[:blank:]' ' '| cut -f '2' -d ' ' | sed 's/"//g');
SEARCHPATH=${PARAMPATH:-"/DeploymentConfig/${CLUSTERECS}/${TASKFAMILY}"};

aws ssm get-parameters-by-path --path ${SEARCHPATH} --recursive --region ${REGION} | JSON.sh -b > ${EC2SSM};

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
rm -f ${ECSMETA};
rm -f ${ECSTASKS};
rm -f ${EC2SSM};
rm -f ${EC2SSMIDX};
rmdir ${TMPDIR};
