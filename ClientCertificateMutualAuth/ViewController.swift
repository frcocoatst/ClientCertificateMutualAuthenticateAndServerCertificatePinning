//
//  ViewController.swift
//  ClientCertificateMutualAuth
//
//  Created by Friedrich HAEUPL on 10.08.19.
//  Copyright © 2019 Friedrich HAEUPL. All rights reserved.
//

/*
 Response = Optional(<NSHTTPURLResponse: 0x60000003b540> { URL: https://client.badssl.com/ } { Status Code: 400, Headers {
 Connection =     (
 close
 );
 "Content-Length" =     (
 262
 );
 "Content-Type" =     (
 "text/html"
 );
 Date =     (
 "Mon, 12 Aug 2019 10:44:00 GMT"
 );
 Server =     (
 "nginx/1.10.3 (Ubuntu)"
 );
 } })
 
 */

import Cocoa

struct IdentityAndTrust {
    var identityRef:SecIdentity
    var trust:SecTrust
    var certArray:NSArray
}

class ViewController: NSViewController, URLSessionDelegate {
    
    // var socket: WebSocket!
    var counterValue = 99
    var data:Data = Data()

    // var request = URLRequest(url: URL(string: "https://client.badssl.com")!)
    // const char *szP12Filename = "/HOST/BADSSL.P12";
    // const char *szPassword = "badssl.com";
    //var request = URLRequest(url: URL(string: "https://prod.idrix.eu/secure/")!)
    //var request = URLRequest(url: URL(string: "https://server.cryptomix.com/secure/")!)
    var hostString = "https://client.badssl.com"
    var logString = ">\n"

    
    @IBOutlet weak var connectOutlet: NSButton!
    @IBOutlet weak var disconnectOutlet: NSButton!
    @IBOutlet weak var sendTextOutlet: NSButton!
    @IBOutlet weak var sendDataOutlet: NSButton!
    @IBOutlet weak var sendPingOutlet: NSButton!
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var counter: NSTextField!
    @IBOutlet weak var slider: NSSlider!
    @IBOutlet weak var hostLabel: NSTextField!
    @IBOutlet weak var hostSelectPopup: NSPopUpButton!
    @IBOutlet var textView: NSTextView!
    
    @IBAction func connect(_ sender: Any) {
        
        hostString = hostSelectPopup.title
        hostLabel.stringValue = hostString
        print (" Trying to connect to \(hostString)")
        
        makeGetRequest(hostString: hostString)
        
        connectOutlet.isEnabled = false
        disconnectOutlet.isEnabled = true
        sendTextOutlet.isEnabled = true
        sendDataOutlet.isEnabled = true
        sendPingOutlet.isEnabled = true
    }
    
    @IBAction func sendText(_ sender: Any) {
        // socket.write(string: textField.stringValue)
    }
    
    @IBAction func sendData(_ sender: Any) {
        
        let len  = slider.intValue
        counter.intValue = len
        data  = randomData(ofLength: Int(len))
        
        //socket.write(data: data)
    }
    
    @IBAction func sliderAction(_ sender: Any) {
        let len  = slider.intValue
        counter.intValue = len
        data  = randomData(ofLength: Int(len))
    }
    
    @IBAction func popUpAction(_ sender: Any) {
        hostString = hostSelectPopup.title
        hostLabel.stringValue = hostString
    }
    
    @IBAction func sendPing(_ sender: Any) {
        let bytes = [UInt8](repeating: 0xAA, count: 20)
        let pingdata = Data(bytes: bytes)
        // socket.write(ping: pingdata)
    }
    
