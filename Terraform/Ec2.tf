resource "aws_security_group" "sgforstrapi" {
  vpc_id      = aws_vpc.vpcstrapi.id
  description = "This is for strapy application"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Sg-strapi"
  }
  depends_on = [ aws_route_table_association.association ]

}
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] 
  depends_on = [ aws_security_group.sgforstrapi ]
}

resource "aws_instance" "ec2forstrapi" {
  ami                         = data.aws_ami.ubuntu.id
  availability_zone           = "us-west-2a"
  instance_type               = var.instancetype
  vpc_security_group_ids      = [aws_security_group.sgforstrapi.id]
  subnet_id                   = aws_subnet.publicsubnet.id
  key_name                    = "strapipem"
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              {
                sudo apt update
                if ! command -v docker &> /dev/null; then 
                  sudo apt install docker.io -y 
                  sudo usermod -aG docker ubuntu 
                  sudo chmod 660 /var/run/docker.sock
                fi
                echo ${var.docker_password} | docker login -u ${var.docker_username} --password-stdin
              } >> /var/log/user-data.log 2>&1
              EOF
  ebs_block_device {
    device_name = "/dev/sdh"
    volume_size = 20
    volume_type = "gp2"
    delete_on_termination = true
  }
  tags = {
    Name = "ec2forstrapi"
  }
  depends_on = [ data.aws_ami.ubuntu ]
}

resource "null_resource" "example" {
    triggers = {
    docker_tag = var.docker_tag
  }

    provisioner "remote-exec" {
      connection {
      type        = "ssh"
      user        = "${var.user}"
      private_key    = "${var.privatekey}"
      host        = aws_instance.ec2forstrapi.public_ip
    }
    inline = [
      "git clone https://github.com/maheshryali1122/strapi-terraform.git",
      "docker image build -t maheshryali/strapi-api:${var.docker_tag} .",
      "docker image push maheshryali/strapi-api:${var.docker_tag}",
      "docker stop $(docker ps -q) || true",
      "docker rm $(docker ps -aq) || true",
      "docker container run -d -p 1337:1337 maheshryali/strapi-api:${var.docker_tag}"
    ]
}
 depends_on = [
    aws_instance.ec2forstrapi
  ]
}

