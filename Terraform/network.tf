resource "aws_vpc" "vpcstrapi" {
  cidr_block = "192.168.0.0/16"
  tags = {
    name = "strapi-vpc"
  }
}

resource "aws_subnet" "publicsubnet" {
  vpc_id            = aws_vpc.vpcstrapi.id
  cidr_block        = "192.168.0.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_internet_gateway" "strapiigw" {
  vpc_id = aws_vpc.vpcstrapi.id
  tags = {
    Name = "strapiigw"
  }
}



resource "aws_route_table" "publicroutetable" {
  vpc_id = aws_vpc.vpcstrapi.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.strapiigw.id
  }
}


resource "aws_route_table_association" "association" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.publicroutetable.id
}
