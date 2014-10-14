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
    
    //music library query
    MPMediaQuery *musicLibraryWithoutCloud = [[MPMediaQuery alloc] init];
    // add filter to avoid cloud music and videos
    [musicLibraryWithoutCloud addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithBool:NO] forProperty:MPMediaItemPropertyIsCloudItem]];

    NSArray *itemsFromGenericQuery = [musicLibraryWithoutCloud items];
    
    self.songsList = [NSMutableArray arrayWithArray:itemsFromGenericQuery];
    
    self.genreList = [[MMGenreList alloc]init];
   
    
    //generate genre list
    NSMutableArray *tmpArr = [[NSMutableArray alloc]init];
    BOOL isNilGenre = false;
    for(MPMediaItem *song in self.songsList)
    {
        NSString *genre = [song valueForProperty: MPMediaItemPropertyGenre];
        if(genre != nil)
        {
            if ([tmpArr containsObject:genre]==false) {
                [tmpArr addObject:genre];
            }
        }
        else if (isNilGenre == false) //if there is a song without genre add genre "Other" to list
        {
            isNilGenre = true;
            genre = self.viewController.nilGenreName;
            if ([tmpArr containsObject:genre]==false) {
                [tmpArr addObject:genre];
            }
        }
    }
    
    for(NSString *genreName in tmpArr)
    {
        MMGenre *genre = [[MMGenre alloc]init];
        genre.name = genreName;
        
        [self.genreList.genreList addObject:genre];
    }
    
    //count genre files for each genre in library
    for(MPMediaItem *song in self.songsList)
    {
        NSString *genreName = [song valueForProperty: MPMediaItemPropertyGenre];
        
        if(genreName == nil)
            genreName = self.viewController.nilGenreName;
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@",genreName];
        NSArray *tmpArr = [self.genreList.genreList filteredArrayUsingPredicate:predicate];
        if(tmpArr.count>0)
        {
            MMGenre *genre = [tmpArr objectAtIndex:0];
            [genre.songsList addObject: song];
        }
    }
    //NSLog(@"%lu",(unsigned long)self.songsList.count);
    
    [self.genreList setInitialPercentage];
    [self.genreList setInitialCellPosition];
    
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
        NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        NSString *string = [[NSString alloc]init];
        for (int i=0;i<[self.textfieldFiles.text length];i++)
        {
            unichar c = [self.textfieldFiles.text characterAtIndex:i];
            if([myCharSet characterIsMember:c])
            {
                string = [NSString stringWithFormat:@"%@%@",string,([NSString stringWithCharacters:&c length:1])];
            }
        }
        //if textfield is empty set value to 0
        if([string length] == 0)
            string = @"0";
        //if textfield value is higher then songslist.count, set value to songslist.count
        if([self.textfieldFiles.text intValue]>self.songsList.count)
            string = [NSString stringWithFormat:@"%lu",(unsigned long)self.songsList.count];
        
        //set new value
        self.textfieldFiles.text = string;
        
        //close textfield keyboard
        [self.textfieldFiles resignFirstResponder];
    }
    
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
    cell.sliderPercent.value = [[self.genreList.genreList objectAtIndex:indexPath.row] percentage];
    
    //genre label
    cell.labelGenre.text = [[self.genreList.genreList objectAtIndex:indexPath.row] name];
    
    //percent label
    cell.labelPercent.text = [NSString stringWithFormat:@"%@%%",[[NSNumber numberWithFloat:cell.sliderPercent.value] stringValue]];
    
    //files in db label
    cell.labelFiles.text = [NSString stringWithFormat:@"%lu",(unsigned long)[[[self.genreList.genreList objectAtIndex:indexPath.row]songsList]count]];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.genreList.genreList.count;
}

/*
 called if a tableSlider Value is changed
 */
-(void) tableSliderChanged:(UISlider *)sender
{
    int sliderValue = [[NSNumber numberWithInt:sender.value] intValue];
    
    long cellPosition = sender.tag;
    
    //[self.tableSliderValuesArray replaceObjectAtIndex:cellPosition withObject:sliderValue];
    [[self.genreList.genreList objectAtIndex:cellPosition] setPercentage:sliderValue];
    
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

/*
 Button pressed, generates new playlist and switch back to playlist tab
 */
- (IBAction)buttonGenerateNewPlaylist:(id)sender {
    
    
    //generate genre list
    NSMutableArray *tmpArr = [[NSMutableArray alloc]init];//[[NSMutableArray alloc]initWithArray:self.songsList];
    NSMutableArray *tmpSongsList = [[NSMutableArray alloc]init];
    
    //fill tmpArr with songs by defined percentage data
    
    //calculate basis song array on the basis of genre and percentage
    for (int i=0; i<self.genreList.genreList.count; i++) {
        MMGenre *genre = [self.genreList.genreList objectAtIndex:i];
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
    NSLog(@"Dateien: %lu",(unsigned long)tmpArr.count);
    
    MPMediaItem *song;
    while(tmpSongsList.count<[self.textfieldFiles.text intValue])
    {
        if(tmpArr.count == 0)
            break;
        
        song = [tmpArr objectAtIndex:arc4random_uniform((int)tmpArr.count)];
        [tmpSongsList addObject:song];
        [tmpArr removeObject:song];
    }
    
    NSLog(@"%lu",(unsigned long)tmpSongsList.count);
    
    //set new playlist
    self.viewController.audioManager.songsList = tmpSongsList;
    
    //set notofication that new playlist is generated
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MMCustomizePlaylistNewPlaylistGeneratedNotification" object:self];
    
    //switch view to "main" viewController
    self.tabBarController.selectedIndex = 0;
}

/*
 Button pressed, set genreList percentage to initial values (100/genreList.count)
 */
-(IBAction) buttonSetInitialPercentage:(id)sender
{
    [self.genreList setInitialPercentage];
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
