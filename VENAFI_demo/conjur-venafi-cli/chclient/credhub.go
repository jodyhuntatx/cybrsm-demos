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

package chclient

import (
	"crypto/sha1"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path"
	"path/filepath"
	"strings"

	"code.cloudfoundry.org/credhub-cli/credhub"
	"code.cloudfoundry.org/credhub-cli/credhub/auth"
	"code.cloudfoundry.org/credhub-cli/credhub/auth/uaa"
	"code.cloudfoundry.org/credhub-cli/credhub/credentials"
	"code.cloudfoundry.org/credhub-cli/credhub/credentials/generate"
	"code.cloudfoundry.org/credhub-cli/credhub/credentials/values"
	"github.com/newcontext-oss/credhub-venafi/output"
)

// ConfigLoader has configuration location info and methods to load the config
type ConfigLoader struct {
	UserHomeDir    string
	CVConfigDir    string
	ConfigFilename string
}

// ReadConfig parses the CredHub client config file
func (c *ConfigLoader) ReadConfig() (*CVConfig, error) {
	configdir := filepath.Join(c.UserHomeDir, c.CVConfigDir)
	if _, err := os.Stat(configdir); os.IsNotExist(err) {
		return nil, fmt.Errorf("no config dir %s %s", configdir, err)
	}

	cvConfig := CVConfig{}
	file, err := ioutil.ReadFile(path.Join(configdir, c.ConfigFilename))
	if err != nil {
		return nil, err
	}

	err = json.Unmarshal([]byte(file), &cvConfig)
	if err != nil {
		return nil, err
	}
	return &cvConfig, nil
}

// CVConfig contains app config info and yaml tags
type CVConfig struct {
	AccessToken       string `json:"access_token"`
	RefreshToken      string `json:"refresh_token"`
	CredhubBaseURL    string `json:"credhub_url"`
	AuthURL           string `json:"auth_url"`
	SkipTLSValidation bool   `json:"skip_tls_validation"`
}

// ICredhubProxy defines the interface for the proxy to communicate with Credhub
type ICredhubProxy interface {
	GenerateCertificate(name string, parameters generate.Certificate, overwrite credhub.Mode) (credentials.Certificate, error)
	PutCertificate(certName string, ca string, certificate string, privateKey string) error
	DeleteCert(name string) error
	List() ([]credentials.CertificateMetadata, error)
	GetCertificate(name string) (credentials.Certificate, error)
}

// CredhubProxy contains the config information for the Credhub request proxy
type CredhubProxy struct {
	BaseURL           string
	Username          string
	Password          string
	ClientID          string
	ClientSecret      string
	AccessToken       string
	RefreshToken      string
	AuthURL           string
	Client            *credhub.CredHub
	ConfigPath        string
	SkipTLSValidation bool
}

// GenerateCertificate generates a certificate in CredHub
func (cp *CredhubProxy) GenerateCertificate(name string, parameters generate.Certificate, overwrite credhub.Mode) (credentials.Certificate, error) {
	newCert, err := cp.Client.GenerateCertificate(name, parameters, overwrite)
	output.Verbose("newCert %+v", newCert)
	return newCert, err
}

// PutCertificate uploads a certificate to CredHub
func (cp *CredhubProxy) PutCertificate(certName string, ca string, certificate string, privateKey string) error {
	c := values.Certificate{}
	c.Ca = ca
	c.Certificate = certificate
	c.PrivateKey = privateKey
	newCert, err := cp.Client.SetCertificate(certName, c)
	_ = newCert
	if err != nil {
		return nil
	}
	return nil
}

// DeleteCert deletes a certificate from CredHub
func (cp *CredhubProxy) DeleteCert(name string) error {
	return cp.Client.Delete(name)
}

// List lists certificates on CredHub
func (cp *CredhubProxy) List() ([]credentials.CertificateMetadata, error) {
	certs, err := cp.Client.GetAllCertificatesMetadata()
	if err != nil {
		return nil, err
	}

	return certs, nil
}

