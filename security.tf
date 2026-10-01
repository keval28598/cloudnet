resource "aws_security_group" "public_sg"{
    name = "cloudnet-public-sg"
    description = "Security group for public subnet"
    vpc_id = aws_vpc.my_vpc.id

    ingress {
        description = "allow http"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

     ingress {
        description = "allow ssh from my IP"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["49.36.64.4/32"]
    }

    egress{
        description = "allow all outbound traffic"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "cloudnet-public-sg"
    }


}



resource "aws_security_group" "private_sg" {
    
    name = "cloudnet-private-sg"
    description = "Security group for private subnet"
    vpc_id = aws_vpc.my_vpc.id

    ingress {
        description = "allow mysql from public sg"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.public_sg.id]
    }

    egress{
        description = "allow all outbound traffic"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]

    }

    tags = {
        Name = "cloudnet-private-sg"
    }
}