    @IBAction func disconnect(_ sender: Any) {
        // check if connected then disconnect
        connectOutlet.isEnabled = true
        disconnectOutlet.isEnabled = false
        sendTextOutlet.isEnabled = false
        sendDataOutlet.isEnabled = false
        sendPingOutlet.isEnabled = false
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        hostLabel.stringValue = "Selected Host"
        textField.stringValue = "Enter Text here"
        counter.intValue = slider.intValue
        
        connectOutlet.isEnabled = true
        disconnectOutlet.isEnabled = false
        sendTextOutlet.isEnabled = false
        sendDataOutlet.isEnabled = false
        sendPingOutlet.isEnabled = false
        textView.string = logString
        
        // makeGetRequest(hostString:"https://client.badssl.com")

    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    

    public func randomData(ofLength length: Int) -> Data {
        /*
         var bytes = [UInt8](repeating: 0, count: length)
         let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
         if status == errSecSuccess {
         return Data(bytes: bytes)
         }
         //
         return Data(bytes: [255])
         */
        let bytes = [UInt8](repeating: 0x55, count: length)
        return Data(bytes: bytes)
    }
    

    // https://forums.developer.apple.com/thread/68897
    
    struct IdentityAndTrust {
        var identityRef:SecIdentity
        var trust:SecTrust
        var certArray:NSArray
    }
    
    func identity(named name: String, password: String) throws -> SecIdentity {
        let url = Bundle.main.url(forResource: name, withExtension: "p12")!
        let data = try Data(contentsOf: url)
        var importResult: CFArray? = nil
        let err = SecPKCS12Import(
            data as NSData,
            [kSecImportExportPassphrase as String: password] as NSDictionary,
            &importResult
        )
        guard err == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(err), userInfo: nil)
        }
        let identityDictionaries = importResult as! [[String:Any]]
        
