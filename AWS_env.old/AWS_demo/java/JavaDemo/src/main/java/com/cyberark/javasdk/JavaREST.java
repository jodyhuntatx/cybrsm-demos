package com.cyberark.javasdk;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;

import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import java.security.cert.X509Certificate;
import java.security.NoSuchAlgorithmException;
import java.security.KeyManagementException;


import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLEncoder;
import java.util.Base64;
import java.io.UnsupportedEncodingException;
import java.lang.InterruptedException;
import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.List;
import java.util.ArrayList;

public class JavaREST {

  /******************************************************************
   * 			PUBLIC MEMBERS
   *
   * void disbleSSL()
   * String httpGet(url,authhdr)
   * String httpPost(url,body,authhdr)
   * String httpPatch(url,body,authhdr)
   *
   ******************************************************************/

    public static Boolean DEBUG=false;

    // ==========================================
    // void disableSSL()
    //   from: https://nakov.com/blog/2009/07/16/disable-certificate-validation-in-java-ssl-connections/
    //
    public static void disableSSL() {
        // Create a trust manager that does not validate certificate chains
        TrustManager[] trustAllCerts = new TrustManager[] {new X509TrustManager() {
                public java.security.cert.X509Certificate[] getAcceptedIssuers() {
                    return null;
                }
                public void checkClientTrusted(X509Certificate[] certs, String authType) {
                }
                public void checkServerTrusted(X509Certificate[] certs, String authType) {
                }
            }
        };

        // Install the all-trusting trust manager
	try {
	        SSLContext sc = SSLContext.getInstance("SSL");
        	sc.init(null, trustAllCerts, new java.security.SecureRandom());
        	HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
	} catch(NoSuchAlgorithmException e) {
		e.printStackTrace();
	} catch(KeyManagementException e) {
		e.printStackTrace();
	}

        // Create all-trusting host name verifier
        HostnameVerifier allHostsValid = new HostnameVerifier() {
            public boolean verify(String hostname, SSLSession session) {
                return true;
            }
        };

        // Install the all-trusting host verifier
        HttpsURLConnection.setDefaultHostnameVerifier(allHostsValid);

    } // disableSSL

    // ===============================================================
    // String httpGet() -
    //
    public static String httpGet(String url_string, String auth_header) {
	String output = "";
	try {
	    URL url = new URL(url_string);
	    HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
	    conn.setRequestMethod("GET");
	    conn.setRequestProperty("Accept", "application/json");
	    conn.setRequestProperty("Authorization", auth_header);

	    if (conn.getResponseCode() != 200) {
			throw new RuntimeException("Failed : HTTP error code : "
					+ conn.getResponseCode());
	    }

	    BufferedReader br = new BufferedReader(new InputStreamReader(
			(conn.getInputStream())));

	    output = br.readLine();
	    String tmp; 
	    while ((tmp = br.readLine()) != null) {
		output = output + System.lineSeparator() + tmp;
	    }

	    conn.disconnect();

	} catch (MalformedURLException e) {
	    e.printStackTrace();
	} catch (IOException e) {
	    e.printStackTrace();
	}

	if(JavaREST.DEBUG) {
	   System.out.println("JavaREST.httpGet() ========");
	   System.out.println(output);
	}

	return output;

     } // httpGet()


    // ===============================================================
    // String httpPost() -
    //
    public static String httpPost(String url_string, String bodyContent, String auth_header) {
	String output = "";
	try {
	    URL url = new URL(url_string);
	    HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
	    conn.setDoOutput(true);
	    conn.setRequestMethod("POST");
	    conn.setRequestProperty("Content-Type", "application/json");
	    conn.setRequestProperty("Authorization", auth_header);

	    OutputStream os = conn.getOutputStream();
	    os.write(bodyContent.getBytes());
	    os.flush();

	    if (conn.getResponseCode() != 200) {
//			throw new RuntimeException("Failed : HTTP error code : "
			System.out.println("Failed : HTTP error code : "
					+ conn.getResponseCode());
	    }

	    BufferedReader br = new BufferedReader(new InputStreamReader(
				(conn.getInputStream())));

	    String tmp;
	    while ((tmp = br.readLine()) != null) {
			output = output + tmp;
	    }

	    conn.disconnect();

	} catch (MalformedURLException e) {
	    e.printStackTrace();
	} catch (IOException e) {
	    e.printStackTrace();
	}

	if(JavaREST.DEBUG) {
	   System.out.println("JavaREST.httpPost() ========");
	   System.out.println("Response:");
	   System.out.println(output);
	   System.out.println("============================");
	}

	return output;

     } // httpPost()


