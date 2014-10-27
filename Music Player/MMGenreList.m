//
//  MMGenreList.m
//  Music Player
//
//  Created by Mathias on 10/10/14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import "MMGenreList.h"

/// includes a list of genres and some methods to manage them
@implementation MMGenreList

- (id) init
{
    if (self = [super init])
    {
        _genreList = [[NSMutableArray alloc]init];;
        
    }
    return self;
}


/// set initial percentage (100/list count)
- (void) setInitialPercentage
{
    for (int i=0; i<self.genreList.count; i++) {
        [[self.genreList objectAtIndex:i] setPercentage:(100/self.genreList.count) ];
    }
}

/// set the initial cell position of each genre
- (void) setInitialCellPosition
{
    for (int i=0; i<self.genreList.count; i++) {
        [[self.genreList objectAtIndex:i] setCellPosition:i];
    }
}

/// generate new List Ranking sorted by Attribute rank (insertion sort)
- ( void) generateNewListRanking
{
    NSMutableArray *tmpArr = [[NSMutableArray alloc]init];
    [tmpArr addObjectsFromArray:self.genreList];
    long count = tmpArr.count;
    int i,j;
    
    // insertion sort by percentage
    for(i=1;i<count;i++)
    {
        j=i;

        while(j>0 && [[tmpArr objectAtIndex:j-1] percentage] > [[tmpArr objectAtIndex:j] percentage])
        {
            // exchange j with j-1
            [tmpArr exchangeObjectAtIndex:j withObjectAtIndex:(j-1)];
            j=j-1;
        }
    }
    
    // generate new ranking by sortet tmp array
    for(i=0;i<tmpArr.count;i++)
    {
        for (j=0; j<self.genreList.count; j++) {
            if([[self.genreList objectAtIndex:j] cellPosition] == [[tmpArr objectAtIndex:i] cellPosition])
                [[self.genreList objectAtIndex:j] setRank:i];
        }
    }
}

@end
