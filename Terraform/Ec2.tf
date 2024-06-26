resource "aws_ecr_repository" "my_ecr_repo" {
  name                 = "strapi-repo" 
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  depends_on = [
    aws_route_table_association.association
  ]
}
resource "aws_iam_role" "ec2_role" {
  name = "ec2-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
  depends_on = [ aws_ecr_repository.my_ecr_repo ]
}
resource "aws_iam_policy" "ecr_policy" {
  name        = "ec2-instance-pulls-from-ecr"
  description = "EC2 instance can pull from ECR"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      Resource = "*"
    }]
  })
  depends_on = [ aws_iam_role.ec2_role ]
}
resource "aws_iam_policy_attachment" "ecr_attachment" {
  name = "my-ecr-policy-attachment"
  policy_arn = aws_iam_policy.ecr_policy.arn
  roles      = [aws_iam_role.ec2_role.name]
  depends_on = [ aws_iam_policy.ecr_policy ]
}
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
  depends_on = [ aws_iam_policy_attachment.ecr_attachment ]
}



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
  depends_on = [ aws_iam_instance_profile.ec2_instance_profile ]

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
  ami                         = data.aws_ami.id
  availability_zone           = "us-west-2a"
  instance_type               = "t2.small"
  vpc_security_group_ids      = [aws_security_group.sgforstrapi.id]
  subnet_id                   = aws_subnet.publicsubnet.id
  key_name                    = "strapipem"
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
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
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa") 
      host        = aws_instance.ec2forstrapi.public_ip
    }
    inline = [
      "sudo apt update",
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt install docker.io -y ",
      "sudo usermod -aG docker ubuntu",
      "docker image build -t ${aws_ecr_repository.my_ecr_repo.repository_url}:${var.docker_tag} .",
      "docker image push ${aws_ecr_repository.my_ecr_repo.repository_url}:${var.docker_tag}",
      "docker container run -d -P ${aws_ecr_repository.my_ecr_repo.repository_url}:${var.docker_tag}"
    ]
}
 depends_on = [
    aws_instance.ec2forstrapi
  ]
}