        return identityDictionaries[0][kSecImportItemIdentity as String] as! SecIdentity
    }
    
    
    func identityAndTrust(named name: String, password: String) throws -> IdentityAndTrust {
        var identityAndTrust:IdentityAndTrust!
        
        let url = Bundle.main.url(forResource: name, withExtension: "p12")!
        let data = try Data(contentsOf: url)
        var importResult: CFArray? = nil
        let err = SecPKCS12Import(
            data as NSData,
            [kSecImportExportPassphrase as String: password] as NSDictionary,
            &importResult
        )
        guard err == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(err), userInfo: nil)
        }
        let identityDictionaries = importResult as! [[String:Any]]
        
        // print(identityDictionaries)
        // [["chain": <__NSArrayM 0x60c000244ef0>
        // (
        //      <cert(0x101132e90) s: BadSSL Client Certificate i: BadSSL Client Root Certificate Authority>
        // ),
        // "trust": <SecTrustRef: 0x60c000105580>,
        // "keyid": <f28d21d2 702e1e73 1fde2f67 0b1a4b5b 4a0548c0>,
        // "label": BadSSL Client Certificate,
        // "identity": <SecIdentity 0x60c0002798c0 [0x7fff937d6b40]>]]
        
        
        let certArray = identityDictionaries[0][kSecImportItemCertChain as String] as! NSArray
        let trustRef = identityDictionaries[0][kSecImportItemTrust as String] as! SecTrust
        let secIdentityRef = identityDictionaries[0][kSecImportItemIdentity as String] as! SecIdentity
        
        identityAndTrust = IdentityAndTrust(identityRef: secIdentityRef, trust: trustRef, certArray:  certArray);
       
        return identityAndTrust
    }
    
    //
    // from: https://stackoverflow.com/questions/44023540/swift-3-urlsession-with-client-authentication-by-certificate
    //

    func makeGetRequest(hostString: String){
        
        guard let requestUrl = URL(string: hostString) else {
            print("Error: cannot create URL")
            return
        }
        let configuration = URLSessionConfiguration.default
        //var request = try! URLRequest(url: requestUrl, method: .get)
        var request = try! URLRequest(url: requestUrl)
        
        let session = URLSession(configuration: configuration,
                                 delegate: self,
                                 delegateQueue: OperationQueue.main)
        
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            
            print("Data = \(data)")
            print("Response = \(response)")
            print("Error = \(error)")
            
        })
        
        task.resume()
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        let authenticationMethod = challenge.protectionSpace.authenticationMethod
        print("authenticationMethod=\(authenticationMethod)")
        
        if authenticationMethod == NSURLAuthenticationMethodClientCertificate {
            
            completionHandler(.useCredential, getClientUrlCredential())
            
        }
        
        else if authenticationMethod == NSURLAuthenticationMethodServerTrust {
            
            let serverCredential = getServerUrlCredential(protectionSpace: challenge.protectionSpace)
            guard serverCredential != nil else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
            completionHandler(.useCredential, serverCredential)
        }
         
        
    }
    
    // https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/NetworkingTopics/Articles/OverridingSSLChainValidationCorrectly.html#//apple_ref/doc/uid/TP40012544
    // https://stackoverflow.com/questions/28983176/nsurlauthenticationmethodservertrust-validation-for-server-certificate
    // https://stackoverflow.com/questions/24063927/swift-how-to-request-a-url-with-a-self-signed-certificate
    // https://linuskarlsson.se/blog/validating-server-certificates-signed-by-own-ca-in-swift/
    
    func getServerUrlCredential(protectionSpace:URLProtectionSpace)->URLCredential?{
        
        // from: https://stackoverflow.com/questions/34223291/ios-certificate-pinning-with-swift-and-nsurlsession
        //if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        //  if let serverTrust = challenge.protectionSpace.serverTrust {
                
            if let serverTrust = protectionSpace.serverTrust {
                var secresult = SecTrustResultType.invalid
                let status = SecTrustEvaluate(serverTrust, &secresult)
                
                if(errSecSuccess == status) {
                    if let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) {
                        let serverCertificateData = SecCertificateCopyData(serverCertificate)
                        let data = CFDataGetBytePtr(serverCertificateData);
                        let size = CFDataGetLength(serverCertificateData);
                        let cert1 = NSData(bytes: data, length: size)
                        
                        print("cert1 = \(cert1)")
                        
                        let file_der = Bundle.main.path(forResource: "badssl_server", ofType: "cer")
                        
                        if let file = file_der {
                            if let cert2 = NSData(contentsOfFile: file) {
                                print("cert2 = \(cert2)")
                                
                                if cert1.isEqual(to: cert2 as Data) {
                                    // completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust:serverTrust))
                                    //Certificates does match, so we can trust the server
                                    return URLCredential(trust: serverTrust)
                                }
                            }
                        }
                    }
                }
            }
        //}
        // Pinning failed
        // completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
        return nil
 /*
        if let serverTrust = protectionSpace.serverTrust {
            //Check if is valid
            var result = SecTrustResultType.invalid
            let status = SecTrustEvaluate(serverTrust, &result)
            print("SecTrustEvaluate res = \(result.rawValue)")
            
            if(status == errSecSuccess),
                let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) {
                //Get Server Certificate Data
                let serverCertificateData = SecCertificateCopyData(serverCertificate)
                //Get Local Certificate NSData
                // tbd: let localServerCertNSData = certificateHelper.getCertificateNSData(withName: "localServerCertName", andExtension: "cer")
                
                //Check if certificates are equals, otherwhise pinning failed and return nil
                // tbd: lguard serverCertificateData == localServerCertNSData else{
                // tbd: l    print("Certificates doesn't match.")
                // tbd: l    return nil
                // tbd: l}
                
                let data = CFDataGetBytePtr(serverCertificateData);
                let size = CFDataGetLength(serverCertificateData);
                let cert1 = NSData(bytes: data, length: size)
                let file_der = Bundle.main.path(forResource: "badssl.com-client", ofType: "p12")
                
                if let file = file_der {
                    if let cert2 = NSData(contentsOfFile: file) {
                        if cert1.isEqual(to: cert2 as Data) {
                            completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust:serverTrust))
                            return
                        }
                    }
                }
                
                //Certificates does match, so we can trust the server
                return URLCredential(trust: serverTrust)
            }
        }
        
        return nil
 */
        
    }
    
    
    func getClientUrlCredential()->URLCredential {
        
        var identityTrust:IdentityAndTrust?
        do {
            // secIdentity =  try identity(named: "badssl.com-client", password: "badssl.com")
            identityTrust =  try identityAndTrust(named: "badssl.com-client", password: "badssl.com")
        }
        catch {
            identityTrust = nil
        }
        
        print(identityTrust!.certArray)
        print(identityTrust!.trust)
        print(identityTrust!.identityRef)
        
        //Create URLCredential
        let urlCredential = URLCredential(identity: identityTrust!.identityRef,
                                          certificates: identityTrust!.certArray as [AnyObject],
                                          persistence: URLCredential.Persistence.permanent)
        
        return urlCredential
    }
}

