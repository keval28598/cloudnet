resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
     Name = "cloudnet-vpc"
    }
    
}

resource "aws_internet_gateway" "my_igw"{
    vpc_id = aws_vpc.my_vpc.id

    tags={
        Name = "cloudnet-igw"
    }
}

resource "aws_route_table" "public_rt"{
    vpc_id = aws_vpc.my_vpc.id

    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_igw.id
    }

    tags = {
        Name = "cloudnet-public-rt"
    }
}

resource "aws_subnet" "public_subnet"{
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true

    tags = {
        Name = "cloudnet-public-subnet"
    }
}

resource "aws_subnet" "private_subnet"{
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = false
    tags = {
        Name = "cloudnet-private-subnet"
    }

}

resource "aws_route_table_association" "public_assoc"{
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_rt.id
}