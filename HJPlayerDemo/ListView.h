//
//  ListView.h
//  HJAudioPlayer
//
//  Created by bianrongqiang on 6/24/18.
//  Copyright © 2018 bianrongqiang. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ListView : UIView
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;


@property (weak, nonatomic) IBOutlet UILabel *bufferTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *playProgressLabel;
@property (weak, nonatomic) IBOutlet UILabel *bufferSize;
@property (weak, nonatomic) IBOutlet UILabel *playStatus;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;

@end

