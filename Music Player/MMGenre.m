//
//  MMGenre.m
//  Music Player
//
//  Created by Mathias on 10/10/14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import "MMGenre.h"

/// Genre is an object that includes a list of songs that belong to this genre and some additional information like genre name
@implementation MMGenre

- (id) init
{
    if (self = [super init])
    {
        _songsList = [[NSMutableArray alloc]init];
    }
    return self;
}

@end
