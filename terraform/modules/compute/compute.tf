resource "aws_security_group" "sg-elb" {
  vpc_id = var.vpc_id
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
  vpc_id = var.vpc_id
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
    cidr_blocks = [var.vpc_cidr]
  }
}

resource "aws_lb_listener" "ec2-elb-listener" {
  protocol          = "HTTP"
  port              = 80
  load_balancer_arn = aws_lb.ec2-elb.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2-elb-tg.arn
  }
}

resource "aws_lb" "ec2-elb" {
  name               = "ec2-elb"
  load_balancer_type = "application"
  subnets            = [var.sn_pub_az1a_id, var.sn_pub_az1c_id]
  security_groups    = [aws_security_group.sg-elb.id]
}

resource "aws_lb_target_group" "ec2-elb-tg" {
  name     = "ec2-elb-tg"
  protocol = "HTTP"
  port     = 80
  vpc_id   = var.vpc_id
}

data "template_file" "userdata" {
  template = file("./modules/compute/scripts/user_data.sh")
}

resource "aws_launch_template" "ec2-lt" {
  name_prefix            = "app-dynamicsite"
  image_id               = var.ec2_ami
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
  vpc_zone_identifier = [var.sn_priv_az1a_id, var.sn_priv_az1c_id]
  target_group_arns   = [aws_lb_target_group.ec2-elb-tg.arn]
  launch_template {
    id      = aws_launch_template.ec2-lt.id
    version = "$Latest"
  }
}