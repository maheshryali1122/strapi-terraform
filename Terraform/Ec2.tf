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

    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Sg-strapi"
  }

}

resource "aws_instance" "ec2forstrapi" {
  ami                         = "ami-03c983f9003cb9cd1"
  availability_zone = "us-west-2a"
  instance_type               = "t2.small"
  vpc_security_group_ids      = [aws_security_group.sgforstrapi.id]
  subnet_id                   = aws_subnet.publicsubnet.id
  key_name                    = "strapipem"
  associate_public_ip_address = true
  ebs_block_device {
    device_name = "/dev/sdh"
    volume_size = 20
    volume_type = "gp2"
    delete_on_termination = true
  }
  tags = {
    Name = "ec2forstrapi"
  }
}

resource "null_resource" "example" {
   triggers = {
    running_number  =  var.number
  }

    provisioner "remote-exec" {
      connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_instance.ec2forstrapi.public_ip
    }
    inline = [
      "sudo apt update",
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt install docker.io -y ",
      "sudo usermod -aG docker ubuntu",
      "docker image pull maheshryali/strapi:9.0"
      "docker container run -d -P maheshryali/strapi:9.0"
    ]
}
 depends_on = [
    aws_instance.ec2forstrapi
  ]
  }
