package com.cyberark.javasdk;

import com.cyberark.javasdk.DAPJava;
import com.cyberark.javasdk.JavaREST;

/*
 * Test driver for DAPJava class
 */

public class JavaDemo {
    public static void main(String[] args) {
	if(args.length != 1)
	{
		System.out.println("Argument required, must be one of: health, user, host, aws");
		System.exit(0);
	}

	DAPJava.initJavaKeyStore(
				System.getenv("JAVA_KEY_STORE_FILE"),
				System.getenv("JAVA_KEY_STORE_PASSWORD")
				);
	DAPJava.initConnection(
				System.getenv("CONJUR_APPLIANCE_URL"),
				System.getenv("CONJUR_ACCOUNT")
				);
	switch(args[0]) {

		case "health" :
			DAPJava.getHealth();
			System.exit(0);
			break;

		case "user" :
			String apiKey = DAPJava.authnLogin(
						System.getenv("CONJUR_USER"),
						System.getenv("CONJUR_PASSWORD")
						);
			DAPJava.authenticate(
						System.getenv("CONJUR_USER"),
						apiKey
						);
			break;

		case "host" :
			DAPJava.authenticate(
						System.getenv("CONJUR_AUTHN_LOGIN"),
						System.getenv("CONJUR_AUTHN_API_KEY")
						);
			break;

		case "aws" :
			DAPJava.DEBUG=true;
			JavaREST.DEBUG=true;
			DAPJava.authnAwsIam(
						System.getenv("AWS_SERVICE_ID"),
						System.getenv("AWS_AUTHN_LOGIN")
						);
			break;

		default :
			System.out.println("Unknown option: " + args[0]);
			System.out.println("Argument required, must be one of: health, user, host");
			System.exit(0);
			
	} // switch

  	System.out.println("Secret value: " 
			+ DAPJava.variableValue(System.getenv("CONJUR_VAR_ID")) );

    } // main()
} // JavaDemo
