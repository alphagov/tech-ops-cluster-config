data "template_file" "flux-yaml" {
  template = "${file("${path.module}/data/flux.yaml")}"

  vars {
    namespace = "${var.namespace}"
  }
}

resource "local_file" "flux-helm-yaml" {
  filename = "flux-helm/${var.namespace}.yaml"
  content  = "${data.template_file.flux-yaml.rendered}"
}
