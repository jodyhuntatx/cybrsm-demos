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

package vcclient

import (
	"encoding/pem"
	"fmt"
	"github.com/Venafi/vcert/pkg/venafi/tpp"
	"net/http"
	"strings"
	"time"

	"github.com/Venafi/vcert"
	"github.com/Venafi/vcert/pkg/certificate"
	"github.com/Venafi/vcert/pkg/endpoint"
	"github.com/newcontext-oss/credhub-venafi/output"
)

var origin = "NewContext Credhub-Venafi"
var CreatedAccessToken = false

// IVcertProxy defines the interface for proxies that manage requests to vcert
type IVcertProxy interface {
	PutCertificate(certName string, cert string, privateKey string) error
	List(vlimit int, zone string) ([]certificate.CertificateInfo, error)
	RetrieveCertificateByThumbprint(thumprint string) (*certificate.PEMCollection, error)
	Login() error
	Logout() error
	Revoke(thumbprint string) error
	Generate(args *CertArgs) (*certificate.PEMCollection, error)
}

// VcertProxy contains the necessary config information for a vcert proxy
type VcertProxy struct {
	Username      string
	Password      string
	Zone          string
	AccessToken   string
	LegacyAuth    bool
	Client        endpoint.Connector
	BaseURL       string
	ConnectorType string
}

// PutCertificate uploads a certificate to vcert
func (v *VcertProxy) PutCertificate(certName string, cert string, privateKey string) error {
	importReq := &certificate.ImportRequest{
		// if PolicyDN is empty, it is taken from cfg.Zone
		ObjectName:      certName,
		CertificateData: cert,
		PrivateKeyData:  privateKey,
		// Password:        "newPassw0rd!",
		Reconcile: false,
		CustomFields: []certificate.CustomField{
			{
				Type:  certificate.CustomFieldOrigin,
				Name:  "Origin",
				Value: origin,
			},
		},
	}

	importResp, err := v.Client.ImportCertificate(importReq)
	if err != nil {
		return err
	}
	output.Verbose("%+v", importResp)
	return nil
}

// List retrieves the list of certificates from vcert
func (v *VcertProxy) List(limit int, zone string) ([]certificate.CertificateInfo, error) {
	output.Info("vcert list from proxy")

	v.Client.SetZone(prependVEDRoot(zone))
	filter := endpoint.Filter{Limit: &limit, WithExpired: true}
	certInfo, err := v.Client.ListCertificates(filter)
	if err != nil {
		return []certificate.CertificateInfo{}, err
	}
	output.Verbose("certInfo %+v", certInfo)
	for a, b := range certInfo {
		output.Verbose("cert %+v %+v\n", a, b)
	}
	return certInfo, nil
}

// RetrieveCertificateByThumbprint fetches a certificate from vcert by the thumbprint
func (v *VcertProxy) RetrieveCertificateByThumbprint(thumprint string) (*certificate.PEMCollection, error) {
	pickupReq := &certificate.Request{
		Thumbprint: thumprint,
		Timeout:    180 * time.Second,
	}

	return v.Client.RetrieveCertificate(pickupReq)
}

// Login creates a session with the TPP server
func (v *VcertProxy) Login() error {
	var connectorType endpoint.ConnectorType
	auth := endpoint.Authentication{}

	switch v.ConnectorType {
	case "tpp":
		connectorType = endpoint.ConnectorTypeTPP

		if v.AccessToken != "" {
			auth = endpoint.Authentication{
				AccessToken: v.AccessToken,
			}
			output.Info("config access token\n")
		} else if v.LegacyAuth {
			output.Print("DEPRECATED: Authorizing with APIKey. Please update your TPP server.\n")
			auth = endpoint.Authentication{
				User:     v.Username,
				Password: v.Password,
			}
		} else {
			connector, err := tpp.NewConnector(v.BaseURL, v.Zone, false, nil)
			if err != nil {
				return fmt.Errorf("could not create tpp client: %s", err)
			}

			resp, err := connector.GetRefreshToken(&endpoint.Authentication{
				User: v.Username, Password: v.Password, ClientId: "vault-venafi",
				Scope: "certificate:manage,delete,discover"})
			if err != nil {
				return fmt.Errorf("could not fetch access token. Enable legacy auth support: %s", err)
			}
			CreatedAccessToken = true
			v.AccessToken = resp.Access_token
			auth = endpoint.Authentication{
				AccessToken: resp.Access_token,
			}
			output.Info("vcert created access token\n")
		}
	default:
		return fmt.Errorf("connector type '%s' not found", v.ConnectorType)
	}

	conf := vcert.Config{
		Credentials:   &auth,
		BaseUrl:       v.BaseURL,
		Zone:          v.Zone,
		ConnectorType: connectorType,
	}

	c, err := vcert.NewClient(&conf)
	if err != nil {
		return fmt.Errorf("could not connect to endpoint: %s", err)
	}
	v.Client = c

	return nil
}

// Revoke revokes a certificate in vcert (delete is not available via the api)
func (v *VcertProxy) Revoke(thumbprint string) error {
	revokeReq := &certificate.RevocationRequest{
		// CertificateDN: requestID,
		Thumbprint: thumbprint,
		Reason:     "key-compromise",
		Comments:   "revocation comment below",
		Disable:    false,
	}

	err := v.Client.RevokeCertificate(revokeReq)
	if err != nil {
		return err
	}

	output.Verbose("Successfully submitted revocation request for thumbprint %s", thumbprint)
	return nil
}

func sendCertificateRequest(c endpoint.Connector, enrollReq *certificate.Request) (requestID string, privateKey string, err error) {
	err = c.GenerateRequest(nil, enrollReq)
	if err != nil {
		return "", "", err
	}

	requestID, err = c.RequestCertificate(enrollReq)
	if err != nil {
		return "", "", err
	}

	pemBlock, err := certificate.GetPrivateKeyPEMBock(enrollReq.PrivateKey)
	if err != nil {
		return "", "", err
	}
	privateKey = string(pem.EncodeToMemory(pemBlock))

	output.Verbose("Successfully submitted certificate request. Will pickup certificate by ID %s", requestID)
	return requestID, privateKey, nil
}

// PrependPolicyRoot adds \Policy\ to the front of the zone string
func PrependPolicyRoot(zone string) string {
	zone = strings.TrimPrefix(zone, "\\")
	zone = strings.TrimPrefix(zone, "Policy\\")
	return prependVEDRoot("\\Policy\\" + zone)
}

func prependVEDRoot(zone string) string {
	zone = strings.TrimPrefix(zone, "\\")
	zone = strings.TrimPrefix(zone, "VED\\")
	return "\\VED\\" + zone
}

// logout revokes a access token in tpp (delete is not available via the tpp client library)
func (p *VcertProxy) Logout() error {
	if CreatedAccessToken {
		var bearer = "Bearer " + p.AccessToken
		req, err := http.NewRequest("GET", p.BaseURL+"/vedauth/revoke/token", nil)
		if err != nil {
			return fmt.Errorf("could not connect to access token endpoint: %s", err)
		}
		req.Header.Set("Authorization", bearer)

		// Send req using http Client
		client := &http.Client{}
		resp, err := client.Do(req)
		if err != nil {
			return fmt.Errorf("could not connect to access token endpoint endpoint: %s", err)
		}

		defer resp.Body.Close()
		output.Info("vcert revoking created access token")
	}
	return nil
}