// GetCertificate downloads a certificate from CredHub
func (cp *CredhubProxy) GetCertificate(name string) (credentials.Certificate, error) {
	cred, err := cp.Client.GetLatestCertificate(name)
	if err != nil {
		return credentials.Certificate{}, err
	}
	return cred, nil
}

// GetThumbprint calculates the thumbprint of a certificate in CredHub
func GetThumbprint(cert string) ([sha1.Size]byte, error) {
	certStr := strings.ReplaceAll(cert, "-----BEGIN CERTIFICATE-----", "")
	certStr = strings.ReplaceAll(certStr, "-----END CERTIFICATE-----", "")
	certStr = strings.ReplaceAll(certStr, "\n", "")

	data, err := base64.StdEncoding.DecodeString(certStr)
	if err != nil {
		return [20]byte{}, err
	}

	return sha1.Sum(data), nil
}

// AuthExisting authenticates an existing CredHub client
func (cp *CredhubProxy) AuthExisting() error {
	var err error
	cp.Client, err = credhub.New(cp.BaseURL,
		credhub.SkipTLSValidation(cp.SkipTLSValidation),
		credhub.Auth(auth.Uaa(
			cp.ClientID,
			cp.ClientSecret,
			cp.Username,
			cp.Password,
			cp.AccessToken,
			cp.RefreshToken,
			false,
		)),
		credhub.AuthURL(cp.AuthURL),
	)

	return err
}

// Auth authenticates a new CredHub client
func (cp *CredhubProxy) Auth() error {
	ch, err := credhub.New(cp.BaseURL,
		credhub.SkipTLSValidation(cp.SkipTLSValidation),
		credhub.Auth(auth.UaaPassword(cp.ClientID, cp.ClientSecret, cp.Username, cp.Password)))
	if err != nil {
		return err
	}
	AuthURL, err := ch.AuthURL()
	if err != nil {
		return err
	}

	uaaClient := uaa.Client{
		AuthURL: AuthURL,
		Client:  ch.Client(),
	}

	if cp.ClientID != "" {
		cp.AccessToken, err = uaaClient.ClientCredentialGrant(cp.ClientID, cp.ClientSecret)
		if err != nil {
			return err
		}
	} else {
		if cp.ClientID == "" {
			// default value to be used
			cp.ClientID = "credhub_cli"
		}
		cp.AccessToken, cp.RefreshToken, err = uaaClient.PasswordGrant(cp.ClientID, cp.ClientSecret, cp.Username, cp.Password)
		if err != nil {
			return err
		}
	}

	// ensure the .cv directory is created
	home, err := os.UserHomeDir()
	if err != nil {
		return err
	}

	homedir := filepath.Join(home, cp.ConfigPath)
	if _, err := os.Stat(homedir); os.IsNotExist(err) {
		os.Mkdir(homedir, os.ModePerm)
	}

	if err != nil {
		return err
	}

	// write out the config file with the access token and refresh
	// write out as json for now
	// our config will just be a struct for now
	cvConfig := CVConfig{AccessToken: cp.AccessToken, RefreshToken: cp.RefreshToken, CredhubBaseURL: cp.BaseURL, AuthURL: AuthURL, SkipTLSValidation: cp.SkipTLSValidation}

	b, err := json.Marshal(&cvConfig)
	if err != nil {
		return err
	}

	err = ioutil.WriteFile(filepath.Join(homedir, "config.json"), b, os.ModePerm)
	if err != nil {
		return err
	}

	cp.Client, err = credhub.New(cp.BaseURL,
		credhub.SkipTLSValidation(cp.SkipTLSValidation),
		credhub.Auth(auth.Uaa(
			cp.ClientID,
			cp.ClientSecret,
			cp.Username,
			cp.Password,
			cp.AccessToken,
			cp.RefreshToken,
			false,
		)),
	)
	if err != nil {
		return err
	}
	return nil
}
