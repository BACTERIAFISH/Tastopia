//
//  QRCodeScanViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/15.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit
import AVFoundation

class QRCodeScanViewController: UIViewController {
    
    @IBOutlet weak var videoView: UIView!
    
    @IBOutlet weak var borderView: UIView!
    
    @IBOutlet weak var showQRButton: UIButton!
    
    var task: TaskData?
    
    var passTaskID: ((String) -> Void)?
    
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        borderView.layer.cornerRadius = 16
        borderView.layer.borderColor = UIColor.white.cgColor
        borderView.layer.borderWidth = 2
        
        showQRButton.layer.cornerRadius = 16
        
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.frame = view.layer.bounds
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoView.layer.addSublayer(videoPreviewLayer)
        
        captureSession.startRunning()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureSession.isRunning == false {
            captureSession.startRunning()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        dismiss(animated: true)
    }
    
    @IBAction func showQRButtonPressed(_ sender: UIButton) {
        guard let qrCodeVC = storyboard?.instantiateViewController(withIdentifier: "QRCodeViewController") as? QRCodeViewController else { return }
        
        captureSession.stopRunning()
        
        qrCodeVC.modalPresentationStyle = .overCurrentContext
        qrCodeVC.task = task
        qrCodeVC.startScan = { [weak self] in
            self?.captureSession.startRunning()
        }
        
        present(qrCodeVC, animated: false)
    }
    
    func failed() {
        let alertController = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
        captureSession = nil
    }
    
    func found(code: String) {
        
        let range = NSRange(location: 0, length: code.utf16.count)
        do {
            let regex = try NSRegularExpression(pattern: "([a-zA-Z0-9]){20}")
            if regex.firstMatch(in: code, options: [], range: range) == nil {
                TTSwiftMessages().pause(color: UIColor.AKABENI!, icon: UIImage.asset(.Icon_32px_Error_White)!, title: "任務代碼錯誤", body: "請重新掃描同伴的任務代碼 QRCode") { [weak self] in
                    self?.captureSession.startRunning()
                }
            } else {
                passTaskID?(code)
                dismiss(animated: true, completion: {
                    TTSwiftMessages().show(color: UIColor.SUMI!, icon: UIImage.asset(.Icon_32px_Success_White)!, title: "同步任務代碼成功", body: "")
                })
            }
        } catch {
            print("found regex error: \(error)")
        }
        
    }
    
}

extension QRCodeScanViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            found(code: stringValue)
        }
        
    }
}
