//
//  ViewController.swift
//  SaveCameraSettings
//
//  Created by Tushar Chitnavis on 25/12/21.
//

import UIKit
import CoreMedia

class ViewController: UIViewController, SessionHandlerDelegate {
    

    var sessionHandler = CameraSessionHandler()
    
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var btnOK: UIButton!
    @IBOutlet weak var btnRetake: UIButton!
    
    @IBOutlet weak var lblISO_Out: UILabel!
    @IBOutlet weak var lblR_Out: UILabel!
    @IBOutlet weak var lblG_Out: UILabel!
    @IBOutlet weak var lblB_Out: UILabel!
    @IBOutlet weak var lblShtr_Out: UILabel!
    @IBOutlet weak var lblBias_Out: UILabel!
    @IBOutlet weak var lblTemp_Out: UILabel!
    @IBOutlet weak var lblTint_Out: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        startCameraSession()
    }

    @IBAction func capturePhoto(_ sender: Any) {
        self.lblISO_Out.text = String(self.sessionHandler.myDevice.iso)
        self.lblBias_Out.text = String(self.sessionHandler.myDevice.exposureTargetBias)
        self.lblShtr_Out.text = String("1/" + "\(round(1.0 / Double(CMTimeGetSeconds(self.sessionHandler.myDevice.exposureDuration))))")
        self.lblR_Out.text = String(self.sessionHandler.myDevice.deviceWhiteBalanceGains.redGain)
        self.lblG_Out.text = String(self.sessionHandler.myDevice.deviceWhiteBalanceGains.greenGain)
        self.lblB_Out.text = String(self.sessionHandler.myDevice.deviceWhiteBalanceGains.blueGain)
        self.lblTemp_Out.text = String(self.sessionHandler.myDevice.temperatureAndTintValues(for: self.sessionHandler.myDevice.deviceWhiteBalanceGains).temperature)
        self.lblTint_Out.text = String(self.sessionHandler.myDevice.temperatureAndTintValues(for: self.sessionHandler.myDevice.deviceWhiteBalanceGains).tint)
        
        sessionHandler.takephoto()
        createTempDirectoryToStoreFile()
    }
    
    @IBAction func retake(_ sender: Any) {
        if !sessionHandler.session.isRunning{
            sessionHandler.session.startRunning()
        }
    }
    
    func startCameraSession() {
        DispatchQueue.main.async {
            
            do{
                try self.sessionHandler.configure()
            } catch {
            }
            
            if !self.sessionHandler.session.isRunning{
                self.sessionHandler.session.startRunning()
            }
            
            self.startCamera()
        }
    }
    
    func startCamera()  {
        sessionHandler.delegate = self
//        self.imagePreview.layer.sublayers?.removeAll()
        let layer = sessionHandler.layer
        layer.frame = imagePreview.bounds
        
        imagePreview.layer.addSublayer(layer)
        view.layoutIfNeeded()
        imagePreview.transform =  CGAffineTransform(scaleX: -1, y: 1)
    }
    
    func createINIfile() -> String {
        
        let ISO_VALUE = "ISO"
        let WHITE_BALANCE_VALUE = "WhiteBalance"
        let TINT_VALUE = "Tint"
        let SHUTTER_SPEED_VALUE = "ShutterSpeed"
        let BIAS_VALUE = "Bias"
        
        let fileData = "\(ISO_VALUE)=\(lblISO_Out.text!)\n\(WHITE_BALANCE_VALUE)=\(lblTemp_Out.text!)\n\(TINT_VALUE)=\(lblTint_Out.text!)\n\(SHUTTER_SPEED_VALUE)=\(String(CMTimeGetSeconds(self.sessionHandler.myDevice.exposureDuration)))\n\(BIAS_VALUE)=\(lblBias_Out.text!)"
        
        return fileData
    }
    
    func createTempDirectoryToStoreFile() {
        
        let iniFileData = createINIfile()
        let fileManager = FileManager.default
        let tempDirectoryURL = fileManager.urls(for: .documentDirectory,
                                                in: .userDomainMask).first!
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmmssSSSddMMyyyy"
        
        let fileURL = tempDirectoryURL.appendingPathComponent("SavedCameraSettings_" + formatter.string(from: date) + ".txt")
        
        do {
            try iniFileData.write(to: fileURL, atomically: false, encoding: .utf8)
        } catch {
            
        }
    }
    
}

extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}

