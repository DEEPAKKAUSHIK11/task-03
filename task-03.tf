// AWS public cloud to launch OS using Terraform

provider "aws"{
  region = "ap-south-1"
  profile = "deepak"
}

// Generates a secure private key and encodes it as PEM

resource "tls_private_key" "instance_key" {
  algorithm   = "RSA"
  rsa_bits = 4096
}

// Generates a local file with the given content

resource "local_file" "key_gen" {
    content = tls_private_key.instance_key.private_key_pem
    filename = "i_am_key.pem"
	file_permission = 0400
}

// Provides an EC2 key pair resource

resource "aws_key_pair" "instance_key" {
  key_name   = "i_am_key"
  public_key = tls_private_key.instance_key.public_key_openssh  
}

// Provides a VPC resource

resource "aws_vpc" "myvpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "myvpc"
  }
}

//Provides an VPC subnet resource

resource "aws_subnet" "public_subnet" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "192.168.1.0/24"
//availability_zone = aws_instance.my_instance.availability_zone
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "public_subnet"
  }
}

//Provides an VPC subnet resource

resource "aws_subnet" "private_subnet" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "192.168.0.0/24"
//availability_zone = aws_instance.my_instance.availability_zone
  availability_zone = "ap-south-1b"

  tags = {
    Name = "private_subnet"
  }
}

//Provides a resource to create a VPC Internet Gateway

resource "aws_internet_gateway" "myvpc_int_gw" {
  vpc_id = "${aws_vpc.myvpc.id}"

  tags = {
    Name = "myvpc_int_gw"
  }
}

//Provides a resource to create a VPC routing table

resource "aws_route_table" "my_gw_route" {
  vpc_id = "${aws_vpc.myvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.myvpc_int_gw.id}"
  }

  tags = {
    Name = "my_gw_route"
  }
}

// Provides a resource to create an association

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.my_gw_route.id
}

// Provides a security group resource

resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress_sg"
  description = "Allow inbound traffic"
  vpc_id = "${aws_vpc.myvpc.id}"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Provides a security group resource

resource "aws_security_group" "mysql_sg" {
  name        = "mysql_sg"
  description = "MySQL sg set-up"
  vpc_id = "${aws_vpc.myvpc.id}"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TCP"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//Provides an EC2 instance resource wordpress_instance

resource "aws_instance" "wordpress_instance" {
	ami = "ami-0c855905d1fe98a30"
	instance_type = "t2.micro"
        associate_public_ip_address = true
	key_name =  aws_key_pair.instance_key.key_name
	vpc_security_group_ids = [aws_security_group.wordpress_sg.id]
        subnet_id="${aws_subnet.public_subnet.id}"
tags = {
	Name = "WordPressOS"
	}
   }
   
//Provides an EC2 instance resource for mysql_instance   

resource "aws_instance" "mysql_instance" {
	ami = "ami-08706cb5f68222d09"
	instance_type = "t2.micro"
        associate_public_ip_address = true  
	key_name =  aws_key_pair.instance_key.key_name
	vpc_security_group_ids = [aws_security_group.mysql_sg.id]
       subnet_id="${aws_subnet.private_subnet.id}"
     
tags = {
	Name = "MySqlOS"
	}
   }

resource "null_resource" "save_key_pair"  {
	provisioner "local-exec" {
	    command = "echo  '${tls_private_key.instance_key.private_key_pem}' > key.pem"
  	}
}