//
//  AddArtViewController.m
//  ArtAround
//
//  Created by Brian Singer on 5/18/13.
//  Copyright (c) 2013 ArtAround. All rights reserved.
//

#import "AddArtViewController.h"
#import "EGOImageButton.h"
#import "Photo.h"
#import "PhotoImageView.h"
#import "Art.h"
#import "ArtAroundAppDelegate.h"
#import "AAAPIManager.h"
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "Utilities.h"
#import "SearchItem.h"
#import "ArtParser.h"

@interface AddArtViewController ()
- (void) buttonPressed:(id)sender;
- (void) categoryButtonPressed;
- (void) commissionedButtonPressed;
- (void) locationButtonPressed;
- (void) doneButtonPressed;
- (void) dateButtonPressed;
- (void) showLoadingView:(NSString*)msg;

- (void)photoUploadCompleted;
- (void)photoUploadFailed;
- (void)photoUploadCompleted:(NSDictionary*)responseDict;
- (void)photoUploadFailed:(NSDictionary*)responseDict;
- (void)artUploadFailed:(NSDictionary*)responseDict;
- (BOOL)findAndResignFirstResponder;

@end

@implementation AddArtViewController

@synthesize photosScrollView;
@synthesize locationButton;
@synthesize artistTextField;
@synthesize titleTextField;
@synthesize urlTextField;
@synthesize categoryButton;
@synthesize dateButton;
@synthesize submitButton;
@synthesize commissionedByButton = _commissionedByButton;
@synthesize descriptionTextView;
@synthesize locationDescriptionTextView;
@synthesize currentLocation = _currentLocation;

