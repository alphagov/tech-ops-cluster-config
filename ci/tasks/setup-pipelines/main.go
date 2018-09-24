package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"

	"github.com/alphagov/gsp-teams/pkg/config"
	"github.com/concourse/atc"

	kingpin "gopkg.in/alecthomas/kingpin.v2"
	yaml "gopkg.in/yaml.v2"
)

var (
	app = kingpin.New("setup-pipelines", "A command-line tool to create a Pipeline Updater or Deploy defined pipelines.")

	configFileMatch = app.Flag("config", "Path to the location of team configuration file. Glob matcher accepted.").Short('c').OverrideDefaultFromEnvar("SETUP_PIPELINE_TEAM_CONFIG").Required().String()
	teamOverwrite   = app.Flag("team", "Force the pipelines to be deployed in specific team.").Short('t').OverrideDefaultFromEnvar("SETUP_PIPELINE_TEAM_NAME").String()
	pausedPipeline  = app.Flag("paused", "Pause pipelines on set.").OverrideDefaultFromEnvar("SETUP_PIPELINE_PAUSED").Bool()
	outputFile      = app.Flag("output", "File desitnation the new data should be written into.").Short('o').Default("concourse-pipelines/pipelines.json").OverrideDefaultFromEnvar("SETUP_PIPELINE_OUTPUT").String()

	updater        = app.Command("updater", "Command to setup the pipeline updater.")
	groupPipelines = updater.Flag("group", "Force pipelines to be deployed as one.").Short('g').OverrideDefaultFromEnvar("SETUP_PIPELINE_UPDATER_GROUP").Bool()

	deployer               = app.Command("deployer", "Command to setup the pipeline deployer.")
	deployerPipelineConfig = deployer.Flag("pipeline-config", "Path to pipeline configuration file.").Short('p').OverrideDefaultFromEnvar("SETUP_PIPELINE_DEPLOYER_PIPELINE_CONFIG").Required().String()
	deployerPipelineName   = deployer.Flag("pipeline", "Pipeline name.").Short('n').OverrideDefaultFromEnvar("SETUP_PIPELINE_DEPLOYER_PIPELINE_NAME").Required().String()
)

type resource struct {
	Config   atc.Config   `json:"config"`
	Pipeline atc.Pipeline `json:"pipeline"`
}

func setTeamName(t string) string {
	if *teamOverwrite != "" {
		return *teamOverwrite
	}

	return t
}

func setPipelineName(p string) string {
	if *teamOverwrite != "" {
		return fmt.Sprintf("setup-pipelines-%s", *teamOverwrite)
	}

	return p
}

// Main ... Why is that exproted?
func Main() error {
	action := kingpin.MustParse(app.Parse(os.Args[1:]))
	list := []resource{}

	teamConfigFiles, err := filepath.Glob(*configFileMatch)
	if err != nil {
		return fmt.Errorf("cannot glob '%s' for team config files: %s", *configFileMatch, err)
	}

	for _, teamConfigFilename := range teamConfigFiles {
		teamFile, err := ioutil.ReadFile(teamConfigFilename)
		if err != nil {
			return fmt.Errorf("cannot read file: %s", err)
		}

		team := config.Team{}
		err = yaml.Unmarshal(teamFile, &team)
		if err != nil {
			return fmt.Errorf("cannot unmarshal team config: %s", err)
		}

		if team.Pipelines == nil {
			continue
		}

		switch action {
		case updater.FullCommand():
			if *groupPipelines {
				list = append(list, resource{
					Config: composeConfig(team.Name, team.Pipelines),
					Pipeline: atc.Pipeline{
						Name:     fmt.Sprintf("setup-pipelines-%s", team.Name),
						TeamName: setTeamName(team.Name),
						Paused:   *pausedPipeline,
					},
				})
			} else {
				for _, pipeline := range team.Pipelines {
					list = append(list, resource{
						Config: composeConfig(team.Name, []config.Pipeline{pipeline}),
						Pipeline: atc.Pipeline{
							Name:     pipeline.Name,
							TeamName: setTeamName(team.Name),
							Paused:   *pausedPipeline,
						},
					})
				}
			}

			break
		case deployer.FullCommand():
			pipelineConfigFile, err := ioutil.ReadFile(*deployerPipelineConfig)
			if err != nil {
				return fmt.Errorf("cannot read file '%s': %s", *deployerPipelineConfig, err)
			}

			pipelineConfig := atc.Config{}
			if err = yaml.Unmarshal(pipelineConfigFile, &pipelineConfig); err != nil {
				return fmt.Errorf("cannot unmarshal pipeline config: %s", err)
			}

			list = append(list, resource{
				Config: pipelineConfig,
				Pipeline: atc.Pipeline{
					Name:     *deployerPipelineName,
					TeamName: setTeamName(team.Name),
					Paused:   *pausedPipeline,
					Public:   true,
				},
			})

			break
		default:
			return fmt.Errorf("unknown command: '%s'", os.Args[1:])
		}
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
		resourcePlan, err := json.Marshal(list)
		if err != nil {
			return fmt.Errorf("unable to marshal teams in resource friendly format: %s", err)
		}

		fmt.Fprintf(os.Stdout, "%s", resourcePlan)
	}

	return nil
}

func main() {
	err := Main()
	if err != nil {
		log.Fatal(err)
	}
}
