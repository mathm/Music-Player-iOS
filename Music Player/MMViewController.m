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

@property (strong, nonatomic) MMCustomizePlaylistViewController *customizePlaylistViewController; // MMCustomizePlaylistViewController
@property (strong, nonatomic) id timeObserver; // timeObserver for used AVPlayer
@property CGPoint panXY; // point value needed for correct pan calculation
@property BOOL panOverride; // value needed for correct pan calculation
@property BOOL playNextSong; // value needed for correct pan calculation
@property BOOL skipSeconds; // value needed for correct pan calculation
@property BOOL showHelpOverlay; // state for help overlay (hidden or visible)
@property UIBackgroundTaskIdentifier bgTaskId; // task identifier used for playing music in background

@end

@implementation MMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setup Audio Session correctly so the audio can be played in the background
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    // necessary because the app should play a sequence of songs, otherwise killed after first one finished
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    // set CustomizePlaylistViewController (used for data access)
    self.customizePlaylistViewController = [self.tabBarController.viewControllers objectAtIndex:1];
    
    self.tableView.dataSource =self;
    self.tableView.delegate = self;
    
    // enable delete button on swipe
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    self.audioManager = [[MMAudioManager alloc]init];
    
    // set a genre name if the resulting genre name is nil
    self.nilGenreName = @"Other";
    
    // -----------------------------
    // music libary query
    // -----------------------------
    
    MPMediaQuery *musicLibraryWithoutCloud = [[MPMediaQuery alloc] init];
    // add filter to avoid cloud music and videos
    [musicLibraryWithoutCloud addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithBool:NO] forProperty:MPMediaItemPropertyIsCloudItem]];
    
    NSArray *itemsFromGenericQuery = [musicLibraryWithoutCloud items];
    
    // set initial song list
    self.audioManager.songsList = [NSMutableArray arrayWithArray:itemsFromGenericQuery];
    
    // -----------------------------
    // setup genre list and start playing if there is a song in the itunes music db
    // -----------------------------
    
    self.genreList = [[MMGenreList alloc]init];
    
    // if there is any song in itunes music db
    if(self.audioManager.songsList.count > 0)
    {
        // generate string array with all occuring genres
        NSMutableArray *tmpArr = [[NSMutableArray alloc]init];
        BOOL isNilGenre = false;
        for(MPMediaItem *song in self.audioManager.songsList)
        {
            NSString *genre = [song valueForProperty: MPMediaItemPropertyGenre];
            if(genre != nil)
            {
                if ([tmpArr containsObject:genre]==false) {
                    [tmpArr addObject:genre];
                }
            }
            else if (isNilGenre == false) // if there is a song without genre add genre "Other" to genre list
            {
                isNilGenre = true;
                genre = self.nilGenreName;
                if ([tmpArr containsObject:genre]==false) {
                    [tmpArr addObject:genre];
                }
            }
        }
        
        // generate array of type genre
        for(NSString *genreName in tmpArr)
        {
            MMGenre *genre = [[MMGenre alloc]init];
            genre.name = genreName;
            
            [self.genreList.genreList addObject:genre];
        }
        
        // add all songs of each genre to their dedicated genre list
        for(MPMediaItem *song in self.audioManager.songsList)
        {
            NSString *genreName = [song valueForProperty: MPMediaItemPropertyGenre];
            
            if(genreName == nil)
                genreName = self.nilGenreName;
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@",genreName];
            NSArray *tmpArr = [self.genreList.genreList filteredArrayUsingPredicate:predicate];
            if(tmpArr.count>0)
            {
                MMGenre *genre = [tmpArr objectAtIndex:0];
                [genre.songsList addObject: song];
            }
        }
        
        // set some initial values for genre lists
        [self.genreList setInitialPercentage];
        [self.genreList setInitialCellPosition];
        
        // set amount of songs in playlist
        self.audioManager.playListAmountOfFiles = (int)self.audioManager.songsList.count;
        
        // generate and set initial playlist
        self.audioManager.playList = [self.customizePlaylistViewController generateNewPlaylist:self.genreList :self.audioManager.playListAmountOfFiles];

        // reload table data
        [self.tableView reloadData];
        
        // start playing with first song on playlist
        [self.audioManager play:0];
    
    }
    
    // update view
    [self updateView];

    // generate TimeObserver for audioPlayer
    self.timeObserver = [self generateTimeObserver];

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
    UIPanGestureRecognizer *oneFingerPanRecognizer =
    [[UIPanGestureRecognizer alloc] initWithTarget:self  action:@selector(oneFingerPan:)];
    
    // Set required touches
    oneFingerPanRecognizer.minimumNumberOfTouches = 1;
    oneFingerPanRecognizer.maximumNumberOfTouches = 1;
    
    [self.controlView addGestureRecognizer:oneFingerPanRecognizer];
    
    // -----------------------------
    // Two finger, pan
    // -----------------------------
    UIPanGestureRecognizer *twoFingerPanRecognizer =
    [[UIPanGestureRecognizer alloc] initWithTarget:self  action:@selector(twoFingerPan:)];
    
    // Set required touches
    twoFingerPanRecognizer.minimumNumberOfTouches = 2;
    twoFingerPanRecognizer.maximumNumberOfTouches = 2;
    
    [self.controlView addGestureRecognizer:twoFingerPanRecognizer];
    
    // -----------------------------
    // Notifications
    // -----------------------------
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd)
                                                 name:@"MMAudioManagerPlayerItemDidReachEndNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newPlaylistGenerated)
                                                 name:@"MMCustomizePlaylistNewPlaylistGeneratedNotification"
                                               object:nil];
    // -----------------------------
    // initialize variables
    // -----------------------------
    
    self.panOverride = true;
    self.playNextSong = true;
    self.skipSeconds = true;
    self.showHelpOverlay = false;

}

