//
//  MMGenre.h
//  Music Player
//
//  Created by Mathias on 10/10/14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MMGenre : NSObject
/// genre name
@property (strong, nonatomic) NSString *name;
/// MutableArray of MPMediaItem Items
@property NSMutableArray *songsList;
/// percentage of this genre in playlist
@property int percentage;
/// position in tableView
@property long cellPosition;
/// rank (computed by percentage)
@property int rank;

@end
