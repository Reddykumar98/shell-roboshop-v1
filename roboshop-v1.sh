
#!/bin/bash

set -e

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="daws92k.store"
hosted_zone_id="Z0908977HOWAYRSVDR61"

for instance in "$@"; do
    echo "Creating instance: $instance"

    instance_id=$(aws ec2 run-instances \
        --image-id "$ami_id" \
        --instance-type "$instance_type" \
        --security-groups "roboshop-common" "roboshop-$instance" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
        --query "Instances[0].InstanceId" \
        --output text)

    echo "$instance ID: $instance_id"

    # Wait until the instance is running and has an IP address
    aws ec2 wait instance-running --instance-ids "$instance_id"

    if [ "$instance" != "frontend" ]; then
        IP=$(aws ec2 describe-instances \
            --instance-ids "$instance_id" \
            --query "Reservations[0].Instances[0].PrivateIpAddress" \
            --output text)

        r53_record="$instance.$domain_name"
    else
        IP=$(aws ec2 describe-instances \
            --instance-ids "$instance_id" \
            --query "Reservations[0].Instances[0].PublicIpAddress" \
            --output text)

        r53_record="$domain_name"
    fi

    if [ -z "$IP" ] || [ "$IP" = "None" ]; then
        echo "Error: No IP address found for $instance ($instance_id)"
        exit 1
    fi

    # Update Route 53 record
    aws route53 change-resource-record-sets \
        --hosted-zone-id "$hosted_zone_id" \
        --change-batch "$(cat <<EOF
{
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "$r53_record",
                "Type": "A",
                "TTL": 60,
                "ResourceRecords": [
                    {
                        "Value": "$IP"
                    }
                ]
            }
        }
    ]
}
EOF
)"

    echo "Updated Route 53 record: $r53_record -> $IP"
done
