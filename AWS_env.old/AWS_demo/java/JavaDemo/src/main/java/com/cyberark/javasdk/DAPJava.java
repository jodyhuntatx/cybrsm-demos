package com.cyberark.javasdk;

import java.net.URLEncoder;
import java.util.Base64;
import java.io.UnsupportedEncodingException;

import java.net.URI;
import java.util.Map;
import java.util.LinkedHashMap;
import com.amazonaws.DefaultRequest;
import com.amazonaws.Request;
import com.amazonaws.Response;
import com.amazonaws.AmazonServiceException;
import com.amazonaws.ClientConfiguration;
import com.amazonaws.auth.AWS4Signer;
import com.amazonaws.auth.InstanceProfileCredentialsProvider;
import com.amazonaws.http.AmazonHttpClient;
import com.amazonaws.http.ExecutionContext;
import com.amazonaws.http.HttpMethodName;
import com.amazonaws.http.DefaultErrorResponseHandler;
import com.amazonaws.http.response.AwsResponseHandlerAdapter;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.JsonProcessingException;
import org.apache.commons.codec.digest.DigestUtils;

import com.cyberark.javasdk.JavaREST;

public class DAPJava {

  /******************************************************************
   * 			PUBLIC MEMBERS
   *
   * void initJavaKeyStore(file,password) - opens Java key store containing server cert
   * void initConnection(url,account) - sets private members for appliance URL and account 
   * void getHealth() - basic DAP health check
   * String authnLogin(uname,password) - Logs in human user with password, returns user's API key 
   * void authenticate(name,apikey) - authenticates with API key, sets private access token member
   * void authnAwsIam(awsAccount,awsIamRole) - authenticates with AWS account & IAM role,
   *                                           sets private access token member
   * void setAccessToken(token) - sets private access token member, use with authn-k8s
   * String search(searchstr) - returns json array for variables where id 
   *                            or annotations match searchstr
   * String variableValue(varname) - gets variable value by name using private members
   * void loadPolicy(method,branchId,fileName) - loads policy file at branchId using method
   *
   ******************************************************************/

    public static Boolean DEBUG=false;

    // ===============================================================
    // void initJavaKeyStore() - opens Java key store containing server cert
    //
    public static void initJavaKeyStore(String _jksFile, String _jksPassword) {
	  System.setProperty("javax.net.ssl.trustStore", _jksFile);
	  System.setProperty("javax.net.ssl.trustStorePassword", _jksPassword);
	  System.setProperty("javax.net.ssl.trustStoreType", "JKS");
    }

    // ===============================================================
    // void initConnection() - sets private appliance URL and account members
    //
    public static void initConnection(String _applianceUrl, String _account) {
	dapApplianceUrl = _applianceUrl;
	dapAccount = _account;

	JavaREST.disableSSL();	// *** WORKAROUND FOR SNI VERIFICATION ERROR
    }

    // ===============================================================
    // void getHealth() - basic health check
    //
    public static void getHealth() {
	System.out.println( JavaREST.httpGet(dapApplianceUrl + "/health", "") );
    }

    // ===============================================================
    // String authnLogin() - Logs in human user with password, returns user's API key 
    //
    public static String authnLogin(String _user, String _password) {
	String authHeader = "Basic " + base64Encode(_user + ":" + _password);
	String requestUrl = dapApplianceUrl
				+ "/authn/" + dapAccount + "/login";
	String authnApiKey = JavaREST.httpGet(requestUrl, authHeader);
  	if(DAPJava.DEBUG) {
	    System.out.println("API key: " + authnApiKey);
	}
	return authnApiKey;
    }

    // ===============================================================
    // void authenticate() - authenticates with API key, sets private access token member
    //
    public static void authenticate(String _authnLogin, String _apiKey) {
	String requestUrl = dapApplianceUrl;
	try {
	    requestUrl = requestUrl + "/authn/" + dapAccount + "/" 
				+ URLEncoder.encode(_authnLogin, "UTF-8")+ "/authenticate";
  	    if(DAPJava.DEBUG) {
  	 	System.out.println("Authenticate requestUrl: " + requestUrl);
	    }
	} catch (UnsupportedEncodingException e) {
		e.printStackTrace();
	}

	String rawToken = JavaREST.httpPost(requestUrl, _apiKey, "");
  	if(DAPJava.DEBUG) System.out.println("Raw token: " + rawToken);
	dapAccessToken = base64Encode(rawToken);
	if(DAPJava.DEBUG) System.out.println("Access token: " + dapAccessToken);
    }