@synthesize art = _art;
@synthesize scrollView = _scrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        _userAddedImages = [[NSMutableArray alloc] init];
        _userAddedImagesAttribution = [[NSMutableDictionary alloc] init];
        _imageButtons = [[NSMutableArray alloc] init];
        _newArtDictionary = [[NSMutableDictionary alloc] init];
        
        _addedImageCount = 0;
        _usingPhotoGeotag = NO;
        
        NSDateFormatter *yearFormatter = [[NSDateFormatter alloc] init];
        [yearFormatter setDateFormat:@"yyyy"];
        NSString *yearString = [yearFormatter stringFromDate:[NSDate date]];
        _currentYear = [yearString intValue];

        
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //set scroll view content frame
    float bottomY = self.submitButton.frame.origin.y + self.submitButton.frame.size.height + 10.0f;
    CGSize contentSize = CGSizeMake(self.view.frame.size.width, bottomY);
    [self.scrollView setContentSize:contentSize];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //track Add Art view
    [Utilities trackPageViewWithName:@"AddArtView"];
    
    //setup back button
    UIImage *backButtonImage = [UIImage imageNamed:@"backArrow.png"];
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, backButtonImage.size.width + 10.0f, backButtonImage.size.height)];
    [backButton addTarget:self.navigationController action:@selector(popToRootViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    [backButton setContentMode:UIViewContentModeCenter];
    [backButton setImage:backButtonImage forState:UIControlStateNormal];
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backButtonItem];
    
    //add actions
    [self.categoryButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.commissionedByButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.locationButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.dateButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    //set listeners on text fields
    [self.titleTextField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventValueChanged];
    [self.artistTextField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventValueChanged];
    [self.urlTextField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventValueChanged];
    
    
    [self setupImages];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [photosScrollView release];
    [locationButton release];
    [artistTextField release];
    [titleTextField release];
    [categoryButton release];
    [descriptionTextView release];
    [descriptionTextView release];
    [dateButton release];
    [locationDescriptionTextView release];
    [urlTextField release];
    [_scrollView release];
    [_commissionedByButton release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setPhotosScrollView:nil];
    [self setLocationButton:nil];
    [self setArtistTextField:nil];
    [self setTitleTextField:nil];
    [self setCategoryButton:nil];
    [self setDescriptionTextView:nil];
    [self setDescriptionTextView:nil];
    [self setDateButton:nil];
    [self setLocationDescriptionTextView:nil];
    [self setUrlTextField:nil];
    [self setScrollView:nil];
    [self setCommissionedByButton:nil];
    [super viewDidUnload];
}

#pragma mark - Actions
- (void) buttonPressed:(id)sender
{
    if (sender == self.locationButton) {
        [self locationButtonPressed];
    }
    else if (sender == self.categoryButton) {
        [self categoryButtonPressed];
    }
    else if (sender == self.locationButton) {
        [self locationButtonPressed];
    }
    else if (sender == self.dateButton) {
        [self dateButtonPressed];
    }
    else if (sender == _doneButton) {
        [self doneButtonPressed];
    }
    else if (sender == _commissionedByButton) {
        [self commissionedButtonPressed];
    }

}

//remove the toolbar and picker and resize scrollview
- (void) doneButtonPressed
{
    
    [UIView animateWithDuration:0.5f animations:^{
        
        [_dateToolbar setFrame:CGRectOffset(_datePicker.frame, 0, _datePicker.frame.size.height + _dateToolbar.frame.size.height)];
        [_datePicker setFrame:CGRectOffset(_datePicker.frame, 0, _datePicker.frame.size.height + _dateToolbar.frame.size.height)];
        [self.scrollView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        
    } completion:^(BOOL finished) {
        [_datePicker removeFromSuperview];
        [_dateToolbar removeFromSuperview];
    }];
}

- (void) categoryButtonPressed
{
    SearchTableViewController *searchTableController = [[SearchTableViewController alloc] initWithStyle:UITableViewStylePlain];
    NSMutableArray *searchItems = [[NSMutableArray alloc] initWithCapacity:[[[AAAPIManager instance] categories] count]];
    for (NSString * cat in [[AAAPIManager instance] categories]) {
        [searchItems addObject:[SearchItem searchItemWithTitle:cat subtitle:@""]];
    }
    
    [searchTableController setCreationEnabled:NO];
    [searchTableController setSearchItems:searchItems];
    [searchTableController setMultiSelectionEnabled:YES];
    [searchTableController setDelegate:self];
    
    //add the categories if they exist
    if ([_newArtDictionary objectForKey:@"categories"]) {
        NSMutableArray *selectedItems = [[NSMutableArray alloc] initWithArray:[_newArtDictionary objectForKey:@"categories"]];
        [searchTableController setSelectedItems:selectedItems];
    }


    [self.navigationController pushViewController:searchTableController animated:YES];
    
    
    
}

- (void) commissionedButtonPressed
{
    SearchTableViewController *searchTableController = [[SearchTableViewController alloc] initWithStyle:UITableViewStylePlain];
    NSMutableArray *searchItems = [[NSMutableArray alloc] initWithCapacity:[[[AAAPIManager instance] categories] count]];
    [searchItems addObject:[SearchItem searchItemWithTitle:@"None" subtitle:@""]];
    for (NSString * com in [[AAAPIManager instance] commissioners]) {
        if (![com isEqualToString:@"All"])
            [searchItems addObject:[SearchItem searchItemWithTitle:com subtitle:@""]];
    }
    
    [searchTableController setCreationEnabled:YES];
    [searchTableController setSearchItems:searchItems];
    [searchTableController setMultiSelectionEnabled:NO];
    [searchTableController setDelegate:self];
    [searchTableController setItemName:@"commissioner"];
    [searchTableController.tableView setTag:10];
    
    //add the categories if they exist
    if ([_newArtDictionary objectForKey:@"commissioned_by"]) {
        SearchItem *item = [SearchItem searchItemWithTitle:[_newArtDictionary objectForKey:@"commissioned_by"] subtitle:@""];
        NSMutableArray *selectedItems = [[NSMutableArray alloc] initWithObjects:item, nil];
        [searchTableController setSelectedItems:selectedItems];
    }
    else if (_art.commissionedBy) {
        SearchItem *item = [SearchItem searchItemWithTitle:_art.commissionedBy subtitle:@""];
        NSMutableArray *selectedItems = [[NSMutableArray alloc] initWithObjects:item, nil];
        [searchTableController setSelectedItems:selectedItems];
    }
    
    
    [self.navigationController pushViewController:searchTableController animated:YES];
}

- (void) locationButtonPressed
{
    
    ArtLocationSelectionViewViewController *locationController = [[ArtLocationSelectionViewViewController alloc] initWithNibName:@"ArtLocationSelectionViewViewController" bundle:[NSBundle mainBundle] geotagLocation:(_imageLocation != nil) ? _imageLocation : nil delegate:self currentLocationSelection:LocationSelectionUserLocation currentLocation:_currentLocation];

    [self.navigationController pushViewController:locationController animated:YES];
    
    if (_selectedLocation) {
        [locationController setSelectedLocation:_selectedLocation];
        [locationController setSelection:LocationSelectionManualLocation];
    }
    else
        [locationController setSelectedLocation:_currentLocation];
    
    
}

- (void) dateButtonPressed
{
    [self findAndResignFirstResponder];
    
    UIPickerView *datePicker = [[UIPickerView alloc] init];
    [datePicker setShowsSelectionIndicator:YES];
    [datePicker setDataSource:self];
    [datePicker setDelegate:self];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(buttonPressed:)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIToolbar *dateToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 44.0f)];
    [dateToolbar setBackgroundColor:[UIColor colorWithRed:67.0f/255.0f green:67.0f/255.0f blue:61.0f/255.0f alpha:1.0f]];
    [dateToolbar setBackgroundImage:[[UIImage alloc] init] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [dateToolbar setShadowImage:[[UIImage alloc] init] forToolbarPosition:UIToolbarPositionAny];
    [dateToolbar setBarStyle:UIBarStyleBlack];
	[dateToolbar setTintColor:[UIColor clearColor]];

    
    [dateToolbar setItems:[NSArray arrayWithObjects:space, doneButton, nil]];
    
    _datePicker = datePicker;
    _doneButton = doneButton;
    _dateToolbar = dateToolbar;
    
    CGRect datePickerFrame = datePicker.frame;
    datePickerFrame.origin.y = self.view.frame.size.height + _dateToolbar.frame.size.height;
    [_datePicker setFrame:datePickerFrame];
    
    [self.view addSubview:dateToolbar];
    [self.view addSubview:datePicker];
    
    
    [UIView animateWithDuration:0.5f animations:^{
        [_datePicker setFrame:CGRectOffset(_datePicker.frame, 0, -datePickerFrame.size.height - dateToolbar.frame.size.height)];
        [_dateToolbar setFrame:CGRectOffset(_dateToolbar.frame, 0, -datePickerFrame.size.height - _dateToolbar.frame.size.height)];
        [self.scrollView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - (_datePicker.frame.size.height + _dateToolbar.frame.size.height))];
        [self.scrollView scrollRectToVisible:CGRectOffset(self.dateButton.frame, 0, 10.0f) animated:YES];
    } completion:^(BOOL finished) {
        
    }];
    
}

- (void) textFieldChanged:(id)textField {
    
    if ([textField isKindOfClass:[UITextField class]]) {
        NSString *key = @"";
        
        if (textField == self.artistTextField)
            key = @"artist";
        else if (textField == self.titleTextField)
            key = @"title";
        else if (textField == self.urlTextField)
            key = @"website";
        
        [_newArtDictionary setObject:[(UITextField*)textField text] forKey:key];
    }
    
    //setup add art button
    if ([_newArtDictionary objectForKey:@"title"] && [[_newArtDictionary objectForKey:@"title"] length] > 0 && _addedImageCount > 0) {
        
        [self.submitButton setBackgroundColor:[UIColor colorWithRed:(223.0f/255.0f) green:(73.0f/255.0f) blue:(70.0f/255.0f) alpha:1.0f]];
        self.submitButton.enabled = YES;
        
    }
    else {
        [self.submitButton setBackgroundColor:[UIColor colorWithWhite:0.71f alpha:1.0f]];
        self.submitButton.enabled = NO;
    }
}

