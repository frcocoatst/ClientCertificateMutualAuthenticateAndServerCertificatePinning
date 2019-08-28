//
//  NSURLSessionPinningDelegate.swift
//  ClientCertificateMutualAuth
//
//  Created by Friedrich HAEUPL on 24.08.19.
//  Copyright © 2019 Friedrich HAEUPL. All rights reserved.
//

import Cocoa

class NSURLSessionPinningDelegate: NSObject, URLSessionDelegate {

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        
        // Adapted from OWASP https://www.owasp.org/index.php/Certificate_and_Public_Key_Pinning#iOS
        
        if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                var secresult = SecTrustResultType.invalid
                let status = SecTrustEvaluate(serverTrust, &secresult)
                
                if(errSecSuccess == status) {
                    if let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) {
                        let serverCertificateData = SecCertificateCopyData(serverCertificate)
                        let data = CFDataGetBytePtr(serverCertificateData);
                        let size = CFDataGetLength(serverCertificateData);
                        let cert1 = NSData(bytes: data, length: size)
                        let file_der = Bundle.main.path(forResource: "badssl_server", ofType: "crt")
                        
                        if let file = file_der {
                            if let cert2 = NSData(contentsOfFile: file) {
                                if cert1.isEqual(to: cert2 as Data) {
                                    completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust:serverTrust))
                                    return
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Pinning failed
        completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
    }
}



// Finally use it in your code to make URL requests:

/*
if let url = NSURL(string: "https://my-https-website.com") {
    
    let session = URLSession(
        configuration: URLSessionConfiguration.ephemeral,
        delegate: NSURLSessionPinningDelegate(),
        delegateQueue: nil)
    
    
    let task = session.dataTask(with: url as URL, completionHandler: { (data, response, error) -> Void in
        if error != nil {
            print("error: \(error!.localizedDescription): \(error!)")
        } else if data != nil {
            if let str = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) {
                print("Received data:\n\(str)")
            } else {
                print("Unable to convert data to text")
            }
        }
    })
    
    task.resume()
} else {
    print("Unable to create NSURL")
}

 */
/*
class SessionDelegate : NSObject, URLSessionDelegate {
    
    private static let rsa2048Asn1Header:[UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    ];
    
    private static let google_com_pubkey = ["4xVxzbEegwDBoyoGoJlKcwGM7hyquoFg4l+9um5oPOI="];
    private static let google_com_full = ["KjLxfxajzmBH0fTH1/oujb6R5fqBiLxl0zrl2xyFT2E="];
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil);
            return;
        }
        
        // Set SSL policies for domain name check
        let policies = NSMutableArray();
        policies.add(SecPolicyCreateSSL(true, (challenge.protectionSpace.host as CFString)));
        SecTrustSetPolicies(serverTrust, policies);
        
        var isServerTrusted = SecTrustEvaluateWithError(serverTrust, nil);
        
        if(isServerTrusted && challenge.protectionSpace.host == "www.google.com") {
            let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
            //Compare public key
            if #available(iOS 10.0, *) {
                let policy = SecPolicyCreateBasicX509();
                let cfCertificates = [certificate] as CFArray;
                
                var trust: SecTrust?
                SecTrustCreateWithCertificates(cfCertificates, policy, &trust);
                
                guard trust != nil, let pubKey = SecTrustCopyPublicKey(trust!) else {
                    completionHandler(.cancelAuthenticationChallenge, nil);
                    return;
                }
                
                var error:Unmanaged<CFError>?
                if let pubKeyData = SecKeyCopyExternalRepresentation(pubKey, &error) {
                    var keyWithHeader = Data(bytes: SessionDelegate.rsa2048Asn1Header);
                    keyWithHeader.append(pubKeyData as Data);
                    let sha256Key = sha256(keyWithHeader);
                    if(!SessionDelegate.google_com_pubkey.contains(sha256Key)) {
                        isServerTrusted = false;
                    }
                } else {
                    isServerTrusted = false;
                }
            } else { //Compare full certificate
                let remoteCertificateData = SecCertificateCopyData(certificate!) as Data;
                let sha256Data = sha256(remoteCertificateData);
                if(!SessionDelegate.google_com_full.contains(sha256Data)) {
                    isServerTrusted = false;
                }
            }
        }
        
        if(isServerTrusted) {
            let credential = URLCredential(trust: serverTrust);
            completionHandler(.useCredential, credential);
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil);
        }
        
    }
    
    func sha256(_ data : Data) -> String {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(data.count), &hash)
        }
        return Data(bytes: hash).base64EncodedString();
    }
    
}
 
 */
