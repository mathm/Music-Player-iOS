//
//  MMViewController.m
//  Music Player
//
//  Created by Mathias on 17.09.14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "MMViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "MMAudioManager.h"

@interface MMViewController ()
@property (strong, nonatomic) NSMutableArray *songsList;
@property (strong, nonatomic) AVPlayer *audioPlayer;
@property (strong, nonatomic) id timeObserver;
@property CGPoint panXY;
@property BOOL panOverride;
@property BOOL playNextSong;
@property (strong, nonatomic) MPMediaItem *currentSong;

@property (strong, nonatomic) MMAudioManager *audioManager;
@end

@implementation MMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view
    //1
    self.tableView.dataSource =self;
    self.tableView.delegate = self;
    //2
    
    self.audioManager = [[MMAudioManager alloc]init];
    
    MPMediaQuery *everything = [[MPMediaQuery alloc] init];
    NSArray *itemsFromGenericQuery = [everything items];
    
    self.audioManager.songsList = [NSMutableArray arrayWithArray:itemsFromGenericQuery];
    //3
    [self.tableView reloadData];
    //enable delete button on swipe
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    //4
    self.audioManager.currentSong = [self.audioManager.songsList objectAtIndex:0];
    AVPlayerItem * currentItem = [AVPlayerItem playerItemWithURL:[self.audioManager.currentSong valueForProperty:MPMediaItemPropertyAssetURL]];
    
    [self.audioManager.audioPlayer replaceCurrentItemWithPlayerItem:currentItem];
    [self.audioManager play];
    //5
    
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
    
    self.panOverride = true;
    self.playNextSong = true;

}

-(void) switchAudiofile:(int)direction :(int)indexPrevious
{
    if(indexPrevious+direction>=0 && indexPrevious+direction<=self.songsList.count)
    {
        [self.audioPlayer pause];
        self.currentSong = [self.songsList objectAtIndex:indexPrevious+direction];
        AVPlayerItem * currentItem = [AVPlayerItem playerItemWithURL:[self.currentSong valueForProperty:MPMediaItemPropertyAssetURL]];
    
        [self.audioPlayer replaceCurrentItemWithPlayerItem:currentItem];
        [self.audioPlayer play];
        [self.togglePlayPause setSelected:YES];
        NSString *songTitle = [self.currentSong valueForProperty: MPMediaItemPropertyTitle];
        self.songName.text = songTitle;
        [self.sliderOutlet setMaximumValue:self.audioPlayer.currentItem.asset.duration.value/self.audioPlayer.currentItem.asset.duration.timescale];
    }
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
    
    //pan ended
    if(recognizer.state == UIGestureRecognizerStateEnded)
    {
        NSLog(@"pan end");
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
    //NSLog(@"TouchDown -remove timeObserver");
    //[self.audioManager.audioPlayer removeTimeObserver:(self.timeObserver)];
}

- (IBAction)sliderTouchUpInside:(id)sender {
    //NSLog(@"TouchUpInside - add timeObserver");
     //self.timeObserver = [self configurePlayer];
    
}

- (IBAction)sliderTouchUpOutside:(id)sender {
    //NSLog(@"TouchUpOutside - add timeObserver");
     //self.timeObserver = [self configurePlayer];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.audioManager.songsList.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"MusicCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
    
    MPMediaItem *song = [self.audioManager.songsList objectAtIndex:indexPath.row];
    NSString *songTitle = [song valueForProperty: MPMediaItemPropertyTitle];
    NSString *songArtist = [song valueForProperty:MPMediaItemPropertyArtist];
    NSString *durationLabel = [song valueForProperty: MPMediaItemPropertyGenre];
    //cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@",songTitle,songArtist];
    cell.textLabel.text = songTitle;
    cell.detailTextLabel.text = durationLabel;
    
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
 if audiomManager plays a song to end
 */
- (void) playerItemDidReachEnd
{
    [self.audioManager playNext];
    [self updateView];
}


@end
