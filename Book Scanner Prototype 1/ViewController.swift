import UIKit
import Alamofire
import SwiftyJSON
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var video = AVCaptureVideoPreviewLayer()
    @IBOutlet weak var square: UIImageView!
    
    @IBOutlet weak var isbnField: UITextField!
    @IBOutlet weak var searchResults: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isbnField.delegate = self;
        let session = AVCaptureSession()
        
        let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices
        do {
            let input = try AVCaptureDeviceInput(device: device)
            session.addInput(input)
        }
        catch {
            print("error!")
        }
        
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        video = AVCaptureVideoPreviewLayer(session: session)
        
        video.frame = view.layer.bounds
        view.layer.addSublayer(video)
        
        self.view.bringSubviewToFront(square)
        
        session.startRunning()
        
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if metadataObjects != nil && metadataObjects.count != 0
        {
            if let object = metadataObjects[0] as? AVMetadataMachineReadableCodeObject
            {
                if object.type == AVMetadataObject.ObjectType.qr
                {
                    let alert = UIAlertController(title: "QR Code", message: object.stringValue, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Retake", style: .default, handler: nil))
                    alert.addAction(UIAlertAction(title: "copy", style: .default, handler: {(nil) in UIPasteboard.general.string = object.stringValue}))
                    present(alert, animated: true, completion: nil)
                }
            }
        }
        
    }
    
    @IBAction func enterISBN(_ sender: Any) {
        Alamofire.request("https://www.googleapis.com/books/v1/volumes?q=isbn:" + isbnField.text!).responseJSON { response in
            debugPrint(response)
            
            if let value = response.result.value {
                let json = JSON(value)
                if (json["totalItems"].stringValue != "0") {
                    let title = json["items"][0]["volumeInfo"]["title"].stringValue
                    let author = json["items"][0]["volumeInfo"]["authors"].arrayValue
                    let description = json["items"][0]["volumeInfo"]["description"].stringValue
                    self.searchResults.text = "Title: \(title)\n\nAuthor: \(author)\n\nSummary: \(description)"
                } else {
                    self.searchResults.text = "No books found."
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isbnField.resignFirstResponder();
    }
    
}

extension ViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true;
    }
}
