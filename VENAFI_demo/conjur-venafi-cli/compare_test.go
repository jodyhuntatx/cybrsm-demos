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

package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"path/filepath"
	"strings"
	"testing"

	"code.cloudfoundry.org/credhub-cli/credhub"
	"code.cloudfoundry.org/credhub-cli/credhub/credentials"
	"code.cloudfoundry.org/credhub-cli/credhub/credentials/generate"
	"code.cloudfoundry.org/credhub-cli/credhub/credentials/values"
	"github.com/Venafi/vcert/pkg/certificate"
	"github.com/newcontext-oss/credhub-venafi/chclient"
	"github.com/newcontext-oss/credhub-venafi/output"
	"github.com/newcontext-oss/credhub-venafi/vcclient"
)

func TestCmpMethod(t *testing.T) {
	comparison := func(l string, r string) int {
		return strings.Compare(l, r)
	}
	a := "a"
	b := "b"
	fmt.Printf("%s and %s cmp  %b", a, b, comparison(a, b))
	// -1
}

func TestCmp3(t *testing.T) {
	comparison := func(l string, r string) int {
		return strings.Compare(l, r)
	}
	comparesides2([]string{"a", "b"}, []string{"c", "d"}, comparison)
	comparesides2([]string{"a", "c"}, []string{"b", "d"}, comparison)
	comparesides2([]string{}, []string{"a", "b", "c", "d"}, comparison)
	comparesides2([]string{"a", "b", "c", "d"}, []string{}, comparison)
	comparesides2([]string{"a"}, []string{"b", "c", "d"}, comparison)
	comparesides2([]string{"a", "b", "c"}, []string{"d"}, comparison)
}

type TestCertCollector struct {
	values   []string
	leftGet  func(certificate.CertificateInfo) string
	rightGet func(credentials.CertificateMetadata) string
}

func (m *TestCertCollector) CertificateInfo(ci certificate.CertificateInfo) {
	if m.leftGet == nil {
		m.leftGet = func(l certificate.CertificateInfo) string {
			return l.CN
		}
	}
	fmt.Printf(".")
	m.values = append(m.values, m.leftGet(ci))
}

func (m *TestCertCollector) CertificateMetadata(cm credentials.CertificateMetadata) {
	if m.rightGet == nil {
		m.rightGet = func(r credentials.CertificateMetadata) string {
			return r.Name
		}
	}
	fmt.Printf(".")
	m.values = append(m.values, m.rightGet(cm))
}

func (m *TestCertCollector) Equals(ci certificate.CertificateInfo, cm credentials.CertificateMetadata) {
	fmt.Printf(".")
	m.values = append(m.values, m.leftGet(ci)+"="+m.rightGet(cm))
}

func TestExtractLastSegment(t *testing.T) {
	lastsegment := extractLastSegment("/thelast")
	if lastsegment != "thelast" {
		t.Errorf("last segment value was %s instead of thelast", lastsegment)
	}
}

type TestStructMember struct {
	a string
}

type TestStruct struct {
	left  *TestStructMember
	right *TestStructMember
}

func TestJsonSerialize(t *testing.T) {
	s := TestStruct{
		left:  &TestStructMember{a: "left"},
		right: &TestStructMember{a: "right"},
	}
	a := []TestStruct{s}
	bytes, err := json.Marshal(a)
	if err != nil {
		fmt.Println("e", err)
	}
	fmt.Println("s", string(bytes))
}

func jsonUnmarshallFromFile(v interface{}, filename string) {
	path := filepath.Join("testdata", filename)
	dat, err := ioutil.ReadFile(path)
	if err != nil {
		fmt.Println("err", err)
		return
	}

	err = json.Unmarshal(dat, v)
	if err != nil {
		fmt.Println("e", err)
		return
	}
}

