//
//  MMMusicPlayerSongTableViewCell.m
//  Music Player
//
//  Created by Mathias on 10/13/14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import "MMMusicPlayerSongTableViewCell.h"

@implementation MMMusicPlayerSongTableViewCell

//synthesize is automactically generate code for accessing the properties
@synthesize labelSongTitle = _labelSongTitle;
@synthesize labelArtist = _labelArtist;
@synthesize labelGenre = _labelGenre;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
