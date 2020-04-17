data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzjsCgBL9v52ucCr1wVwHLJ7N7wkJHufAg3m2BRUQIgdLMoLwps9F1CxqIp5B6Wpncqtduoyo56pb9Gx1bAyzURURa+f9qRf+nSFrBmNnkctWy1n0SPNduKAZuMY9vU1JQMWFJ4beTQtdo9wWLKRUg64+eeYmw7dYAIpQF2m0ztTq68Cgv+cMZdd2J3UbibTxk6AMrkVWIKEH6iz6BNEcTsRj1oALNEvheo3+kL9mpyl+JGqIGrMWT0oB6AGJqfHEP4W5ywQm7QPOXRTWT/ndVboL6V4yXqk9wzF6mwV0REZ0h+4Nb8a932WZt+7fhPLBsarvR//Gi+PmAVILp3kA5 makky@2327"
}


#data "aws_subnet_ids" "default" {
#  vpc_id = data.aws_vpc.default.id
#}


data "aws_vpc" "default" {
  default = true
}


#data "aws_subnet" "default" {
#  vpc_id = data.aws_vpc.default.id
#  id     = data.aws_subnet_ids.default.id
#
#  tags = {
#    Name = "test"
#  }
#}


resource "aws_default_subnet" "default" {
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Default subnet for us-west-2a"
  }
}

module "sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.0.0"

  name        = "test"
  description = "Security group for test"

  vpc_id = aws_default_subnet.default.vpc_id

  ingress_with_cidr_blocks = concat(
    [
      {
        rule        = "ssh-tcp"
        cidr_blocks = "0.0.0.0/0"
        description = "Allow ssh"
      }
  ])

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbount traffic"
    }
  ]
}


resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_default_subnet.default.id]

  #subnet_mapping {
  #  subnet_id     = var.public_subnet_us_east_1a
  #  allocation_id = aws_eip.app_us_east_1a.id
  #}


  enable_deletion_protection = true

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.test.arn
  port              = 22
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.test.arn
    type             = "forward"
  }
}

#resource "aws_lb_target_group" "nlb_target_group" {
#  name     = "nlb-target-group"
#  port     = "22"
#  protocol = "TCP"
#  vpc_id   = data.aws_vpc.default.id
#  tags = {
#    name = "nlb_target_group"
#  }
#}


resource "aws_lb_target_group" "test" {
  name              = "terraform-asg-example"
  port              = "22"
  protocol          = "TCP"
  vpc_id            = aws_default_subnet.default.vpc_id
  target_type       = "instance"
  proxy_protocol_v2 = false
  #    health_check {
  #        path = "/"
  #        protocol = "HTTP"
  #        matcher = "200"
  #        interval = 15
  #        timeout = 3
  #        healthy_threshold = 2
  #        unhealthy_threshold = 2
  #    }
}


resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.test.id
  port             = 22
}


resource "aws_ebs_volume" "prometheus" {
  availability_zone = "us-west-2a"
  type              = "gp2"
  size              = 2
  # encrypted         = true
  # kms_key_id        = aws_kms_key.ebs.arn

  tags = {
    "Name"      = "test"
    "Terraform" = "true"
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes  = all
  }
}


resource "aws_instance" "test" {
  ami               = data.aws_ami.ubuntu.id
  availability_zone = var.availability_zone_names
  instance_type     = var.instance_type
  key_name          = aws_key_pair.deployer.key_name

  #  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  vpc_security_group_ids = concat(
    [module.sg.this_security_group_id]
  )

  #  subnet_id = data.aws_subnet.selected.id

  #  tenancy                     = var.tenancy
  #  associate_public_ip_address = var.associate_public_ip_address

  # ebs_optimized = var.root_volume_ebs_optimized

  #  disable_api_termination = false
  #  get_password_data       = false
  ipv6_address_count = 0
  ipv6_addresses     = []
  source_dest_check  = true

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = var.root_volume_delete_on_termination
    encrypted             = false
  }

  volume_tags = {
    "Env"       = "dev"
    "Name"      = "prometheus"
    "Terraform" = "true"
  }

  timeouts {}

  tags = {
    "Name"      = "test"
    "Terraform" = "true"
  }

}

resource "aws_volume_attachment" "test" {
  device_name = "/dev/xvdo"
  volume_id   = aws_ebs_volume.prometheus.id
  instance_id = aws_instance.test.id
}

#resource "aws_route53_record" "www" {
#  zone_id = data.terraform_remote_state.dns.outputs.hosted_zone_id
#  name    = "api.yourwebsite.com"
#  type    = "A"
#
#  alias {
#    name                   = "${aws_lb.lambda-example.dns_name}"
#    zone_id                = "${aws_lb.lambda-example.zone_id}"
#    evaluate_target_health = true
#  }
#}

