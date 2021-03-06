//
//  AddArtViewController.h
//  ArtAround
//
//  Created by Brian Singer on 5/18/13.
//  Copyright (c) 2013 ArtAround. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "FBConnect.h"
#import "FlagViewController.h"
#import "FlickrNameViewController.h"
#import "PhotoImageView.h"
#import "SearchTableViewController.h"
#import "TPKeyboardAvoidingScrollView.h"
#import "ArtLocationSelectionViewViewController.h"

@class Art;

static const float _kPhotoPadding = 5.0f;
static const float _kPhotoSpacing = 10.0f;
static const float _kPhotoInitialPaddingPortait = 5.0f;
static const float _kPhotoInitialPaddingForOneLandScape = 144.0f;
static const float _kPhotoInitialPaddingForTwoLandScape = 40.0f;
static const float _kPhotoInitialPaddingForThreeLandScape = 15.0f;
static const float _kPhotoWidth = 310.0f;
static const float _kPhotoHeight = 180.5f;

#define _kAddImageActionSheet 100
#define _kShareActionSheet 101
#define _kFlagActionSheet 102
#define _kLocationActionSheet 103
#define _kUserAddedImageTagBase 1000
#define _kAddImageTagBase 2000



@interface AddArtViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate, PhotoImageViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, FlickrNameViewControllerDelegate, SearchTableViewDelegate, UIScrollViewDelegate, ArtLocationSelectionViewViewControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UINavigationControllerDelegate>
{
    int                     _addedImageCount, _currentYear;
    NSString*               _yearString;
    BOOL                    _usingPhotoGeotag;
    NSMutableArray*         _userAddedImages, *_imageButtons;
    NSMutableDictionary*    _newArtDictionary, *_userAddedImagesAttribution;
    UIAlertView*            _loadingAlertView;
    UIPickerView*           _datePicker;
    UIToolbar*              _dateToolbar;
    UIBarButtonItem*        _doneButton;
    CLLocation*             _imageLocation, *_selectedLocation;
}


#pragma mark - Properties
@property (nonatomic, retain) CLLocation *currentLocation;
@property (nonatomic, assign) Art *art;

#pragma mark - IB Outlet
@property (retain, nonatomic) IBOutlet TPKeyboardAvoidingScrollView *scrollView;
@property (retain, nonatomic) IBOutlet UIScrollView *photosScrollView;
@property (retain, nonatomic) IBOutlet UIButton *locationButton;
@property (retain, nonatomic) IBOutlet UITextField *artistTextField;
@property (retain, nonatomic) IBOutlet UITextField *titleTextField;
@property (retain, nonatomic) IBOutlet UITextField *urlTextField;
@property (retain, nonatomic) IBOutlet UIButton *categoryButton;
@property (retain, nonatomic) IBOutlet UIButton *dateButton;
@property (retain, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (retain, nonatomic) IBOutlet UITextView *locationDescriptionTextView;
@property (retain, nonatomic) IBOutlet UIButton *submitButton;
@property (retain, nonatomic) IBOutlet UIButton *commissionedByButton;

- (void)userAddedImage:(UIImage*)image;
- (void)userAddedImage:(UIImage*)image withAttributionText:(NSString*)text withAttributionURL:(NSString*)url;
- (void)setupImages;
- (IBAction)postButtonPressed:(id)sender;



@end
