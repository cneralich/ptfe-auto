terraform {
  backend "s3" {
    region = "${var.aws_region}"
    bucket = "${var.s3_bucket}"
    key    = "${var.s3_key}"
  }
}

provider "aws" {
  region = "${var.aws_region}"
}

data "aws_route53_zone" "main" {
  name = "hashidemos.io."
}

#------------------------------------------------------------------------------
# network
#------------------------------------------------------------------------------

module "network" {
  source    = "network/"
  namespace = "${var.namespace}"
}

#------------------------------------------------------------------------------
# demo/poc ptfe
#------------------------------------------------------------------------------

module "demo" {
  source                 = "demo/"
  namespace              = "${var.namespace}"
  aws_instance_type      = "${var.aws_instance_type}"
  subnet_id              = "${module.network.public_subnet_ids[0]}"
  vpc_security_group_ids = "${module.network.security_group_id}"
  ssh_key_name           = "${var.ssh_key_name}"
  ssh_key_path           = "${var.ssh_key_path}"
  license_path           = "${var.license_path}"
  hashidemos_zone_id     = "${data.aws_route53_zone.main.zone_id}"
  owner                  = "${var.owner}"
  ttl                    = "${var.ttl}"
}