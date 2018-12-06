data "template_file" "flux" {
  template = "${file("${path.module}/data/flux.yaml")}"

  vars {
    namespace = "flux-system"
  }
}

resource "local_file" "flux" {
  filename = "${var.addons_dir}/flux.yaml"
  content  = "${data.template_file.flux.rendered}"
}

data "template_file" "namespace" {
  template = "${file("${path.module}/data/namespace.yaml")}"

  vars {
    namespace = "${var.namespace}"
  }
}

resource "local_file" "namespace" {
  filename = "${var.addons_dir}/${var.namespace}-namespace.yaml"
  content  = "${data.template_file.namespace.rendered}"
}

data "template_file" "helm-release" {
  template = "${file("${path.module}/data/helm-release.yaml")}"

  vars {
    namespace  = "${var.namespace}"
    chart_git  = "${var.chart_git}"
    chart_ref  = "${var.chart_ref}"
    chart_path = "${var.chart_path}"
    values     = "${var.values}"
  }
}

resource "local_file" "helm-release-yaml" {
  filename = "${var.addons_dir}/${var.namespace}-helm-release.yaml"
  content  = "${data.template_file.helm-release.rendered}"
}
