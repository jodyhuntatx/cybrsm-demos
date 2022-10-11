// Copyright 2019 New Context, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package config_test

import (
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/newcontext-oss/credhub-venafi/config"
)

var dataDir string = "../testdata/config"

func TestReadConfigWithValidFile(t *testing.T) {
	desired := &config.YAMLConfig{
		VcertUsername:    "test",
		VcertPassword:    "test",
		VcertZone:        "some_zone",
		VcertBaseURL:     "some_url",
		VcertAccessToken: "access_token",
		VcertLegacyAuth:  false,
		ConnectorType:    "tpp",
		ClientID:         "some_id",
		ClientSecret:     "some_secret",
		CredhubUsername:  "test2",
		CredhubPassword:  "test2",
		CredhubEndpoint:  "some_other_url",
		LogLevel:         "info",
	}
	actual, err := config.ReadConfig(dataDir, "test_config.yml")
	if err != nil {
		t.Fail()
		t.Logf("Failed to create config from file: %s", err)
	}
	assert.Equal(t, desired, actual, "It should create a valid config from a yaml file")
}

func TestReadConfigWithMissingFile(t *testing.T) {
	_, err := config.ReadConfig(dataDir, "missing.yml")
	assert.NotNil(t, err, "It should raise an error when the config file is missing")
}

func TestReadConfigWithInvalidFile(t *testing.T) {
	_, err := config.ReadConfig(dataDir, "test_config_invalid.yml")
	assert.NotNil(t, err, "It should raise an error when the config file is invalid")
}
