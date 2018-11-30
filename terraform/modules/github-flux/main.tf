data "template_file" "flux-yaml" {
  template = "${file("${path.module}/data/flux.yaml")}"

  vars {
    namespace = "${var.namespace}"
  }
}

resource "local_file" "flux-yaml" {
  filename = "${var.addons_dir}/${var.namespace}-flux.yaml"
  content  = "${data.template_file.flux-yaml.rendered}"
}

data "template_file" "helm-release-yaml" {
  template = "${file("${path.module}/data/helm-release.yaml")}"

  vars {
    namespace = "${var.namespace}"
    chart_git = "${var.chart_git}"
    chart_ref = "${var.chart_ref}"
    chart_path = "${var.chart_path}"
    values = "${var.values}"
  }
}

resource "local_file" "helm-release-yaml" {
  filename = "${var.addons_dir}/${var.namespace}-helm-release.yaml"
  content  = "${data.template_file.helm-release-yaml.rendered}"
}
