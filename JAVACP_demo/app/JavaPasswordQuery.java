import java.util.Arrays;
import java.util.ArrayList;
import javapasswordsdk.*;
import javapasswordsdk.exceptions.*;

public class JavaPasswordQuery {
  public static void main(String[] args) {
    PSDKPassword password = null;
    char[] content = null;
    try {
      PSDKPasswordRequest passRequest = new PSDKPasswordRequest();

      // Set request properties
      passRequest.setAppID( System.getenv("APP_ID") );
      passRequest.setQuery("Safe=" + System.getenv("SAFE") + ";"
                           + "Folder=root;"
			   + "Address=" + System.getenv("ADDRESS") );
      passRequest.setReason("Java CP password query demo");

      // ArrayList of additional properties to get
      ArrayList reqProps = new ArrayList (); 
      reqProps.add ("PolicyId");
      reqProps.add ("UserName");
      passRequest.setRequiredProperties (reqProps);

      // Get password object
      password = javapasswordsdk.PasswordSDK.getPassword(passRequest);

      System.out.println ("UserName: "
      + password.getAttribute ("PassProps.UserName"));

      // Get password content
      content = password.getSecureContent();
      System.out.println("Password: " + new String(content));

      System.out.println ("PolicyID: "
      + password.getAttribute ("PassProps.PolicyID"));

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
