//
//  MMCustomizePlaylistViewController.h
//  Music Player
//
//  Created by Mathias on 01.10.14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMGenreList.h"

@interface MMCustomizePlaylistViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UIView *controlView;
@property (weak, nonatomic) IBOutlet UITextField *textfieldFiles;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)buttonGenerateNewPlaylist:(id)sender;
- (IBAction)buttonSetInitialPercentage:(id)sender;

- (NSMutableArray *) generateNewPlaylist:(MMGenreList *)genreList :(int)size;

- (void) clearTextfieldResultingNumbersOnly:(UITextField *)textField :(int) maxPlaylistSize;

@end
