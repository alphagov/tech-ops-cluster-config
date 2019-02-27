variable "subnet_ids" {
  type = "list"
}

variable "cluster_name" {
  type = "string"
}

variable "security_group_ids" {
  description = "List of security groups that are allowed to interact with HSM cluster"
  type        = "list"
}

resource "aws_cloudhsm_v2_cluster" "cluster" {
  hsm_type   = "hsm1.medium"
  subnet_ids = ["${var.subnet_ids}"]

  tags = {
    Name = "${var.cluster_name}-hsm-cluster"
  }
}

resource "aws_security_group_rule" "hsm-worker-ingress" {
  count                    = "${length(var.security_group_ids)}"
  security_group_id        = "${aws_cloudhsm_v2_cluster.cluster.security_group_id}"
  type                     = "ingress"
  from_port                = 2223
  to_port                  = 2225
  protocol                 = "tcp"
  source_security_group_id = "${var.security_group_ids[count.index]}"
}

resource "aws_security_group_rule" "hsm-self-ingress" {
  security_group_id        = "${aws_cloudhsm_v2_cluster.cluster.security_group_id}"
  type                     = "ingress"
  from_port                = 2223
  to_port                  = 2225
  protocol                 = "tcp"
  source_security_group_id = "${aws_cloudhsm_v2_cluster.cluster.security_group_id}"
}

resource "aws_security_group_rule" "hsm-self-egress" {
  security_group_id        = "${aws_cloudhsm_v2_cluster.cluster.security_group_id}"
  type                     = "egress"
  from_port                = 2223
  to_port                  = 2225
  protocol                 = "tcp"
  source_security_group_id = "${aws_cloudhsm_v2_cluster.cluster.security_group_id}"
}

# We can only create one HSM in Terraform rather than the multiple we require for high availability as you must create
# a single HSM, initialise and activate it (which is done manually) before you can create more as they are clones of the
# first HSM. The other HSMs will need to be created after the Terraform apply
# Manual steps to initalise and activate the HSM can be followed from
# https://docs.aws.amazon.com/cloudhsm/latest/userguide/configure-sg.html onwards
resource "aws_cloudhsm_v2_hsm" "cloudhsm_v2_hsm" {
  subnet_id  = "${aws_cloudhsm_v2_cluster.cluster.subnet_ids[0]}"
  cluster_id = "${aws_cloudhsm_v2_cluster.cluster.cluster_id}"
}
