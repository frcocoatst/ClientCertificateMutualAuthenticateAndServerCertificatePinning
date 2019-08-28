# Client Certificate Mutual Authenticate and Server Certificate Pinning

https://client.badssl.com is a server for testing client certificate provision (badssl.com-client.p12)
As it is a https server it also has a server certificate (bass.com.cer).


Get the certificate from a server using Safari. 
Drag out the certificate and add it to the bundle:

![CertDrag](https://github.com/frcocoatst/ClientCertificateMutualAuthenticateAndServerCertificatePinning/blob/master/certdrag.png
)

First there is authenticationMethod=NSURLAuthenticationMethodServerTrust
The certificate from SecTrustGetCertificate is compared against the stored certificate (badssl.com.cer) in the bundle.

If they are equal authenticationMethod=NSURLAuthenticationMethodClientCertificate is executed.
If the correct client certificate is presented to the server the Status Code gets 200

HINT: The GUI is not functional yet, except pressing connect

Trying to connect to https://client.badssl.com
authenticationMethod=NSURLAuthenticationMethodServerTrust
isServerTrusted = true

cert1 from SecTrustGetCertificate = <30820718 30820600 a0030201 02021001 f202031d fda98efd ff0f72be 51060d30 0d06092a 864886f7 0d01010b 0500304d 310b3009 06035504 06130255 53311530 13060355 040a130c 44696769 ...

cert2 from bundle = <30820718 30820600 a0030201 02021001 f202031d fda98efd ff0f72be 51060d30 0d06092a 864886f7 0d01010b 0500304d 310b3009 06035504 06130255 53311530 13060355 040a130c 44696769 43657274 ....

authenticationMethod=NSURLAuthenticationMethodClientCertificate
(
"<cert(0x101400d70) s: BadSSL Client Certificate i: BadSSL Client Root Certificate Authority>"
)
<SecTrustRef: 0x600000103c30>
<SecIdentity 0x608000267780 [0x7fffaeb94b40]>
Data = Optional(662 bytes)
Response = Optional(<NSHTTPURLResponse: 0x60800002eca0> { URL: https://client.badssl.com/ } 
{ Status Code: 200, Headers {
...



