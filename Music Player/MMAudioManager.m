//
//  MMAudioManager.m
//  Music Player
//
//  Created by Mathias on 25.09.14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import "MMAudioManager.h"

@implementation MMAudioManager


- (id) init
{
    if (self = [super init])
    {
        _isPlaying = false;
        _audioPlayer = [[AVPlayer alloc]init];
        
        //if avplayer play song to end notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
        
        //load alle .jpg images with prefix "no_artwork" from mainBundle
        NSMutableArray *imagePaths = [[NSMutableArray alloc]init];
        [[[NSBundle mainBundle] pathsForResourcesOfType:@"jpg" inDirectory:nil]enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop)
         {
             NSString *path = [obj lastPathComponent];
             if([path hasPrefix:@"no_artwork"])
             {
                 [imagePaths addObject:path];
                 NSLog(@"%@",path);
             }
         }];

        //fill the noAlbumArtworkImages with images
        _noAlbumArtworkImages = [[NSMutableArray alloc]init];
        for(NSString *imagePath in imagePaths)
        {
            UIImage *tmpImage = [UIImage imageNamed:imagePath];
            [_noAlbumArtworkImages addObject:tmpImage];
        }
    }
    return self;
}

- (void) setCurrentSong:(MPMediaItem *)currentSong
{
    //song
    _currentSong = currentSong;
    
    //song index in playlist
    _currentSongIndex =  (int)[self.playList indexOfObject:self.currentSong];
    
    //song title
    _currentSongTitle = [_currentSong valueForProperty: MPMediaItemPropertyTitle];
    
    //artwork - song image
    UIImage *albumArtworkImage = NULL;
    MPMediaItemArtwork *itemArtwork = [_currentSong valueForProperty:MPMediaItemPropertyArtwork]; //get album artwork from currentSong
    if(itemArtwork != nil)
    {
        //generate UI image
        albumArtworkImage = [itemArtwork imageWithSize:CGSizeMake(500.0, 500.0)];
    }
    if(albumArtworkImage)
    {
        _currentArtwork = albumArtworkImage;
    }
    else
    {
       //if there was no album artwork, set random artwork
        _currentArtwork = [self.noAlbumArtworkImages objectAtIndex:arc4random_uniform((int)self.noAlbumArtworkImages.count)];
    }

}


- (void) play
{
    [self.audioPlayer play];
    self.isPlaying = true;
}

- (void) pause
{
    [self.audioPlayer pause];
    self.isPlaying = false;
}

- (void) playNext
{
    [self switchAudioFile:1 :(int)[self.playList indexOfObject:self.currentSong]];
}

- (void) playPrevious
{
    [self switchAudioFile:-1 :(int)[self.playList indexOfObject:self.currentSong]];
}

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

- (BOOL) isPlayingSong:(int)index
{
    if([self.playList objectAtIndex:index] == self.currentSong)
        return true;
    else
        return false;
}

- (void) switchAudioFile:(int)direction :(int)indexPrevious
{
    if(indexPrevious+direction>=0 && indexPrevious+direction<self.playList.count)
    {
        [self play:(indexPrevious+direction)];
    }
}

/* action, if player reach end of the played song
 send notification: MMAudioManagerPlayerItemDidReachEndNotification
 */
- (void) playerItemDidReachEnd
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MMAudioManagerPlayerItemDidReachEndNotification" object:self];
}

@end