    // ===============================================================
    // String httpPatch() -
    //
    // Formats shell call out to curl command.
    //
    public static String httpPatch(String url_string, String bodyContent, String auth_header) {
	List<String> curlCmd = new ArrayList<String>();
	curlCmd.add("./curlpatch.sh");
	curlCmd.add(auth_header);
	curlCmd.add(bodyContent);
	curlCmd.add(url_string);

	String output="";

	if(JavaREST.DEBUG) {
	   System.out.println("JavaREST.httpPatch() ========");
	   System.out.println("curl command:\n" + curlCmd);
	}

	try {
	    ProcessBuilder pb = new ProcessBuilder(curlCmd);
	    pb.redirectErrorStream(true);	// direct errors to input stream
	    Process process = pb.start();	// make request
						// get response
	    BufferedReader br = new BufferedReader(new InputStreamReader(
				(process.getInputStream())));
	    String tmp;
	    while ((tmp = br.readLine()) != null) {
		output = output + tmp;
	    }

	    int exitCode = process.waitFor();
	    assert exitCode==0;
	} catch (InterruptedException e) {
	    e.printStackTrace();
	} catch (IOException e) {
	    e.printStackTrace();
	}

	if(JavaREST.DEBUG) {
	   System.out.println("Response:");
	   System.out.println(output);
	   System.out.println("=============================");
	}

	return output;
    }

    // ===============================================================
    // String httpPatch() -
    //
    public static String xxxhttpPatch(String url_string, String bodyContent, String auth_header) {
	String output = "";
	allowMethods("PATCH");
	try {
	    URL url = new URL(url_string);
	    HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
	    conn.setDoOutput(true);
	    conn.setRequestMethod("PATCH");
	    conn.setRequestProperty("Content-Type", "application/json");
	    conn.setRequestProperty("Authorization", auth_header);

	    OutputStream os = conn.getOutputStream();
	    os.write(bodyContent.getBytes());
	    os.flush();

	    if (conn.getResponseCode() != 201) {
			throw new RuntimeException("Failed : HTTP error code : "
					+ conn.getResponseCode());
	    }

	    BufferedReader br = new BufferedReader(new InputStreamReader(
				(conn.getInputStream())));

	    String tmp;
	    while ((tmp = br.readLine()) != null) {
			output = output + tmp;
	    }

	    conn.disconnect();

	} catch (MalformedURLException e) {
	    e.printStackTrace();
	} catch (IOException e) {
	    e.printStackTrace();
	}

	return output;

     } // httpPatch()

  /******************************************************************
   * 			PRIVATE MEMBERS
   *
   ******************************************************************/

    // ===============================================================
    private static void allowMethods(String... methods) {
        try {
            Field methodsField = HttpsURLConnection.class.getDeclaredField("methods");

            Field modifiersField = Field.class.getDeclaredField("modifiers");
            modifiersField.setAccessible(true);
            modifiersField.setInt(methodsField, methodsField.getModifiers() & ~Modifier.FINAL);

            methodsField.setAccessible(true);

            String[] oldMethods = (String[]) methodsField.get(null);
            Set<String> methodsSet = new LinkedHashSet<>(Arrays.asList(oldMethods));
            methodsSet.addAll(Arrays.asList(methods));
            String[] newMethods = methodsSet.toArray(new String[0]);

            methodsField.set(null/*static field*/, newMethods);
        } catch (NoSuchFieldException | IllegalAccessException e) {
            throw new IllegalStateException(e);
        }
    }

    // ===============================================================
    // String base64Encode() - base64 encodes argument and returns encoded string
    //
    private static String base64Encode(String input) {
	String encodedString = "";
	try {
	    encodedString = Base64.getEncoder().encodeToString(input.getBytes("utf-8"));
	} catch (UnsupportedEncodingException e) {
		e.printStackTrace();
	}
	return encodedString;
    } // base64Encode

} // JavaREST
