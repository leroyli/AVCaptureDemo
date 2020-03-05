//
//  ViewController.swift
//  AVCaptureDemo
//
//  Created by liyuzhu on 2020/2/25.
//  Copyright © 2020 leroy. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    lazy var videoBtn: UIButton = {
        let b = UIButton.init(type: .custom)
        b.frame = CGRect(x: 100, y: 200, width: 160, height: 80)
        b.backgroundColor = .red
        b.setTitle("Video", for: .normal)
        b.layer.cornerRadius = 10
        b.addTarget(self, action: #selector(videoAction), for: .touchUpInside)
        return b
    }()
    
    lazy var audioBtn: UIButton = {
        let b = UIButton.init(type: .custom)
        b.frame = CGRect(x: 100, y: 100, width: 160, height: 80)
        b.backgroundColor = .red
        b.setTitle("Audio", for: .normal)
        b.layer.cornerRadius = 10
        b.addTarget(self, action: #selector(audioAction), for: .touchUpInside)
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        view.addSubview(videoBtn)
        view.addSubview(audioBtn)
        
        
    }
    
    @objc func videoAction() {
        let vc = MMVideoRecordController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func audioAction() {
        let vc = MMAudioRecordController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