func TestCompareCerts(t *testing.T) {
	certInfo := []certificate.CertificateInfo{}
	items := []credentials.CertificateMetadata{}
	jsonUnmarshallFromFile(&certInfo, "certinfo.json")
	jsonUnmarshallFromFile(&items, "chitems.json")

	ct := CommonNameStrategy{}
	certCompare := compareCerts(&ct, certInfo, items, "", "")
	assertLenEquals(t, len(certCompare), 4)
	assertStringEquals(t, certCompare[0].Left.CN, "TestCertb")
	assertStringContains(t, certCompare[0].Right.Name, "TestCertb")
	assertStringEquals(t, certCompare[1].Left.CN, "TestCommonName")
	assertStringContains(t, certCompare[1].Right.Name, "TestCommonName")
	assertTrue(t, certCompare[2].Left == nil)
	assertStringEquals(t, certCompare[2].Right.Name, "/aname")
	assertStringEquals(t, certCompare[3].Left.CN, "localhost")
	assertTrue(t, certCompare[3].Right == nil)
}

func assertTrue(t *testing.T, result bool) {
	t.Helper()
	if !result {
		t.Errorf("expected true but was false")
	}
}

func assertStringEquals(t *testing.T, expected, actual string) {
	t.Helper()
	if expected != actual {
		t.Errorf("expected '%s' but was '%s'", expected, actual)
	}
}

func assertStringContains(t *testing.T, actual, shouldContain string) {
	t.Helper()
	if !strings.Contains(actual, shouldContain) {
		t.Errorf("expected to contain '%s' but was '%s'", shouldContain, actual)
	}
}

func assertLenEquals(t *testing.T, expected, actual int) {
	t.Helper()
	if expected != actual {
		t.Errorf("expected length of %d but was %d", expected, actual)
	}
}

func TestComparePathPrefixTransform(t *testing.T) {
	tctWithPrefix := PathStrategy{leftPrefix: "\\FRED", rightPrefix: "\\VED"}
	tctEmpty := PathStrategy{}

	tests := []struct {
		tct   ComparisonStrategy
		left  []string
		right []string
		out   []string
	}{
		{
			&tctEmpty,
			[]string{
				"\\VED\\Policy\\Certificates\\Division 3\\TestCerta",
				"\\VED\\Policy\\Certificates\\Division 3\\localhost",
				"\\VED\\Policy\\Certificates\\Division 3\\TestCertb"},
			[]string{
				"\\VED\\Policy\\Certificates\\Division 3\\localhost",
				"\\VED\\Policy\\Certificates\\Division 3\\TestCerta",
				"\\VED\\Policy\\Certificates\\Division 3\\TestCertb"},
			[]string{
				"\\VED\\Policy\\Certificates\\Division 3\\TestCerta=\\VED\\Policy\\Certificates\\Division 3\\TestCerta",
				"\\VED\\Policy\\Certificates\\Division 3\\TestCertb=\\VED\\Policy\\Certificates\\Division 3\\TestCertb",
				"\\VED\\Policy\\Certificates\\Division 3\\localhost=\\VED\\Policy\\Certificates\\Division 3\\localhost"}},
		{
			&tctWithPrefix,
			[]string{
				"\\FRED\\Policy\\Certificates\\Division 3\\TestCerta",
				"\\FRED\\Policy\\Certificates\\Division 3\\localhost",
				"\\FRED\\Policy\\Certificates\\Division 3\\TestCertb"},
			[]string{
				"\\VED\\Policy\\Certificates\\Division 3\\localhost",
				"\\VED\\Policy\\Certificates\\Division 3\\TestCerta",
				"\\VED\\Policy\\Certificates\\Division 3\\TestCertb"},
			[]string{
				"\\FRED\\Policy\\Certificates\\Division 3\\TestCerta=\\VED\\Policy\\Certificates\\Division 3\\TestCerta",
				"\\FRED\\Policy\\Certificates\\Division 3\\TestCertb=\\VED\\Policy\\Certificates\\Division 3\\TestCertb",
				"\\FRED\\Policy\\Certificates\\Division 3\\localhost=\\VED\\Policy\\Certificates\\Division 3\\localhost"}},
	}

	runTests := func() {
		for _, test := range tests {
			left := []certificate.CertificateInfo{}
			for _, item := range test.left {
				left = append(left, certificate.CertificateInfo{ID: item})
			}
			right := []credentials.CertificateMetadata{}
			for _, item := range test.right {
				right = append(right, credentials.CertificateMetadata{Name: item})
			}

			comparison := buildCompareTransform(test.tct)

			compare := func(
				l []certificate.CertificateInfo,
				r []credentials.CertificateMetadata,
				comparison func(certificate.CertificateInfo, credentials.CertificateMetadata) int, tc CertCollector) {
				compareLists(l, r, comparison, tc, test.tct)
			}

			tc := &TestCertCollector{leftGet: test.tct.leftGet, rightGet: test.tct.rightGet}
			compare(left, right, comparison, tc)

			assertStringSliceEqual(t, test.out, tc.values)
		}
	}

	runTests()
}