- (void) textFieldChanged:(UITextField*)textField withText:(NSString*)text
{
    
    NSString *key = @"";
    
    if (textField == self.artistTextField)
        key = @"artist";
    else if (textField == self.titleTextField)
        key = @"title";
    else if (textField == self.urlTextField)
        key = @"website";
    
    [_newArtDictionary setObject:text forKey:key];
    
    //setup add art button
    if ([_newArtDictionary objectForKey:@"title"] && [[_newArtDictionary objectForKey:@"title"] length] > 0 && _addedImageCount > 0) {
        
        [self.submitButton setBackgroundColor:[UIColor colorWithRed:(223.0f/255.0f) green:(73.0f/255.0f) blue:(70.0f/255.0f) alpha:1.0f]];
        self.submitButton.enabled = YES;
        
    }
    else {
        [self.submitButton setBackgroundColor:[UIColor colorWithWhite:0.71f alpha:1.0f]];
        self.submitButton.enabled = NO;
    }
    
}


#pragma mark - Art Handlers

- (void) artButtonPressed:(id)sender
{
    EGOImageButton *button = (EGOImageButton*)sender;
    
    NSArray *keys = [_userAddedImagesAttribution allKeys];
    NSDictionary *attDict = [_userAddedImagesAttribution objectForKey:[keys objectAtIndex:(button.tag - _kUserAddedImageTagBase)]];
    
    PhotoImageView *imgView = [[PhotoImageView alloc] initWithFrame:CGRectOffset(self.view.frame, 0, 0)];
    [imgView setPhotoImageViewDelegate:self];
    [imgView setContentMode:UIViewContentModeScaleAspectFit];
    [imgView setBackgroundColor:kFontColorDarkBrown];
    
    //set the photo attribution if they exist
    if ([attDict objectForKey:@"text"] && [[attDict objectForKey:@"text"] length] > 0) {
        [(UILabel*)[imgView.photoAttributionButton viewWithTag:kAttributionButtonLabelTag] setText:[NSString stringWithFormat:@"Photo by %@", [attDict objectForKey:@"text"]]];
    }
    else {
        [(UILabel*)[imgView.photoAttributionButton viewWithTag:kAttributionButtonLabelTag] setText:@"Photo by anonymous user"];
    }
    

    if ([attDict objectForKey:@"website"] && [[attDict objectForKey:@"website"] isKindOfClass:[NSString class]] && [[attDict objectForKey:@"website"] length] > 0) {
        [imgView setUrl:[NSURL URLWithString:[attDict objectForKey:@"website"]]];
    }
    
    if (button.imageView.image)
        [imgView setImage:button.imageView.image];
    
    
    UIViewController *viewController = [[UIViewController alloc] init];
    viewController.view = imgView;
    
    
    [self.navigationController pushViewController:viewController animated:YES];
    DebugLog(@"Button Origin: %f", imgView.photoAttributionButton.frame.origin.y);
    [imgView release];
    [viewController release];
    
    
    
    
}

