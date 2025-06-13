resource "aws_vpc" "face_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "face-vpc"
  }
}

resource "aws_internet_gateway" "face_igw" {
  vpc_id = aws_vpc.face_vpc.id

  tags = {
    Name = "face-igw"
  }
}

resource "aws_subnet" "face_subnet" {
  vpc_id                  = aws_vpc.face_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  availability_zone = "us-east-2a"

  tags = {
    Name = "face-subnet"
  }
}

resource "aws_route_table" "face_route_table" {
  vpc_id = aws_vpc.face_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.face_igw.id
  }

  tags = {
    Name = "face-rt"
  }
}

resource "aws_route_table_association" "face_assoc" {
  subnet_id      = aws_subnet.face_subnet.id
  route_table_id = aws_route_table.face_route_table.id
}