    // ===============================================================
    // void authnAwsIam()
    //
    // Authenticates with AWS Account & IAM role, sets private access token member
    //
    public static void authnAwsIam(String _serviceId, String _hostId) {
	// Instantiate the request to Secure Token Service
	Request<Void> request = new DefaultRequest<Void>("sts"); 
	request.setHttpMethod(HttpMethodName.GET);
	request.addHeader("x-amz-content-sha256", DigestUtils.sha256Hex(""));
	request.setEndpoint(URI.create("https://sts.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15"));

	// Sign it...
	AWS4Signer signer = new AWS4Signer();
	signer.setRegionName("us-east-1");
	signer.setServiceName(request.getServiceName());
	signer.sign(request, InstanceProfileCredentialsProvider.getInstance().getCredentials());

	// Sort headers and convert to json
	Map<String,String> rawHeaders = request.getHeaders();
	LinkedHashMap<String,String> headers = new LinkedHashMap<String,String>();
	headers.put("host", rawHeaders.get("Host"));
	headers.put("x-amz-date", rawHeaders.get("X-Amz-Date"));
	headers.put("x-amz-security-token", rawHeaders.get("X-Amz-Security-Token"));
	headers.put("x-amz-content-sha256", rawHeaders.get("x-amz-content-sha256"));
	headers.put("authorization", rawHeaders.get("Authorization"));
	
	String headersJson = null; 
	try {
	    ObjectMapper mapper = new ObjectMapper();
	    headersJson = mapper.writeValueAsString(headers);
	} catch (JsonProcessingException e) {
		e.printStackTrace();
	}

	// Construct authn URL
	String requestUrl = dapApplianceUrl;
	try {
	    requestUrl = requestUrl + "/authn-iam/" + _serviceId + "/" + dapAccount + "/"
				+ URLEncoder.encode(_hostId, "UTF-8").replace("+","%20")
		    		+ "/authenticate";
	} catch (UnsupportedEncodingException e) {
		e.printStackTrace();
	}

	if(DAPJava.DEBUG) {
  	    System.out.println("AWS IAM authenticate requestUrl: " + requestUrl);
  	    System.out.println("Headers:");
	    for (Map.Entry<String,String> entry : headers.entrySet())  
                System.out.println("    Key = " + entry.getKey() + 
                                 ", Value = " + entry.getValue()); 
  	    System.out.println("Headers (json):" + headersJson);
	}

	String rawToken = JavaREST.httpPost(requestUrl, headersJson, "");
  	if(DAPJava.DEBUG) System.out.println("Raw token: " + rawToken);
	dapAccessToken = base64Encode(rawToken);
	if(DAPJava.DEBUG) System.out.println("Access token: " + dapAccessToken);

    }

    // ===============================================================
    // void setAccessToken() - sets private access token member, use with authn-k8s
    //
    public static void setAccessToken(String _rawToken) {
	dapAccessToken = base64Encode(_rawToken);
    }

    // ===============================================================
    // String search() - returns json array for variables where id or annotations match searchStr
    //
    public static String search(String _searchStr) {
	String authHeader = "Token token=\"" + dapAccessToken + "\"";
	String requestUrl = dapApplianceUrl
				+ "/resources/" + dapAccount + "?kind=variable" 
				+ "&search=" + _searchStr.replace(" ","%20");
	if(DAPJava.DEBUG) System.out.println("Search request: " + requestUrl);
  	return JavaREST.httpGet(requestUrl, authHeader);
    }

    // ===============================================================
    // String variableValue() - gets variable value by name using private members
    //
    public static String variableValue(String _varId) {
	String authHeader = "Token token=\"" + dapAccessToken + "\"";
	String requestUrl = dapApplianceUrl;
	try {
	    // Java URLEncoder encodes a space as + instead of %20 - DAP REST doesn't accept +
	    requestUrl = requestUrl + "/secrets/" + dapAccount 
				+ "/variable/" 
				+ URLEncoder.encode(_varId, "UTF-8").replace("+","%20");
  	    if(DAPJava.DEBUG) System.out.println("Variable requestUrl: " + requestUrl);
	} catch (UnsupportedEncodingException e) {
		e.printStackTrace();
	}
	return JavaREST.httpGet(requestUrl, authHeader);
    }

    // ===============================================================
    // void loadPolicy() - loads policy at a given branch using specfied method
    //
    public static void loadPolicy(String _method, String _branchId, String _policyText) {
	String authHeader = "Token token=\\\"" + dapAccessToken + "\\\"";
	String requestUrl = dapApplianceUrl + "/policies/" + dapAccount + "/policy/" + _branchId;
	switch(_method) {
	    case "delete":
		if(DEBUG) {
		    System.out.println("loadPolicy:");
		    System.out.println("  requestUrl: " + requestUrl);
		    System.out.println("  method: delete/patch");
		    System.out.println("policyText:");
		    System.out.println(_policyText);
		    System.out.println("");
		}
		JavaREST.httpPatch(requestUrl, _policyText, authHeader);
		break;
	    case "replace":
		System.out.println("\"replace/put\" policy load method not implemented.");
		break;
	    default:
		if(DEBUG) {
		    System.out.println("loadPolicy:");
		    System.out.println("  requestUrl: " + requestUrl);
		    System.out.println("  method: append/post");
		    System.out.println("policyText:");
		    System.out.println(_policyText);
		    System.out.println("");
		}
		JavaREST.httpPost(requestUrl, _policyText, authHeader);
	} // switch
    } // loadPolicy

  /******************************************************************
   * 			PRIVATE MEMBERS
   ******************************************************************/

    private static String dapApplianceUrl;;
    private static String dapAccount;
    private static String dapAccessToken;

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

} // DAPJava
