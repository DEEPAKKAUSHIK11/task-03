# task-03

Task Description

We have to create a web portal for our company with all the security as much as possible. So, we use Wordpress software with dedicated database server. Database should not be accessible from the outside world for security purposes. We only need to public the WordPress to clients. So here are the steps for proper understanding!

Steps:-

    Write a Infrastructure as code using terraform, which automatically create a VPC.
    In that VPC we have to create 2 subnets:

   a) public subnet [ Accessible for Public World! ] 

   b) private subnet [ Restricted for Public World! ]

    Create a public facing internet gateway for connect our VPC/Network to the internet world and attach this gateway to our VPC.
    Create a routing table for Internet gateway so that instance can connect to outside world, update and associate it with public subnet.
    Launch an ec2 instance which has Wordpress setup already having the security group allowing port 80 so that our client can connect to our wordpress site. Also attach the key to instance for further login into it.
    Launch an ec2 instance which has MYSQL setup already with security group allowing port 3306 in private subnet so that our wordpress VM can connect with the same. Also attach the key with the same.

NOTE - Wordpress instance launched here is a part of public subnet so that our client can connect our site. MySQL instance is part of private subnet so that outside world can't connect to it. Also auto ip assign and auto dns name assignment option is enabled.

Prerequisites -:

    AWS Console Account
    AWS CLI
    Installed Terraform in system

Steps to perform

Step 1: Code for creating Provider, key-pair and VPC listed below :

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

Step 2: Creating a VPC with CIDR Block 192.168.0.0/16 and enable DNS Hostnames to assign dns names to instances.

// Provides a VPC resource


resource "aws_vpc" "myvpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"


  tags = {
   
     Name = "myvpc"
  }

}

We can see the VPC created in AWS from the above code behind the scene shown below
No alt text provided for this image

Step 3: Creating public subnet:-

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.10.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "true"
tags = {
    Name = "public-subnet"
  }

}


Public Subnet created in AWS from the above code behind the scene shown below
No alt text provided for this image

Step 4: Creating a private subnet:-

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.20.0/24"
  availability_zone = "ap-south-1a"
tags = {
    Name = "private-subnet"
  }

}

Private Subnet created in AWS from the above code behind the scene shown below
No alt text provided for this image

Step 5: Creating a Internet Gateway in Previosly created VPC for PUBLIC SUBNET to connect Internet:-

//Provides a resource to create a VPC Internet Gateway


resource "aws_internet_gateway" "myvpc_int_gw" {
  vpc_id = "${aws_vpc.myvpc.id}"


  tags = {
    
     Name = "myvpc_int_gw"
  }

}

Internet Gateway created in AWS from the above code behind the scene shown below
No alt text provided for this image

Step 6: Write a Terraform code to Create a routing table for Internet gateway so that instance can connect to outside world, update and associate it with public subnet:-

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

Route Table created and subnet association in AWS from the above code behind the scene shown below
No alt text provided for this image
No alt text provided for this image

Step 7: Create two security group (firewall) for WordPress and MySQL instance. Security Group named wordpress_sg created below allow port 80 to connect the client and mysql_sg allow port 3306 for MySQL server.

// Provides a security group resource for wordpress_sg

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


// Provides a security group resource for mysql_sg

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


Security Group created for WordPress & MySQL along with inbound and outbound rules in AWS from the above code behind the scene shown below
No alt text provided for this image
No alt text provided for this image
No alt text provided for this image

Step 8: Launch an ec2 instance which has Wordpress & MySQL setup already having the security group allowing port 80 (in public subnet) & 3306 (in private subnet) so that our client can connect to our wordpress site. Also attach the key to instance :

//Provides an EC2 instance resource


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


EC2 instances created in AWS from the above code behind the scene shown below
No alt text provided for this image

Terraform must store state about our managed infrastructure and configuration. This state is used by Terraform to map real world resources to our configuration, keep track of metadata, and to improve performance for large infrastructures.

Below is the snapshot of WordPress Launched -
No alt text provided for this image

Thank you for reading article
Blog Link:- https://www.linkedin.com/pulse/task-03-create-personal-vpc-integrate-ec2public-private-kaushik/
