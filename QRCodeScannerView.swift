//
//  QRCodeScannerView.swift
//  终活
//
//  使用 Vision 框架实现二维码扫描
//

import SwiftUI
import UIKit
import AVFoundation
import Vision

struct QRCodeScannerView: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    let onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.onCodeScanned = onCodeScanned
        viewController.onCancel = onCancel
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

class ScannerViewController: UIViewController {
    var onCodeScanned: ((String) -> Void)?
    var onCancel: (() -> Void)?
    
    private let captureSession = AVCaptureSession()
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var isScanning = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        checkPermissions()
    }
    
    private func setupUI() {
        // 关闭按钮
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 20
        closeButton.frame = CGRect(x: 20, y: 50, width: 40, height: 40)
        closeButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        // 扫描框
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.clear
        overlayView.layer.cornerRadius = 12
        overlayView.layer.borderWidth = 2
        overlayView.layer.borderColor = UIColor.white.cgColor
        overlayView.frame = CGRect(x: 50, y: 200, width: 300, height: 300)
        view.addSubview(overlayView)
        
        // 说明文字
        let label = UILabel()
        label.text = "将二维码放入框内，即可自动扫描"
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.frame = CGRect(x: 50, y: 520, width: 300, height: 50)
        view.addSubview(label)
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCaptureSession()
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async { [weak self] in
                self?.showPermissionAlert()
            }
        @unknown default:
            break
        }
    }
    
    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
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
        
        captureSession.commitConfiguration()
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    private func failed() {
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "错误", message: "无法启动相机")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "相机权限",
            message: "请在设置中允许访问相机以扫描二维码",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { [weak self] _ in
            self?.onCancel?()
        })
        alert.addAction(UIAlertAction(title: "打开设置", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        present(alert, animated: true)
    }
    
    @objc private func cancelTapped() {
        onCancel?()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue,
              isScanning == false else {
            return
        }
        
        isScanning = true
        
        // 震动反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // 播放扫描音效
        AudioServicesPlaySystemSound(1104)
        
        onCodeScanned?(stringValue)
    }
}

#Preview {
    QRCodeScannerView(
        onCodeScanned: { code in
            print("Scanned: \(code)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}
