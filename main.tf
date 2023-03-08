resource "aws_vpc" "bookstore_vpc" {
  cidr_block = "10.0.0.0/16"
   tags = {
    Name = "bookstore_vpc"
  }
}

resource "aws_internet_gateway" "bookstore_ig" {
  vpc_id = aws_vpc.bookstore_vpc.id
  
  tags = {
    Name = "bookstore_ig"
  }
}

resource "aws_route_table" "bookstore_rt" {
  vpc_id = aws_vpc.bookstore_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.bookstore_ig.id
  }

#   route {
#     ipv6_cidr_block        = "::/0"
#     egress_only_gateway_id = aws_egress_only_internet_gateway.bookstore_vpc.id
#   }

  tags = {
    Name = "bookstore_rt"
  }
}

resource "aws_subnet" "bookstore_s1" {
  vpc_id = aws_vpc.bookstore_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "bookstore_s1"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.bookstore_s1.id
  route_table_id = aws_route_table.bookstore_rt.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.bookstore_vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

resource "aws_network_interface" "web_server_nic" {
  subnet_id       = aws_subnet.bookstore_s1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

  
}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web_server_nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [
    aws_internet_gateway.bookstore_ig
  ]
}


resource "aws_instance" "bookstore_web_server" {
    ami = var.ami
    instance_type = var.instance_type
    availability_zone = "us-east-1a"
    key_name = "bookstore-key"

    network_interface {
        device_index         = 0
        network_interface_id = aws_network_interface.web_server_nic.id
    }

    # Check instance connection
  provisioner "remote-exec" {
    inline = ["sudo apt install -y python3"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_key_private)
      host        = self.public_ip
    }
  }

    # user_data = "${file("install_apache.sh")}"
    
    tags = {
        Name = var.instance_name
    }
}

#=======================
# Start ansible playbook
#=======================

## make playbook
resource "null_resource" "CK_Ubuntu" {
  triggers = {
    instance_ips = join(", ", aws_instance.bookstore_web_server[*].public_ip)
  }
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '${join(", ", aws_instance.bookstore_web_server[*].public_ip)}', --private-key ${var.ssh_key_private} ${var.playbook_path}"
  }
}




