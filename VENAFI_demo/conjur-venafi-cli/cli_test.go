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

// +build integration

package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"testing"
)

func TestBuildGenerateRequest(t *testing.T) {
	flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	os.Args = []string{"noop", "create", `-cn`, `cn`, `-san-dns`, `san-dns`, `-key-type`, `rsa`, `-key-curve`, `key-curve`, `-o`, `o`, `-ou`, `ou`, `-c`, `c`, `-st`, `st`, `-l`, `l`, `-san-email`, `one@two.com`, `-san-ip`, `127.0.0.1`, `-key-password`, `key-password`, `common.name.venafi.example.com`}
	// os.Args = []string{os.Args[0:1]}
	// fmt.Println("command:", os.Args[1])

	parseCommand()
}

func TestEmptyInput(t *testing.T) {
	fmt.Println("empty command line")

	er := func(err error) {
		if err != nil {
			t.Fatal(err)
		}
	}

	flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	os.Args = []string{"noop"}
	v, err := parseCommand()
	er(err)

	er(v.execute())
}

func TestLoginAndGenerateCredhub(t *testing.T) {
	fmt.Println("login")

	er := func(err error) {
		if err != nil {
			t.Fatal(err)
		}
	}

	// run a login
	flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	os.Args = []string{"noop", "login", `-u`, `credhub`, `-p`, `password`, "-url", "https://127.0.0.1:9000", "-clientid", "credhub_cli", "-clientsecret", "", "-skip-tls-validation"}
	v, err := parseCommand()
	er(err)

	er(v.execute())

	// now that we are logged-in, run a delete
	flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	// os.Args = []string{"noop", "create", "-name", "mycredname6", "-common-name", "myname", "-key-usage", "data_encipherment", "-ext-key-usage", "client_auth", "-ca", "/aname"}
	// os.Args = []string{"noop", "create", "-credhub", "-name", "mycredname11", "-cn", "myname11", "-key-usage", "data_encipherment", "-ext-key-usage", "client_auth", "-ca", "/aname", "-genonly"}
	// os.Args = []string{"noop", "create", "-name", "mycredname11z", "-cn", "myname11z", "-key-usage", "data_encipherment", "-ext-key-usage", "client_auth", "-ca", "/aname", "-genonly"}
	os.Args = []string{"noop", "create", "-credhub", "-name", "mycredname11mm", "-cn", "mycredname11mm", "-key-usage", "data_encipherment", "-ext-key-usage", "client_auth", "-ca", "/aname"}
	v, err = parseCommand()
	er(err)

	er(v.execute())
}

func TestLoginAndBothListMethod(t *testing.T) {
	fmt.Println("login")

	er := func(err error) {
		if err != nil {
			t.Fatal(err)
		}
	}

	// run a login
	flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	os.Args = []string{"noop", "login", "-url", "https://127.0.0.1:9000", "-clientid", "credhub_client", "-clientsecret", "secret", "-skip-tls-validation"}
	// os.Args = []string{"noop", "login", `-u`, `credhub`, `-p`, `password`, "-url", "https://127.0.0.1:9000", "-skip-tls-validation"}
	v, err := parseCommand()
	er(err)

	er(v.execute())

	// now that we are logged-in, run a delete
	flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	// os.Args = []string{"noop", "listboth"}
	// os.Args = []string{"noop", "listboth", "-bythumbprint"}
	// os.Args = []string{"noop", "listboth", "-bycommonname"}
	// os.Args = []string{"noop", "listboth", "-bypath", "-croot", "/a"}
	// os.Args = []string{"noop", "listboth", "-bypath", "-vprefix", "/VED/Policy/Certificates/Division 3/"}
	// os.Args = []string{"noop", "list", "-bypath", "-vroot", "\\VED\\Policy\\Certificates\\Division 3\\"}
	// os.Args = []string{"noop", "list", "--bycommonname", "-vroot", "\\VED\\Policy\\Certificates\\Division 3\\"}
	// os.Args = []string{"noop", "list", "--bythumbprint", "-vroot", "\\VED\\Policy\\Certificates\\Division 3\\"}
	os.Args = []string{"noop", "list", "--bythumbprint", "-vlimit", "200", "-vroot", "\\VED\\Policy\\Certificates\\"}
	v, err = parseCommand()
	er(err)

	er(v.execute())
}

func TestLogin(t *testing.T) {
	fmt.Println("login")

	flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	// os.Args = []string{"noop", "login", `-u`, `credhub`, `-p`, `password`, "-url", "https://127.0.0.1:9000", "-clientid", "credhub_cli", "-clientsecret", "", "-skip-tls-validation"}
	// os.Args = []string{"noop", "login", "-url", "https://127.0.0.1:9000", "-clientid", "credhub_cli", "-clientsecret", "secret", "-skip-tls-validation"}
	// os.Args = []string{"noop", "login", "-url", "https://127.0.0.1:9000", `-u`, `credhub`, `-p`, `password`, "-skip-tls-validation"}
	os.Args = []string{"noop", "login"}
	v, err := parseCommand()
	if err != nil {
		panic(err)
	}
	err = v.execute()
	if err != nil {
		panic(err)
	}
}

