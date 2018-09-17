package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"

	"github.com/alphagov/gsp-teams/pkg/config"

	yaml "gopkg.in/yaml.v2"
)

var (
	dirPath    = flag.String("dir", "./teams", "Path to the location containing all teams configuration files.")
	outputFile = flag.String("output", "", "File desitnation the new data should be written into.")
)

type resource struct {
	Name string              `json:"name"`
	Auth map[string][]string `json:"auth"`
}

// Main ... Why is that exproted?
func Main() error {
	if *dirPath == "" {
		return fmt.Errorf("-dir flag pointing to directory of team config files is %s", "required")
	}

	path := filepath.Join(*dirPath, "*.yaml")
	filenames, err := filepath.Glob(path)
	if err != nil {
		return fmt.Errorf("cannot glob directory '%s' for team config files: %s", *dirPath, err)
	}

	list := []resource{}
	for _, filename := range filenames {
		setup, err := ioutil.ReadFile(filename)
		if err != nil {
			return fmt.Errorf("cannot read file: %s", err)
		}

		team := config.Team{}
		err = yaml.Unmarshal(setup, &team)
		if err != nil {
			return fmt.Errorf("cannot unmarshal team config: %s", err)
		}

		list = append(list, resource{
			Name: team.Name,
			Auth: map[string][]string{
				"github": []string{fmt.Sprintf("team:%s:%s", team.Auth.Github.Organisation, team.Auth.Github.Team)},
			},
		})
	}

	j, err := json.Marshal(list)
	if err != nil {
		return fmt.Errorf("unable to marshal teams in resource friendly format: %s", err)
	}

	if *outputFile != "" {
		file, err := os.Create(*outputFile)
		if err != nil {
			return fmt.Errorf("failed to create file: %s", err)
		}

		err = json.NewEncoder(file).Encode(list)
		if err != nil {
			return fmt.Errorf("failed to encode list of teams into file: %s", err)
		}
	} else {
		fmt.Fprintf(os.Stdout, "%s", j)
	}

	return nil
}

func main() {
	flag.Parse()

	err := Main()
	if err != nil {
		log.Fatal(err)
	}
}
