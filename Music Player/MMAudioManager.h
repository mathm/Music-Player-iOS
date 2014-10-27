//
//  MMAudioManager.h
//  Music Player
//
//  Created by Mathias on 25.09.14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface MMAudioManager : NSObject

//Properties

/// list with all songs
@property (strong, nonatomic) NSMutableArray *songsList;
/// current playlist
@property (strong, nonatomic) NSMutableArray *playList;
/// audio player
@property (strong, nonatomic) AVPlayer *audioPlayer;
/// the song thats currently is playing
@property (strong, nonatomic) MPMediaItem *currentSong;
/// title of the current song
@property (strong, nonatomic) NSString *currentSongTitle;
/// artwork of the current song
@property (strong, nonatomic) UIImage *currentArtwork;
/// index in playlist of the current song
@property int currentSongIndex;
/// amount of files in playlist
@property int playListAmountOfFiles;
/// is the player playing or not
@property BOOL isPlaying;
/// images used if played song has no album artwork
@property (strong, nonatomic) NSMutableArray *noAlbumArtworkImages;

// Actions

- (void) play;
- (void) pause;
- (void) playNext;
- (void) playPrevious;
- (void) skip:(int)direction :(float)percent;
- (void) play:(int)index;
- (BOOL) isPlayingSong:(int)index;
- (void) increaseVolume:(float)percent;
- (void) decreaseVolume:(float)percent;

- (void) modifyVolume:(int)direction :(float)percent;
- (void) switchAudioFile:(int)direction :(int)indexPrevious;
- (void) playerItemDidReachEnd;


@end
