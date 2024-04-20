resource "aws_vpc" "vpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "subnet" {
  cidr_block = var.cidr
  vpc_id = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  tags = {
    name = "subnet-1"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.vpc.id
  name = "SG-1"

  ingress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "webservers" {
  image_id = var.imageid
  instance_type = var.instancetype
  key_name = "pem"
}

resource "aws_elb" "elb" {
  name = "load-balancer"
  security_groups = [aws_security_group.sg.id]
  subnets = [aws_subnet.subnet.id]
  listener {
    instance_port = 8000
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
}

resource "aws_autoscaling_group" "asg" {
  launch_configuration = aws_launch_configuration.webservers.id
  min_size = var.minsize
  max_size = var.maxsize
  desired_capacity = var.desiredcapacity
  health_check_type = "EC2"
  load_balancers = [aws_elb.elb.name]
  vpc_zone_identifier  = [aws_subnet.subnet.id]
  tag {
    key                 = "Environment"
    value               = var.env
    propagate_at_launch = true
  }
}


variable "cidr" {
  description = "cidr value"
}

variable "env" {
  description = "environment"
}

variable "minsize" {
  description = "autoscaling_group min size"
}

variable "maxsize" {
  description = "autoscaling_group max size"
}

variable "desiredcapacity" {
  description = "autoscaling_group desired size"
}

variable "imageid" {
  description = "image id"
}

variable "instancetype" {
  description = "instancetype"
}
