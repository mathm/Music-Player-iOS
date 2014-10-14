//
//  MMViewController.m
//  Music Player
//
//  Created by Mathias on 17.09.14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "MMViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "MMMusicPlayerSongTableViewCell.h"
#import "MMCustomizePlaylistViewController.h"

@interface MMViewController ()
@property (strong, nonatomic) NSMutableArray *songsList;
@property (strong, nonatomic) id timeObserver;
@property CGPoint panXY;
@property BOOL panOverride;
@property BOOL playNextSong;
@property BOOL sliderDurationTouched;
@property (strong, nonatomic) MPMediaItem *currentSong;
@property UIBackgroundTaskIdentifier bgTaskId;

@property (strong, nonatomic) MMCustomizePlaylistViewController *customizePlaylistViewController;

@end

@implementation MMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view
    
    //setup Audio Session correctly so the audio can be played in the background
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    //necessary because the app should play a sequence of songs, otherwise killed after first one finished
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    //loading CustomizePlaylistViewController Data
    self.customizePlaylistViewController = [self.tabBarController.viewControllers objectAtIndex:1];
    
    self.tableView.dataSource =self;
    self.tableView.delegate = self;
    
    self.audioManager = [[MMAudioManager alloc]init];
    
    MPMediaQuery *everything = [[MPMediaQuery alloc] init];
    NSArray *itemsFromGenericQuery = [everything items];
    
    self.audioManager.songsList = [NSMutableArray arrayWithArray:itemsFromGenericQuery];

    //set a genre name if the resulting genre name is nil
    self.nilGenreName = @"Other";
    
    [self.tableView reloadData];
    //enable delete button on swipe
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    self.audioManager.currentSong = [self.audioManager.songsList objectAtIndex:0];
    AVPlayerItem * currentItem = [AVPlayerItem playerItemWithURL:[self.audioManager.currentSong valueForProperty:MPMediaItemPropertyAssetURL]];
    
    [self.audioManager.audioPlayer replaceCurrentItemWithPlayerItem:currentItem];
    [self.audioManager play];
    
    [self updateView];

    
    self.timeObserver = [self configurePlayer];

    // -----------------------------
    // One finger, tap
    // -----------------------------
    
    // Create gesture recognizer
    UITapGestureRecognizer *oneFingerTab =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(oneFingerTab:)];
    
    // Set required taps and number of touches
    [oneFingerTab setNumberOfTapsRequired:1];
    [oneFingerTab setNumberOfTouchesRequired:1];
    
    // Add the gesture to the view
    [self.controlView addGestureRecognizer:oneFingerTab];
    
    // -----------------------------
    // One finger, pan
    // -----------------------------
    UIPanGestureRecognizer *panRecognizer =
    [[UIPanGestureRecognizer alloc] initWithTarget:self  action:@selector(oneFingerPan:)];
    [self.controlView addGestureRecognizer:panRecognizer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd)
                                                 name:@"MMAudioManagerPlayerItemDidReachEndNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newPlaylistGenerated)
                                                 name:@"MMCustomizePlaylistNewPlaylistGeneratedNotification"
                                               object:nil];
    
    self.panOverride = true;
    self.playNextSong = true;
    self.sliderDurationTouched = false;

}

/*--------------------------------------------------------------
 * One finger, tab
 *-------------------------------------------------------------*/
- (void) oneFingerTab:(UITapGestureRecognizer *)recognizer
{
    NSLog(@"one finger tab");
    if (self.audioManager.isPlaying) {
        [self.audioManager pause];
    } else {
        [self.audioManager play];
    }
    
    [self updateView];
}

/*--------------------------------------------------------------
 * One finger, pan
 *-------------------------------------------------------------*/
