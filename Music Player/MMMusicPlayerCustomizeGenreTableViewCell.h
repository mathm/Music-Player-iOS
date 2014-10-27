//
//  MMMusicPlayerCustomizeGenreTableViewCell.h
//  Music Player
//
//  Created by Mathias on 06.10.14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMMusicPlayerCustomizeGenreTableViewCell : UITableViewCell


@property (nonatomic, weak) IBOutlet UILabel *labelGenre;
@property (nonatomic, weak) IBOutlet UILabel *labelPercent;
@property (nonatomic, weak) IBOutlet UISlider *sliderPercent;
@property (nonatomic, weak) IBOutlet UILabel *labelFiles;

@end