// one finger, tab
// play/ pause music
- (void) oneFingerTab:(UITapGestureRecognizer *)recognizer
{
    if (self.audioManager.isPlaying) {
        [self.audioManager pause];
    } else {
        [self.audioManager play];
    }
    
    [self updateView];
}

// one finger, pan
// used for volume configuration (up/down) and switch songs (play previous/next song)
- (void)oneFingerPan:(UIPanGestureRecognizer *)recognizer 
{

    // where the user touches the screen
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
            if(self.playNextSong)
            {
                [self.audioManager playNext];
                self.playNextSong = false;
                [self updateView];
            }
        }
        //pan down
        else if(point.y > self.panXY.y + 10)
        {
            self.panOverride = true;
            [self.audioManager decreaseVolume:0.1];
        }
        //pan up
        else if(point.y < self.panXY.y - 10)
        {
            self.panOverride = true;
            [self.audioManager increaseVolume:0.1];
        }
    }
    
    //pan ended, used for reset values, next time pan can used again for switch song
    if(recognizer.state == UIGestureRecognizerStateEnded)
    {
        self.panOverride = true;
        self.playNextSong = true;
    }
}

// two finger, pan
// used for fast-forward and fast-backward the played song
- (void)twoFingerPan:(UIPanGestureRecognizer *)recognizer
{
    // where the user touches the screen
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
            if(self.skipSeconds)
            {
                [self.audioManager skip:+1 :0.1]; //skip 10% forward
                self.skipSeconds = false;
                [self updateView];
            }

        }
        //pan left
        else if (point.x < self.panXY.x - 10)
        {
            if(self.skipSeconds)
            {
                [self.audioManager skip:-1 :0.1]; //skip 10% backward
                self.skipSeconds = false;
                [self updateView];
            }
        }
    }
    
    //pan ended, reset values
    if(recognizer.state == UIGestureRecognizerStateEnded)
    {
        self.panOverride = true;
        self.skipSeconds = true;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

//generate and set new playlist
- (IBAction)buttonNewPlaylistPressed:(id)sender {
    self.audioManager.playList = [self.customizePlaylistViewController generateNewPlaylist:self.genreList :self.audioManager.playListAmountOfFiles];
    //set notofication that new playlist is generated
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MMCustomizePlaylistNewPlaylistGeneratedNotification" object:self];
}

// if pressed the help overlay switch state between visible and hidden
- (IBAction)buttonHelpPressed:(id)sender {
    
    if(self.showHelpOverlay)
        self.showHelpOverlay = false;
    else
        self.showHelpOverlay = true;
    
    [self updateView];
}

// if pressed the help overlay switch state between visible and hidden
- (IBAction)buttonBackToMainViewPressed:(id)sender {
    if(self.showHelpOverlay)
        self.showHelpOverlay = false;
    else
        self.showHelpOverlay = true;
    
    [self updateView];
}

// returns number of cells in tableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.audioManager.playList.count;
}

// fill in tableView with cells
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"MusicPlayerSongTableCell";
    
    MMMusicPlayerSongTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell==nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"MusicPlayerSongTableCell" owner: self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    MPMediaItem *song = [self.audioManager.playList objectAtIndex:indexPath.row];
    NSString *songTitle = [song valueForProperty: MPMediaItemPropertyTitle];
    NSString *songArtist = [song valueForProperty:MPMediaItemPropertyArtist];
    NSString *songGenre = [song valueForProperty: MPMediaItemPropertyGenre];

    /*int duration = [[song valueForProperty:MPMediaItemPropertyPlaybackDuration] intValue];
    int durationMins = (int)(duration/60);
    int durationSec  = (int)(duration%60);
    
    NSString *durationString = [NSString stringWithFormat:@"%2d:%02d",durationMins,durationSec];*/
    
    cell.labelSongTitle.text = songTitle;
    cell.labelArtist.text = songArtist;
    if (songGenre == nil) {
        songGenre = self.nilGenreName;
    }
    cell.labelGenre.text = songGenre;
    
    return cell;
}

// if user select a table view row
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // play selected song
    [self.audioManager play:(int)indexPath.row];
    
    // update view
    [self updateView];
}

