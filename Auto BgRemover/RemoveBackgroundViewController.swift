//
//  RemoveBackgroundViewController.swift
//  PhotoEditorForPassport
//
//  Created by Pawan iOS on 06/10/2022.
//

import UIKit
import Combine
import Foundation

class RemoveBackgroundViewController: UIViewController {
    
    // MARK: - IBOutlets, Variables & Constants
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var manualitemView: UIView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var autoTrickButton: UIButton!
    @IBOutlet weak var manualBgRemoveButton: UIButton!
    @IBOutlet weak var backgroundRemoveButton: UIButton!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    @IBOutlet weak var colorsView: UICollectionView!
    @IBOutlet weak var tbCollectionView: UICollectionView!
    @IBOutlet weak var redoButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var brushSizeSlider: UISlider!
    @IBOutlet weak var colorsCollectionViewBottomConstrain: NSLayoutConstraint!
    @IBOutlet weak var undoButtonTralingConstraint: NSLayoutConstraint!
    var originalImage: UIImage?
    var bgRemoveImage: UIImage?
    var cancellable: AnyCancellable?
    var newImage: UIImage?
    var selectedColorIndex: Int?
    var path = UIBezierPath()
    var isDrawing: Bool = false
    var shapeLayer = CAShapeLayer()
    var previousTouchPoint = CGPoint.zero
    var brushCircle: UIView?
    var oldPathForUndo = [CGPath]()
    var redoLines = [CGPoint]()
    var undoStart: Bool = false
    var colorCollectionArray = [
        UIColor(red: 0.961, green: 0.961, blue: 0.961, alpha: 1),
        UIColor(red: 1, green: 1, blue: 1, alpha: 1),
        UIColor(red: 0.51, green: 0.678, blue: 1, alpha: 1),
        UIColor(red: 0.289, green: 0.616, blue: 1, alpha: 1),
        UIColor(red: 0.208, green: 0.596, blue: 0.859, alpha: 1),
        UIColor(red: 0.231, green: 0.541, blue: 0.906, alpha: 1),
        UIColor(red: 0.961, green: 0.961, blue: 0.961, alpha: 1)
    ]
    
    
    
    // MARK: - UIViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        brushCircle = UIView(frame: CGRect(x: imageView.center.x, y: imageView.center.y, width: 5, height: 5))
        brushCircle?.layer.cornerRadius = (brushCircle?.frame.height)! / 2
        brushCircle?.backgroundColor =  UIColor(displayP3Red: 53/255.0, green: 152/255.0, blue: 219/255.0, alpha: 1.0)
        brushCircle?.alpha = 0.5
        self.imageView.addSubview(brushCircle!)
        brushCircle?.isHidden = true
        
        imageView.image = bgRemoveImage
        originalImage = imageView.image
        bottomView.layer.cornerRadius = 30
        loader.isHidden = true
        colorsView.isHidden = true
        
        tbCollectionView.delegate = self
        tbCollectionView.dataSource = self
        
        manualBgRemoveButton.setTitle("Manual", for: .selected)
        manualBgRemoveButton.setImage(UIImage(named: "Group 33"), for: .normal)
        manualBgRemoveButton.setImage(UIImage(named: "Group 33-1"), for: .selected)
        
        
        autoTrickButton.setTitle("Auto", for: .selected)
        autoTrickButton.setImage(UIImage(named: "Group 33505"), for: .normal)
        autoTrickButton.setImage(UIImage(named: "Group 34"), for: .selected)
        
