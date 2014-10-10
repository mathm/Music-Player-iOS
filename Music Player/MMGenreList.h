//
//  MMGenreList.h
//  Music Player
//
//  Created by Mathias on 10/10/14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMGenre.h"

@interface MMGenreList : NSObject

@property (strong, nonatomic) NSMutableArray *genreList;

- (void) setInitialPercentage;
- (void) setInitialCellPosition;
- (void) generateNewListRanking;

@end
