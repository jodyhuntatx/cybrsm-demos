import java.util.Arrays;
import javapasswordsdk.*;
import javapasswordsdk.exceptions.*;

public class JavaPasswordRequest {
    public static void main(String[] args) {
        PSDKPassword password = null;
        char[] content = null;
        try {
            PSDKPasswordRequest passRequest = new PSDKPasswordRequest();

            // Set request properties
            passRequest.setAppID( System.getenv("APP_ID") );
            passRequest.setSafe( System.getenv("SAFE") );
            passRequest.setObject( System.getenv("OBJECT") );
            passRequest.setFolder("root");
            passRequest.setReason("Java CP demo");

            // Get password object
            password = javapasswordsdk.PasswordSDK.getPassword(passRequest);

            // Get password content
            content = password.getSecureContent();
	    System.out.println(new String(content));

            // ...
            // Use password content here
            // Use password properties - i.e password.getUserName()
            // ...
        } catch (PSDKException ex) {
            ex.printStackTrace();
        } finally {
          if(content != null) {
            // Clean the returned object
            Arrays.fill(content, (char) 0);
          }
          if(password != null) {
              // Dispose of resources used by this PSDKPassword object
            try {
              password.dispose();
            } catch (PSDKException ex) {
              ex.printStackTrace();
	    }
          }
        }
    }
}