func TestCompareTransformCommonName(t *testing.T) {
	tests := []struct {
		left  []string
		right []string
		out   []string
	}{
		{[]string{"TestCommonName"}, []string{"/booyah/TestCommonName_20nov25_DE13"}, []string{"TestCommonName=/booyah/TestCommonName_20nov25_DE13"}},
		{[]string{"TestCommonName", "abc", "zoo"}, []string{"/booyah/TestCommonName_20nov25_DE13", "def", "/zoo"}, []string{"TestCommonName=/booyah/TestCommonName_20nov25_DE13", "abc", "def", "zoo=/zoo"}},
	}

	tct := CommonNameStrategy{}
	comparison := buildCompareTransform(&tct)

	compare := func(
		l []certificate.CertificateInfo,
		r []credentials.CertificateMetadata,
		comparison func(certificate.CertificateInfo, credentials.CertificateMetadata) int, tc CertCollector) {
		compareLists(l, r, comparison, tc, &tct)
	}
	runTests := func() {
		for _, test := range tests {
			left := []certificate.CertificateInfo{}
			for _, item := range test.left {
				left = append(left, certificate.CertificateInfo{CN: item})
			}
			right := []credentials.CertificateMetadata{}
			for _, item := range test.right {
				right = append(right, credentials.CertificateMetadata{Name: item})
			}
			tc := &TestCertCollector{leftGet: tct.leftGet, rightGet: tct.rightGet}
			compare(left, right, comparison, tc)
			assertStringSliceEqual(t, test.out, tc.values)
		}
	}

	// run sorting the list beforehand
	runTests()

	compare = func(
		l []certificate.CertificateInfo,
		r []credentials.CertificateMetadata,
		comparison func(certificate.CertificateInfo, credentials.CertificateMetadata) int, tc CertCollector) {
		compareSortedLists(l, r, comparison, tc)
	}

	// run sorting the list beforehand output should be the same, but won't be if sorting causes issues
	runTests()
}

func TestCompareFunc(t *testing.T) {
	tests := []struct {
		left  []string
		right []string
		out   []string
	}{
		{[]string{"a", "b"}, []string{"c", "d"}, []string{"a", "b", "c", "d"}},
		{[]string{"a", "c"}, []string{"b", "d"}, []string{"a", "b", "c", "d"}},
		{[]string{}, []string{"a", "b", "c", "d"}, []string{"a", "b", "c", "d"}},
		{[]string{"a", "b", "c", "d"}, []string{}, []string{"a", "b", "c", "d"}},
		{[]string{"a"}, []string{"b", "c", "d"}, []string{"a", "b", "c", "d"}},
		{[]string{"a", "b", "c"}, []string{"d"}, []string{"a", "b", "c", "d"}},
	}

	comparison := func(l certificate.CertificateInfo, r credentials.CertificateMetadata) int {
		return strings.Compare(l.CN, r.Name)
	}

	compare := func(
		l []certificate.CertificateInfo,
		r []credentials.CertificateMetadata,
		comparison func(certificate.CertificateInfo, credentials.CertificateMetadata) int, tc CertCollector) {
		compareSortedLists(l, r, comparison, tc)
	}
	runTests := func() {
		for _, test := range tests {
			left := []certificate.CertificateInfo{}
			for _, item := range test.left {
				left = append(left, certificate.CertificateInfo{CN: item})
			}
			right := []credentials.CertificateMetadata{}
			for _, item := range test.right {
				right = append(right, credentials.CertificateMetadata{Name: item})
			}
			tc := &TestCertCollector{}
			compare(left, right, comparison, tc)
			assertStringSliceEqual(t, test.out, tc.values)
		}
	}

	runTests()
}