// override to support conditional editing of the table view cells, default is NO
- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


// Action if table row action is selected
- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // if tablerow action delete is selected
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        BOOL isPlayingSong = false;
        // if the song that actualy is playing should be deleted, set isPlayingSong = true
        if([self.audioManager isPlayingSong:(int)indexPath.row])
            isPlayingSong = true;
 
        // delete song from playlist
        [self.audioManager.playList removeObjectAtIndex:indexPath.row];
        // delete row from table, important because of the row selection and a animation after the delete
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationFade];

        // reload table data
        [self.tableView reloadData];
        
        // play next song in playlist, if deleted song was actualy been played
        if(isPlayingSong)
            if(self.audioManager.playList.count>0)
                [self.audioManager play:(int)indexPath.row];
        
        // update view
        [self updateView];
    }
}

// updates view
- (void) updateView
{
    // if there is at leat 1 song in playlist
    if(self.audioManager.playList.count>0)
    {
        // update song name
        self.songName.text = self.audioManager.currentSongTitle;
        
        // progressView
        // set progress in %
        [self.progressViewOutlet setProgress:(float)((self.audioManager.audioPlayer.currentTime.value)/self.audioManager.audioPlayer.currentTime.timescale)/(int) (self.audioManager.audioPlayer.currentItem.asset.duration.value/self.audioManager.audioPlayer.currentItem.asset.duration.timescale) animated:true];
        
        if([self.progressViewOutlet isHidden])
            [self.progressViewOutlet setHidden:false];
        
        // update duration outlet
        int currentTime = (int)((self.audioManager.audioPlayer.currentTime.value)/self.audioManager.audioPlayer.currentTime.timescale);
        int currentMins = (int)(currentTime/60);
        int currentSec  = (int)(currentTime%60);
        
        NSString * durationLabel = [NSString stringWithFormat:@"%02d:%02d",currentMins,currentSec];
        self.durationOutlet.text = durationLabel;
        
        
        if([self.durationOutlet isHidden])
            [self.durationOutlet setHidden:false];
        
        // update song/album artwork
        self.imageViewArtwork.image = self.audioManager.currentArtwork;
       
        // update play/pause imageView
        if(self.audioManager.isPlaying)
            [self.imageViewPlayPause setImage:[UIImage imageNamed:@"play_icon.png"]];
        else
            [self.imageViewPlayPause setImage:[UIImage imageNamed:@"pause_icon.png"]];
        
        if([self.imageViewPlayPause isHidden])
            [self.imageViewPlayPause setHidden:false];
        
        // update tableview selected row
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.audioManager.currentSongIndex inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
        
    }
    else // if playlist is empty
    {
        
        // pause audioplayer
        [self.audioManager pause];
        
        // update song name
        self.songName.text = @"There are no songs in the playlist!";
        
        // update song/album artwork
        self.imageViewArtwork.image = [self.audioManager.noAlbumArtworkImages objectAtIndex:arc4random_uniform((int)self.audioManager.noAlbumArtworkImages.count)];
        
        // update play/pause imageView
        if([self.imageViewPlayPause isHidden]==false)
            [self.imageViewPlayPause setHidden:true];
        
        // update duration outlet
        if([self.durationOutlet isHidden]==false)
            [self.durationOutlet setHidden:true];
        
        // update progress outlet
        if([self.progressViewOutlet isHidden])
            [self.progressViewOutlet setHidden:false];
        
    }
    
    //set help overlay
    if(self.showHelpOverlay)
    {
        [self.imageViewHelpOverlay setHidden:false];
        [self.buttonBackToMainView setHidden:false];
    }
    else
    {
        [self.imageViewHelpOverlay setHidden:true];
        [self.buttonBackToMainView setHidden:true];
    }
}

// timeObserver for audio player, used for updating the duration label and the progressView
-(id) generateTimeObserver {
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

                                                  //set progress in %
                                                  [weakSelf.progressViewOutlet setProgress:(float)currentTime/(int) (weakSelf.audioManager.audioPlayer.currentItem.asset.duration.value/weakSelf.audioManager.audioPlayer.currentItem.asset.duration.timescale) animated:true];

                                              }];
    return timeObserver;
    
}

// set Background Task Identifier for playing songs in background
- (void) setBackgroundTaskIdentifier
{
    UIBackgroundTaskIdentifier newTaskId = UIBackgroundTaskInvalid;
    newTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:NULL];
    
    if(newTaskId != UIBackgroundTaskInvalid && self.bgTaskId != UIBackgroundTaskInvalid)
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTaskId];
    
    self.bgTaskId = newTaskId;
}

// if audioManager plays a song to end
- (void) playerItemDidReachEnd
{
    [self.audioManager playNext];
    [self updateView];
}

// if new playlist is generated/set
- (void) newPlaylistGenerated
{
 
    // play first song on this list
    [self.audioManager play:0];
    
    // reloead table data
    [self.tableView reloadData];
    
    // update view
    [self updateView];
}

@end
