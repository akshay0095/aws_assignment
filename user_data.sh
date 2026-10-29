#!/bin/bash
set -euxo pipefail

dnf install -y nginx

TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)

cat > /usr/share/nginx/html/index.html <<EOF
<!DOCTYPE html>
<html>
  <head><title>AWS Assignment</title></head>
  <body>
    <h1>Shopalyst assignment</h1>
    <p>Served by $INSTANCE_ID in $AZ</p>
  </body>
</html>
EOF

systemctl enable --now nginx
