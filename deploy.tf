provider "aws" {
  shared_credentials_file = "..\\credentials"
  region = "${var.region}"
}

# create a security group that allows for all ports from my home IP address
resource "aws_security_group" "home" {
  name = "home"
  description = "allow inbound traffic from home and port ${var.port}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.home_ip}/32"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# create IAM role to allow EC2 to assume the s3 role
resource "aws_iam_role" "assume_s3_role" {
  name = "assume_s3_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Sid": ""
    }
  ]
}
EOF
}

# create IAM policy to access s3 buckets
resource "aws_iam_policy" "access_s3_policy" {
  name = "access_s3_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# attach IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "attach_s3_role_policy" {
  role = "${aws_iam_role.assume_s3_role.name}"
  policy_arn = "${aws_iam_policy.access_s3_policy.arn}"
}

# create a profile to allow new EC2 instances to access to s3
resource "aws_iam_instance_profile" "access_s3_profile" {
  name = "access_s3_profile"
  role = "${aws_iam_role.assume_s3_role.name}"
}

# create an AWS instance and start Factorio
resource "aws_instance" "factorio" {
  ami = "${lookup(var.amis, var.region)}"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.home.id}"]
  key_name = "${var.ssh_key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.access_s3_profile.name}"

  connection {
    private_key = "${file("..\\home.pem")}"
    user = "ec2-user"
    agent = false
  }

  provisioner "remote-exec" {
    inline = [
        "aws s3api get-object --bucket greydevilfactorio --key factorio_headless_x64_0.15.40.tar.xz /tmp/factorio_headless_x64_0.15.40.tar.xz",
        "tar -xf /tmp/factorio_headless_x64_0.15.40.tar.xz -C /tmp",
        "sudo mv /tmp/factorio /opt/factorio",
        "mkdir /opt/factorio/saves",
        "aws s3api get-object --bucket greydevilfactorio --key saves/multi.zip /opt/factorio/saves/multi.zip",
        "/opt/factorio/bin/x64/factorio --start-server /opt/factorio/saves/multi.zip"
    ]

# should this be s3fs instead?
# need to grab mods from somewhere like S3 as well, probably recreate the rail map too
# parameterize the name of the save
# set up some default passwords for the server, perhaps have it join the multiplayer hosting via config (loaded from S3)
  }
}

# output the SSH url
output "ssh_url" {
  value = "ec2-user@${aws_instance.factorio.public_dns}"
}

# output the address for factorio
output "factorio_address" {
  value = "${aws_instance.factorio.public_dns}:${var.port}"
}
