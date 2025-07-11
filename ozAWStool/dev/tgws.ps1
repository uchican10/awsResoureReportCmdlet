$transitgateway = aws ec2 describe-transit-gateways | jq -r --arg OWNER "$env:AWS_ACCOUNT_ID" '.TransitGateways[] | select(.OwnerId == $OWNER) | .TransitGatewayId'

$transitgateway