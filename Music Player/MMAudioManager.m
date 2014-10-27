//
//  MMAudioManager.m
//  Music Player
//
//  Created by Mathias on 25.09.14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import "MMAudioManager.h"

/// AudioManager includes AVAudioPlayer and provides extended methods to handle audiofiles
@implementation MMAudioManager


- (id) init
{
    if (self = [super init])
    {
        _isPlaying = false;
        _audioPlayer = [[AVPlayer alloc]init];
        
        // if avplayer play song to end notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
        
        // load alle .jpg images with prefix "no_artwork" from mainBundle
        NSMutableArray *imagePaths = [[NSMutableArray alloc]init];
        [[[NSBundle mainBundle] pathsForResourcesOfType:@"jpg" inDirectory:nil]enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop)
         {
             NSString *path = [obj lastPathComponent];
             if([path hasPrefix:@"no_artwork"])
             {
                 [imagePaths addObject:path];
             }
         }];

        // fill the noAlbumArtworkImages with images
        _noAlbumArtworkImages = [[NSMutableArray alloc]init];
        for(NSString *imagePath in imagePaths)
        {
            UIImage *tmpImage = [UIImage imageNamed:imagePath];
            [_noAlbumArtworkImages addObject:tmpImage];
        }
        
        // set amount of songs in playlist
        _playListAmountOfFiles = 10;
    }
    return self;
}

/// override setter from currentSong
- (void) setCurrentSong:(MPMediaItem *)currentSong
{
    // song
    _currentSong = currentSong;
    
    // song index in playlist
    _currentSongIndex =  (int)[self.playList indexOfObject:self.currentSong];
    
    // song title
    _currentSongTitle = [_currentSong valueForProperty: MPMediaItemPropertyTitle];
    
    // artwork - song image
    UIImage *albumArtworkImage = NULL;
    MPMediaItemArtwork *itemArtwork = [_currentSong valueForProperty:MPMediaItemPropertyArtwork]; //get album artwork from currentSong
    if(itemArtwork != nil)
    {
        // generate UI image
        albumArtworkImage = [itemArtwork imageWithSize:CGSizeMake(600.0, 600.0)];
    }
    if(albumArtworkImage)
    {
        _currentArtwork = albumArtworkImage;
    }
    else
    {
       // if there was no album artwork, set random artwork
        _currentArtwork = [self.noAlbumArtworkImages objectAtIndex:arc4random_uniform((int)self.noAlbumArtworkImages.count)];
    }

}

/// set player to play
- (void) play
{
    [self.audioPlayer play];
    self.isPlaying = true;
}

/// set player to pause
- (void) pause
{
    [self.audioPlayer pause];
    self.isPlaying = false;
}

/// play next song on playlist
- (void) playNext
{
    [self switchAudioFile:1 :(int)[self.playList indexOfObject:self.currentSong]];
}

/// play previous song on playlist
- (void) playPrevious
{
    [self switchAudioFile:-1 :(int)[self.playList indexOfObject:self.currentSong]];
}

/// skips some seconds from the current song directions: -1 backward | 1 forward percent: amount of seconds skipped in percent, float value between 0 and 1
- (void) skip:(int)direction :(float)percent
{
    int currentTime = (int)((self.audioPlayer.currentTime.value)/self.audioPlayer.currentTime.timescale);
    int duration = (int) (self.audioPlayer.currentItem.asset.duration.value/self.audioPlayer.currentItem.asset.duration.timescale);
    int newTime = 0;
    
    if(direction<0) // backwards
    {
        // if newTime would be <0 set newTime to 1
        if((currentTime - (int)(duration * percent)) > 0)
            newTime = currentTime - (int)(duration * percent);
        else
            newTime = 1;
    }
    else // forwards
    {
        // if newTime would be >song duration play next song
        if((currentTime + (int)(duration * percent)) < duration)
            newTime = currentTime + (int)(duration * percent);
        else
            [self playNext];
    }

    [self.audioPlayer seekToTime:CMTimeMakeWithSeconds(newTime,1)];
}

/// play the song with the specified index
- (void) play:(int)index
{
    if(self.playList.count>0)
    {
        [self pause];
        self.currentSong = [self.playList objectAtIndex:index];
        AVPlayerItem * currentItem = [AVPlayerItem playerItemWithURL:[self.currentSong valueForProperty:MPMediaItemPropertyAssetURL]];
        
        [self.audioPlayer replaceCurrentItemWithPlayerItem:currentItem];
        [self play];
    }
    else
        [self pause];
}

/// returns true if the song with the sent index is curently playing
- (BOOL) isPlayingSong:(int)index
{
    if([self.playList objectAtIndex:index] == self.currentSong)
        return true;
    else
        return false;
}

/// increase volume by given percent (values between 0 and 1)
- (void) increaseVolume:(float)percent
{
    [self modifyVolume:1 :percent];
}

/// decrease volume by given percent (values between 0 and 1)
- (void) decreaseVolume:(float)percent
{
    [self modifyVolume:-1 :percent];
}

/// modify Volume by given direction (-1 deccreade | 1 increase) and percent (values between 0 and 1)
- (void) modifyVolume:(int)direction :(float)percent
{
    if(direction<0)
    {
        if(self.audioPlayer.volume>0 && self.audioPlayer.volume - percent >= 0)
            self.audioPlayer.volume = self.audioPlayer.volume - percent;
        else
            self.audioPlayer.volume = 0;
    }
    else if(direction>0)
    {
        if(self.audioPlayer.volume<1 && self.audioPlayer.volume + percent <= 1)
            self.audioPlayer.volume = self.audioPlayer.volume + percent;
        else
            self.audioPlayer.volume = 1;
    }
}
/// play next song from playlist, depending on direction: -1 play previous song | 1 play next song and the in of the song that is playing at the moment (indexPrevious)
- (void) switchAudioFile:(int)direction :(int)indexPrevious
{
    // if the index of next song would be on the playlist
    if(indexPrevious+direction>=0 && indexPrevious+direction<self.playList.count)
    {
        [self play:(indexPrevious+direction)];
    }
    // reset indext to first song and set player to pause
    else if (indexPrevious+direction>=self.playList.count && direction>0)
    {
        [self play:0];
        [self pause];
    }
}

/// action, if player reach end of the played song send notification: MMAudioManagerPlayerItemDidReachEndNotification
- (void) playerItemDidReachEnd
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MMAudioManagerPlayerItemDidReachEndNotification" object:self];
}

@end