func TestLoginAndDelete(t *testing.T) {
	fmt.Println("login")

	er := func(err error) {
		if err != nil {
			t.Fatal(err)
		}
	}

	// run a login
	flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	// os.Args = []string{"noop", "login", `-u`, `credhub`, `-p`, `password`, "-url", "https://127.0.0.1:9000", "-clientid", "credhub_cli", "-clientsecret", "", "-skip-tls-validation"}
	os.Args = []string{"noop", "login", `-u`, `credhub`, `-p`, `password`, "-url", "https://127.0.0.1:9000", "-skip-tls-validation"}
	v, err := parseCommand()
	er(err)

	er(v.execute())

	// now that we are logged-in, run a delete
	flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	// os.Args = []string{"noop", "delete", `-name`, `/mycertfromvenafi22`}
	os.Args = []string{"noop", "delete", `-name`, `/mycredname31`}

	v, err = parseCommand()
	er(err)

	er(v.execute())

}

func TestLoginAndGenerate(t *testing.T) {
	fmt.Println("vcert cli integration test")

	er := func(err error) {
		if err != nil {
			t.Fatal(err)
		}
	}

	// run a login
	flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	os.Args = []string{"noop", "login", `-u`, `credhub`, `-p`, `password`, "-url", "https://127.0.0.1:9000", "-skip-tls-validation"}
	v, err := parseCommand()
	er(err)

	er(v.execute())

	flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	// os.Args = []string{"noop", "create", `-cn`, `atestcert`, `-name`, `mycertfromvenafi23`}
	os.Args = []string{"noop", "create", `-cn`, `atestcert`, `-name`, `mycertfromvenafi24`}

	v, err = parseCommand()
	er(err)

	er(v.execute())
}

func TestWhat(t *testing.T) {
	fmt.Println("what")

	er := func(err error) {
		if err != nil {
			t.Fatal(err)
		}
	}

	flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	os.Args = []string{"noop", "create", "what"}

	v, err := parseCommand()
	er(err)

	er(v.execute())
}

func TestGetThumbprint(t *testing.T) {
	testCert := GetCert()
	tp, err := getThumbprint(testCert)
	if err != nil {
		t.Fatal(err)
	}
	fmt.Println("tp", tp)

}

// var red string = "\\e[1;31m"
// var grn string = "\\e[1;32m"
// var blu string = "\\e[1;34m"
// var mag string = "\\e[1;35m"
// var cyn string = "\\e[1;36m"
// var white string = "\\e[0m"

func TestColors(t *testing.T) {
	fmt.Println("\033[31mRed")
	fmt.Println("\033[32mGreen")
	fmt.Println("\033[34mBlue")
}

func TestConfigReadWrite(t *testing.T) {
	dir, err := ioutil.TempDir("/tmp/", "testconfigreadwrite")
	if err != nil {
		log.Fatal(err)
	}

	defer os.RemoveAll(dir) // clean up

	cl := ConfigLoader{userHomeDir: dir, cvConfigDir: ".cv", configFilename: "config.json"}
	cl.ensureDirExists()
	cl.writeConfig(&CVConfig{AccessToken: "accesstoken", RefreshToken: "refreshtoken", CredhubBaseURL: "http://url"})
	conf, err := cl.readConfig()
	if err != nil {
		t.Fatal(err)
	}

	if conf.AccessToken != "accesstoken" {
		t.Fatal("accesstoken not equal")
	}
	if conf.RefreshToken != "refreshtoken" {
		t.Fatal("refreshtoken not equal")
	}
	if conf.CredhubBaseURL != "http://url" {
		t.Fatal("baseURL not equal")
	}
	fmt.Printf("conf %+v", conf)
}

func TestYAML2(t *testing.T) {
	alt, err := config.ReadConfig("/tmp/", "yaml.yml")
	if err != nil {
		t.Fatal(err)
	}
	fmt.Printf("yaml %+v", alt)

	if alt.VcertUsername != "1" {
		t.Fatal("VcertUsername not equal")
	}
	if alt.VcertPassword != "2" {
		t.Fatal("VcertPassword not equal")
	}
	if alt.VcertZone != "3" {
		t.Fatal("VcertZone not equal")
	}
	if alt.VcertBaseURL != "4" {
		t.Fatal("VcertBaseURL not equal")
	}
	if alt.ConnectorType != "5" {
		t.Fatal("ConnectorType not equal")
	}
}
