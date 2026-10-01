# 1. Automatically fetch the latest Amazon Linux 2023 OS image
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 2. Upload our newly generated public key to AWS
resource "aws_key_pair" "cloudnet_auth" {
  key_name   = "cloudnet-key"
  public_key = file("${path.module}/cloudnet_key.pub")
}


resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  # Network placement
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  associate_public_ip_address = true

  # Access
  key_name = aws_key_pair.cloudnet_auth.key_name

  # Bootstrapping a basic web server
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "CloudNet: Deployment Successful!" > /var/www/html/index.html
EOF

tags = {
Name = "cloudnet-web-server"
}


}