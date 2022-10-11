// Copyright 2020 New Context, Inc.
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

package output_test

import (
	"bytes"
	"log"
	"strings"
	"testing"

	"github.com/newcontext-oss/credhub-venafi/config"
	"github.com/newcontext-oss/credhub-venafi/output"
	"github.com/stretchr/testify/assert"
)

func TestCenteredString(t *testing.T) {
	in := "center"
	desired := "  center  "
	actual := output.CenteredString(in, 10)
	assert.Equal(t, desired, actual, "It should center the string with space-padding")
}

func TestVerbose(t *testing.T) {
	var str bytes.Buffer
	msg := "Verbose level log"
	log.SetOutput(&str)
	config.LogLevel = config.VERBOSE
	output.Verbose(msg)
	assert.Contains(t, strings.TrimSuffix(str.String(), "\n"), "Verbose", "It should emit a log when level is VERBOSE")
	str.Reset()
	config.LogLevel = config.VERBOSE - 1
	output.Verbose(msg)
	assert.Equal(t, strings.TrimSuffix(str.String(), "\n"), "", "It should not emit a log when level is lower")
	str.Reset()
	config.LogLevel = config.VERBOSE + 1
	output.Verbose(msg)
	assert.Contains(t, strings.TrimSuffix(str.String(), "\n"), "Verbose", "It should emit a log when level is higher")
}

func TestInfo(t *testing.T) {
	var str bytes.Buffer
	msg := "Info level log"
	log.SetOutput(&str)
	config.LogLevel = config.INFO
	output.Info(msg)
	assert.Contains(t, strings.TrimSuffix(str.String(), "\n"), "Info", "It should emit a log when level is INFO")
	str.Reset()
	config.LogLevel = config.INFO - 1
	output.Info(msg)
	assert.Equal(t, strings.TrimSuffix(str.String(), "\n"), "", "It should not emit a log when level is lower")
	str.Reset()
	config.LogLevel = config.INFO + 1
	output.Info(msg)
	assert.Contains(t, strings.TrimSuffix(str.String(), "\n"), "Info", "It should emit a log when level is higher")
}

func TestStatus(t *testing.T) {
	var str bytes.Buffer
	msg := "Status level log"
	log.SetOutput(&str)

	config.LogLevel = config.STATUS
	output.Status(msg)
	assert.Contains(t, strings.TrimSuffix(str.String(), "\n"), "Status", "It should emit a log when level is STATUS")
	str.Reset()
	output.Print(msg)
	assert.Contains(t, strings.TrimSuffix(str.String(), "\n"), "Status", "It should emit a log when level is STATUS")
	str.Reset()

	config.LogLevel = config.STATUS - 1
	output.Status(msg)
	assert.Equal(t, strings.TrimSuffix(str.String(), "\n"), "", "It should not emit a log when level is lower")
	str.Reset()
	output.Print(msg)
	assert.Equal(t, strings.TrimSuffix(str.String(), "\n"), "", "It should not emit a log when level is lower")
	str.Reset()

	config.LogLevel = config.STATUS + 1
	output.Status(msg)
	assert.Contains(t, strings.TrimSuffix(str.String(), "\n"), "Status", "It should emit a log when level is higher")
	str.Reset()
	output.Print(msg)
	assert.Contains(t, strings.TrimSuffix(str.String(), "\n"), "Status", "It should emit a log when level is STATUS")
}

func TestError(t *testing.T) {
	var str bytes.Buffer
	msg := "Error level log"
	log.SetOutput(&str)
	config.LogLevel = config.ERROR
	output.Errorf(msg)
	assert.Contains(t, strings.TrimSuffix(str.String(), "\n"), "Error", "It should emit a log when level is ERROR")
	str.Reset()
	config.LogLevel = config.ERROR - 1
	output.Errorf(msg)
	assert.Equal(t, strings.TrimSuffix(str.String(), "\n"), "", "It should not emit a log when level is lower")
	str.Reset()
	config.LogLevel = config.ERROR + 1
	output.Errorf(msg)
	assert.Contains(t, strings.TrimSuffix(str.String(), "\n"), "Error", "It should emit a log when level is higher")
}
