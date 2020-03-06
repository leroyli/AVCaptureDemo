//
//  MMVideoRecordController.swift
//  AVCaptureDemo
//
//  Created by liyuzhu on 2020/2/25.
//  Copyright © 2020 leroy. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import PhotosUI

class MMVideoRecordController: UIViewController {
    
    fileprivate lazy var session : AVCaptureSession = AVCaptureSession()
    fileprivate var videoOutput : AVCaptureVideoDataOutput?
    fileprivate var previewLayer : AVCaptureVideoPreviewLayer?
    fileprivate var videoInput : AVCaptureDeviceInput?
    fileprivate var fileOutPut: AVCaptureMovieFileOutput?
    fileprivate var duration: Int = 0
    fileprivate var timer: Timer!
    /** .mov or .mp4*/
    fileprivate let url = URL(fileURLWithPath: "\(NSHomeDirectory())/tmp/movie.mp4")
    
    //MARK: - lazy var
    lazy var recordBtn: UIButton = {
        let b = UIButton.init(type: .custom)
        b.frame = CGRect(x: 140, y: 500, width: 80, height: 80)
        b.backgroundColor = .red
        b.setImage(UIImage(named: "play_normal"), for: .normal)
        b.setImage(UIImage(named: "pause_normal"), for: .selected)
        b.layer.cornerRadius = 40
        b.addTarget(self, action: #selector(recordAction(_:)), for: .touchUpInside)
        return b
    }()
    
    lazy var switchCameraBtn: UIButton = {
        let b = UIButton.init(type: .custom)
        b.frame = CGRect(x: 50, y: 520, width: 40, height: 40)
        b.backgroundColor = .clear
        b.setImage(UIImage(named: "camera_switch"), for: .normal)
        b.layer.cornerRadius = 20
        b.addTarget(self, action: #selector(rotateCamera), for: .touchUpInside)
        return b
    }()
    
    lazy var timeLabel: UILabel = {
        let l = UILabel.init(frame: CGRect(x: 260, y: 530, width: 60, height: 20))
        l.textAlignment = .center
        l.text = "00:00"
        return l
    }()
    
    lazy var tipsLabel: UILabel = {
        let l = UILabel.init(frame: CGRect(x: 260, y: 530, width: 100, height: 20))
        l.center = self.view.center
        l.textAlignment = .center
        l.text = "saved to album"
        return l
    }()
    
    //MARK: - life cycle
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.timer.invalidate()
        self.timer = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        view.addSubview(recordBtn)
        view.addSubview(switchCameraBtn)
        view.addSubview(timeLabel)
        view.addSubview(tipsLabel)
        tipsLabel.isHidden = true
        
        //1.初始化视频的输入&输出
        setUpVideoInputOutput()
        
        //2.初始化音频的输入&输出
        setupAudioInputOutput()
        
        //3.初始化一个预览图层
        setupPreviewLayer()
        
        // 设置输出路径
        setupFileOutput()
        
        session.startRunning()
    }

    deinit {
        session.stopRunning()
        print(">>>>>>deint")
    }
}

extension MMVideoRecordController {
    @objc func recordAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            startTimer()
            startCapturing()
        } else {
            stopCapturing()
            stopTimer()
        }
    }
    
    //MARK: - startCapturing
    func startCapturing(){
    //  let connection = self.fileOutPut?.connection(with: .video)
        self.fileOutPut?.startRecording(to: self.url, recordingDelegate: self)
            
    }
    
    //MARK: - stopCapturing
    func stopCapturing(){
        self.fileOutPut?.stopRecording()
        saveToAlbum(self.url)
    }
    
    //MARK: - rotateCamera
    @objc func rotateCamera(){
        guard let videoInput = videoInput else {
            return
        }
        let position : AVCaptureDevice.Position = (videoInput.device.position == .front) ? .back: .front
        guard let devices = AVCaptureDevice.devices() as? [AVCaptureDevice] else {return}
        guard let device = devices.filter({$0.position == position}).first else {return}
        guard let input = try? AVCaptureDeviceInput(device: device) else {return}
        
        //移除旧的input，添加新input
        session.beginConfiguration()
        session.removeInput(videoInput)
        if session.canAddInput(input) {
            session.addInput(input)
        }
        session.commitConfiguration()
        
        self.videoInput = input
    }
}

