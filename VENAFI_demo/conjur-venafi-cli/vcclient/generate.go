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

package vcclient

// This file contains the code supporting the "Generate" function.  It's in its own file to
// try to make it easier to understand.

import (
	"crypto/x509/pkix"
	"fmt"
	"net"
	"time"

	"github.com/Venafi/vcert/pkg/certificate"
)

// CertArgs holds the arguments for certificate creation in vcert
type CertArgs struct {
	Name               string
	CommonName         string
	OrganizationName   string
	SANDNS             []string
	KeyCurve           certificate.EllipticCurve
	OrganizationalUnit []string
	Origin             string
	Country            string
	State              string
	Locality           string
	SANEmail           []string
	SANIP              []net.IP
	KeyPassword        string
}

// Generate generates a certificate in vcert
func (v *VcertProxy) Generate(args *CertArgs) (*certificate.PEMCollection, error) {
	req, err := buildGenerateRequest(args)
	if err != nil {
		return nil, err
	}

	requestID, privateKey, err := sendCertificateRequest(v.Client, req)
	if err != nil {
		return nil, err
	}

	pickupReq := &certificate.Request{
		PickupID: requestID,
		Timeout:  180 * time.Second,
	}

	pcc, err := v.Client.RetrieveCertificate(pickupReq)
	if err != nil {
		return nil, fmt.Errorf("could not retrieve certificate using requestId %s: %s", requestID, err)
	}
	pcc.PrivateKey = privateKey
	return pcc, nil
}

func buildGenerateRequest(v *CertArgs) (*certificate.Request, error) {
	r := &certificate.Request{}
	r.FriendlyName = v.Name

	subject := pkix.Name{}
	if v.CommonName != "" {
		subject.CommonName = v.CommonName
	}
	if v.OrganizationName != "" {
		subject.Organization = []string{v.OrganizationName}
	}
	if len(v.SANDNS) != 0 {
		r.DNSNames = v.SANDNS
	}
	r.KeyCurve = v.KeyCurve
	if len(v.OrganizationalUnit) > 0 {
		subject.OrganizationalUnit = v.OrganizationalUnit
	}
	if v.Country != "" {
		subject.Country = []string{v.Country}
	}
	if v.State != "" {
		subject.Province = []string{v.State}
	}
	if v.Locality != "" {
		subject.Locality = []string{v.Locality}
	}
	if len(v.SANEmail) > 0 {
		r.EmailAddresses = v.SANEmail
	}
	if len(v.SANIP) > 0 {
		r.IPAddresses = v.SANIP
	}
	if v.KeyPassword == "" {
		r.KeyPassword = v.KeyPassword
	}
	r.Subject = subject

	r.CustomFields = append(r.CustomFields, certificate.CustomField{
		Type:  certificate.CustomFieldOrigin,
		Name:  "Origin",
		Value: origin,
	})

	return r, nil
}
