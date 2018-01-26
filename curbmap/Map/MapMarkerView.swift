// MARK: - Draggable View
// https://www.mapbox.com/ios-sdk/examples/draggable-views/
import Mapbox

class DraggableAnnotationView: MGLAnnotationView {
    enum AnnotationType : Int {
        case photo = 0
        case line = 1
        case photoNotDraggable = 2
        case lineNotDraggable = 3
    }
    var callback: ((_ mapMarker: MapMarker?)->Void)!
    var type: AnnotationType!
    
    init(reuseIdentifier: String, size: CGFloat, type: AnnotationType) {
        super.init(reuseIdentifier: reuseIdentifier)
        //
        self.type = type
        // `isDraggable` is a property of MGLAnnotationView, disabled by default.
        isDraggable = true
        
        // This property prevents the annotation from changing size when the map is tilted.
        scalesWithViewingDistance = false
        
        // Begin setting up the view.
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        
        backgroundColor = .clear
        let imageView = UIImageView(frame: frame)
        if (self.type == .photo) {
            imageView.image = UIImage(named: "photomarker")
        } else if (self.type == .line){
            imageView.image = UIImage(named: "linemarker")
        } else if (self.type == .photoNotDraggable) {
            imageView.image = UIImage(named: "photomarkerN")
            imageView.isOpaque = false
            imageView.alpha = 0.8
        } else {
            imageView.image = UIImage(named: "linemarkerN")
            imageView.isOpaque = false
            imageView.alpha = 0.8
        }
        addSubview(imageView)
    }
    
    // These two initializers are forced upon us by Swift.
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set_callback(function: @escaping(_ mapMarker: MapMarker?)->Void) {
        callback = function
    }

    
    // Custom handler for changes in the annotation’s drag state.
    override func setDragState(_ dragState: MGLAnnotationViewDragState, animated: Bool) {
        super.setDragState(dragState, animated: animated)
        
        switch dragState {
        case .starting:
            startDragging()
        case .dragging:
            break
        case .ending, .canceling:
            endDragging()
        case .none:
            return
        }
    }
    
    // When the user interacts with an annotation, animate opacity and scale changes.
    func startDragging() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
            self.layer.opacity = 0.8
            self.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
        }, completion: nil)
    }
    
    func endDragging() {
        transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
            self.layer.opacity = 1
            self.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 1)            
        }, completion: nil)
        if let updateLine = callback {
            updateLine(nil)
        }
    }
}

