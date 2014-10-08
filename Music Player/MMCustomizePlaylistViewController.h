//
//  MMCustomizePlaylistViewController.h
//  Music Player
//
//  Created by Mathias on 01.10.14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMCustomizePlaylistViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *songsList;

@property (strong, nonatomic) NSMutableArray *genreList;

@end
