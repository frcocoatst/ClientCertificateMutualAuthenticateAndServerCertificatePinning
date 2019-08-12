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
        // var request = URLRequest(url: URL(string: hostString)!)
        // request.timeoutInterval = 5
        /*
         socket = WebSocket(request: request)
         socket.delegate = self
         socket.pongDelegate = self
         socket.connect()
         */
        // var secIdentity: SecIdentity?
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
        
        makeGetRequest(hostString:"https://client.badssl.com")

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
    
    func getServerUrlCredential(protectionSpace:URLProtectionSpace)->URLCredential?{
        
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
                
                //Certificates does match, so we can trust the server
                return URLCredential(trust: serverTrust)
            }
        }
        
        return nil
        
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

