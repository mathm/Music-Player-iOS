//
//  MMCustomizePlaylistViewController.m
//  Music Player
//
//  Created by Mathias on 01.10.14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import "MMCustomizePlaylistViewController.h"
#import "MMMusicPlayerCustomizeGenreTableViewCell.h"
#import "MMViewController.h"
#import "MMGenre.h"
#import "MMGenreList.h"

@interface MMCustomizePlaylistViewController ()

@property (strong, nonatomic) MMViewController *viewController;

@end

@implementation MMCustomizePlaylistViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //loading viewController Data
    self.viewController = [self.tabBarController.viewControllers objectAtIndex:0];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    //update table
    [self.tableView reloadData];
    
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
    
    self.textfieldFiles.text = [NSString stringWithFormat:@"%i",self.viewController.audioManager.playListAmountOfFiles];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//one finger, tab
- (void) oneFingerTab:(UITapGestureRecognizer *)recognizer
{
    //close textfield keyboard if its open and check for numbers only
    //if any other characters found, delete them
    if([self.textfieldFiles isFirstResponder])
    {
        //clear textfield
        [self clearTextfieldResultingNumbersOnly:self.textfieldFiles :(int)self.viewController.audioManager.songsList.count];
        //set new value for max amount of playlist files
        self.viewController.audioManager.playListAmountOfFiles = [self.textfieldFiles.text intValue];
        
        //close textfield keyboard
        [self.textfieldFiles resignFirstResponder];
    }
    
}

// check textfield for numbers only, if any other characters found, delete them
- (void) clearTextfieldResultingNumbersOnly:(UITextField *)textField :(int) maxPlaylistSize
{
    NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    NSString *string = [[NSString alloc]init];
    for (int i=0;i<[textField.text length];i++)
    {
        unichar c = [textField.text characterAtIndex:i];
        if([myCharSet characterIsMember:c])
        {
            string = [NSString stringWithFormat:@"%@%@",string,([NSString stringWithCharacters:&c length:1])];
        }
    }
    //if textfield is empty set value to 0
    if([string length] == 0)
        string = @"0";
    //if textfield value is higher then songslist.count, set value to songslist.count
    if([textField.text intValue]>maxPlaylistSize)
        string = [NSString stringWithFormat:@"%i",maxPlaylistSize];
    
    //set new value
    textField.text = string;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"MusicPlayerCustomizeGenreTableCell";
    
    MMMusicPlayerCustomizeGenreTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell==nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"MusicPlayerCustomizeGenreTableCell" owner: self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    // slider
    // set a method which will get called when a slider in a cell changes value
    [cell.sliderPercent addTarget:self action:@selector(tableSliderChanged:) forControlEvents:UIControlEventValueChanged];
    //Keep a reference to each slider by assigning a tag so that we can determine which slider is being changed
    cell.sliderPercent.tag = indexPath.row;
    //grab the percentage value from genre
    cell.sliderPercent.value = [[self.viewController.genreList.genreList objectAtIndex:indexPath.row] percentage];
    
    //genre label
    cell.labelGenre.text = [[self.viewController.genreList.genreList objectAtIndex:indexPath.row] name];
    
    //percent label
    cell.labelPercent.text = [NSString stringWithFormat:@"%@%%",[[NSNumber numberWithFloat:cell.sliderPercent.value] stringValue]];
    
    //files in db label
    cell.labelFiles.text = [NSString stringWithFormat:@"%lu",(unsigned long)[[[self.viewController.genreList.genreList objectAtIndex:indexPath.row]songsList]count]];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.viewController.genreList.genreList.count;
}


