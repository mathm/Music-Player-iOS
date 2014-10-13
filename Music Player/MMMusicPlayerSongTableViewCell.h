//
//  MMMusicPlayerSongTableViewCell.h
//  Music Player
//
//  Created by Mathias on 10/13/14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMMusicPlayerSongTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *labelSongTitle;
@property (nonatomic, weak) IBOutlet UILabel *labelArtist;
@property (nonatomic, weak) IBOutlet UILabel *labelGenre;

@end
