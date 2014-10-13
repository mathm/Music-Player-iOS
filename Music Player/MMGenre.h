//
//  MMGenre.h
//  Music Player
//
//  Created by Mathias on 10/10/14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MMGenre : NSObject

@property (strong, nonatomic) NSString *name;
@property int filesInDatabase;
@property int percentage;
@property long cellPosition;
@property int rank;

@end
