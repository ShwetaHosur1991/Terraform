resource "aws_vpc" "my_vpc" {
    cidr_block = var.cidr 
}
resource "aws_subnet" "my_sub1" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.102.0/24"
  availability_zone = "us-west-1b"
   map_public_ip_on_launch = true
}
resource "aws_subnet" "my_sub2" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.101.0/24"
  availability_zone = "us-west-1c"
   map_public_ip_on_launch = true
}
resource "aws_internet_gateway" "my_igw" {
     vpc_id = aws_vpc.my_vpc.id
}
resource "aws_route_table" "my_route_table" {
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_igw.id
    }
}
resource "aws_route_table_association" "my_rta1" {
  subnet_id = aws_subnet.my_sub1.id
  route_table_id = aws_route_table.my_route_table.id
}
resource "aws_route_table_association" "my_rta2" {
  subnet_id = aws_subnet.my_sub2.id
   route_table_id = aws_route_table.my_route_table.id
}
resource "aws_security_group" "sg" {
    name = "web"
    vpc_id = aws_vpc.my_vpc.id
    ingress {
        description = "HTTP from VPC"
        to_port = 80
        from_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
    description = "SSH"
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

  tags = {
    Name = "Web-sg"
  }
}
resource "aws_s3_bucket" "my_s3" {
  bucket = "shwetaterraform2023project"
}
resource "aws_instance" "my_instance1_in_subnet1" {
    ami = "ami-06d2c6c1b5cbaee5f"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.sg.id]
    subnet_id              = aws_subnet.my_sub1.id
    user_data              = base64encode(file("userdata.sh"))
  
}
resource "aws_instance" "my_instance2_in_subnet2" {
    ami = "ami-06d2c6c1b5cbaee5f"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.sg.id]
    subnet_id              = aws_subnet.my_sub2.id
    user_data              = base64encode(file("userdata.sh")) 
}
resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.sg.id]
  subnets         = [aws_subnet.my_sub1.id, aws_subnet.my_sub2.id]

  tags = {
    Name = "web"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "myTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.my_instance1_in_subnet1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.my_instance2_in_subnet2.id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}

output "loadbalancerdns" {
  value = aws_lb.myalb.dns_name
}