// ----
/*
// from: https://linuskarlsson.se/blog/validating-server-certificates-signed-by-own-ca-in-swift/
public func URLSession(session: URLSession, didReceiveChallenge challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
        // First load our extra root-CAs to be trusted from the app bundle.
        let trust = challenge.protectionSpace.serverTrust
        
        let rootCa = "eitroot"
        if let rootCaPath = Bundle.main.path(forResource: rootCa, ofType: "der") {
            if let rootCaData = NSData(contentsOfFile: rootCaPath) {
                let rootCert = SecCertificateCreateWithData(nil, rootCaData)
                
                //let certArrayRef = CFArrayCreate(nil, UnsafeMutablePointer<UnsafePointer>([rootCert]), 1, nil)
                let certs: [CFTypeRef] = [rootCert as CFTypeRef]
                let certArrayRef : CFArray = CFBridgingRetain(certs as NSArray) as! CFArray

                SecTrustSetAnchorCertificates(trust!, certArrayRef)
                SecTrustSetAnchorCertificatesOnly(trust!, false) // also allow regular CAs.
            }
        }
        
        var trustResult: SecTrustResultType = SecTrustResultType(rawValue: 0)!
        SecTrustEvaluate(trust!, &trustResult)
        
        if (trustResult == SecTrustResultType.unspecified ||
            trustResult == SecTrustResultType.proceed) {
            // Trust certificate.
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            challenge.sender!.use(credential, for: challenge)
        } else {
            NSLog("Invalid server certificate.")
            challenge.sender!.cancel(challenge)
        }
    }
    else
    {
        NSLog("Got unexpected authentication method \(challenge.protectionSpace.authenticationMethod)");
        challenge.sender!.cancel(challenge)
    }
}

// https://www.yeradis.com/swift-authentication-challenge

public func URLSession(session: URLSession, didReceiveChallenge challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    
    if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
        
        let trust = challenge.protectionSpace.serverTrust
        
        let rootCaCerts = rootCACertificatesData.map() { // fix needed
            (data) -> CFData? in
            return CFDataCreate(kCFAllocatorDefault, UnsafePointer(data.bytes), data.length)
            }.filter({$0 != nil}).map() { ref -> CFTypeRef in
                return SecCertificateCreateWithData(kCFAllocatorDefault, ref!)!
        }
        
        let certArrayRef : CFArray = CFBridgingRetain(rootCaCerts as NSArray) as! CFArrayRef
        
        SecTrustSetAnchorCertificates(trust!, certArrayRef)
        SecTrustSetAnchorCertificatesOnly(trust!, true) // if "true" then also allows certificates signed with one of the system available root certificates.
        
        var trustResult: SecTrustResultType = SecTrustResultType(rawValue: 0)!
        SecTrustEvaluate(trust!, &trustResult)
        
        if (trustResult == SecTrustResultType.unspecified ||
            trustResult == SecTrustResultType.proceed) {
            //Trust the server certificate cause its signed with one of the allowed in-house CA
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            challenge.sender!.use(credential, for: challenge)
            
            completionHandler(URLSession.AuthChallengeDisposition.UseCredential, credential) // fix needed
        } else {
            print("Invalid server certificate.") //this also happens with expired certificates
            challenge.sender!.cancel(challenge)
            
            completionHandler(URLSession.AuthChallengeDisposition.CancelAuthenticationChallenge, nil) // fix needed
        }
        
    } else {
        print("Unexpected authentication method");
        challenge.sender!.cancel(challenge)
        completionHandler(URLSession.AuthChallengeDisposition.CancelAuthenticationChallenge, nil) // fix needed
    }
    
}


 // So insted of a list with files names, lets find all the “DER” files and load them into an array:
let enumerator = NSFileManager.defaultManager().enumeratorAtPath(NSBundle.mainBundle().bundlePath)
while let filePath = enumerator?.nextObject() as? String {
    if NSURL(fileURLWithPath: filePath).pathExtension == "der" {
        if let data = NSData(contentsOfURL:(NSBundle.mainBundle().bundleURL.URLByAppendingPathComponent(filePath))) {
            self.rootCaFiles.append(data)
        }
    }
}
 
 from:  https://www.bugsee.com/blog/ssl-certificate-pinning-in-mobile-applications/
 
 
*/
