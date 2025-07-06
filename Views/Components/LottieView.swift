// LottieView.swift
import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let animation: LottieAnimation?
    var loopMode: LottieLoopMode = .playOnce
    var animationSpeed: CGFloat = 1.0
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        let animationView = LottieAnimationView()
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.animationSpeed = animationSpeed
        animationView.play()
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: view.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update animation if needed
    }
    
    func looping() -> Self {
        var view = self
        view.loopMode = .loop
        return view
    }
    
    func speed(_ speed: CGFloat) -> Self {
        var view = self
        view.animationSpeed = speed
        return view
    }
}
