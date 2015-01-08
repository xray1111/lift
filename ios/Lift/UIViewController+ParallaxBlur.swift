import Foundation

internal class UIParallaxViewController : UIViewController, UIScrollViewDelegate {
    private var headerOverlayView: UIView?
    // TODO: height here
    private let imageHeight: CGFloat = 193.0
    private let headerHeight: CGFloat = 72.0
    private let blurDistance: CGFloat = 200.0

    private let mainScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        scrollView.autoresizesSubviews = true
        return scrollView
    }()
    private let backgroundScrollView: UIScrollView = {
       let backgroundView = UIScrollView()
        backgroundView.scrollEnabled = false
        backgroundView.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        backgroundView.autoresizesSubviews = true
        return backgroundView
    }()
    private let headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        imageView.backgroundColor = UIColor.whiteColor()
        return imageView
    }()
    private let floatingHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clearColor()
        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        return view
        //return UIVisualEffectView(effect: UIVibrancyEffect()).cont
    }()
    private let scrollViewContainer: UIView = {
        let svc = UIView()
        svc.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        return svc
    }()
    private var cv: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up the holding view
        cv = contentView()
        cv.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        cv.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.New, context: nil)
        
        // set our view to be the scroll view
        let contentHeight = cv.contentSize.height + imageHeight
        mainScrollView.contentSize = CGSizeMake(view.frame.size.width, contentHeight)
        mainScrollView.delegate = self
        mainScrollView.frame = view.frame
        view = mainScrollView
        
        // background scroll view
        backgroundScrollView.contentSize = CGSizeMake(view.frame.size.width, contentHeight)

        // set up frames
        backgroundScrollView.frame = CGRectMake(0, 0, CGRectGetWidth(view.frame), imageHeight)
        headerImageView.frame = CGRectMake(0, 0, CGRectGetWidth(backgroundScrollView.frame), CGRectGetHeight(backgroundScrollView.frame))
        floatingHeaderView.frame = backgroundScrollView.frame
        scrollViewContainer.frame = CGRectMake(0, CGRectGetHeight(backgroundScrollView.frame), CGRectGetWidth(view.frame), CGRectGetHeight(view.frame) - offsetHeight())
        
        // set up the view structure
        backgroundScrollView.addSubview(headerImageView)
        scrollViewContainer.addSubview(cv!)
        mainScrollView.addSubview(backgroundScrollView)
        mainScrollView.addSubview(floatingHeaderView)
        mainScrollView.addSubview(scrollViewContainer)
    }

    override func viewWillAppear(animated: Bool) {
        cv.frame = CGRectMake(0, 0, CGRectGetWidth(scrollViewContainer.frame), CGRectGetHeight(view.frame) - offsetHeight())
    }
    
    override func viewDidAppear(animated: Bool) {
        mainScrollView.contentSize = CGSizeMake(CGRectGetWidth(view.frame), cv.contentSize.height + CGRectGetHeight(backgroundScrollView.frame))
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if keyPath == "contentSize" {
            if let nsv = change[NSKeyValueChangeNewKey] as? NSValue {
                let newSize = nsv.CGSizeValue()
                mainScrollView.contentSize = CGSizeMake(CGRectGetWidth(view.frame), newSize.height + CGRectGetHeight(backgroundScrollView.frame))
            }
        }
    }
    
    func navBarHeight() -> CGFloat {
        if let x = navigationController {
            if !x.navigationBarHidden {
                return CGRectGetHeight(x.navigationBar.frame) + 20
            }
        }
        return 0
    }

    func offsetHeight() -> CGFloat {
        return headerHeight + navBarHeight();
    }
    
    func contentView() -> UIScrollView {
        fatalError("Implement me")
    }
    
    func scrollToTop() {
        mainScrollView.contentOffset.y = 10
    }

    // MARK: UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var delta: CGFloat = 0
        let rect = CGRectMake(0, 0, CGRectGetWidth(scrollViewContainer.frame), imageHeight)
        let backgroundScrollViewLimit = backgroundScrollView.frame.size.height - offsetHeight()
        
        if scrollView.contentOffset.y < 0.0 {
            //calculate delta
            delta = abs(min(0.0, mainScrollView.contentOffset.y + navBarHeight()))
            backgroundScrollView.frame = CGRectMake(CGRectGetMinX(rect) - delta / 2.0, CGRectGetMinY(rect) - delta,
                CGRectGetWidth(scrollViewContainer.frame) + delta, CGRectGetHeight(rect) + delta)
        } else {
            delta = mainScrollView.contentOffset.y;
            
            // Here I check whether or not the user has scrolled passed the limit where I want to stick the header, if they have then I move the frame with the scroll view
            // to give it the sticky header look
            if (delta > backgroundScrollViewLimit) {
                backgroundScrollView.frame = CGRect(origin: CGPoint(x: 0, y: delta - backgroundScrollView.frame.size.height + offsetHeight()), size: CGSize(width: CGRectGetWidth(scrollViewContainer.frame), height: imageHeight))
                floatingHeaderView.frame = CGRect(origin: CGPoint(x: 0, y: delta - floatingHeaderView.frame.size.height + offsetHeight()), size: CGSize(width: CGRectGetWidth(scrollViewContainer.frame), height: imageHeight))
                scrollViewContainer.frame = CGRect(origin: CGPoint(x: 0, y: CGRectGetMinY(backgroundScrollView.frame) + CGRectGetHeight(backgroundScrollView.frame)), size: scrollViewContainer.frame.size)
                cv.contentOffset = CGPointMake(0, delta - backgroundScrollViewLimit)
                let contentOffsetY = -backgroundScrollViewLimit * 0.5
                backgroundScrollView.contentOffset = CGPoint(x: 0, y: contentOffsetY)
            } else {
                backgroundScrollView.frame = rect
                floatingHeaderView.frame = rect
                scrollViewContainer.frame = CGRect(origin: CGPoint(x: 0, y: CGRectGetMinY(rect) + CGRectGetHeight(rect)), size: scrollViewContainer.frame.size)
                cv.contentOffset = CGPoint(x: 0, y: 0)
                backgroundScrollView.contentOffset = CGPoint(x: 0, y: -delta * 0.5)
            }
        }
    }
    
    // MARK: Public methods
    
    func setHeaderImage(headerImage: UIImage) {
        if let x = headerImage.applyExtraLightEffect() {
            headerImageView.image = x
            if let nb = navigationController?.navigationBar {
                let ac = x.averageColor()
                nb.barTintColor = ac
            }
        }
    }
    
    func addHeaderOverlayView(overlayView: UIView) {
        headerOverlayView = overlayView
        headerOverlayView!.frame = headerImageView.frame
        headerOverlayView!.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        floatingHeaderView.addSubview(overlayView)
    }
    
}