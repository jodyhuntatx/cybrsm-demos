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

package chclient_test

import (
	"testing"

	"github.com/newcontext-oss/credhub-venafi/chclient"
	"github.com/stretchr/testify/assert"
)

var loader = chclient.ConfigLoader{
	UserHomeDir: "../testdata/chclient",
}

var testCert string = "-----BEGIN CERTIFICATE-----\nMIIDSjCCAjKgAwIBAgIUdpQ3G/AnIilrPAsvMz3Zf9VnvWgwDQYJKoZIhvcNAQEL\nBQAwGjEYMBYGA1UEAwwPZm9vX2NlcnRpZmljYXRlMB4XDTE3MTEyMTE2MjUyMFoX\nDTE4MTEyMTE2MjUyMFowGjEYMBYGA1UEAwwPZm9vX2NlcnRpZmljYXRlMIIBIjAN\nBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwqIrV8HpCuPyuJ6VvyG7gVhYJGAO\nX4zhclxkTAKT5rkE4Lfj048GZsDghK+pHs+tVotfyrJzYGJoEBTn9Wy7kP5pQmLR\nF54imDztep15OlyoJmLZfRgct/8Kyxkjgg3PKVw68IiNhnTlYaw4CAyZ/13mvw2c\nWIYlag9LV5R2ifcyubaYllxJhdWSXrcbYxrts1kRsUQTo99jJzKu71meLigMryaM\nry8xvjv1X8Yjq3s3Lud6gWZ6BuaaaVVIjI9clGgR1MkgKJgVkWjNzDRiCxYnq1LH\nCho9bgKgiY4p604zPk9Mw4FhtCbOim6HOsHTimONZXfDNmfsJ9wJefA0UwIDAQAB\no4GHMIGEMB0GA1UdDgQWBBTyAOrrFMy88bGgEBVI4PRGD4b02jBVBgNVHSMETjBM\ngBQ3ZlJJaG9Brzf3IM6tWsMJce6YIKEepBwwGjEYMBYGA1UEAwwPZm9vX2NlcnRp\nZmljYXRlghQvHGgHfN/J7QzPNFAa0q3DwILanjAMBgNVHRMBAf8EAjAAMA0GCSqG\nSIb3DQEBCwUAA4IBAQBC1x2+E35y+iX3Mu+SWD1I3RNTGE3qKdUqj+O+QeavqCRQ\n01nolxFaSvrM/4znAlWukfp9lCOHl8foD3vHQ+meW+PlLIH9HlBjn9T3c6h4p8EQ\niYV93tyCmUlPdtzW7k4Onl3IroNNHem9Uj+OSZxGtw35YU84T+hM1kaDKtZeS1je\nFWF1W8DCORxD2rFXFwe2nJd6SSeF3KWzuKAKDqJ7CmbdRb1TtgjUym6X55SQfW2a\ndwNE+9ztMBQm4ERhwMU/NMx14UjsOPvNjF1VVei52qQ2ce7c1vgW1RI2cYFgV8q8\noFjMdJePy7eLbGRaW7Jpdy9MOiEZOj513lT5MBGk\n-----END CERTIFICATE-----"

func TestReadValidConfigFile(t *testing.T) {
	loader.CVConfigDir = "cv"
	loader.ConfigFilename = "config.json"
	c, err := loader.ReadConfig()
	assert.Nil(t, err, "It should not raise an error with a valid config file")
	assert.Contains(t, c.AccessToken, "eyJhbGciOiJSUzI1Ni", "It should read the access token from the file")
}

func TestReadMissingConfigDir(t *testing.T) {
	loader.CVConfigDir = "missing"
	loader.ConfigFilename = "config.json"
	_, err := loader.ReadConfig()
	assert.NotNil(t, err, "It should raise an error with a missing config directory")
}

func TestReadMissingConfigFile(t *testing.T) {
	loader.CVConfigDir = "cv"
	loader.ConfigFilename = "missing.json"
	_, err := loader.ReadConfig()
	assert.NotNil(t, err, "It should raise an error with a missing config file")
}

func TestReadInvalidConfigFile(t *testing.T) {
	loader.CVConfigDir = "cv"
	loader.ConfigFilename = "empty.json"
	_, err := loader.ReadConfig()
	assert.NotNil(t, err, "It should raise an error with a missing config file")
}

func TestGetThumbprint(t *testing.T) {
	expected := [20]uint8{0xeb, 0xdb, 0xe3, 0x2e, 0xf9, 0x89, 0x91, 0x69, 0x59, 0x58, 0xea, 0x25, 0x10, 0x28, 0x7f, 0xe, 0x6c, 0x52, 0xa4, 0x83}
	actual, _ := chclient.GetThumbprint(testCert)
	assert.Equal(t, expected, actual, "It should calculate the correct thumbprint")
}