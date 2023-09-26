provider "aws" { 
    region = "us-west-1"
}

resource "aws_instance" "name" {
    ami = "ami-06d2c6c1b5cbaee5f"
    instance_type = "t2.micro"
}