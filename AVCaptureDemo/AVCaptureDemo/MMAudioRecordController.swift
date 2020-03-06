//
//  MMAudioRecordController.swift
//  VideoCaptureDemo
//
//  Created by liyuzhu on 2020/2/25.
//
//

import UIKit
import AVFoundation

class MMAudioRecordController: UIViewController {
    fileprivate var recorder:AVAudioRecorder? //录音器
    fileprivate var player:AVAudioPlayer? //播放器
    fileprivate var recorderSeetingsDic:[String : Any]? //录音器设置参数数组
    fileprivate var volumeTimer:Timer! //定时器线程，循环监测录音的音量大小
    fileprivate var aacPath:String? //录音存储路径
    fileprivate var timer: Timer!
    fileprivate var duration: Int = 0
    
    //MARK: - lazy var
    //显示录音音量
    lazy var volumLab: UILabel = {
        let l = UILabel.init(frame: CGRect(x: 100, y: 500, width: 200, height: 20))
        l.textAlignment = .center
        return l
    }()
    
    lazy var recordBtn: UIButton = {
        let b = UIButton.init(type: .custom)
        b.frame = CGRect(x: 100, y: 100, width: 160, height: 100)
        b.backgroundColor = .red
        b.setTitle("startRecord", for: .normal)
        b.setTitle("stopRecord", for: .selected)
        b.layer.cornerRadius = 10
        b.addTarget(self, action: #selector(recordAction(_:)), for: .touchUpInside)
        return b
    }()
    
    lazy var playbtn: UIButton = {
        let b = UIButton.init(type: .custom)
        b.frame = CGRect(x: 100, y: 230, width: 160, height: 100)
        b.backgroundColor = .red
        b.setTitle("play", for: .normal)
        b.layer.cornerRadius = 10
        b.addTarget(self, action: #selector(playAction(_:)), for: .touchUpInside)
        return b
    }()
    
    lazy var timeLabel: UILabel = {
        let l = UILabel.init(frame: CGRect(x: 50, y: 10, width: 60, height: 20))
        l.textAlignment = .center
        l.text = "00:00"
        return l
    }()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.timer.invalidate()
        self.timer = nil
    }
    
    //MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        view.addSubview(recordBtn)
        view.addSubview(playbtn)
        view.addSubview(volumLab)
        recordBtn.addSubview(timeLabel)
        
        setupRecorder()
    }
    
    deinit {
        print(">>>>>>deinit")
    }
}

extension MMAudioRecordController {
    func setupRecorder() {
        //初始化录音器
        let session:AVAudioSession = AVAudioSession.sharedInstance()
         
        //设置录音类型
        try! session.setCategory(AVAudioSession.Category.playAndRecord)
        //设置支持后台
        try! session.setActive(true)
        //获取Document目录
        let docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                         .userDomainMask, true)[0]
        //组合录音文件路径
        aacPath = docDir + "/play.aac"
        //初始化字典并添加设置参数
        recorderSeetingsDic =
            [
                AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
                AVNumberOfChannelsKey: 2, //录音的声道数，立体声为双声道
                AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
                AVEncoderBitRateKey : 320000,
                AVSampleRateKey : 44100.0 //录音器每秒采集的录音样本数
            ]
    }
    
    //定时检测录音音量
    @objc func levelTimer(){
        recorder!.updateMeters() // 刷新音量数据
        let _:Float = recorder!.averagePower(forChannel: 0) //获取音量的平均值
        let maxV:Float = recorder!.peakPower(forChannel: 0) //获取音量最大值
        let lowPassResult:Double = pow(Double(10), Double(0.05*maxV))
        volumLab.text = "录音音量:\(lowPassResult)"
    }
}

extension MMAudioRecordController {
    @objc func recordAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            startTimer()
            startAction()
        } else {
            stopTimer()
            stopAction()
        }
    }
    
    //MARK: - 播放
    @objc func playAction(_ sender: UIButton) {
        play()
    }
    
    //MARK: - 开始录音
    func startAction() {
        //初始化录音器
        recorder = try! AVAudioRecorder(url: URL(string: aacPath!)!,
                                        settings: recorderSeetingsDic!)
        if recorder != nil {
            //开启仪表计数功能
            recorder!.isMeteringEnabled = true
            //准备录音
            recorder!.prepareToRecord()
            //开始录音
            recorder!.record()
            //启动定时器，定时更新录音音量
            volumeTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self,
                                               selector: #selector(levelTimer),
                                userInfo: nil, repeats: true)
        }
    }
    
    //MARK: - 结束录音
    func stopAction() {
        //停止录音
        recorder?.stop()
        //录音器释放
        recorder = nil
        //暂停定时器
        volumeTimer.invalidate()
        volumeTimer = nil
        volumLab.text = "录音音量:0"
    }
    
    //MARK: - 播放录制的声音
    func play() {
        //播放
        player = try! AVAudioPlayer(contentsOf: URL(string: aacPath!)!)
        if player == nil {
            print(">>>>>>播放失败")
        } else {
            player?.play()
        }
    }
}

extension MMAudioRecordController {
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
    
    func startTimer() {
        setupTimer()
    }
    
    func stopTimer() {
        duration = 0
        timeLabel.text = "00:00"
        self.timer.fireDate = Date.distantFuture
    }
}
