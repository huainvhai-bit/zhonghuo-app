//
//  QRCodeScannerView.swift
//  终活
//
//  二维码扫描器 - 使用 AVFoundation
//

import SwiftUI
import UIKit
import AVFoundation

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
        requestCameraAccess()
    }
    
    private func setupUI() {
        // 视频预览层（全屏）
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        if let previewLayer = videoPreviewLayer {
            view.layer.addSublayer(previewLayer)
        }
        
        // 关闭按钮（右上角）
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.layer.cornerRadius = 20
        closeButton.frame = CGRect(x: view.bounds.width - 60, y: 50, width: 40, height: 40)
        closeButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        // 扫描框（居中）
        let boxSize: CGFloat = min(view.bounds.width - 100, 300)
        let boxX = (view.bounds.width - boxSize) / 2
        let boxY = (view.bounds.height - boxSize) / 2 - 50
        
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.clear
        overlayView.layer.cornerRadius = 12
        overlayView.layer.borderWidth = 3
        overlayView.layer.borderColor = UIColor.white.cgColor
        overlayView.frame = CGRect(x: boxX, y: boxY, width: boxSize, height: boxSize)
        view.addSubview(overlayView)
        
        // 四个角的装饰
        let cornerSize: CGFloat = 30
        let cornerWidth: CGFloat = 4
        
        // 左上角
        let topLeftCorner = UIView()
        topLeftCorner.backgroundColor = UIColor.white
        topLeftCorner.frame = CGRect(x: boxX, y: boxY, width: cornerWidth, height: cornerSize)
        view.addSubview(topLeftCorner)
        
        let topLeftCorner2 = UIView()
        topLeftCorner2.backgroundColor = UIColor.white
        topLeftCorner2.frame = CGRect(x: boxX, y: boxY, width: cornerSize, height: cornerWidth)
        view.addSubview(topLeftCorner2)
        
        // 右上角
        let topRightCorner = UIView()
        topRightCorner.backgroundColor = UIColor.white
        topRightCorner.frame = CGRect(x: boxX + boxSize - cornerWidth, y: boxY, width: cornerWidth, height: cornerSize)
        view.addSubview(topRightCorner)
        
        let topRightCorner2 = UIView()
        topRightCorner2.backgroundColor = UIColor.white
        topRightCorner2.frame = CGRect(x: boxX + boxSize - cornerSize, y: boxY, width: cornerSize, height: cornerWidth)
        view.addSubview(topRightCorner2)
        
        // 左下角
        let bottomLeftCorner = UIView()
        bottomLeftCorner.backgroundColor = UIColor.white
        bottomLeftCorner.frame = CGRect(x: boxX, y: boxY + boxSize - cornerSize, width: cornerWidth, height: cornerSize)
        view.addSubview(bottomLeftCorner)
        
        let bottomLeftCorner2 = UIView()
        bottomLeftCorner2.backgroundColor = UIColor.white
        bottomLeftCorner2.frame = CGRect(x: boxX, y: boxY + boxSize - cornerWidth, width: cornerSize, height: cornerWidth)
        view.addSubview(bottomLeftCorner2)
        
        // 右下角
        let bottomRightCorner = UIView()
        bottomRightCorner.backgroundColor = UIColor.white
        bottomRightCorner.frame = CGRect(x: boxX + boxSize - cornerWidth, y: boxY + boxSize - cornerSize, width: cornerWidth, height: cornerSize)
        view.addSubview(bottomRightCorner)
        
        let bottomRightCorner2 = UIView()
        bottomRightCorner2.backgroundColor = UIColor.white
        bottomRightCorner2.frame = CGRect(x: boxX + boxSize - cornerSize, y: boxY + boxSize - cornerWidth, width: cornerSize, height: cornerWidth)
        view.addSubview(bottomRightCorner2)
        
        // 说明文字（扫描框下方）
        let label = UILabel()
        label.text = "将二维码放入框内，即可自动扫描"
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        label.frame = CGRect(x: 50, y: boxY + boxSize + 20, width: view.bounds.width - 100, height: 40)
        view.addSubview(label)
    }
    
    private func requestCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.setupCaptureSession()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCaptureSession()
                    } else {
                        self?.showPermissionAlert()
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
        guard captureSession.inputs.isEmpty && captureSession.outputs.isEmpty else {
            return
        }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("❌ 无法获取摄像头设备")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("❌ 创建视频输入失败：\(error)")
            failed()
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            print("❌ 无法添加视频输入")
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
            
            // 设置扫描区域（中间 70%）
            metadataOutput.rectOfInterest = CGRect(x: 0.15, y: 0.15, width: 0.7, height: 0.7)
        } else {
            print("❌ 无法添加元数据输出")
            failed()
            return
        }
        
        captureSession.commitConfiguration()
        
        // 在后台线程启动会话
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            print("✅ 摄像头已启动")
        }
    }
    
    private func failed() {
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "错误", message: "无法启动相机，请检查相机权限")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.onCancel?()
        })
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
              !isScanning else {
            return
        }
        
        isScanning = true
        
        print("✅ 扫描到二维码：\(stringValue)")
        
        // 震动反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // 播放扫描音效
        AudioServicesPlaySystemSound(1104)
        
        // 高亮扫描框
        UIView.animate(withDuration: 0.2, animations: {
            // 可以添加闪烁效果
        }) { _ in
            self.onCodeScanned?(stringValue)
        }
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
