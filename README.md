# InstructionalPatch

This is an iOS hotfix framework that doesn't rely on any other language engine. It parses json files and uses the runtime to perform hot fixes. However, it also has many limitations.

## Usage

```objective-c
#import <IPIntructionPatcher/IPIntructionPatcher.h>

// use you own `json to model` tool
IPIntructionModel *model = ...
// start engine
[IPIntructionPatcher run:model];


// stop engine
[IPIntructionPatcher stop];
```

[更多用法](Usage_CN.md)

[框架介绍](http://blog.intmaxdev.com/2018/03/10/instructional-patch/)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

InstructionalPatch is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'InstructionPatch'
```

## Author

shouye

## License

InstructionPatch is available under the MIT license. See the LICENSE file for more info.