using ConjurClient;
//using ConjurClient.Resources;
using System.Collections.Generic;
using System;
using System.Security;

namespace YourAppNamespace
{
    public class YourAppClass
    {
        public static void Main(string[] args)
        {
            Conjur conjur = new Conjur();
            // Authenticate the conjur client
            conjur.Authenticate();

            // Retrieve a specific secret
            SecureString secretValue = conjur.RetrieveSecret("cicd-secrets/prod-db-username");
            Console.WriteLine("Secret Value: {0}", Utilities.ToString(secretValue));
        }
    }
}
