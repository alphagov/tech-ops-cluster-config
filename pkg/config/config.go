package config

// Pipeline defines the structure of each pipeline element in the team
// configuration.
type Pipeline struct {
	Name       string `yaml:"name"`
	Repository string `yaml:"repository"`
	Branch     string `yaml:"branch"`
	File       string `yaml:"file"`
}

// Kubestate defines the structure of each kubernetes element in the team
// configuration.
type Kubestate struct {
	Repository string `yaml:"repository"`
	File       string `yaml:"file,omitempty"`
	Directory  string `yaml:"directory,omitempty"`
}

// GithubAuth defines the structure of Github Auth configuration in a single
// team config.
type GithubAuth struct {
	Organisation string `json:"organisation"`
	Team         string `json:"team"`
}

// Auth defines the structure of each team configuration.
type Auth struct {
	Type   string     `yaml:"type"`
	Github GithubAuth `yaml:"github,omitempty"`
	Team   string     `yaml:"team,omitempty"`
}

// Team defines a single team when configuring the GSP system.
type Team struct {
	Name       string      `yaml:"name"`
	Contact    string      `yaml:"contact"`
	Pipelines  []Pipeline  `yaml:"pipelines,omitempty"`
	Kubernetes []Kubestate `yaml:"kubernetes,omitempty"`
	Auth       Auth        `yaml:"auth"`
}
