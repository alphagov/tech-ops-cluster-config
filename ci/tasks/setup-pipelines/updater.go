package main

import (
	"fmt"
	"path/filepath"
	"strings"

	"github.com/alphagov/gsp-teams/pkg/config"
	"github.com/concourse/atc"
)

const (
	staticRepoName    = "gsp-teams"
	staticConfigFiles = "gsp-teams/teams/%s.yaml"

	pipelinesResource    = "paroxp/concourse-pipelines-resource"
	pipelinesResourceTag = "0.0.1537562405" // TODO: We probably want to target master, remove line after all's working.

	setupPipelineTaskRepo       = "https://github.com/alphagov/gsp-teams.git"
	setupPipelineTaskRepoBranch = "develop" // TODO: We probably want to target master, remove line after all's working.
	setupPipelineTaskFile       = "gsp-teams/ci/tasks/setup-pipelines/task.yaml"

	defaultBranchName = "master"
)

func defaultBranch(s string) string {
	if s != "" {
		return s
	}

	return defaultBranchName
}

func composeConfig(teamName string, pipelines []config.Pipeline) atc.Config {
	existingRepos := map[string]bool{
		"gsp-teams": true,
	}

	preparedResources := atc.ResourceConfigs{
		atc.ResourceConfig{
			Name: "concourse-pipelines",
			Type: "concourse-pipelines-resource",
			Source: atc.Source{
				"username": "((concourse.username))",
				"password": "((concourse.password))",
				"target":   "http://concourse-web:8080",
				"insecure": true,
			},
		},
		atc.ResourceConfig{
			Name: staticRepoName,
			Type: "git",
			Source: atc.Source{
				"uri":    setupPipelineTaskRepo,
				"branch": setupPipelineTaskRepoBranch,
			},
		},
	}

	preparedJobs := atc.JobConfigs{}

	for _, pipeline := range pipelines {
		baseRepoName := filepath.Base(pipeline.Repository)
		repoName := strings.TrimSuffix(baseRepoName, filepath.Ext(baseRepoName))

		if _, ok := existingRepos[repoName]; !ok {
			preparedResources = append(atc.ResourceConfigs{
				atc.ResourceConfig{
					Name: repoName,
					Type: "git",
					Source: atc.Source{
						"uri":    pipeline.Repository,
						"branch": defaultBranch(pipeline.Branch),
					},
				},
			}, preparedResources...)

			existingRepos[repoName] = true
		}

		preparedPlans := atc.PlanSequence{
			atc.PlanConfig{
				Get:     repoName,
				Trigger: true,
			},
			atc.PlanConfig{
				Task: "prepare-pipeline",
				Params: map[string]interface{}{
					"SETUP_PIPELINE_ACTION":                   "deployer",
					"SETUP_PIPELINE_TEAM_CONFIG":              fmt.Sprintf(staticConfigFiles, teamName),
					"SETUP_PIPELINE_TEAM_NAME":                teamName,
					"SETUP_PIPELINE_DEPLOYER_PIPELINE_CONFIG": filepath.Join(repoName, pipeline.File),
					"SETUP_PIPELINE_DEPLOYER_PIPELINE_NAME":   pipeline.Name,
				},
				TaskConfigPath: setupPipelineTaskFile,
			},
			atc.PlanConfig{
				Put: "concourse-pipelines",
			},
		}

		// Make sure we're not duplicating the get resource.
		if repoName != staticRepoName {
			preparedPlans = append(atc.PlanSequence{
				atc.PlanConfig{
					Get: staticRepoName,
				},
			}, preparedPlans...)
		}

		preparedJobs = append(preparedJobs, atc.JobConfig{
			Name: fmt.Sprintf("setup-pipeline-%s", pipeline.Name),
			Plan: preparedPlans,
		})
	}

	return atc.Config{
		ResourceTypes: atc.ResourceTypes{
			atc.ResourceType{
				Name: "concourse-pipelines-resource",
				Type: "docker-image",
				Source: atc.Source{
					"repository": pipelinesResource,
					"tag":        pipelinesResourceTag,
				},
			},
		},
		Resources: preparedResources,
		Jobs:      preparedJobs,
	}
}