func assertStringSliceEqual(t *testing.T, a, b []string) {
	if len(a) != len(b) {
		t.Errorf("slices not of equals size expected size %d actual size %d", len(a), len(b))
		t.Errorf("slices not equal expected %+v actual %+v", a, b)
		return
	}
	for i, v := range a {
		if v != b[i] {
			t.Errorf("slices not equal expected %+v actual %+v", a, b)
			return
		}
	}
}

func comparesides2(l, r []string, comparison func(string, string) int) {
	// Initial indexes of first and second subarrays
	i := 0
	j := 0
	n1 := len(l)
	n2 := len(r)

	for i < n1 && j < n2 {
		if comparison(l[i], r[j]) < 0 {
			fmt.Printf("l[i] %s\n", l[i])
			i++
		} else {
			fmt.Printf("r[j] %s\n", r[j])
			j++
		}
	}

	for i < n1 {
		// arr[k] = L[i];
		fmt.Printf("*l[i] %s\n", l[i])
		i++
	}

	for j < n2 {
		// arr[k] = R[j];
		fmt.Printf("*r[j] %s\n", r[j])
		j++
	}
}

func TestTrimPrefix(t *testing.T) {
	result := strings.TrimPrefix("sammadiṭṭhi", "samma")
	if result != "diṭṭhi" {
		t.Error("did not match")
	}
}

func TestRegexReplace(t *testing.T) {
	if removeTPPUploadSuffix("TestCommonName_20nov25_DE13") != "TestCommonName" {
		t.Error("did not match")
	}
	if removeTPPUploadSuffix("TestCommonName_20nov25_DE1") != "TestCommonName_20nov25_DE1" {
		t.Error("did not match")
	}
}

func TestCompareAndTransformThumbprint(t *testing.T) {
	c := ThumbprintStrategy{}
	// assertStringEquals(t, credname, "credname")
	c.getCertificate = func(name string) (credentials.Certificate, error) {
		return credentials.Certificate{Value: values.Certificate{Certificate: GetCert()}}, nil
	}
	credname := c.rightGet(credentials.CertificateMetadata{Name: "credname"})
	assertStringEquals(t, "ebdbe32ef98991695958ea2510287f0e6c52a483", credname)
	// output := c.rightTransform("credname")
	// fmt.Println("s", output)
}

func TestJoinRoot(t *testing.T) {
	assertStringEquals(t, "a/b", joinRoot("a", "b", "/"))
	assertStringEquals(t, "a/b", joinRoot("a/", "/b", "/"))
	assertStringEquals(t, "a/b", joinRoot("a/", "b", "/"))
	assertStringEquals(t, "a/b", joinRoot("a", "/b", "/"))

	assertStringEquals(t, "a\\b", joinRoot("a", "b", "\\"))
	assertStringEquals(t, "a\\b", joinRoot("a\\", "\\b", "\\"))
	assertStringEquals(t, "a\\b", joinRoot("a\\", "b", "\\"))
	assertStringEquals(t, "a\\b", joinRoot("a", "\\b", "\\"))
}

type CredhubProxyMock struct {
	CredhubProxy chclient.CredhubProxy
	returnlist   []credentials.CertificateMetadata
}

// Need all of the methods for the Interface
func (cp *CredhubProxyMock) List() ([]credentials.CertificateMetadata, error) {
	return cp.returnlist, nil
}
func (cp *CredhubProxyMock) DeleteCert(name string) error {
	return nil
}
func (cp *CredhubProxyMock) GenerateCertificate(name string, parameters generate.Certificate, overwrite credhub.Mode) (credentials.Certificate, error) {
	return credentials.Certificate{}, nil
}
func (cp *CredhubProxyMock) GetCertificate(name string) (credentials.Certificate, error) {
	return credentials.Certificate{}, nil
}
func (cp *CredhubProxyMock) PutCertificate(name string, ca string, certificate string, privateKey string) error {
	return nil
}