- (void)oneFingerPan:(UIPanGestureRecognizer *)recognizer 
{
    if(self.sliderDurationTouched == false)
    {

        CGPoint point = [recognizer locationInView:[self view]];
        if(self.panOverride == true)
        {
            self.panXY = point;
            self.panOverride = false;
        } else
        {
            //pan right
            if(point.x > self.panXY.x +10)
            {
                NSLog(@"right %f,%f", self.panXY.x, self.panXY.y);
                if(self.playNextSong)
                {
                    [self.audioManager playPrevious];
                    self.playNextSong = false;
                    [self updateView];
                }
            }
            //pan left
             else if (point.x < self.panXY.x - 10)
            {
                NSLog(@"left %f,%f", self.panXY.x, self.panXY.y);
                if(self.playNextSong)
                {
                    //[self switchAudiofile:-1 :(int)[self.songsList indexOfObject:self.currentSong]];
                    [self.audioManager playNext];
                    self.playNextSong = false;
                    [self updateView];
                }
            }
            //pan down
            else if(point.y > self.panXY.y + 10)
            {
                NSLog(@"up %f,%f volume %f", self.panXY.x, self.panXY.y,self.audioManager.audioPlayer.volume);
                self.panOverride = true;
                if(self.audioManager.audioPlayer.volume>0)
                    self.audioManager.audioPlayer.volume = self.audioManager.audioPlayer.volume - 0.1;
            }
            //pan up
            else if(point.y < self.panXY.y - 10)
            {
                NSLog(@"up %f,%f volume %f", self.panXY.x, self.panXY.y,self.audioManager.audioPlayer.volume);
                self.panOverride = true;
                if(self.audioManager.audioPlayer.volume<1)
                    self.audioManager.audioPlayer.volume = self.audioManager.audioPlayer.volume + 0.1;
            }
        }
    }
    
    //pan ended
    if(recognizer.state == UIGestureRecognizerStateEnded)
    {
        //NSLog(@"pan end");
        self.panOverride = true;
        self.playNextSong = true;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

- (IBAction)togglePlayPauseTapped:(UIButton *)sender
{
    if(self.audioManager.isPlaying)
        [self.audioManager pause];
    else
        [self.audioManager play];
    [self updateView];
}

- (IBAction)sliderDragged:(id)sender {
    [self.audioManager.audioPlayer seekToTime:CMTimeMakeWithSeconds((int)(self.sliderOutlet.value),1)];
}

- (IBAction)sliderTouchDown:(id)sender {
    /*NSLog(@"TouchDown");
    if(self.sliderDurationTouched == false)
    {
        NSLog(@"remove timeObserver");
        self.sliderDurationTouched = true;
        //[self.audioManager.audioPlayer removeTimeObserver:(self.timeObserver)];
    }*/
}

- (IBAction)sliderTouchUpInside:(id)sender {
    //self.sliderDurationTouched = false;
    //NSLog(@"TouchUpInside - add timeObserver");
    //self.timeObserver = [self configurePlayer];
    
}

- (IBAction)sliderTouchUpOutside:(id)sender {
    //self.sliderDurationTouched = false;
    //NSLog(@"TouchUpOutside - add timeObserver");
    //self.timeObserver = [self configurePlayer];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.audioManager.songsList.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"MusicPlayerSongTableCell";
    
    MMMusicPlayerSongTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell==nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"MusicPlayerSongTableCell" owner: self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    MPMediaItem *song = [self.audioManager.songsList objectAtIndex:indexPath.row];
    NSString *songTitle = [song valueForProperty: MPMediaItemPropertyTitle];
    NSString *songArtist = [song valueForProperty:MPMediaItemPropertyArtist];
    NSString *songGenre = [song valueForProperty: MPMediaItemPropertyGenre];

    cell.labelSongTitle.text = songTitle;
    cell.labelArtist.text = songArtist;
    if (songGenre == nil) {
        songGenre = self.nilGenreName;
    }
    cell.labelGenre.text = songGenre;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.audioManager pause];
    self.audioManager.currentSong = [self.audioManager.songsList objectAtIndex:indexPath.row];
    AVPlayerItem * currentItem = [AVPlayerItem playerItemWithURL:[self.audioManager.currentSong valueForProperty:MPMediaItemPropertyAssetURL]];
    
    [self.audioManager.audioPlayer replaceCurrentItemWithPlayerItem:currentItem];
    [self.audioManager play];
    [self updateView];
    
}

/*
 override to support conditional editing of the table view cells, default is NO
 */
- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

/*
 Action if table row action is selected
 */
- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //if tablerow action delete is selected
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSLog(@"Delete");
    }
}

- (void) updateView
{
    if(self.audioManager.songsList.count>0)
    {
        //update song name
        self.songName.text = self.audioManager.currentSongTitle;
        
        //update slider maximum value
        [self.sliderOutlet setMaximumValue:self.audioManager.audioPlayer.currentItem.asset.duration.value/self.audioManager.audioPlayer.currentItem.asset.duration.timescale];
        
        //update song/album artwork
        self.imageViewArtwork.image = self.audioManager.currentArtwork;

        // update play/pause button
        if(self.audioManager.isPlaying)
            [self.togglePlayPause setSelected:NO];
        else
            [self.togglePlayPause setSelected:YES];
        
        //update tableview selected row
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.audioManager.currentSongIndex inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
    }
    else
    {
        //update song name
        self.songName.text = @"";
        
        //update slider maximum value
        [self.sliderOutlet setMaximumValue:1];
        
        //update song/album artwork
        self.imageViewArtwork.image = [UIImage imageNamed:@"blackbox.jpg"];
        
        // update play/pause button
        if(self.audioManager.isPlaying)
            [self.togglePlayPause setSelected:NO];
        else
            [self.togglePlayPause setSelected:YES];
        
        //update duration label
        self.durationOutlet.text =[NSString stringWithFormat:@"%02d:%02d",0,0];

        self.sliderOutlet.value = 0;
    }
}

-(id) configurePlayer {
    //7
    __block MMViewController * weakSelf = self;
    //8
    id timeObserver = [self.audioManager.audioPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1)
                                                   queue:NULL
                                              usingBlock:^(CMTime time) {
                                                  if(!time.value) {
                                                      return;
                                                  }
                                                  
                                                  int currentTime = (int)((weakSelf.audioManager.audioPlayer.currentTime.value)/weakSelf.audioManager.audioPlayer.currentTime.timescale);
                                                  int currentMins = (int)(currentTime/60);
                                                  int currentSec  = (int)(currentTime%60);
                                                  
                                                  NSString * durationLabel =
                                                  [NSString stringWithFormat:@"%02d:%02d",currentMins,currentSec];
                                                  weakSelf.durationOutlet.text = durationLabel;
                                                  weakSelf.sliderOutlet.value = currentTime;
                                              }];
    return timeObserver;
    
}

/*
 set Background Task Identifier for playing songs in background
 */
- (void) setBackgroundTaskIdentifier
{
    UIBackgroundTaskIdentifier newTaskId = UIBackgroundTaskInvalid;
    newTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:NULL];
    
    if(newTaskId != UIBackgroundTaskInvalid && self.bgTaskId != UIBackgroundTaskInvalid)
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTaskId];
    
    self.bgTaskId = newTaskId;
}

/*
 if audioManager plays a song to end
 */
- (void) playerItemDidReachEnd
{
    [self.audioManager playNext];
    [self updateView];
}

- (void) newPlaylistGenerated
{
    NSLog(@"new playlist set");
    //play first song on this list
    [self.audioManager play:0];
    
    [self.tableView reloadData];
    [self updateView];
}

@end
