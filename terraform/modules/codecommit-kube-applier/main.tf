resource "aws_codecommit_repository" "repo" {
  repository_name = "${var.repository_name}"
  description     = "${var.repository_description}"
}

data "template_file" "kube-applier-yaml" {
    template = "${file("${path.module}/data/kube-applier.yaml")}"

    vars {
        git_repo = "${aws_codecommit_repository.repo.clone_url_http}"
        namespace = "${var.namespace}"
    }
}

resource "local_file" "kube-applier-yaml" {
    filename = "${var.namespace}-kube-applier.yaml"
    content = "${data.template_file.kube-applier-yaml.rendered}"
}

output "repo_url" {
    value = "${aws_codecommit_repository.repo.clone_url_http}"
}
