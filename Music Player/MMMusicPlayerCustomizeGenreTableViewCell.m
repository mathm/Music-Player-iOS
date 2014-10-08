//
//  MMMusicPlayerCustomizeGenreTableViewCell.m
//  Music Player
//
//  Created by Mathias on 06.10.14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import "MMMusicPlayerCustomizeGenreTableViewCell.h"

@implementation MMMusicPlayerCustomizeGenreTableViewCell

//synthesize is automactically generate code for accessing the properties
@synthesize labelGenre = _labelGenre;
@synthesize labelPercent = _labelPercent;
@synthesize sliderPercent = _sliderPercent;

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
