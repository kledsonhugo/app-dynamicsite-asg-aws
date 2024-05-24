resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "sn-pub-az1a" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sn-pub-az1c" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "us-east-1c"
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sn-priv-az1a" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.2.0/24"
}

resource "aws_subnet" "sn-priv-az1c" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "us-east-1c"
  cidr_block              = "10.0.4.0/24"
}

resource "aws_eip" "eip-az1a" {}

resource "aws_nat_gateway" "ngw-az1a" {
    allocation_id = aws_eip.eip-az1a.id
    subnet_id     = aws_subnet.sn-pub-az1a.id
}

resource "aws_eip" "eip-az1c" {}

resource "aws_nat_gateway" "ngw-az1c" {
    allocation_id = aws_eip.eip-az1c.id
    subnet_id     = aws_subnet.sn-pub-az1c.id
}

resource "aws_route_table" "rt-pub" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "rt-priv-az1a" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw-az1a.id
  }
}

resource "aws_route_table" "rt-priv-az1c" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw-az1c.id
  }
}

resource "aws_route_table_association" "sn-pub-az1a" {
  subnet_id      = aws_subnet.sn-pub-az1a.id
  route_table_id = aws_route_table.rt-pub.id
}

resource "aws_route_table_association" "sn-pub-az1c" {
  subnet_id      = aws_subnet.sn-pub-az1c.id
  route_table_id = aws_route_table.rt-pub.id
}

resource "aws_route_table_association" "sn-priv-az1a" {
  subnet_id      = aws_subnet.sn-priv-az1a.id
  route_table_id = aws_route_table.rt-priv-az1a.id
}

resource "aws_route_table_association" "sn-priv-az1c" {
  subnet_id      = aws_subnet.sn-priv-az1c.id
  route_table_id = aws_route_table.rt-priv-az1c.id
}

resource "aws_security_group" "sg-elb" {
  vpc_id = aws_vpc.vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg-ec2" {
  vpc_id = aws_vpc.vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_lb_listener" "ec2-lb-listener" {
  protocol          = "HTTP"
  port              = 80
  load_balancer_arn = aws_lb.ec2-lb.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2-lb-tg.arn
  }
}

resource "aws_lb" "ec2-lb" {
  name               = "ec2-lb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.sn-pub-az1a.id, aws_subnet.sn-pub-az1c.id]
  security_groups    = [aws_security_group.sg-elb.id]
}

resource "aws_lb_target_group" "ec2-lb-tg" {
  name     = "ec2-lb-tg"
  protocol = "HTTP"
  port     = 80
  vpc_id   = aws_vpc.vpc.id
}

data "template_file" "userdata" {
  template = file("./scripts/userdata.sh")
}

resource "aws_launch_template" "ec2-lt" {
  name_prefix            = "app-dynamicsite"
  image_id               = "ami-02e136e904f3da870"
  instance_type          = "t2.micro"
  key_name               = "vockey"
  user_data              = base64encode(data.template_file.userdata.rendered)
  vpc_security_group_ids = [aws_security_group.sg-ec2.id]
}

resource "aws_autoscaling_group" "ec2-asg" {
  name                = "ec2-asg"
  desired_capacity    = 4
  min_size            = 2
  max_size            = 8
  vpc_zone_identifier = [aws_subnet.sn-priv-az1a.id, aws_subnet.sn-priv-az1c.id]
  target_group_arns   = [aws_lb_target_group.ec2-lb-tg.arn]
  launch_template {
    id      = aws_launch_template.ec2-lt.id
    version = "$Latest"
  }
}