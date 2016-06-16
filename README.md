# CCOInteractiveBlurView

## Description

This library aims to mimic the `UIVisualEffectView` behavior when configured with a `UIBlurEffect` effect.  
Whatever view you insert into its `contentView` won't be blurred, but everything in the background of it will.  
The main difference when comparing to `UIVisualEffectView` is that it allows to be configured with percentage values, from `0.0` to `1.0`, `0.0` being not blurred at all, and `1.0` being fully blurred.  
NOTE: you need to make a call to `prepareBlurEffect` every time you are going to use this view, before starting to animate it / set percentage values to it.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

CCOInteractiveBlurView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "CCOInteractiveBlurView"
```

## Contributions

Base yourself on the latest changes of the `develop` branch (and of course send PRs to this repository's `develop` branch).  

## Author

Gian Franco Zabarino, gfzabarino@gmail.com.  
This library is heavily based on ideas taken from [here](http://five.agency/how-to-create-an-interactive-blur-effect-in-ios8). It also uses code from Apple's `UIImageEffects` for achieving the blur effect.

## License

CCOInteractiveBlurView is available under the Apache 2.0 license. See the LICENSE.md file for more info.
