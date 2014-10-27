//
//  MMViewController.h
//  Music Player
//
//  Created by Mathias on 17.09.14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MMAudioManager.h"
#import "MMGenre.h"
#import "MMGenreList.h"
#import "MMCustomizePlaylistViewController.h"

@interface MMViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

//outlets
@property (weak, nonatomic) IBOutlet UIImageView *imageViewPlayPause;
@property (strong, nonatomic) IBOutlet UILabel *songName;
@property (strong, nonatomic) IBOutlet UILabel *durationOutlet;
@property (strong, nonatomic) IBOutlet UIProgressView *progressViewOutlet;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIImageView *imageViewArtwork;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewHelpOverlay;
@property (weak, nonatomic) IBOutlet UIButton *buttonHelp;
@property (weak, nonatomic) IBOutlet UIButton *buttonBackToMainView;
@property (strong, nonatomic) IBOutlet UIView *controlView;

//other properties

/// audioManager, includes AVAudioPlayer
@property (strong, nonatomic) MMAudioManager *audioManager;
/// list of all genres, including songs of genres as well
@property (strong, nonatomic) MMGenreList *genreList;
/// name of the genre if there is no genre-name in MPMediaItem
@property NSString *nilGenreName;


/// timeObserver for used AVPlayer
@property (strong, nonatomic) id timeObserver;
/// point value needed for correct pan calculation
@property CGPoint panXY;
/// value needed for correct pan calculation
@property BOOL panOverride;
/// value needed for correct pan calculation
@property BOOL playNextSong;
/// value needed for correct pan calculation
@property BOOL skipSeconds;
/// state for help overlay (hidden or visible)
@property BOOL showHelpOverlay;
/// task identifier used for playing music in background
@property UIBackgroundTaskIdentifier bgTaskId;

//Actions
- (IBAction)buttonNewPlaylistPressed:(id)sender;
- (IBAction)buttonHelpPressed:(id)sender;
- (IBAction)buttonBackToMainViewPressed:(id)sender;

- (void) oneFingerTab:(UITapGestureRecognizer *)recognizer;
- (void) oneFingerPan:(UIPanGestureRecognizer *)recognizer;
- (void) twoFingerPan:(UIPanGestureRecognizer *)recognizer;
- (void) updateView;
- (id) generateTimeObserver;
- (void) setBackgroundTaskIdentifier;
- (void) playerItemDidReachEnd;
- (void) newPlaylistGenerated;

@end
