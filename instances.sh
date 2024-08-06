#!/bin/bash
AMI="ami-0b4f379183e5706b9"
SG="sg-0d2c5fcd8720ee8f8"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "web")

for i in "${INSTANCES[@]}"
do
    echo "creating instance : $i"
    if [ $i == "mongodb" ] || [ $i == "mysql" ] || [ $i == "shipping" ]
    then
        INSTANCES_TYPE="t3.small"
    else
        INSTANCES_TYPE="t2.micro"
    fi
    # if [ $i == "web" ];then
    #     IP_Address=$(aws ec2 wait run-instances --image-id $AMI --instance-type $INSTANCES_TYPE --security-group-ids $SG --count 1 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" --query 'Instances[0].PublicIpAddress' --output text)
    # else
    #     IP_Address=$(aws ec2 run-instances --image-id $AMI --instance-type $INSTANCES_TYPE --security-group-ids $SG --count 1 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" --query 'Instances[0].PrivateIpAddress' --output text)
    # fi
# Launch the instance
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI --instance-type $INSTANCES_TYPE --security-group-ids $SG --count 1 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" --query 'Instances[0].InstanceId' --output text)

    # Wait until the instance is running
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID

    # Get the IP address
    if [ "$i" = "web" ]; then
        IP_Address=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    else
        IP_Address=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    fi

    echo "Creating Route53 record for $i APPLICATION : {$IP_Address} "
    aws route53 change-resource-record-sets \
    --hosted-zone-id Z092833841YAHBL3RZKX \
    --change-batch '
    {
        "Comment": "Creating DNS A records for roboshop Applicationt"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$i'.infome.website"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP_Address'"
            }]
        }
        }]
    }
    '
done

