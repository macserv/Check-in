//
//  QRCodeScanner.swift
//  CheckIn
//
//  Created by Anand Kelkar on 15/02/18.
//

import Foundation

import UIKit
import AVFoundation
import CoreData

class QRScannerController: UIViewController {
    
    var captureSession = AVCaptureSession()
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    var scan=true;
    
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.upce,
                                      AVMetadataObject.ObjectType.code39,
                                      AVMetadataObject.ObjectType.code39Mod43,
                                      AVMetadataObject.ObjectType.code93,
                                      AVMetadataObject.ObjectType.code128,
                                      AVMetadataObject.ObjectType.ean8,
                                      AVMetadataObject.ObjectType.ean13,
                                      AVMetadataObject.ObjectType.aztec,
                                      AVMetadataObject.ObjectType.pdf417,
                                      AVMetadataObject.ObjectType.itf14,
                                      AVMetadataObject.ObjectType.dataMatrix,
                                      AVMetadataObject.ObjectType.interleaved2of5,
                                      AVMetadataObject.ObjectType.qr]
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        let backButtonAttributes: NSDictionary = [NSAttributedStringKey.foregroundColor: ColorSettings.navTextColor]
        UIBarButtonItem.appearance().setTitleTextAttributes(backButtonAttributes as? [NSAttributedStringKey:Any], for: UIControlState.normal)
        
        //Unhide page control
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "unhidePageControl"), object: nil)
        
        //Enable swipe
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "createSwipeList"), object: nil)
        
        enableScan()
    }
    
    @objc func enableScan()
    {
        scan=true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Unhide page control
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "unhidePageControl"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(enableScan), name: NSNotification.Name(rawValue: "scanEnable"), object: nil)
        
        // Get the back-facing camera for capturing videos
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("Failed to get the camera device")
            return
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Set the input device on the capture session.
            captureSession.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        // Start video capture.
        captureSession.startRunning()
        
        // Initialize QR Code Frame to highlight the QR code
        qrCodeFrameView = UIView()
        
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 5
            view.addSubview(qrCodeFrameView)
            view.bringSubview(toFront: qrCodeFrameView)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var gid:String=""
    var gfname:String=""
    var glname:String=""
    var gsname:String=""
    var gmedia:String=""
    var gvip:String=""
    var gpicture:UIImage=UIImage(named:"default")!
    var gchecked:Bool=false
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let profile = segue.destination as? ProfileViewController
        {
            profile.id=gid
            profile.fname=gfname
            profile.lname=glname
            profile.sname=gsname
            profile.media=gmedia
            profile.spicture=gpicture
            profile.vip=gvip
            profile.method=1
            
        }
    }
    
    
    //Function called for profile view
    func showProfile(id:String) {
        if(scan)
        {
        scan=false
        //Find student record by APS ID
        var student : [NSManagedObject]
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Student")
        fetchRequest.predicate = NSPredicate(format: "studentId == %@", id)
        do {
            student = try managedContext.fetch(fetchRequest)
            
            if(student.isEmpty)
            {
                let invalidQrAlert = UIAlertController(title:"No record found", message:"No record was found for the scanned code. Try using the manual search", preferredStyle: .alert)
                invalidQrAlert.addAction(UIAlertAction(title:"OK", style: .cancel, handler:nil))
                self.present(invalidQrAlert, animated:true)
            }
            else{
                
//                let foundAlert = UIAlertController(title:"Success", message:"Student record found.", preferredStyle: .alert)
//                foundAlert.addAction(UIAlertAction(title:"Continue", style: .default, handler:
//                    {
//                        (alertAction: UIAlertAction) in
//
                        //Fields and labels
                        let studentRecord=student.first
                        self.gfname=studentRecord?.value(forKey:"firstName") as! String
                        self.glname=studentRecord?.value(forKey:"lastName") as! String
                        self.gsname=studentRecord?.value(forKey:"school") as! String
                        self.gmedia=studentRecord?.value(forKey:"media") as! String
                        self.gid=studentRecord?.value(forKey:"studentId") as! String
                        self.gvip=studentRecord?.value(forKey: "vip") as! String
                        
                        if(UIImage(named:self.gid) != nil)
                        {
                            self.gpicture=UIImage(named:self.gid)!
                        }
                        else{
                            self.gpicture=UIImage(named:"default")!
                        }
                        
                        self.performSegue(withIdentifier: "showProfile", sender: self)
                        
//                }
//                ))
//                self.present(foundAlert, animated:true)
            
            }
        }catch _ as NSError {
            print ("Could not fetch data")
        }
    }
    }
    
}

extension QRScannerController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata (or barcode) then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                showProfile(id: metadataObj.stringValue!.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
    }
    
}