        backgroundRemoveButton.setTitle("Background", for: .selected)
        backgroundRemoveButton.setImage(UIImage(named: "layer"), for: .normal)
        backgroundRemoveButton.setImage(UIImage(named: "layer-1"), for: .selected)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        
        navigationItem.title = "Remove Background"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveButtonTapped))
    }
    
    // MARK: - Selectors
    @objc func saveButtonTapped(sender: UIBarButtonItem) {
        
        let savePhotoViewController = SavePhotoViewController()
        savePhotoViewController.modalPresentationStyle = .overCurrentContext
        savePhotoViewController.finalImage = imageView.image
        present(savePhotoViewController, animated: true, completion: nil)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if manualBgRemoveButton.isSelected {
            isDrawing = true
            if !isDrawing { return }
            if let location = touches.first?.location(in: imageView ) {
                previousTouchPoint = location
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if manualBgRemoveButton.isSelected {
            isDrawing = true
            drawMore()
            if !isDrawing { return }
            if let location = touches.first?.location(in: imageView) {
                path.move(to: location)
                path.addLine(to: previousTouchPoint)
                previousTouchPoint = location
                redoLines.append(location)
                shapeLayer.path = path.cgPath
                oldPathForUndo.append(shapeLayer.path!)
                brushCircle?.center = CGPoint(x: location.x, y: location.y)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if manualBgRemoveButton.isSelected {
            if !isDrawing { return }
            applyMask()
        }
    }
    
    // MARK: - IBActions
    @IBAction func manualBgRemove(_ sender: UIButton) {
        setupView()
        undoButton.isHidden = false
        colorsView.isHidden = true
        redoButton.isHidden = false
        autoTrickButton.isSelected = false
        backgroundRemoveButton.isSelected = false
        
        if manualBgRemoveButton.isSelected {
            manualitemView.isHidden = true
            manualBgRemoveButton.isSelected = false
            brushCircle?.isHidden = true
            applyMask()
            
        } else {
            manualitemView.isHidden = false
            manualBgRemoveButton.isSelected = true
            //isDrawing = true
            brushCircle?.isHidden = false
            undoButtonTralingConstraint.constant = 10
        }
    }
    
    @IBAction func autoRemoveBgButtonTapped(_ sender: UIButton) {
        colorsView.isHidden = true
        undoButton.isHidden = false
       
        manualitemView.isHidden = true
        manualBgRemoveButton.isSelected = false
        backgroundRemoveButton.isSelected = false
        if autoTrickButton.isSelected {
            autoTrickButton.isSelected = false
            undoButtonTralingConstraint.constant = 10
            redoButton.isHidden = false
        } else {
            autoTrickButton.isSelected = true
            undoButtonTralingConstraint.constant = -34
            loader.isHidden = false
            loader.startAnimating()
            removeBackgroundColorFromImage()
            redoButton.isHidden = true
        }
    }
    
    @IBAction func backgroundButtonTapped(_ sender: UIButton) {
        
        bgRemoveImage = image(from: imageView.layer)
        imageView.layer.mask = nil
        imageView.image = bgRemoveImage
        
        colorsCollectionViewBottomConstrain.constant = 30
        undoButton.isHidden = true
        redoButton.isHidden = true
        
        manualitemView.isHidden = true
        manualBgRemoveButton.isSelected = false
        autoTrickButton.isSelected = false
        
        if backgroundRemoveButton.isSelected {
            backgroundRemoveButton.isSelected = false
            colorsView.isHidden = true
            manualBgRemoveButton.isEnabled = true
        } else {
            backgroundRemoveButton.isSelected = true
            colorsView.isHidden = false
            manualBgRemoveButton.isEnabled = false
        }
    }
    
    @IBAction func BrushSizeSlider(_ sender: UISlider) {
        self.shapeLayer.lineWidth = CGFloat(sender.value)
        brushCircle?.frame.size = CGSize(width: CGFloat(sender.value), height: CGFloat(sender.value))
        brushCircle?.layer.cornerRadius = CGFloat(sender.value / 2)
    }
    
    @IBAction func undoButtonAction(_ sender: UIButton) {
        if autoTrickButton.isSelected == true {
            imageView.image = originalImage
        }
        shapeLayer.path = oldPathForUndo.popLast()
    }
    
    @IBAction func redoButtonAction(_ sender: UIButton) {
            if redoLines.isEmpty { return }
            if autoTrickButton.isSelected == true {
                autoTrickButton.isSelected = false
            } else  {
                path.addLine(to: redoLines.popLast()!)
                shapeLayer.path = path.cgPath
            }
    }
    
    // MARK: - Private Methods
    private func removeBackgroundColorFromImage() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            if imageView.image != nil {
                if let cgImg = imageView.image!.segmentation(){
                    let filter = GraySegmentFilter()
                    filter.inputImage = CIImage.init(cgImage: (imageView.image?.cgImage!)!)
                    filter.maskImage = CIImage.init(cgImage: cgImg)
                    let output = filter.value(forKey:kCIOutputImageKey) as! CIImage
                    let ciContext = CIContext(options: nil)
                    let cgImage = ciContext.createCGImage(output, from: output.extent)!
                    bgRemoveImage = UIImage(cgImage: cgImage)
                    imageView.image = UIImage(cgImage: cgImage)
                    loader.stopAnimating()
                    loader.hidesWhenStopped = true
                }
            }
        }
    }
    
    private func setupView() {
        self.imageView.layer.addSublayer(shapeLayer)
        updateView()
    }
    
    private func updateView() {
        self.shapeLayer.lineCap = .round
        self.shapeLayer.strokeColor = UIColor.blue.cgColor
        self.shapeLayer.opacity = 0.3
        self.imageView.isUserInteractionEnabled = true
    }
    
    private  func applyMask() -> Void {
        shapeLayer.opacity = 1.0
        imageView.layer.mask = shapeLayer
        isDrawing = false
    }
    
    private func drawMore() -> Void {
        imageView.layer.mask = nil
        shapeLayer.opacity = 0.3
        self.imageView.layer.addSublayer(shapeLayer)
        isDrawing = true
    }
    
    private func image(from layer: CALayer?) -> UIImage? {
        UIGraphicsBeginImageContext(layer?.frame.size ?? CGSize.zero)
        if let context = UIGraphicsGetCurrentContext() {
            layer?.render(in: context)
        }
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return outputImage
    }

}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension RemoveBackgroundViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colorCollectionArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = ColorCollectionViewCell.registerColorsCollectionViewCell(collectionView: collectionView, indexpath: indexPath)
        if indexPath.row == 0 {
            cell.backgroundView = UIImageView(image: UIImage(named: "colorLess"))
            cell.isUserInteractionEnabled = true
        } else if indexPath.row == 6 {
            cell.backgroundView = UIImageView(image: UIImage(named: "colors"))
            cell.isUserInteractionEnabled = true
        } else {
            cell.backgroundColor = colorCollectionArray[indexPath.row]
            cell.layer.cornerRadius = cell.layer.frame.height / 2
            cell.contentView.mask?.clipsToBounds  = true
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedColorIndex = indexPath.row
        
        if selectedColorIndex == 6 {
            let picker = UIColorPickerViewController()
            picker.delegate = self
            picker.selectedColor = self.view.backgroundColor!
            newImage  =  imageView.image?.withBackgroundColor(color: colorCollectionArray[selectedColorIndex!])
            self.present(picker, animated: true, completion: nil)
        } else {
            imageView.image = bgRemoveImage
            newImage = imageView.image?.withBackgroundColor(color: colorCollectionArray[selectedColorIndex!])
        }
        imageView.image = newImage
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 38, height: 38)
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension RemoveBackgroundViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        imageView.image = bgRemoveImage
        newImage = imageView.image?.withBackgroundColor(color: viewController.selectedColor)
        imageView.image = newImage
    }
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
    }
}

// MARK: - UIImage
extension UIImage {
    
    func withBackgroundColor(color: UIColor, opaque: Bool = true) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        
        guard let ctx = UIGraphicsGetCurrentContext(), let image = cgImage else { return self }
        defer { UIGraphicsEndImageContext() }
        let rect = CGRect(origin: .zero, size: size)
        ctx.setFillColor(color.cgColor)
        ctx.fill(rect)
        ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
        ctx.draw(image, in: rect)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
