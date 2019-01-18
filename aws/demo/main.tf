#------------------------------------------------------------------------------
# demo/poc ptfe resources
#------------------------------------------------------------------------------

locals {
  namespace = "${var.namespace}-demo"
}

data "template_file" "replicated_settings" {
  template = "${file("${path.module}/replicated-settings.tpl.json")}"
}

data "template_file" "replicated_conf" {
  template = "${file("${path.module}/replicated.tpl.conf")}"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "demo" {
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "${var.aws_instance_type}"
  subnet_id              = "${var.subnet_id}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  key_name               = "${var.ssh_key_name}"

  provisioner "file" {
    source      = "${var.license_path}"
    destination = "/tmp/license.rli"

    connection {
      user        = "ubuntu"
      private_key = "${file("${var.ssh_key_path}")}"
    }
  }

  provisioner "file" {
    content     = "${data.template_file.replicated_conf.rendered}"
    destination = "/tmp/replicated.conf"

    connection {
      user        = "ubuntu"
      private_key = "${file("${var.ssh_key_path}")}"
    }
  }

  provisioner "file" {
    content     = "${data.template_file.replicated_settings.rendered}"
    destination = "/tmp/replicated-settings.json"

    connection {
      user        = "ubuntu"
      private_key = "${file("${var.ssh_key_path}")}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/replicated.conf /etc/",
      "curl -o install.sh https://install.terraform.io/ptfe/stable",
      "sudo bash install.sh no-proxy",
    ]

    connection {
      user        = "ubuntu"
      private_key = "${file("${var.ssh_key_path}")}"
    }
  }

  root_block_device {
    volume_size = 80
    volume_type = "gp2"
  }

  tags {
    Name  = "${local.namespace}-instance"
    owner = "${var.owner}"
    TTL   = "${var.ttl}"
  }
}

resource "aws_eip" "demo" {
  instance = "${aws_instance.demo.id}"
  vpc      = true
}

resource "aws_route53_record" "demo" {
  zone_id = "${var.hashidemos_zone_id}"
  name    = "${local.namespace}.hashidemos.io."
  type    = "A"
  ttl     = "300"
  records = ["${aws_eip.demo.public_ip}"]
}