type VcertProxyMock struct {
	VcertProxy vcclient.VcertProxy
	retCerts   []certificate.CertificateInfo
}

func (v *VcertProxyMock) List(vlimit int, zone string) ([]certificate.CertificateInfo, error) {
	return v.retCerts, nil
}
func (v *VcertProxyMock) Revoke(thumbprint string) error {
	return nil
}
func (v *VcertProxyMock) Generate(args *vcclient.CertArgs) (*certificate.PEMCollection, error) {
	return &certificate.PEMCollection{}, nil
}
func (v *VcertProxyMock) RetrieveCertificateByThumbprint(thumbprint string) (*certificate.PEMCollection, error) {
	return &certificate.PEMCollection{}, nil
}
func (v *VcertProxyMock) PutCertificate(certName string, cert string, privateKey string) error {
	return nil
}
func (v *VcertProxyMock) Login() error {
	return nil
}
func (v *VcertProxyMock) Logout() error {
	return nil
}

func TestCVListBoth(t *testing.T) {
	tests := []struct {
		left        []string
		right       []string
		leftPrefix  string
		rightPrefix string
		out         []string
	}{
		{[]string{"a", "b"}, []string{"a", "b"}, "", "", []string{"a=a", "b=b"}},
		{[]string{"/a", "b"}, []string{"a", "b"}, "", "", []string{"/a=a", "b=b"}},
		{[]string{"a", "b"}, []string{"a", "/b"}, "", "", []string{"a=a", "b=/b"}},
		{[]string{"a", "b"}, []string{"/b", "a"}, "", "", []string{"a=a", "b=/b"}},
		{[]string{"/z/a", "b"}, []string{"/b", "a"}, "/z/", "", []string{"/z/a=a", "b=/b"}},
	}

	for _, test := range tests {
		left := []certificate.CertificateInfo{}
		for _, item := range test.left {
			left = append(left, certificate.CertificateInfo{ID: item})
		}
		right := []credentials.CertificateMetadata{}
		for _, item := range test.right {
			right = append(right, credentials.CertificateMetadata{Name: item})
		}

		ch := CredhubProxyMock{returnlist: right}
		v := VcertProxyMock{retCerts: left}
		c := CV{credhub: &ch, vcert: &v}
		l := &ListCommand{VenafiPrefix: test.leftPrefix, CredhubPrefix: test.rightPrefix, ByPath: true}
		r, err := c.listBoth(l)
		assertTrue(t, err == nil)
		s := []string{}
		for _, i := range r {
			l := ""
			r := ""
			if i.Left != nil {
				l = i.Left.ID
			}
			if i.Right != nil {
				r = i.Right.Name
			}
			// fmt.Println("s", i)
			s = append(s, fmt.Sprintf("%s=%s", l, r))
		}
		fmt.Println("s", s)

		// tc := &TestCertCollector{}
		// compare(left, right, comparison, tc)
		assertStringSliceEqual(t, test.out, s)
	}
}

