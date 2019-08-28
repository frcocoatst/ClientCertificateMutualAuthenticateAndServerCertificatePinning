# Client Certificate Mutual Authenticate and Server Certificate Pinning

https://client.badssl.com is a server for testing client certificate provision (badssl.com-client.p12)
As it is a https server it also has a server certificate (bass.com.cer).


Get the certificate from a server using Safari. 
Drag out the certificate and add it to the bundle:

![CertDrag](https://github.com/frcocoatst/ClientCertificateMutualAuthenticateAndServerCertificatePinning/blob/master/certdrag.png
)

First there is authenticationMethod=NSURLAuthenticationMethodServerTrust
The certificate from SecTrustGetCertificate is compared against the store certificate (badssl.com.cer) in the bundle.

If they are equal authenticationMethod=NSURLAuthenticationMethodClientCertificate is executed.
If the correct client certificate is presented to the server the Status Code is 200

The GUI is not functionalist, except pressing connect


