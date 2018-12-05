resource "aws_codecommit_repository" "canary" {
  repository_name = "gsp-canary-chart-${var.cluster_id}"
}

resource "local_file" "namespace" {
  filename = "${var.addons_dir}/gsp-canary-namespace.yaml"
  content  = "${file("${path.module}/data/namespace.yaml")}"
}

data "template_file" "helm-release" {
  template = "${file("${path.module}/data/helm-release.yaml")}"

  vars {
    namespace  = "gsp-canary"
    chart_git  = "${aws_codecommit_repository.canary.clone_url_http}"
    chart_ref  = "master"
    chart_path = "charts/gsp-canary"
  }
}

resource "local_file" "helm-release-yaml" {
  filename = "${var.addons_dir}/gsp-canary-helm-release.yaml"
  content  = "${data.template_file.helm-release.rendered}"

  provisioner "local-exec" {
    command = "../../../scripts/initialise_canary_helm_codecommit.sh"

    environment {
      SOURCE_REPO_URL     = "https://github.com/alphagov/gsp-canary-chart"
      CODECOMMIT_REPO_URL = "${aws_codecommit_repository.canary.clone_url_http}"
    }
  }
}
