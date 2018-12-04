variable "namespace" {
    description = "namespace to deploy into"
    type = "string"
}

variable "chart_git" {
    description = "git repository containing helm chart to watch/deploy"
    type = "string"
}

variable "chart_ref" {
    description = "git ref/branch to watch"
    type = "string"
}

variable "chart_path" {
    description = "path within the git repository to a helm chart to deploy"
    type = "string"
}

variable "addons_dir" {
    description = "local target path to place kubernetes resource yaml"
    type = "string"
    default = "addons"
}