// called if a tableSlider Value is changed
-(void) tableSliderChanged:(UISlider *)sender
{
    int sliderValue = [[NSNumber numberWithInt:sender.value] intValue];
    
    long cellPosition = sender.tag;
    
    //[self.tableSliderValuesArray replaceObjectAtIndex:cellPosition withObject:sliderValue];
    [[self.viewController.genreList.genreList objectAtIndex:cellPosition] setPercentage:sliderValue];
    
    /*
    // add all slider values to avoid a overall value > 100
    int tmp = 0;
    for(MMGenre *genre in self.genreList.genreList)
    {
        int tmpSliderValue = [genre percentage];
        tmp = tmp + tmpSliderValue;
    }

    // if the overall value is > 100, take the smalest value and reduce his value by 1
    while(tmp>100)
    {
        // generate list ranking
        [self.genreList generateNewListRanking];
        
        long cellPositionMinValue = 0;

        //looking for genre with lowest rank to subtract redundant percentage from it
        BOOL breakOuterFor = false;
        for(int i=0;i<self.genreList.genreList.count;i++)
        {
            for(int j=0;j<self.genreList.genreList.count;j++)
            {
                if ([[self.genreList.genreList objectAtIndex:j] rank] == i) {
                    if([[self.genreList.genreList objectAtIndex:j] percentage] > 0 && [[self.genreList.genreList objectAtIndex:j] cellPosition] != cellPosition)
                    {
                        cellPositionMinValue = j;
                        breakOuterFor = true;
                        break;
                    }
                }
            }
            if(breakOuterFor) break;
        }
        
        int minValue = [[self.genreList.genreList objectAtIndex:cellPositionMinValue] percentage];
        int newValue = 0;
        
        //if its possible to subtract redundant percentage (dont shut be lower than zero)
        if (minValue-(tmp-100)>0) {
            newValue = minValue-(tmp-100);
            tmp = tmp - (tmp-100);
        } else
        {
            newValue = 0;
            tmp = tmp - minValue;
            
            if(minValue == 0 && newValue == 0)
                break;
        }

        //set new percentage to genre
        [[self.genreList.genreList objectAtIndex:cellPositionMinValue] setPercentage:newValue];
    }
    */
    //update table data
    [self.tableView reloadData];
}

// Button pressed, generates new playlist and switch back to playlist tab
- (IBAction)buttonGenerateNewPlaylist:(id)sender {
    
    //close textfield keyboard if its open and check for numbers only
    //if any other characters found, delete them
    if([self.textfieldFiles isFirstResponder])
    {
        //clear textfield
        [self clearTextfieldResultingNumbersOnly:self.textfieldFiles :(int)self.viewController.audioManager.songsList.count];
        //set new value for max amount of playlist files
        self.viewController.audioManager.playListAmountOfFiles = [self.textfieldFiles.text intValue];
        
        //close textfield keyboard
        [self.textfieldFiles resignFirstResponder];
    }
    
    NSLog(@"playListAmountOfFiles %i",self.viewController.audioManager.playListAmountOfFiles);
    //generate and set new playlist
    self.viewController.audioManager.playList = [self generateNewPlaylist:self.viewController.genreList :self.viewController.audioManager.playListAmountOfFiles];
    
    //set notofication that new playlist is generated
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MMCustomizePlaylistNewPlaylistGeneratedNotification" object:self];
    
    //switch view to "main" viewController
    self.tabBarController.selectedIndex = 0;
}

// generates new playlist by given genreList and playlist size
- (NSMutableArray *) generateNewPlaylist:(MMGenreList *)genreList :(int)size
{

    //generate genre list
    NSMutableArray *tmpArr = [[NSMutableArray alloc]init];
    NSMutableArray *tmpSongsList = [[NSMutableArray alloc]init];
    
    //fill tmpArr with songs by defined percentage data
    //calculate basis song array on the basis of genre and percentage
    for (int i=0; i<genreList.genreList.count; i++) {
        MMGenre *genre = [genreList.genreList objectAtIndex:i];
        if(genre.percentage>0)
        {
            int rounded = ceil(((int)[genre.songsList count] * genre.percentage)/100);
            if(rounded>=0&&rounded<1)
                rounded=1;
            
            NSMutableArray *tmpGenreArr = [[NSMutableArray alloc]initWithArray:genre.songsList];
            MPMediaItem *song;
            for(int j = 0;j<rounded;j++)
            {
                song = [tmpGenreArr objectAtIndex:arc4random_uniform((int)tmpGenreArr.count)];
                [tmpArr addObject:song];
                [tmpGenreArr removeObject:song];
            }
        }
    }

    MPMediaItem *song;
    while(tmpSongsList.count<size)
    {
        if(tmpArr.count == 0)
            break;
        
        song = [tmpArr objectAtIndex:arc4random_uniform((int)tmpArr.count)];
        [tmpSongsList addObject:song];
        [tmpArr removeObject:song];
    }
    
    //return new playlist
    return tmpSongsList;
}

/*
 Button pressed, set genreList percentage to initial values (100/genreList.count)
 */
-(IBAction) buttonSetInitialPercentage:(id)sender
{
    [self.viewController.genreList setInitialPercentage];
    [self.tableView reloadData];
}

#pragma mark - Navigation
/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.destinationViewController isKindOfClass:[MMViewController class]])
    {
        MMViewController *mainView = segue.destinationViewController;
        self.test = mainView.songName.text;
    }
}

*/

@end
