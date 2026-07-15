#!/bin/bash

# -------------------------------
# Check AWS CLI
# -------------------------------
check_awscli() {
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI not found. Installing..."
        install_awscli
    fi
}

# -------------------------------
# Install AWS CLI
# -------------------------------
install_awscli() {
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -o awscliv2.zip
    sudo ./aws/install
}

# -------------------------------
# Wait for instance
# -------------------------------
wait_for_instance() {
    local instance_id="$1"
    echo "Waiting for instance $instance_id..."

    while true; do
        state=$(aws ec2 describe-instances \
            --instance-ids "$instance_id" \
            --query "Reservations[0].Instances[0].State.Name" \
            --output text)

        echo "Current state: $state"

        if [ "$state" == "running" ]; then
            echo "Instance is running ✅"
            break
        fi

        sleep 5
    done
}

# -------------------------------
# Get Public IP
# -------------------------------
get_instance_ip() {
    aws ec2 describe-instances \
        --instance-ids "$1" \
        --query "Reservations[0].Instances[0].PublicIpAddress" \
        --output text
}

# -------------------------------
# Wait for SSH
# -------------------------------
wait_for_ssh() {
    local ip="$1"
    echo "Waiting for SSH..."

    while ! nc -z "$ip" 22; do
        sleep 3
    done

    echo "SSH ready ✅"
}

# -------------------------------
# Create EC2 Instance
# -------------------------------
create_ec2_instance() {

    echo "Creating EC2 instance..."

    instance_id=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type "$INSTANCE_TYPE" \
        --key-name "$KEY_NAME" \
        --security-group-ids "$SECURITY_GROUP_IDS" \
        --subnet-id "$SUBNET_ID" \
        --associate-public-ip-address \
        --query "Instances[0].InstanceId" \
        --output text)

    # ❗ STOP if failed
    if [ -z "$instance_id" ]; then
        echo "❌ Instance creation failed"
        exit 1
    fi

    echo "Instance created: $instance_id"

    wait_for_instance "$instance_id"

    public_ip=$(get_instance_ip "$instance_id")

    echo "Public IP: $public_ip"

    wait_for_ssh "$public_ip"

    echo "======================================"
    echo "Connect using:"
    echo "ssh -i Devops.pem ubuntu@$public_ip"
    echo "======================================"
}

# -------------------------------
# MAIN
# -------------------------------
main() {

    check_awscli

    # 🔹 UPDATE THESE VALUES
    AMI_ID="ami-0aba19e56f3eaec05"
    INSTANCE_TYPE="t3.micro"
    KEY_NAME="Devops"

    # ⚠️ VERY IMPORTANT: Use REAL values
    SUBNET_ID="subnet-0b8151b01197bd81a"
    SECURITY_GROUP_IDS="sg-0a4a4d2d456d8ccec"

    create_ec2_instance

    echo "Done 🚀"
}

main "$@"

  