func GetCert() string {
	return "-----BEGIN CERTIFICATE-----\nMIIDSjCCAjKgAwIBAgIUdpQ3G/AnIilrPAsvMz3Zf9VnvWgwDQYJKoZIhvcNAQEL\nBQAwGjEYMBYGA1UEAwwPZm9vX2NlcnRpZmljYXRlMB4XDTE3MTEyMTE2MjUyMFoX\nDTE4MTEyMTE2MjUyMFowGjEYMBYGA1UEAwwPZm9vX2NlcnRpZmljYXRlMIIBIjAN\nBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwqIrV8HpCuPyuJ6VvyG7gVhYJGAO\nX4zhclxkTAKT5rkE4Lfj048GZsDghK+pHs+tVotfyrJzYGJoEBTn9Wy7kP5pQmLR\nF54imDztep15OlyoJmLZfRgct/8Kyxkjgg3PKVw68IiNhnTlYaw4CAyZ/13mvw2c\nWIYlag9LV5R2ifcyubaYllxJhdWSXrcbYxrts1kRsUQTo99jJzKu71meLigMryaM\nry8xvjv1X8Yjq3s3Lud6gWZ6BuaaaVVIjI9clGgR1MkgKJgVkWjNzDRiCxYnq1LH\nCho9bgKgiY4p604zPk9Mw4FhtCbOim6HOsHTimONZXfDNmfsJ9wJefA0UwIDAQAB\no4GHMIGEMB0GA1UdDgQWBBTyAOrrFMy88bGgEBVI4PRGD4b02jBVBgNVHSMETjBM\ngBQ3ZlJJaG9Brzf3IM6tWsMJce6YIKEepBwwGjEYMBYGA1UEAwwPZm9vX2NlcnRp\nZmljYXRlghQvHGgHfN/J7QzPNFAa0q3DwILanjAMBgNVHRMBAf8EAjAAMA0GCSqG\nSIb3DQEBCwUAA4IBAQBC1x2+E35y+iX3Mu+SWD1I3RNTGE3qKdUqj+O+QeavqCRQ\n01nolxFaSvrM/4znAlWukfp9lCOHl8foD3vHQ+meW+PlLIH9HlBjn9T3c6h4p8EQ\niYV93tyCmUlPdtzW7k4Onl3IroNNHem9Uj+OSZxGtw35YU84T+hM1kaDKtZeS1je\nFWF1W8DCORxD2rFXFwe2nJd6SSeF3KWzuKAKDqJ7CmbdRb1TtgjUym6X55SQfW2a\ndwNE+9ztMBQm4ERhwMU/NMx14UjsOPvNjF1VVei52qQ2ce7c1vgW1RI2cYFgV8q8\noFjMdJePy7eLbGRaW7Jpdy9MOiEZOj513lT5MBGk\n-----END CERTIFICATE-----"
}

func TestErrorf(t *testing.T) {
	output.Errorf("error: %s", fmt.Errorf("hello"))
}

func TestCenter(t *testing.T) {
	s := "in the middleya"
	w := 112 // or whatever

	// centered := fmt.Sprintf("|%[1]*s|", -w, fmt.Sprintf("%[1]*s", (w+len(s))/2, s))
	// centered = truncateString(centered, 110)
	centered := output.CenteredString(s, w)
	fmt.Println("s", centered, len(centered))
}

type stringPair struct {
	left  string
	right string
}

func TestPrettify(t *testing.T) {
	// #       TPP     CH0

	compareResults := []stringPair{{"\\VED\\Policy\\Certificates\\Division 3\\TestCerta", "NA"},
		{"\\VED\\Policy\\Certificates\\Division 3\\TestCertb", "NA"},
		{"NA", "/TestCertb_20nov26_DE38"},
		{"NA", "/TestCommonName_20nov25_DE13"},
		{"\\VED\\Policy\\Certificates\\Division 3\\localhost", "NA"},
		{"NA", "/mycertfromvenafi23"},
		{"NA", "/mycredname11"},
		{"\\VED\\Policy\\Certificates\\Division 3\\mycredname11mm", "/mycredname11mm"},
		{"NA", "/mycredname11zb"},
		{"NA", "/mycredname2"}}
	leftLongest := 0
	rightLongest := 0
	for _, item := range compareResults {
		leftLongest = max(leftLongest, len(item.left))
		rightLongest = max(rightLongest, len(item.right))
	}

	header := fmt.Sprintf("%s%s | %s\n", output.Cyan, output.CenteredString("VENAFI", leftLongest), output.CenteredString("CREDHUB", rightLongest))
	fmt.Print(header)
	fmt.Println(strings.Repeat("-", leftLongest+rightLongest+3))

	for _, item := range compareResults {
		// fmt.Printf("%[1]*s | %[1]*s\n", -leftLongest, item.left, -rightLongest, item.right)
		fmt.Printf("%s%[2]*s %s| %s%[6]*s\n", output.Green, -leftLongest, item.left, output.Cyan, output.Green, -rightLongest, item.right)
	}
	// fmt.Printf("%s|%s")
}