- (void) photoDeleteButtonPressed:(id)sender
{
    UIButton *button = (UIButton*)sender;
    int buttonTag = button.tag;
    
    [_userAddedImages removeObjectAtIndex:(buttonTag - _kUserAddedImageTagBase)];
    
    NSArray *keys = [_userAddedImagesAttribution allKeys];
    [_userAddedImagesAttribution removeObjectForKey:[keys objectAtIndex:(buttonTag - _kUserAddedImageTagBase)]];
    
    _addedImageCount = [_userAddedImages count];
    
    [self.photosScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [self setupImages];
    
    //setup add art button
    if ([_newArtDictionary objectForKey:@"title"] && [[_newArtDictionary objectForKey:@"title"] length] > 0 && _addedImageCount > 0) {
        
        [self.submitButton setBackgroundColor:[UIColor colorWithRed:(223.0f/255.0f) green:(73.0f/255.0f) blue:(70.0f/255.0f) alpha:1.0f]];
        self.submitButton.enabled = YES;
        
    }
    else {
        [self.submitButton setBackgroundColor:[UIColor colorWithWhite:0.71f alpha:1.0f]];
        self.submitButton.enabled = NO;
    }
    
    
}

- (void)userAddedImage:(UIImage*)image
{
    [self userAddedImage:image withAttributionText:@"" withAttributionURL:@""];
}

- (void)userAddedImage:(UIImage*)image withAttributionText:(NSString*)text withAttributionURL:(NSString*)url
{
    //increment the number of new images
    _addedImageCount += 1;
    
    
    [_userAddedImages addObject:image];
    
    NSDictionary *attDict = [[NSDictionary alloc] initWithObjectsAndKeys:text, @"text", url, @"website", nil];
    [_userAddedImagesAttribution setObject:attDict forKey:[[NSNumber numberWithInt:_userAddedImages.count] stringValue]];
    
    //reload the images to show the new image
    [self setupImages];
}

#pragma mark - Image Scroll View
- (void)setupImages
{
	//loop through all the images and add an image view if it doesn't exist yet
	//update the url for each image view that doesn't have one yet
	//this method may be called multiple times as the flickr api returns info on each photo
    //insert the add button at the end of the scroll view
	EGOImageButton *prevView = nil;
	int totalPhotos = _userAddedImages.count;
	int photoCount = 0;
    
    for (UIImage *thisUserImage in _userAddedImages) {
		
		//adjust the image view y offset
		float prevOffset = _kPhotoPadding;
		if (prevView) {
            
			//adjust offset based on the previous frame
			prevOffset = prevView.frame.origin.x + prevView.frame.size.width + _kPhotoSpacing;
			
		} else {
			
			//adjust the initial offset based on the total number of photos
			BOOL isPortrait = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation));
			if (isPortrait) {
				prevOffset = _kPhotoInitialPaddingPortait;
			} else {
				
				switch (totalPhotos) {
					case 1:
						prevOffset = _kPhotoInitialPaddingForOneLandScape;
						break;
						
					case 2:
						prevOffset = _kPhotoInitialPaddingForTwoLandScape;
						break;
						
					case 3:
					default:
						prevOffset = _kPhotoInitialPaddingForThreeLandScape;
						break;
				}
				
			}
            
		}
		
		//grab existing or create new image view
		EGOImageButton *imageView = (EGOImageButton *)[self.photosScrollView viewWithTag:(_kUserAddedImageTagBase + [_userAddedImages indexOfObject:thisUserImage])];
        UIButton *deleteButton = (UIButton*)[imageView viewWithTag:(_kUserAddedImageTagBase + [_userAddedImages indexOfObject:thisUserImage])];
        
		if (!imageView) {
			imageView = [[EGOImageButton alloc] initWithPlaceholderImage:nil];
			[imageView setClipsToBounds:YES];
			[imageView.imageView setContentMode:UIViewContentModeScaleAspectFill];
            [imageView setImage:thisUserImage forState:UIControlStateNormal];
			[imageView setBackgroundColor:[UIColor lightGrayColor]];
            [imageView addTarget:self action:@selector(artButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [deleteButton setFrame:CGRectMake(2.0f, 2.0f, 20.0f, 20.0f)];
            [deleteButton setBackgroundColor:[UIColor clearColor]];
            [deleteButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
            [deleteButton setBackgroundImage:[UIImage imageNamed:@"closeIcon.png"] forState:UIControlStateNormal];
            [deleteButton setAdjustsImageWhenHighlighted:YES];
            [deleteButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [deleteButton setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
            [deleteButton addTarget:self action:@selector(photoDeleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [deleteButton setTag:imageView.tag];
            [imageView addSubview:deleteButton];

            
			[self.photosScrollView addSubview:imageView];
            [_imageButtons addObject:imageView];

            
		}
        
        [imageView setFrame:CGRectMake(prevOffset, _kPhotoPadding, _kPhotoWidth, _kPhotoHeight)];
        [imageView setTag:(_kUserAddedImageTagBase + [_userAddedImages indexOfObject:thisUserImage])];
        [deleteButton setTag:(_kUserAddedImageTagBase + [_userAddedImages indexOfObject:thisUserImage])];
		
		
		//adjust the imageView autoresizing masks when there are fewer than 3 images so that they stay centered
		if (imageView && totalPhotos < 3) {
			[imageView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
		}
		
		//store the previous view for reference
		//increment photo count
		prevView = imageView;
		photoCount++;
		
	}
	
    
    
    //get the add button's offset
    float prevOffset = _kPhotoPadding;
    if (prevView) {
        //adjust offset based on the previous frame
        prevOffset = prevView.frame.origin.x + prevView.frame.size.width + _kPhotoSpacing;
        
    } else {
        
        //adjust the initial offset based on the total number of photos
        BOOL isPortrait = (UIInterfaceOrientationIsPortrait(self.interfaceOrientation));
        if (isPortrait) {
            prevOffset = _kPhotoInitialPaddingPortait;
        } else {
            prevOffset = _kPhotoInitialPaddingForOneLandScape;
        }
    }
    
    //setup the add image button
    UIButton *addImgButton = (UIButton*)[self.photosScrollView viewWithTag:_kAddImageTagBase];
    
    if (!addImgButton) {
        addImgButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [addImgButton setImage:[UIImage imageNamed:@"uploadPhoto_noBgwithtext.png"] forState:UIControlStateNormal];
        [addImgButton setTag:_kAddImageTagBase];
        [addImgButton.imageView setContentMode:UIViewContentModeCenter];
        [addImgButton setBackgroundColor:[UIColor colorWithRed:(170.0f/255.0f) green:(170.0f/255.0f) blue:(170.0f/255.0f) alpha:1.0f]];
        [addImgButton addTarget:self action:@selector(addImageButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.photosScrollView addSubview:addImgButton];
    }
    
    if (_userAddedImages.count == 0) {
    
    [addImgButton setFrame:CGRectMake(prevOffset, _kPhotoPadding, _kPhotoWidth, _kPhotoHeight)];
    
    //adjust the button's autoresizing mask when there are fewer than 3 images so that it stays centered
    if (totalPhotos < 3) {
        [addImgButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    }
    
    }
    
    
	//set the content size
	[self.photosScrollView setContentSize:CGSizeMake(addImgButton.frame.origin.x + addImgButton.frame.size.width + _kPhotoSpacing, self.photosScrollView.frame.size.height)];
	
	
}

#pragma mark - Submission
- (IBAction)postButtonPressed:(id)sender
{
    
    if ([_newArtDictionary objectForKey:@"title"] && [[_newArtDictionary objectForKey:@"title"] length] > 0 && [[_newArtDictionary objectForKey:@"title"] length] > 0 && _addedImageCount > 0) {
    
        //set the location
        if (_selectedLocation)
            [_newArtDictionary setObject:_selectedLocation forKey:@"location[]"];
        else
            [_newArtDictionary setObject:self.currentLocation forKey:@"location[]"];
        
        //make sure strings are url encoded
        [_newArtDictionary setObject:[Utilities urlEncode:[_newArtDictionary objectForKey:@"title"]] forKey:@"title"];
        
        if ([_newArtDictionary objectForKey:@"artist"])
            [_newArtDictionary setObject:[Utilities urlEncode:[_newArtDictionary objectForKey:@"artist"]] forKey:@"artist"];
        
        if ([_newArtDictionary objectForKey:@"website"])
            [_newArtDictionary setObject:[Utilities urlEncode:[_newArtDictionary objectForKey:@"website"]] forKey:@"website"];
        
        if ([_newArtDictionary objectForKey:@"commissioned_by"])
            [_newArtDictionary setObject:[Utilities urlEncode:[_newArtDictionary objectForKey:@"commissioned_by"]] forKey:@"commissioned_by"];
        
        if ([_newArtDictionary objectForKey:@"description"])
            [_newArtDictionary setObject:[Utilities urlEncode:[_newArtDictionary objectForKey:@"description"]] forKey:@"description"];
        
        if ([_newArtDictionary objectForKey:@"location_description"])
            [_newArtDictionary setObject:[Utilities urlEncode:[_newArtDictionary objectForKey:@"location_description"]] forKey:@"location_description"];
        
        if (_yearString) {
            [_newArtDictionary setObject:_yearString forKey:@"year"];
        }
        
        if ([_newArtDictionary objectForKey:@"categories"]) {
            NSString *cats = [[_newArtDictionary objectForKey:@"categories"] componentsJoinedByString:@","];
            [_newArtDictionary setObject:[Utilities urlEncode:cats] forKey:@"category"];
            [_newArtDictionary removeObjectForKey:@"categories"];
        }
        
        //call the submit request
        [[AAAPIManager instance] submitArt:_newArtDictionary withTarget:self callback:@selector(artUploadCompleted:) failCallback:@selector(artUploadFailed:)];
        
        [self showLoadingView:@"Uploading Art..."];
        
    }
    else {
        UIAlertView *todoAlert = [[UIAlertView alloc] initWithTitle:@"Need More Info" message:@"All art must have a title, category, and photo before submission." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [todoAlert show];
        return;
    }
    
    
}

#pragma mark - Art Upload Callback Methods

- (void)artUploadCompleted:(NSDictionary*)responseDict
{
    //flag to check if this was an edit or a new submission
    BOOL newArt = NO;
    
    if ([responseDict objectForKey:@"success"]) {
        
        //parse new art and update this controller instance's art
        //grab the newly created slug if this is a creation
        if (!_art.slug) {
            [_newArtDictionary setObject:[responseDict objectForKey:@"success"] forKey:@"slug"];
            
            //it was new art
            newArt = YES;
        }
        
        //decode the objects
        for (NSString *thisKey in [_newArtDictionary allKeys]) {
            if ([[_newArtDictionary objectForKey:thisKey] isKindOfClass:[NSString class]])
                [_newArtDictionary setValue:[Utilities urlDecode:[_newArtDictionary objectForKey:thisKey]] forKey:thisKey];
        }
        
        [[AAAPIManager managedObjectContext] lock];
        _art = [[ArtParser artForDict:_newArtDictionary inContext:[AAAPIManager managedObjectContext]] retain];
        [[AAAPIManager managedObjectContext] unlock];
        
        //merge context
        [[AAAPIManager instance] performSelectorOnMainThread:@selector(mergeChanges:) withObject:[NSNotification notificationWithName:NSManagedObjectContextDidSaveNotification object:[AAAPIManager managedObjectContext]] waitUntilDone:YES];
        [(id)[[UIApplication sharedApplication] delegate] saveContext];
        
    }
    else {
        [self artUploadFailed:responseDict];
        return;
    }
    
    
    //if there are user added images upload them
    NSArray *keys = [_userAddedImagesAttribution allKeys];
    for (int index = 0; index < _userAddedImages.count; index++) {
        
        UIImage *thisImage = [_userAddedImages objectAtIndex:index];
        NSDictionary *thisAttribution = [_userAddedImagesAttribution objectForKey:[keys objectAtIndex:index]];
        
        [[AAAPIManager instance] uploadImage:thisImage forSlug:self.art.slug withFlickrHandle:[thisAttribution objectForKey:@"text"] withPhotoAttributionURL:[thisAttribution objectForKey:@"website"] withTarget:self callback:@selector(photoUploadCompleted:) failCallback:@selector(photoUploadFailed:)];
    }

    
}

- (void)artUploadFailed:(NSDictionary*)responseDict
{
    //dismiss loading view
    [_loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
    
    //show fail alert
    UIAlertView *failedAlertView = [[UIAlertView alloc] initWithTitle:@"Upload Failed" message:@"The upload failed. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [failedAlertView show];
    [failedAlertView release];
}

#pragma mark - Photo Upload Callback Methods

- (void)photoUploadCompleted
{
    _addedImageCount -= 1;
    
    //dismiss the alert view
    [_loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
    
}

- (void)photoUploadFailed
{
    _addedImageCount -= 1;
    
    //dismiss the alert view
    [_loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
    
}


- (void)photoUploadCompleted:(NSDictionary*)responseDict
{
    if ([responseDict objectForKey:@"slug"]) {
        
        //parse the art object returned and update this controller instance's art
        [[AAAPIManager managedObjectContext] lock];
        //_art = [[ArtParser artForDict:responseDict inContext:[AAAPIManager managedObjectContext]] retain];
        [self setArt:[[ArtParser artForDict:responseDict inContext:[AAAPIManager managedObjectContext]] retain]];
        [[AAAPIManager managedObjectContext] unlock];
        
        //merge context
        [[AAAPIManager instance] performSelectorOnMainThread:@selector(mergeChanges:) withObject:[NSNotification notificationWithName:NSManagedObjectContextDidSaveNotification object:[AAAPIManager managedObjectContext]] waitUntilDone:YES];
    }
    else {
        [self photoUploadFailed:responseDict];
        return;
    }
    
    _addedImageCount -= 1;
    
    //if there are no more photo upload requests processing
    //switch out of edit mode
    if (_addedImageCount == 0) {
        
        //dismiss the alert view
        [_loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
        
        //reload the map view so the updated/new art is there
        ArtAroundAppDelegate *appDelegate = (id)[[UIApplication sharedApplication] delegate];
        [appDelegate saveContext];
        
        
        [self.navigationController popViewControllerAnimated:YES];
        
        if (self.art)
            [appDelegate.mapViewController updateAndShowArt:self.art];
        else
            [appDelegate.mapViewController updateArt];

        
        //clear the user added images array
        [_userAddedImages removeAllObjects];
        [_userAddedImagesAttribution removeAllObjects];
    }
    
    
}

- (void)photoUploadFailed:(NSDictionary*)responseDict
{
    _addedImageCount -= 1;
    
    //dismiss the alert view
    [_loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
    
    
}

#pragma mark - Helpers

- (void)showLoadingView:(NSString*)msg
{
    //display loading alert view
    if (!_loadingAlertView) {
        _loadingAlertView = [[UIAlertView alloc] initWithTitle:msg message:nil delegate:self cancelButtonTitle:nil otherButtonTitles: nil];
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicator.tag = 10;
        // Adjust the indicator so it is up a few pixels from the bottom of the alert
        indicator.center = CGPointMake(_loadingAlertView.bounds.size.width / 2, _loadingAlertView.bounds.size.height - 50);
        indicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [indicator startAnimating];
        [_loadingAlertView addSubview:indicator];
        [indicator release];
    }
    
    [_loadingAlertView setTitle:msg];
    [_loadingAlertView show];
    
    
    
    //display an activity indicator view in the center of alert
    UIActivityIndicatorView *activityView = (UIActivityIndicatorView*)[_loadingAlertView viewWithTag:10];
    [activityView setCenter:CGPointMake(_loadingAlertView.bounds.size.width / 2, _loadingAlertView.bounds.size.height - 44)];
    [activityView setFrame:CGRectMake(roundf(activityView.frame.origin.x), roundf(activityView.frame.origin.y), activityView.frame.size.width, activityView.frame.size.height)];
}

- (BOOL) findAndResignFirstResponder
{
    if (self.isFirstResponder) {
        [self resignFirstResponder];
        return YES;
    }
    
    if (self.titleTextField.isFirstResponder) {
        [self.titleTextField resignFirstResponder];
        return YES;
    }
    else if (self.artistTextField.isFirstResponder) {
        [self.artistTextField resignFirstResponder];
        return YES;
    }
    else if (self.urlTextField.isFirstResponder) {
        [self.urlTextField resignFirstResponder];
        return YES;
    }
    else if (self.descriptionTextView.isFirstResponder) {
        [self.descriptionTextView resignFirstResponder];
        return YES;
    }
    else if (self.locationDescriptionTextView.isFirstResponder) {
        [self.locationDescriptionTextView resignFirstResponder];
        return YES;
    }
    
    return NO;
}

#pragma mark - Text View Delegate

- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString* newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    if (textView == self.descriptionTextView && ![textView.text isEqualToString:@"Share what you know about this art..."])
        [_newArtDictionary setObject:newText forKey:@"description"];
    else if (textView == self.locationDescriptionTextView && ![textView.text isEqualToString:@"Add extra location details..."])
        [_newArtDictionary setObject:newText forKey:@"location_description"];    
    
    return YES;
}
- (void) textViewDidChange:(UITextView *)textView
{

}

- (BOOL) textViewShouldBeginEditing:(UITextView *)textView
{
    return YES;
}

- (void) textViewDidBeginEditing:(UITextView *)textView {
    
    if ([textView.text isEqualToString:@"Share what you know about this art..."] || [textView.text isEqualToString:@"Add extra location details..."]) {
        [textView setText:@""];
        [textView setTextColor:[UIColor blackColor]];
    }
    
}

- (BOOL) textViewShouldEndEditing:(UITextView *)textView
{
    return YES;
}

- (void) textViewDidEndEditing:(UITextView *)textView
{
    if (textView.text.length == 0) {
        if (textView == self.descriptionTextView) {
            [textView setText:@"Share what you know about this art..."];
        }
        else {
            [textView setText:@"Add extra location details..."];
        }
        
        [textView setTextColor:[UIColor colorWithWhite:0.71f alpha:1.0f]];
    }
}

#pragma mark - Text Field Delegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [self findAndResignFirstResponder];
    return YES;
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString* newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    [self textFieldChanged:textField withText:newText];
    return YES;
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    
    [self textFieldChanged:textField];
}

#pragma mark - PhotoImageViewDelegate
- (void) attributionButtonPressed:(id)sender withTitle:(NSString*)title andURL:(NSURL*)url
{
    //create request
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    
    //create webview
    UIWebView *webView = [[UIWebView alloc] init];
    [webView loadRequest:request];
    
    //create view controller
    UIViewController *containerViewController = [[UIViewController alloc] init];
    [containerViewController setView:webView];
    [containerViewController setTitle:title];
    
    /*
    //create the navcontroller
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:containerViewController];
    
    //create close button and add to nav bar
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewControllerAnimated:)];
    [containerViewController.navigationItem setLeftBarButtonItem:closeButton];
    
    
    //present nav controller
    [self presentModalViewController:navController animated:YES];
    */
    [self.navigationController pushViewController:containerViewController animated:YES];
    
}


#pragma mark - AddImageButton
- (void)addImageButtonTapped
{
    
    UIActionSheet *imgSheet = [[UIActionSheet alloc] initWithTitle:@"Upload Photo" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take a Photo", @"Camera roll", nil];
    [imgSheet setTag:_kAddImageActionSheet];
    [imgSheet showInView:self.view];
    [imgSheet release];
    
}


#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{

    switch (actionSheet.tag) {
        case _kAddImageActionSheet:
            
            //decide what the picker's source is
            switch (buttonIndex) {
                    
                case 0:
                {
                    UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
                    imgPicker.delegate = self;
                    imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                    imgPicker.cameraFlashMode = ([Utilities instance].flashMode) ? [[Utilities instance].flashMode integerValue] : UIImagePickerControllerCameraFlashModeAuto;
                    [self presentModalViewController:imgPicker animated:YES];
                    break;
                }
                case 1:
                {
                    UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
                    imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                    imgPicker.delegate = self;
                    [self presentModalViewController:imgPicker animated:YES];
                    break;
                }
                default:
                    break;
            }
            
            break;
            
        case _kLocationActionSheet:
            
            switch (buttonIndex) {
                case 0:
                    _selectedLocation = [[CLLocation alloc] initWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
                    _usingPhotoGeotag = NO;
                    break;
                case 1:
                    if ([actionSheet cancelButtonIndex] != 1 && _imageLocation)
                        _selectedLocation = [[CLLocation alloc] initWithLatitude:_imageLocation.coordinate.latitude longitude:_imageLocation.coordinate.longitude];
                    _usingPhotoGeotag = YES;
                default:
                    break;
            }
            
            break;
            
        default:
            break;
    }
    


}


#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {

//    //save flash mode in case it changed
//    NSNumber *flashMode = [[NSNumber alloc] initWithInteger:picker.cameraFlashMode];
//    [[Utilities instance] setFlashMode:flashMode];
    
    //dismiss the picker view
    [self dismissViewControllerAnimated:YES completion:^{
    }];
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    //save flash mode in case it changed
//    NSNumber *flashMode = [[NSNumber alloc] initWithInteger:picker.cameraFlashMode];
//    [[Utilities instance] setFlashMode:flashMode];
    
    //dismiss the picker view
    [self dismissViewControllerAnimated:YES completion:^{
        
        // Get the image from the result
        UIImage* image = [[info valueForKey:@"UIImagePickerControllerOriginalImage"] retain];
        
        NSMutableDictionary *newInfo = [[NSMutableDictionary alloc] initWithDictionary:info];
        
        
        //create asset library
        ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
        
        //if its from the camera we have to save it first
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera && [info valueForKey:@"UIImagePickerControllerMediaMetadata"]) {
            [newInfo setObject:_currentLocation forKey:ALAssetPropertyLocation];
            _imageLocation = [[CLLocation alloc] initWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
            
        }
        else {

            NSURL *assetURL = [info valueForKey:UIImagePickerControllerReferenceURL];
            
            [assetLibrary assetForURL:assetURL
                          resultBlock:^(ALAsset *asset) {
                              
                              ALAssetRepresentation *rep = [asset defaultRepresentation];
                              NSDictionary *metadata = rep.metadata;
                              DebugLog(@"%@", metadata);
                              
                              //DebugLog(@"%@", [asset description]);
                              //check for location
                              if ([asset valueForProperty:ALAssetPropertyLocation]) {
                                  
                                  _imageLocation = [[asset valueForProperty:ALAssetPropertyLocation] retain];
                                  
                              }
                              else {
                                   DebugLog(@"No location for image");
                              }
                              
                          }
                         failureBlock:^(NSError *error) {
                             
                             //TODO: Failure case
                             DebugLog(@"Failed to get asset");
                             
                         }];
            
        }
        //if the user has already been asked for a flickr handle just add image
        if ([Utilities instance].lastFlickrUpdate) {
            
            //add image to user added images array
            [_userAddedImages addObject:image];
            
            [self userAddedImage:image];
            
        }
        else {  //if this is the first upload then prompt for their flickr handle
            
            FlickrNameViewController *flickrNameController = [[FlickrNameViewController alloc] initWithNibName:@"FlickrNameViewController" bundle:[NSBundle mainBundle]];
            [flickrNameController setImage:image];
            flickrNameController.view.autoresizingMask = UIViewAutoresizingNone;
            flickrNameController.delegate = self;
            
            [self.view addSubview:flickrNameController.view];
            [self.navigationItem.backBarButtonItem setEnabled:NO];
            [self.navigationItem.rightBarButtonItem setEnabled:NO];
            
        }
        
    }];
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    [self dismissViewControllerAnimated:YES completion:^{
        
        
        
        //if the user has already been asked for a flickr handle just add image
        if ([Utilities instance].lastFlickrUpdate) {
            
            //add image to user added images array
            [_userAddedImages addObject:image];
            
            [self userAddedImage:image];
            
        }
        else {  //if this is the first upload then prompt for their flickr handle
            
            FlickrNameViewController *flickrNameController = [[FlickrNameViewController alloc] initWithNibName:@"FlagViewController" bundle:[NSBundle mainBundle]];
            [flickrNameController setImage:image];
            flickrNameController.view.autoresizingMask = UIViewAutoresizingNone;
            flickrNameController.delegate = self;
            
            [self.view addSubview:flickrNameController.view];
            [self.navigationItem.backBarButtonItem setEnabled:NO];   
            [self.navigationItem.rightBarButtonItem setEnabled:NO];
            
        }
        
    }];
}

#pragma mark - UIScrollViewDelegate
- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView == self.scrollView) {
        if ([self.descriptionTextView isFirstResponder])
            [self.descriptionTextView resignFirstResponder];
        else if ([self.locationDescriptionTextView isFirstResponder])
            [self.locationDescriptionTextView resignFirstResponder];
    }
}

#pragma mark - FlickrNameViewControllerDelegate
//submit flag
- (void)flickrNameViewControllerPressedSubmit:(id)controller
{
    NSString *text = [[NSString alloc] initWithString:[[(FlickrNameViewController*)controller flickrHandleField] text]];
    NSString *url = [[NSString alloc] initWithString:[[(FlickrNameViewController*)controller attributionURLField] text]];
    
    [Utilities instance].photoAttributionText = text;
    [Utilities instance].photoAttributionURL = url;
    
    [self userAddedImage:[(FlickrNameViewController*)controller image] withAttributionText:text withAttributionURL:url];
    
    
    
    [[controller view] removeFromSuperview];
    [self.navigationItem.backBarButtonItem setEnabled:YES];
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    
    //setup add art button
    if ([_newArtDictionary objectForKey:@"title"] && [[_newArtDictionary objectForKey:@"title"] length] > 0 && _addedImageCount > 0) {
        
        [self.submitButton setBackgroundColor:[UIColor colorWithRed:(223.0f/255.0f) green:(73.0f/255.0f) blue:(70.0f/255.0f) alpha:1.0f]];
        self.submitButton.enabled = YES;
        
    }
    else {
        [self.submitButton setBackgroundColor:[UIColor colorWithWhite:0.71f alpha:1.0f]];
        self.submitButton.enabled = NO;
    }
    
}

//dismiss flag controller
- (void) flickrNameViewControllerPressedCancel:(id)controller
{
    
    [self userAddedImage:[(FlickrNameViewController*)controller image] withAttributionText:@"" withAttributionURL:@""];
    
    [[(FlickrNameViewController*)controller view] removeFromSuperview];
    [self.navigationItem.backBarButtonItem setEnabled:YES];
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    
    //setup add art button
    if ([_newArtDictionary objectForKey:@"title"] && [[_newArtDictionary objectForKey:@"title"] length] > 0 && _addedImageCount > 0) {
        
        [self.submitButton setBackgroundColor:[UIColor colorWithRed:(223.0f/255.0f) green:(73.0f/255.0f) blue:(70.0f/255.0f) alpha:1.0f]];
        self.submitButton.enabled = YES;
        
    }
    else {
        [self.submitButton setBackgroundColor:[UIColor colorWithWhite:0.71f alpha:1.0f]];
        self.submitButton.enabled = NO;
    }

}

//successful submission
- (void) flickrNameSubmissionCompleted
{
    [[self.view.subviews objectAtIndex:(self.view.subviews.count - 1)] removeFromSuperview];
    [self.navigationItem.backBarButtonItem setEnabled:YES];
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    
    //setup add art button
    if ([_newArtDictionary objectForKey:@"title"] && [[_newArtDictionary objectForKey:@"title"] length] > 0 && _addedImageCount > 0) {
        
        [self.submitButton setBackgroundColor:[UIColor colorWithRed:(223.0f/255.0f) green:(73.0f/255.0f) blue:(70.0f/255.0f) alpha:1.0f]];
        self.submitButton.enabled = YES;
        
    }
    else {
        [self.submitButton setBackgroundColor:[UIColor colorWithWhite:0.71f alpha:1.0f]];
        self.submitButton.enabled = NO;
    }

}

//unsuccessful submission
- (void) flickrNameSubmissionFailed
{
    [[self.view.subviews objectAtIndex:(self.view.subviews.count - 1)] removeFromSuperview];
    [self.navigationItem.backBarButtonItem setEnabled:YES];
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    
    //setup add art button
    if ([_newArtDictionary objectForKey:@"title"] && [[_newArtDictionary objectForKey:@"title"] length] > 0 && _addedImageCount > 0) {
        
        [self.submitButton setBackgroundColor:[UIColor colorWithRed:(223.0f/255.0f) green:(73.0f/255.0f) blue:(70.0f/255.0f) alpha:1.0f]];
        self.submitButton.enabled = YES;
        
    }
    else {
        [self.submitButton setBackgroundColor:[UIColor colorWithWhite:0.71f alpha:1.0f]];
        self.submitButton.enabled = NO;
    }

}

#pragma mark - Search Table Delegate
- (void) searchTableViewController:(SearchTableViewController *)searchController didFinishWithSelectedItems:(NSArray *)items
{
 
    if (searchController.tableView.tag == 10) {
        if (items.count > 0) {
            if ([[[items objectAtIndex:0] title] isEqualToString:@"None"]) {
                [_newArtDictionary removeObjectForKey:@"commissioned_by"];
                [_commissionedByButton setTitle:@"Commissioned By" forState:UIControlStateNormal];
            }
            else {
                NSString *com = [[NSString alloc] initWithString:[[items objectAtIndex:0] title]];
                [_newArtDictionary setObject:com forKey:@"commissioned_by"];
                [_commissionedByButton setTitle:com forState:UIControlStateNormal];
            }
        }
    }
    else {
        //reset and add the cateogries to the new art
        NSMutableArray *categories = [[NSMutableArray alloc] init];
        [_newArtDictionary setObject:categories forKey:@"categories"];
        
        for (SearchItem *thisItem in items) {
            
            if ([thisItem isKindOfClass:[SearchItem class]]) {
            
                if (![[_newArtDictionary objectForKey:@"categories"] containsObject:thisItem.title]) {
                    [[_newArtDictionary objectForKey:@"categories"] addObject:thisItem.title];
                }
            }
            else if ([thisItem isKindOfClass:[NSString class]]) {
                if (![[_newArtDictionary objectForKey:@"categories"] containsObject:thisItem]) {
                    [[_newArtDictionary objectForKey:@"categories"] addObject:thisItem];
                }
            }
        }
        
        if (categories.count > 0) {
            [self.categoryButton setTitle:[categories componentsJoinedByString:@", "] forState:UIControlStateNormal];
        }
        else {
            [self.categoryButton setTitle:@"Categories" forState:UIControlStateNormal];
        }
        
        
        //setup add art button
        if ([_newArtDictionary objectForKey:@"title"] && [[_newArtDictionary objectForKey:@"title"] length] > 0 && _addedImageCount > 0) {
            
            [self.submitButton setBackgroundColor:[UIColor colorWithRed:(223.0f/255.0f) green:(73.0f/255.0f) blue:(70.0f/255.0f) alpha:1.0f]];
            self.submitButton.enabled = YES;
            
        }
        else {
            [self.submitButton setBackgroundColor:[UIColor colorWithWhite:0.71f alpha:1.0f]];
            self.submitButton.enabled = NO;
        }
    }
    
    [self.navigationController popToViewController:self animated:YES];
}

#pragma mark - ArtLocationSelectionDelegate
- (void) locationSelectionViewController:(ArtLocationSelectionViewViewController *)controller selected:(LocationSelection)selection
{
    _selectedLocation = [[CLLocation alloc] initWithLatitude:controller.selectedLocation.coordinate.latitude longitude:controller.selectedLocation.coordinate.longitude];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:_selectedLocation.coordinate.latitude longitude:_selectedLocation.coordinate.longitude];
    [geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error){
            DebugLog(@"Error durring reverse geocode");
        }
        
        if (placemarks.count > 0) {
            [self.locationButton setTitle:[[placemarks objectAtIndex:0] name] forState:UIControlStateNormal];
            [self.locationButton setImage:nil forState:UIControlStateNormal];
            [self.locationButton setImageEdgeInsets:UIEdgeInsetsZero];
            [self.locationButton setContentEdgeInsets:UIEdgeInsetsZero];
            [self.locationButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 5.0f, 0, 20.0f)];
        }
        
    }];

//    switch (selection) {
//        case LocationSelectionUserLocation:
//            _selectedLocation = [[CLLocation alloc] initWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
//            [self.locationButton setTitle:@"Current Location" forState:UIControlStateNormal];
//            _usingPhotoGeotag = NO;
//            break;
//        case LocationSelectionPhotoLocation:
//            _selectedLocation = [[CLLocation alloc] initWithLatitude:_imageLocation.coordinate.latitude longitude:_imageLocation.coordinate.longitude];
//            [self.locationButton setTitle:@"Photo Location" forState:UIControlStateNormal];            
//            _usingPhotoGeotag = YES;
//            break;
//        default:
//            break;
//    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Picker Data Source
- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 114;
}

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *title = @"";
    
    NSNumber *yearNumber = [NSNumber numberWithInt:_currentYear-row];
    title = [yearNumber stringValue];
    
    return title;
}

#pragma mark - Picker View Delegate
- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSNumber *yearNumber = [NSNumber numberWithInt:_currentYear-row];
    _yearString = [[NSString alloc] initWithString:[yearNumber stringValue]];
    [self.dateButton setTitle:_yearString forState:UIControlStateNormal];
    
}


@end
