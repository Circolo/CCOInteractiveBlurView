Pod::Spec.new do |s|
  s.name             = 'CCOInteractiveBlurView'
  s.version          = '0.1.4'
  s.summary          = 'Interactive Blur View, inspired on UIVisualEffectView configured with UIBlurEffect.'

  s.description      = <<-DESC
Interactive Blur View, inspired on UIVisualEffectView configured with UIBlurEffect. The blurring effect can be set
proportionally to a given percentage, ideal to be used with a UIPanGestureRecognizer that changes this value.
                       DESC

  s.homepage         = 'https://github.com/Circolo/CCOInteractiveBlurView'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE.md' }
  s.author           = { 'Gian Franco Zabarino' => 'gfzabarino@gmail.com' }
  s.source           = { :git => 'https://github.com/Circolo/CCOInteractiveBlurView.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'CCOInteractiveBlurView/Classes/**/*'

  s.public_header_files = 'CCOInteractiveBlurView/Classes/**/*.h'
  s.frameworks = 'UIKit', 'Accelerate'
end
