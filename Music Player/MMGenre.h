//
//  MMGenre.h
//  Music Player
//
//  Created by Mathias on 10/10/14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MMGenre : NSObject

@property (strong, nonatomic) NSString *name; //genre name
@property NSMutableArray *songsList; //MutableArray of MPMediaItem Items
@property int percentage; //percentage of this genre in playlist
@property long cellPosition; //position in tableView
@property int rank; //rank (computed by percentage)

@end