extension MMVideoRecordController {
    //MARK: - timer
    func setupTimer() {
        if let timer = self.timer {
            DispatchQueue.main.async {
                timer.fireDate = Date()
            }
            
        } else {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
            self.timer.fire()
        }
        
    }
    
    @objc func timerAction() {
        duration = duration + 1
        var text: String = "00:00"
        if duration < 10 {
            text = "00:0\(duration)"
        }
        if duration >= 10 && duration < 60 {
            text = "00:\(duration)"
        }
        if duration >= 60 {
            let s = duration % 60
            let min = duration / 60
            
            var mins: String = ""
            if min < 10 {
                mins = "0\(min)"
            }
            if min >= 10 && min < 60 {
                mins = "\(min)"
            }
            
            if s < 10 {
                text = "\(mins):0\(s)"
            } else {
                text = "\(mins):\(s)"
            }
        }
        timeLabel.text = text
    }
    
    //MARK: - startTimer
    func startTimer() {
        setupTimer()
    }
    
    //MARK: - stopTimer
    func stopTimer() {
        duration = 0
        timeLabel.text = "00:00"
        self.timer.fireDate = Date.distantFuture
    }
}

extension MMVideoRecordController {
    fileprivate func setUpVideoInputOutput() {
        //1.添加视频输入
        guard let devices = AVCaptureDevice.devices() as? [AVCaptureDevice] else {return}
        guard let device = devices.filter({$0.position == .front}).first else {return}
        guard let input = try? AVCaptureDeviceInput(device: device) else {return}
        self.videoInput = input
        
        //2.添加视频输出
        let output = AVCaptureVideoDataOutput()
        let queue = DispatchQueue.global()
        output.setSampleBufferDelegate(self, queue: queue)
        self.videoOutput = output
        
        //3.添加输入&输出
        addInputOutputToSession(input, output)
    }
    
    //MARK: - outPutFile
    func setupFileOutput() {
        self.fileOutPut = AVCaptureMovieFileOutput.init()
        self.fileOutPut?.movieFragmentInterval = .init()
        
        if self.session.canAddOutput(self.fileOutPut!) {
            self.session.addOutput(self.fileOutPut!)
        }
    }
    
    fileprivate func setupAudioInputOutput() {
        //1.创建输入
        guard let device = AVCaptureDevice.default(for: .audio) else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        //2.创建输出
        let output = AVCaptureAudioDataOutput()
        let queue = DispatchQueue.global()
        output.setSampleBufferDelegate(self, queue: queue)
        
        //3.添加输入&输出
        addInputOutputToSession(input, output)
    }
    
    private func addInputOutputToSession(_ input : AVCaptureInput, _ output : AVCaptureOutput){
        session.beginConfiguration()
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
    }
    
    fileprivate func setupPreviewLayer() {
        //1.创建预览图层
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        //2.设置previewLayer属性
        previewLayer.frame = view.bounds;
        
        //3.将图层添加到控制器的view的layer中
        view.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer
    }
}

extension MMVideoRecordController {
    func saveToAlbum(_ url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { (success, err) in
            if success {
                self.tipsLabel.isHidden = false
                DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                    self.tipsLabel.isHidden = true
                }
                print(">>>>> save video success")
            }
        }
        
    }
    
}

extension MMVideoRecordController : AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if videoOutput?.connection(with: .video) == connection {
            print(">>>>>采集视频")
        } else {
            print(">>>>>>采集音频")
        }
    }
}

extension MMVideoRecordController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print(">>>>>didStartRecording")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print(">>>>>didFinishRecording")
    }
}
