//
//  MapNENativeMain.m
//  MapsNE_Native
//
//  Created by Meet Shah on 6/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MapNENativeMain.h"
#include "FlashRuntimeExtensions.h"
#import <MapKit/MapKit.h>
#import "QuartzCore/CAEAGLLayer.h"
#include "MyCustomAnnotation.h"
#include "PinAnnotation.h"

#define MERCATOR_OFFSET 268435456
#define MERCATOR_RADIUS 85445659.44705395

// Objective-C code
#import <UIKit/UIKit.h>
id refToSelf;
FREContext ctxRef=nil;
float scaleFactor=1.0;
int32_t selectedId = -1;
NSString *my_location_text = NULL;

NSMutableArray * annotationsArray=nil;

@implementation MapNENativeMain

@synthesize mapView,applicationView;

//Sets the viewPort i.e the bounds of the map View
-(void)setViewPort:(CGRect)frame
{
	[mapView setFrame:frame];
}
//Returns the viewPort i.e the bounds of the map View
-(CGRect)getViewPort
{
	return mapView.frame;
}
//Adds the mapView onto the main View root View Controller
-(void)showMap
{
	NSLog(@"*******************In showMapView function********************");
	if([mapView superview]==nil)
	{
		NSLog(@"Adding a Map View");
		[applicationView addSubview:mapView];
	}
}

//Removes the mapView from the main View root View Controller
-(void)hideMap
{	
	NSLog(@"*******************In hideMapView function********************");
	if([mapView superview]!=nil)
	{
		NSLog(@"Removing a Map View");
		[mapView removeFromSuperview];
	}
	
}

-(void)panTo:(CLLocationCoordinate2D)newCenter{
	[mapView setCenterCoordinate:newCenter animated:YES];
}
-(void)setZoom:(MKCoordinateRegion)newRegion{
	
	//MKCoordinateRegion rtf=[mapView regionThatFits:newRegion];
	//NSLog([NSString stringWithFormat:@"Coordinate that fits :%f %f",rtf.span.latitudeDelta,rtf.span.longitudeDelta]);
	
	[mapView setRegion:newRegion animated:YES];	
}

-(double)getZoom{
	//return mapView.region.span;
	double z=[refToSelf zoomFromSpan:[[refToSelf mapView] region].span];
	return z;
}
-(void)setMapCenter:(CLLocationCoordinate2D)newCenter
{
	[mapView setCenterCoordinate:newCenter animated:YES];
   // [refToSelf doStuff];
}
-(CLLocationCoordinate2D)getMapCenter
{
	return [mapView centerCoordinate];
}

//MKMapView Delegate Event Handlers:
-(void)mapViewWillStartLoadingMap:(MKMapView *)mapView
{
	NSLog(@"Loading Map");
	FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"WillStartLoadingMap", (const uint8_t*)"");
}
-(void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
	NSLog(@"Map Loading Finished");
	FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"DidFinishLoadingMap", (const uint8_t*)"");	
   // [mapView setVisibleMapRect:MKMapRectMake(154649346, 86164736, 227644, 295937) animated:YES];
}
-(void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error
{
	NSLog(@"Error Loading Map");
	FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"DidFailLoadingMap", (const uint8_t*)"");
}



//Helper methods for mapping the google Maps zoomLevel to iOS MKCordinateSpan
- (double)longitudeToPixelSpaceX:(double)longitude
{
    return round(MERCATOR_OFFSET + MERCATOR_RADIUS * longitude * M_PI / 180.0);
}

- (double)latitudeToPixelSpaceY:(double)latitude
{
    return round(MERCATOR_OFFSET - MERCATOR_RADIUS * logf((1 + sinf(latitude * M_PI / 180.0)) / (1 - sinf(latitude * M_PI / 180.0))) / 2.0);
}

- (double)pixelSpaceXToLongitude:(double)pixelX
{
    return ((round(pixelX) - MERCATOR_OFFSET) / MERCATOR_RADIUS) * 180.0 / M_PI;
}

- (double)pixelSpaceYToLatitude:(double)pixelY
{
    return (M_PI / 2.0 - 2.0 * atan(exp((round(pixelY) - MERCATOR_OFFSET) / MERCATOR_RADIUS))) * 180.0 / M_PI;
	
}
- (MKCoordinateSpan)coordinateSpanWithMapView:(MKMapView *)mapViewLocal
							 centerCoordinate:(CLLocationCoordinate2D)centerCoordinate
								 andZoomLevel:(NSUInteger)zoomLevel
{
    // convert center coordiate to pixel space
    double centerPixelX = [self longitudeToPixelSpaceX:centerCoordinate.longitude];
    double centerPixelY = [self latitudeToPixelSpaceY:centerCoordinate.latitude];
    
    // determine the scale value from the zoom level
    NSInteger zoomExponent = 20 - zoomLevel;
    double zoomScale = pow(2, zoomExponent);
    
    // scale the map’s size in pixel space
    CGSize mapSizeInPixels = mapViewLocal.bounds.size;
    double scaledMapWidth = mapSizeInPixels.width * zoomScale;
    double scaledMapHeight = mapSizeInPixels.height * zoomScale;
    
    // figure out the position of the top-left pixel
    double topLeftPixelX = centerPixelX - (scaledMapWidth / 2);
    double topLeftPixelY = centerPixelY - (scaledMapHeight / 2);
    
    // find delta between left and right longitudes
    CLLocationDegrees minLng = [self pixelSpaceXToLongitude:topLeftPixelX];
    CLLocationDegrees maxLng = [self pixelSpaceXToLongitude:topLeftPixelX + scaledMapWidth];
    CLLocationDegrees longitudeDelta = maxLng - minLng;
    
    // find delta between top and bottom latitudes
    CLLocationDegrees minLat = [self pixelSpaceYToLatitude:topLeftPixelY];
    CLLocationDegrees maxLat = [self pixelSpaceYToLatitude:topLeftPixelY + scaledMapHeight];
    CLLocationDegrees latitudeDelta = -1 * (maxLat - minLat);
    
    // create and return the lat/lng span
    MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    return span;
}
-(double)zoomFromSpan:(MKCoordinateSpan)mapSpan
{
	CGPoint topLeftPt;topLeftPt.x=0;topLeftPt.y=0;
	CLLocationCoordinate2D topLeftCoordinate=[mapView convertPoint:topLeftPt toCoordinateFromView:mapView];
	
	NSLog(@"%f %f top Left",topLeftCoordinate.latitude,topLeftCoordinate.longitude);
	
	CGPoint bottomRightPt;bottomRightPt.x=mapView.bounds.size.width;bottomRightPt.y=mapView.bounds.size.height;
	CLLocationCoordinate2D bottomRightCoordinate=[mapView convertPoint:bottomRightPt toCoordinateFromView:mapView];
	
	NSLog(@"%f %f bottom right",bottomRightCoordinate.latitude,bottomRightCoordinate.longitude);
	
	double leftPixelX=[self longitudeToPixelSpaceX:topLeftCoordinate.longitude];
	double rightPixelX=[self longitudeToPixelSpaceX:bottomRightCoordinate.longitude];
	double scaledMapWidth=rightPixelX-leftPixelX;
	
	double topPixelY=[self latitudeToPixelSpaceY:topLeftCoordinate.latitude];
	double bottomPixelY=[self latitudeToPixelSpaceY:bottomRightCoordinate.latitude];
	double scaledMapHeight=topPixelY-bottomPixelY;
	
	double zoomScale=scaledMapWidth / mapView.bounds.size.width;
	double zoomScaleVerify=-1 * (scaledMapHeight / mapView.bounds.size.height);
	NSLog(@"%f %f zoom and verify",zoomScale, zoomScaleVerify);
	
	double zoomExponent=logf(zoomScale)/logf(2.0f);
	double zoomLevel=20-zoomExponent;
	NSLog(@"%f %f Exponent and Level",zoomExponent,zoomLevel);
	
	return zoomLevel;
	
}

/************* Code for creating bitmap graphics context****************************/
CGContextRef MyCreateBitmapContext (int pixelsWide,int pixelsHigh)
{
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    
    bitmapBytesPerRow   = (pixelsWide * 4);// 1
    bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    bitmapData = malloc( bitmapByteCount);// 3
    memset(bitmapData, 0, sizeof(bitmapData));
    if (bitmapData == NULL)
    {
        fprintf (stderr, "Memory not allocated!");
        return NULL;
    }
    context = CGBitmapContextCreate (bitmapData,// 4
                                     pixelsWide,
                                     pixelsHigh,
                                     8,      // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     kCGImageAlphaPremultipliedLast);
    if (context== NULL)
    {
        free (bitmapData);// 5
        fprintf (stderr, "Context not created!");
        return NULL;
    }
    CGColorSpaceRelease( colorSpace );// 6
    
    return context;// 7
}
//************NEW STUFF ADDED HERE OR MODIFIED
//************NEW STUFF ADDED HERE OR MODIFIED
//************NEW STUFF ADDED HERE OR MODIFIED
//************NEW STUFF ADDED HERE OR MODIFIED
//************NEW STUFF ADDED HERE OR MODIFIED

/*-(void)zoomToRect:(CLLocation*)param,(CLLocation*)param2
{ 

// var myLocation1:LatLng = new LatLng(59.83817,10.68051);
// var myLocation2:LatLng = new LatLng(59.83717,10.68151)
//45.788235,24.143221 - sibiu location
//59.83817,10.68051 - norway
//45.790031,24.142599
CLLocationCoordinate2D coord;
//coord.latitude =  45.788235;
//coord.longitude = 24.143221;
coord.latitude = 59.83717;
coord.longitude = 10.68151;
MKMapPoint mp1 = MKMapPointForCoordinate(coord);
coord.latitude = 59.83817;
coord.longitude = 10.68051;
MKMapPoint mp2 = MKMapPointForCoordinate(coord);


MKMapRect mr = MKMapRectMake (fmin(mp1.x, mp2.x),
                              fmin(mp1.y, mp2.y),
                              fabs(mp1.x - mp2.x),
                              fabs(mp1.y - mp2.y));

[mapView setVisibleMapRect:mr animated:YES];


}*/


-(void)showUserLocation{
	
    mapView.showsUserLocation=YES;
}
-(void)hideUserLocation{
    mapView.showsUserLocation=false;
}
//Annotation Event handlers
-(MKAnnotationView *)mapView:(MKMapView *)mapViewLocal viewForAnnotation:(id<MKAnnotation>)annotation
{
    if([annotation isKindOfClass:[MKUserLocation class]])
    {
       
     FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"USER_LOCATION_AVAILABLE", (const uint8_t *)"");
        return nil;
    }
    if (annotation==mapView.userLocation ) {
        FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"USER_LOCATION_CLICKED", (const uint8_t *)"");
        return nil;
    }
    MKPinAnnotationView* pinView=(MKPinAnnotationView*)[mapViewLocal dequeueReusableAnnotationViewWithIdentifier:@"CustomPinAnnotation"];
    if(!pinView)
    {
        NSLog(@"Got from dequeue");
        pinView=[[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"CustomPinAnnotation"] autorelease];
        UIButton *myDetailButton = [UIButton buttonWithType:UIButtonTypeCustom];
      if ([((MyCustomAnnotation*)annotation) detailBtn])
      {
        myDetailButton.frame = CGRectMake(0, 0, 32, 32);
        myDetailButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        myDetailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        
        [myDetailButton addTarget:self
                        action:@selector(showDetails:)
              forControlEvents:UIControlEventTouchUpInside];
        
        // Set the image for the button
        [myDetailButton setImage:[UIImage imageNamed:@"MKarrow.png"] forState:UIControlStateNormal];
        
        // Set the button as the callout view
        pinView.rightCalloutAccessoryView = myDetailButton;
      }
        
    }
    else
    {
        NSLog(@"Didnt got");
        pinView.annotation=annotation;
    }
    pinView.pinColor=[((MyCustomAnnotation*)annotation) markerPinColor];
    pinView.canShowCallout=YES;
    NSLog(@"Returning PinView %d",[((MyCustomAnnotation*)annotation) markerPinColor]);
    return pinView;
}
- (void)showDetails:(id)sender
{
    // RETURNEAZA ID-UL
    int32_t myInt = selectedId;
    NSString *myOutStr = [NSString stringWithFormat:@"%d", myInt];
    FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"DETAIL_BUTTON_PRESSED", (const uint8_t *)myOutStr.UTF8String);

}

//select and deselect
-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
	NSLog(@"test event");
    int32_t myInt = selectedId;
    NSString *myOutStr = [NSString stringWithFormat:@"%d", myInt];
	FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"PIN_DESELECTED", (const uint8_t*)myOutStr.UTF8String);
    selectedId = -1;
}
-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    
    NSLog(@"Test event");
    
    MyCustomAnnotation *selAnnotation = view.annotation;
    
    if([selAnnotation isKindOfClass:[MKUserLocation class]])
    {
      
        FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"USER_LOCATION_CLICKED", (const uint8_t *)"");
       /*
        if(my_location_text != NULL)
        {
           
            //NSString *mumu = [NSString stringWithFormat:@"mu: %s", my_location_text];
            // FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"()()()()()", (const uint8_t *)my_location_text);
            //[selAnnotation setTitle: (NSString *)mumu];
            // [selAnnotation setTitle: (const uint8_t *)my_location_text.UTF8String];
        }*/
        return;
    }
    //// RETURNEAZA PIN TITLE
    //NSString* myText = [@"Trace -->" stringByAppendingString: [selAnnotation title]];
    //FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"didSelectTitle", (const uint8_t *)myText.UTF8String);
    // RETURNEAZA ID
    int32_t myInt = [selAnnotation myId];
    NSString *myOutStr = [NSString stringWithFormat:@"%d", myInt];
    FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"PIN_SELECTED", (const uint8_t *)myOutStr.UTF8String);
    
    selectedId = [selAnnotation myId];
}

//SET CURECT LOCATION HANDLER ACTION 
-(void)setIt:(NSString*)param
{
  // FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"USER_LOCATION_TITLE_CHANGED", (const uint8_t *)"");
   mapView.userLocation.title = param;
   return;
}
//ZOOOM TO RECT HANDLER ACTION
-(void)zoomMeToRect:(MKMapRect)param
{
    mapView.visibleMapRect = (param);
    return;
}
//opens the callout of the pin with the given id 
-(void)openMyMarker:(int32_t)param
{
    MyCustomAnnotation *abc=NULL;
   for(int i=0;i<[annotationsArray count];i++)
    {
        abc=[annotationsArray objectAtIndex:i];
        if([abc myId]==param)
        {
            id<MKAnnotation> myAnnotation = [self.mapView.annotations objectAtIndex:i];
            [self.mapView selectAnnotation:myAnnotation animated:YES];
            int32_t myInt = [abc myId];
            NSString *myOutStr = [NSString stringWithFormat:@"%d", myInt];
            FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"PIN_SELECTED", (const uint8_t *)myOutStr.UTF8String);
            selectedId = myInt;
            break;
        }
        
    }
}
//closes the callout of the pin with the given id 
-(void)closeMyMarker
{
    MyCustomAnnotation *abc=NULL;
    for(int i=0;i<[annotationsArray count];i++)
    {
        abc=[annotationsArray objectAtIndex:i];
        if([abc myId]==selectedId)
        {
            id<MKAnnotation> myAnnotation = [self.mapView.annotations objectAtIndex:i];
            [self.mapView deselectAnnotation:myAnnotation animated:YES];
            int32_t myInt = [abc myId];
            NSString *myOutStr = [NSString stringWithFormat:@"%d", myInt];
            FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"PIN_DESELECTED", (const uint8_t *)myOutStr.UTF8String);
            selectedId = -1;
            break;
        }
        
    }
}

//user location events
- (void)mapView:(MKMapView *)theMapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
   NSString *myLat = [NSString stringWithFormat:@"%f|", userLocation.location.coordinate.latitude];
   NSString *myLon = [NSString stringWithFormat:@"%f", userLocation.location.coordinate.longitude];
   NSString *concat = [myLat stringByAppendingString:myLon];
   FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"USER_LOCATION_UPDATE", (const uint8_t *)concat.UTF8String);
}
- (void)mapView:(MKMapView *)theMapView didFailToLocateUserWithError:(NSError *)error
{
   FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"USER_LOCATION_FAIL_TO_LOCATE_USER_WITH_ERROR", (const uint8_t *)error);
}
- (void)mapView:(MKMapView *)theMapView mapViewWillStart :(NSError *)error
{
    FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"USER_LOCATION_FAIL_TO_LOCATE_USER", (const uint8_t *)"");
}
-(void)mapViewWillStartLocatingUser:(MKMapView *)mapView
{
 FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"USER_LOCATION_UPDATE_STARTED", (const uint8_t *)"");
}
-(void)mapViewDidStopLocatingUser:(MKMapView *)mapView
{
    FREDispatchStatusEventAsync(ctxRef, (const uint8_t *)"USER_LOCATION_UPDATE_STOPPED", (const uint8_t *)"");
}
@end

//NEW FREEOBJECT STUFF

//opens the callout of the pin with the given id
FREObject closeMarkerHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	NSLog(@"*******************In setUserLocationHandler function********************");
    [refToSelf closeMyMarker];
    return NULL;
}

//opens the callout of the pin with the given id
FREObject openMarkerHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	NSLog(@"*******************In setUserLocationHandler function********************");
    int32_t ID;
    
    FREGetObjectAsInt32(argv[0],&ID);
   [refToSelf openMyMarker:ID];
    return NULL;
}


// sets the zoom and location of the map to fit in a specified rectangle

FREObject zoomToRectHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
  	NSLog(@"*******************In ZOOM TO RECTANGLE function********************");

    FREObject x;
    FREObject y;
    FREObject width;
    FREObject height;
    
    FREGetObjectProperty(argv[0], (const uint8_t*)"x", &x, NULL);
    FREGetObjectProperty(argv[0], (const uint8_t*)"y", &y, NULL);
    FREGetObjectProperty(argv[0], (const uint8_t*)"width", &width, NULL);
    FREGetObjectProperty(argv[0], (const uint8_t*)"height", &height, NULL);

    CLLocationCoordinate2D coord;
    CLLocationCoordinate2D coord2;
   
    double d1,d2,d3,d4;
    
    FREGetObjectAsDouble(x, &d1);coord.latitude = d1;
    FREGetObjectAsDouble(y, &d2);coord.longitude = d2;
    FREGetObjectAsDouble(width, &d3);coord2.latitude = d3;
    FREGetObjectAsDouble(height, &d4);coord2.longitude = d4;
 
    MKMapPoint mp1 = MKMapPointForCoordinate(coord);
    MKMapPoint mp2 = MKMapPointForCoordinate(coord2);
    
    MKMapRect mr = MKMapRectMake (fmin(mp1.x, mp2.x),
                                  fmin(mp1.y, mp2.y),
                                  fabs(mp1.x - mp2.x),
                                  fabs(mp1.y - mp2.y));
    [refToSelf zoomMeToRect:mr];
     return NULL;

}


//sets the text for the user location pin 
FREObject setUserLocationTextHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	NSLog(@"*******************In setUserLocationTextHandler function********************");
    
    FREObject userTitle;
    FREGetObjectProperty(argv[0], (const uint8_t*)"userTitle", &userTitle, NULL);
    const uint8_t* myString;

    uint32_t titleLength;
    FREGetObjectAsUTF8(userTitle, &titleLength, &myString);
   
    NSString *albumString = [NSString stringWithUTF8String:(char*)myString];
   
    [refToSelf setIt:albumString]; 
    return NULL;
}

//set user location to visible or not visibile
FREObject setUserLocationHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	NSLog(@"*******************In setUserLocationHandler function********************");
    int32_t mapType;
    
    FREGetObjectAsInt32(argv[0],&mapType);
    if(mapType==1)
        [refToSelf showUserLocation];
        //[[refToSelf mapView] showsUserLocation:NO];
    else if(mapType==0)
      [refToSelf hideUserLocation];
        // [[refToSelf mapView] showsUserLocation:YES];
   	return NULL;
}



// Creates a Map View Object
FREObject createMapViewHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	
	
	NSLog(@"*******************In createMapViewHandler function********************");
	CGRect frame=CGRectMake(50, 50, 300,300);
	
    //Create a MKMapView Object
	MKMapView *aView=[[MKMapView alloc] initWithFrame:frame];
    aView.delegate=refToSelf;
	[refToSelf setMapView:aView];
	return NULL;
}

// Show a Map View Object
FREObject showMapViewHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	NSLog(@"*******************In showMapViewHandler function********************");
	
	[refToSelf showMap];
	return NULL;
}

// Remove a Map View Object
FREObject hideMapViewHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	NSLog(@"*******************In hideMapViewHandler function********************");
	
	[refToSelf hideMap];
	return NULL;
}

// Returns the bounds of Map View in pixel coordinates
FREObject getViewPortHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	NSLog(@"*******************In getViewPortHandler function********************");
	CGRect frame=[refToSelf getViewPort];
	
	NSLog(@"*******************Constructing Rectangle FRE Object from native CGRect*****************");
	FREObject* argV=(FREObject*)malloc(sizeof(FREObject)*4);
	FREObject returnObject;
	FRENewObjectFromDouble(frame.origin.x*scaleFactor, &argV[0]);
	FRENewObjectFromDouble(frame.origin.y*scaleFactor, &argV[1]);
	FRENewObjectFromDouble(frame.size.width*scaleFactor, &argV[2]);
	FRENewObjectFromDouble(frame.size.height*scaleFactor, &argV[3]);
	
	//int i= FRENewObject((const uint8_t*)"flash.geom.Rectangle",4,argV,&returnObject,NULL);
	//if (i!=FRE_OK) {
	//	NSLog([NSString stringWithFormat:@"Call to FRENewObject reply value is %d",i]);
	//}
	return returnObject;
}

// Changes the bounds of Map View to new pixel coordinates
FREObject setViewPortHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	NSLog(@"*******************In setViewPortHandler function********************");
	
	NSLog(@"*******************Constructing native CGRect from Rectangle FRE Object*****************");
	FREObject x;
	FREObject y;
	FREObject width;
	FREObject height;
	
	FREGetObjectProperty(argv[0], (const uint8_t*)"x", &x, NULL);
	FREGetObjectProperty(argv[0], (const uint8_t*)"y", &y, NULL);
	FREGetObjectProperty(argv[0], (const uint8_t*)"width", &width, NULL);
	FREGetObjectProperty(argv[0], (const uint8_t*)"height", &height, NULL);
	
	CGRect frame;
	double d1,d2,d3,d4;
	
	FREGetObjectAsDouble(x, &d1);frame.origin.x=d1/scaleFactor;
	FREGetObjectAsDouble(y, &d2);frame.origin.y=d2/scaleFactor;	
	FREGetObjectAsDouble(width, &d3);frame.size.width=d3/scaleFactor;
	FREGetObjectAsDouble(height, &d4);frame.size.height=d4/scaleFactor;
	[refToSelf setViewPort:frame];
	return NULL;
}

FREObject getCenterHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	NSLog(@"*******************In getCenterHandler function********************");
	CLLocationCoordinate2D mapCenter=[refToSelf getMapCenter];
	
	
	NSLog(@"*******************Constructing Custom LatLng FRE Object from native CGRect*****************");
	FREObject* argV=(FREObject*)malloc(sizeof(FREObject)*2);
	FREObject returnObject;
	FRENewObjectFromDouble(mapCenter.latitude, &argV[0]);
	FRENewObjectFromDouble(mapCenter.longitude, &argV[1]);
	
	int i= FRENewObject((const uint8_t*)"com.adobe.nativeExtensions.maps.LatLng",2,argV,&returnObject,NULL);
	if (i!=FRE_OK) {
		NSLog(@"Call to FRENewObject reply value is %d",i);
	}
	return returnObject;
	

}

FREObject setCenterHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	NSLog(@"*******************In setCenterHandler function********************");
	
	NSLog(@"*******************Constructing native CLLocationCoordinate2D from Custom LatLng FRE Object*****************");
	FREObject lat;
	FREObject lng;

	if(FRECallObjectMethod(argv[0], (const uint8_t*)"lat",0,nil, &lat, NULL) != FRE_OK) NSLog(@"Error ");
	FRECallObjectMethod(argv[0], (const uint8_t*)"lng",0,nil, &lng, NULL);
	
	CLLocationCoordinate2D newCenter;
	double nlat,nlng;
	
	FREGetObjectAsDouble(lat, &nlat);newCenter.latitude=nlat;
	FREGetObjectAsDouble(lng, &nlng);newCenter.longitude=nlng;
	
	[refToSelf setMapCenter:newCenter];
	
	return NULL;
	
}

FREObject panToHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	NSLog(@"*******************In panToHandler function********************");
	
	NSLog(@"*******************Constructing native CLLocationCoordinate2D from Custom LatLng FRE Object*****************");
	FREObject lat;
	FREObject lng;
	
	if(FRECallObjectMethod(argv[0], (const uint8_t*)"lat",0,nil, &lat, NULL) != FRE_OK) NSLog(@"Error ");
	FRECallObjectMethod(argv[0], (const uint8_t*)"lng",0,nil, &lng, NULL);
	
	CLLocationCoordinate2D newCenter;
	double nlat,nlng;
	
	FREGetObjectAsDouble(lat, &nlat);newCenter.latitude=nlat;
	FREGetObjectAsDouble(lng, &nlng);newCenter.longitude=nlng;
	
	[refToSelf panTo:newCenter];
	return NULL;
	
}


FREObject getZoomHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	NSLog(@"*******************In getZoomHandler function********************");
	
	NSLog(@"*******************Constructing FRE Object from native Double*****************");
	FREObject returnObject;
	
	//Both latitude and longitude are same for this NE so return any of them
	FRENewObjectFromDouble([refToSelf getZoom], &returnObject);
	return returnObject;
	
}



FREObject setZoomHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	NSLog(@"*******************In setZoomHandler function********************");
	
	NSLog(@"*******************Constructing native Double from FRE Number*****************");
	double newZoomNative;
	
	FREGetObjectAsDouble(argv[0], &newZoomNative);
	
	newZoomNative = MIN(newZoomNative, 28);
    
    // use the zoom level to compute the region
    MKCoordinateSpan span = [refToSelf coordinateSpanWithMapView:[refToSelf mapView] centerCoordinate:[[refToSelf mapView] centerCoordinate] andZoomLevel:newZoomNative];
    MKCoordinateRegion newRegion = MKCoordinateRegionMake([refToSelf mapView].region.center, span);
	
	NSLog(@"Setting new Zoom to %f",newZoomNative);
	
	[refToSelf setZoom:newRegion];

	return NULL;
}


FREObject addOverlayHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	NSLog(@"*******************In addOverlayHandler function********************");
    
    NSLog(@"*******************Coverting Marker object to native Annotation Object*********************");
    
    FREObject latLng,title,subtitle,my_Id,fillColor,detailBtn;
    int32_t myAsId,intColor,myDetailBtn;
   // BOOL myDetailBtn;
    MKPinAnnotationColor pinColor;
    FREGetObjectProperty(argv[0], (const uint8_t*)"latLng", &latLng, NULL);
    FREGetObjectProperty(argv[0], (const uint8_t*)"title", &title, NULL);
    FREGetObjectProperty(argv[0], (const uint8_t*)"subtitle", &subtitle, NULL);
    FREGetObjectProperty(argv[0], (const uint8_t*)"myId", &my_Id, NULL);
    FREGetObjectProperty(argv[0], (const uint8_t*)"fillColor", &fillColor, NULL);
    FREGetObjectProperty(argv[0], (const uint8_t*)"detailBtn", &detailBtn, NULL);
    FREGetObjectAsInt32(fillColor,&intColor);
    pinColor=(MKPinAnnotationColor)intColor;
    FREGetObjectAsInt32(my_Id,&myAsId);
    FREGetObjectAsInt32(detailBtn,&myDetailBtn);
    //FREGetObjectAsBool(detailBtn, &myDetailBtn);
                       
    NSLog(@"%d is the value",myAsId);
    
    
    FREObject lat;
	FREObject lng;
    if(FRECallObjectMethod(latLng, (const uint8_t*)"lat",0,nil, &lat, NULL) != FRE_OK) NSLog(@"Error ");
	FRECallObjectMethod(latLng, (const uint8_t*)"lng",0,nil, &lng, NULL);
    
    MyCustomAnnotation *annotation1= [MyCustomAnnotation alloc];
    [annotation1 initWithId:myAsId];
    [annotation1 setDetail:myDetailBtn];
    CLLocationCoordinate2D annLocation1;
    FREGetObjectAsDouble(lat, &(annLocation1.latitude));
	FREGetObjectAsDouble(lng, &(annLocation1.longitude));
    const uint8_t* titleN;
    const uint8_t* subtitleN;
    const uint8_t* detailN;
    uint32_t titleLength,subtitleLength,detailLength;
    FREGetObjectAsUTF8(detailBtn, &detailLength, &detailN);
    FREGetObjectAsUTF8(title, &titleLength, &titleN);
    FREGetObjectAsUTF8(subtitle, &subtitleLength, &subtitleN);
    
   // NSString *testS = [NSString stringWithFormat:@"%s", titleN];
    
    [annotation1 setCoordinate:annLocation1];
     NSString *titleString = [NSString stringWithUTF8String:(char*)titleN];
     NSString *subtitleString = [NSString stringWithUTF8String:(char*)subtitleN];
    [annotation1 setTitle:titleString];
    [annotation1 setSubtitle:subtitleString];
    // [annotation1 setTitle:[NSString stringWithUTF8String:(const char*)&testS]];
  //  [annotation1 setTitle:[NSString stringWithFormat:@"XXX-> %s",titleN]];
  //  [annotation1 setSubtitle:[NSString stringWithFormat:@"æøåÆØÅ %s",]];
//WORKING - AND OLD
    // [annotation1 setSubtitle:[NSString stringWithFormat:@"%s",titleN]];
    // [annotation1 setSubtitle:[NSString stringWithFormat:@"%s",subtitleN]];
    NSLog(@"Creating Marker with color %d",pinColor);
    if(pinColor==0)
        [annotation1 setMarkerPinColor:MKPinAnnotationColorRed];
    else if(pinColor==1)
        [annotation1 setMarkerPinColor:MKPinAnnotationColorGreen];
    else if(pinColor==2)
        [annotation1 setMarkerPinColor:MKPinAnnotationColorPurple];
    else
        pinColor=MKPinAnnotationColorRed;
	
    
    [[refToSelf mapView] addAnnotation:annotation1];
    [annotationsArray addObject:annotation1];
	
	return NULL;
}

FREObject removeOverlayHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	NSLog(@"*******************In removeOverlayHandler function********************");
    FREObject my_Id;
    int32_t myAsId;
    MyCustomAnnotation *abc=NULL;
    FREGetObjectProperty(argv[0], (const uint8_t*)"myId", &my_Id, NULL);
    FREGetObjectAsInt32(my_Id,&myAsId);
	for(int i=0;i<[annotationsArray count];i++)
    {
        abc=[annotationsArray objectAtIndex:i];
        if([abc myId]==myAsId)
        {
            [annotationsArray removeObject:abc];
            NSLog(@"Element Removed with Id %d",i);
            [[refToSelf mapView]removeAnnotation:abc];
            break;
        }
    }
    
	return NULL;
}

FREObject setMapTypeHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	NSLog(@"*******************In setMapTypeHandler function********************");
    int32_t mapType;

    FREGetObjectAsInt32(argv[0],&mapType);
    if(mapType==0)
        [[refToSelf mapView] setMapType:MKMapTypeStandard];
    else if(mapType==1)
        [[refToSelf mapView] setMapType:MKMapTypeSatellite];
    else if(mapType==2)
        [[refToSelf mapView] setMapType:MKMapTypeHybrid];
	return NULL;
}

FREObject drawViewPortToBitmapDataHandler(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
	NSLog(@"*******************In drawViewPortToBitmapDataHandler function********************");
    
    
    
    /*capture screenshot of mapview*/
    UIGraphicsBeginImageContextWithOptions([refToSelf mapView].bounds.size, YES, scaleFactor);
    [[refToSelf mapView].layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSLog(@"mapview captured onto image");
    
    /*Create a BitmapContext for holding the image data*/
    CGImageRef cgImageRef=[image CGImage];
    CGContextRef myBitmapContext = MyCreateBitmapContext (CGImageGetWidth(cgImageRef) ,CGImageGetHeight(cgImageRef));
    if(myBitmapContext==nil)
    {
        NSLog(@"Error no memory in context");
        return NULL;
    }
    NSLog(@"Bitmap Context created successfully");
    
    /*capturing cgimage to bitmapcontext created above*/
    size_t bdWidth=CGImageGetWidth(cgImageRef);
    size_t bdHeight=CGImageGetHeight(cgImageRef);
    CGRect rect={{0,0},{bdWidth,bdHeight}};
    CGContextDrawImage(myBitmapContext, rect, cgImageRef);
    //Another method : [[refToSelf mapView].layer renderInContext:myBitmapContext];
    NSLog(@"CGImage captured to bitmapContext");
    
    /*taking the actual bitmap data from bitmapContext*/
    CGBitmapInfo info = CGImageGetBitmapInfo(cgImageRef);
    size_t bpp=CGImageGetBitsPerPixel(cgImageRef);
    size_t bpr=CGImageGetBytesPerRow(cgImageRef);
    size_t bpc=CGImageGetBitsPerComponent(cgImageRef);
    NSLog(
          @"\n"
          "===== INFORMATION =====\n"
          "CGImageGetHeight: %d\n"
          "CGImageGetWidth:  %d\n"
          "CGImageGetColorSpace: %@\n"
          "CGImageGetBitsPerPixel:     %d\n"
          "CGImageGetBitsPerComponent: %d\n"
          "CGImageGetBytesPerRow:      %d\n"
          "CGImageGetBitmapInfo: 0x%.8X\n"
          "  kCGBitmapAlphaInfoMask     = %s\n"
          "  kCGBitmapFloatComponents   = %s\n"
          "  kCGBitmapByteOrderMask     = %s\n"
          "  kCGBitmapByteOrderDefault  = %s\n"
          "  kCGBitmapByteOrder16Little = %s\n"
          "  kCGBitmapByteOrder32Little = %s\n"
          "  kCGBitmapByteOrder16Big    = %s\n"
          "  kCGBitmapByteOrder32Big    = %s\n",
          (int)bdWidth,
          (int)bdHeight,
          CGImageGetColorSpace(cgImageRef),
          (int)bpp,
          (int)bpc,
          (int)bpr,
          (unsigned)info,
          (info & kCGBitmapAlphaInfoMask)     ? "YES" : "NO",
          (info & kCGBitmapFloatComponents)   ? "YES" : "NO",
          (info & kCGBitmapByteOrderMask)     ? "YES" : "NO",
          (info & kCGBitmapByteOrderDefault)  ? "YES" : "NO",
          (info & kCGBitmapByteOrder16Little) ? "YES" : "NO",
          (info & kCGBitmapByteOrder32Little) ? "YES" : "NO",
          (info & kCGBitmapByteOrder16Big)    ? "YES" : "NO",
          (info & kCGBitmapByteOrder32Big)    ? "YES" : "NO"
          );
    uint32_t *data=CGBitmapContextGetData(myBitmapContext);
    
    if(data)
    {
        FREBitmapData bitmapData;
        FREAcquireBitmapData(argv[0], &bitmapData);
        
        for(int i=0;i<bdHeight;i++)
        {
            for(int j=0;j<bdWidth;j++)
            {
                //NSLog(@"%x %x %x %x ",data[i*bpr+j*4],data[i*bpr+j*4+1],data[i*bpr+j*4+2],data[i*bpr+j*4+3]);
//                if(j==10)
//                    NSLog(@"%x D",data[i*bdWidth+j]);
                uint32_t a=data[i*bdWidth+j];
                uint32_t r=a&0x00ff0000;r=r>>16;
                uint32_t b=a&0x000000ff;b=b<<16;
                a=a&0xff00ff00;
                a=a|r;
                a=a|b;
                *(bitmapData.bits32+i*bdWidth+j)=a;
//                if(j==10)
//                    NSLog(@"%x",a);
            }   
        }
        
        //memcpy(bitmapData.bits32, data, 2000);
        FREInvalidateBitmapDataRect(argv[0], 0, 0, bdWidth, bdHeight);
        FREReleaseBitmapData(argv[0]);
        NSLog(@"bitmap data from bitmapcontext obtained. Returning .....");
    }
    else
    {
        NSLog(@"bitmap data from bitmapcontext is null");
    }
    
    /*assuming that the bitmap will be created after capturing the bitmapData*/
    //FREInvalidateBitmapDataRect(bitmapData, 0, 0, bdWidth, bdHeight);
    
	return NULL;
}


// A native context instance is created
void MapsExtensionContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, 
						uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet) {
	NSLog(@"*******************In context Initializer********************");
	*numFunctionsToTest = 19;
	FRENamedFunction* func = (FRENamedFunction*)malloc(sizeof(FRENamedFunction)*19);
	
	func[0].name = (const uint8_t*)"createMapView";
	func[0].functionData = NULL;
	func[0].function = &createMapViewHandler;
	
	func[1].name = (const uint8_t*)"showMapView";
	func[1].functionData = NULL;
	func[1].function = &showMapViewHandler;
	
	func[2].name = (const uint8_t*)"hideMapView";
	func[2].functionData = NULL;
	func[2].function = &hideMapViewHandler;
	
	func[3].name = (const uint8_t*)"getViewPort";
	func[3].functionData = NULL;
	func[3].function = &getViewPortHandler;
	
	func[4].name = (const uint8_t*)"setViewPort";
	func[4].functionData = NULL;
	func[4].function = &setViewPortHandler;
	
	func[5].name = (const uint8_t*)"getCenter";
	func[5].functionData = NULL;
	func[5].function = &getCenterHandler;
	
	func[6].name = (const uint8_t*)"setCenter";
	func[6].functionData = NULL;
	func[6].function = &setCenterHandler;
	
	func[7].name = (const uint8_t*)"panTo";
	func[7].functionData = NULL;
	func[7].function = &panToHandler;
	
	func[8].name = (const uint8_t*)"getZoom";
	func[8].functionData = NULL;
	func[8].function = &getZoomHandler;
	
	func[9].name = (const uint8_t*)"setZoom";
	func[9].functionData = NULL;
	func[9].function = &setZoomHandler;
    
    func[10].name=(const uint8_t*)"addOverlay";
    func[10].functionData=NULL;
    func[10].function=&addOverlayHandler;
	
    func[11].name=(const uint8_t*)"removeOverlay";
    func[11].functionData=NULL;
    func[11].function=&removeOverlayHandler;
    
    func[12].name=(const uint8_t*)"setMapType";
    func[12].functionData=NULL;
    func[12].function=&setMapTypeHandler;
    
    func[13].name=(const uint8_t*)"drawViewPortToBitmapData";
    func[13].functionData=NULL;
    func[13].function=&drawViewPortToBitmapDataHandler;
    
    func[14].name=(const uint8_t*)"setUserLocation";
    func[14].functionData=NULL;
    func[14].function=&setUserLocationHandler;

    func[15].name=(const uint8_t*)"setUserLocationText";
    func[15].functionData=NULL;
    func[15].function=&setUserLocationTextHandler;
    
    func[16].name=(const uint8_t*)"zoomToRect";
    func[16].functionData=NULL;
    func[16].function=&zoomToRectHandler;
    
    func[17].name=(const uint8_t*)"openMarker";
    func[17].functionData=NULL;
    func[17].function=&openMarkerHandler;
    
    func[18].name=(const uint8_t*)"closeMarker";
    func[18].functionData=NULL;
    func[18].function=&closeMarkerHandler;
    
	*functionsToSet = func;
	
	//Initialize the Class which contains the feature implemetation and set refToSelf
	MapNENativeMain * t = [[MapNENativeMain alloc] init];
    refToSelf = t;
    
    annotationsArray=[[NSMutableArray alloc] init];
    
	//Set the Main application view into applicationView property of this class for further use in program
	[refToSelf setApplicationView:[[[[UIApplication sharedApplication] windows] objectAtIndex:0] rootViewController].view];
	
	ctxRef = ctx;
    NSLog(@"%s ************",ctxType);
	
	//CAEAGLLayer *layer=(CAEAGLLayer *)([[refToSelf applicationView] layer]);
	//NSLog([NSString stringWithFormat: @"*******************Retina Now******************** %f",layer.contentsScale]);
	
	scaleFactor=[[refToSelf applicationView] contentScaleFactor];
	if([[refToSelf applicationView] contentScaleFactor] > 1.0 )
	{
		NSLog(@"*******************Retina******************** %f",[[refToSelf applicationView] contentScaleFactor]);
	}
	else {
		NSLog(@"*******************Non Retina******************** %f",[[refToSelf applicationView] contentScaleFactor]);
	}

		
}

CGPoint doubleMe(CGPoint oldPt){
	CGPoint newPt;
	newPt.x=oldPt.x*2.0;
	newPt.y=oldPt.y*2.0;
	return newPt;
}

CGPoint halfMe(CGPoint oldPt){
	CGPoint newPt;
	newPt.x=oldPt.x/2.0;
	newPt.y=oldPt.y/2.0;
	return newPt;
}

// A native context instance is disposed
void MapsExtensionContextFinalizer(FREContext ctx) {
	NSLog(@"*******************In context finalizer********************");
	[refToSelf mapView].delegate=nil;
	[[refToSelf mapView] release];
	[refToSelf release];
	return;
}

// Initialization function of each extension
void MapsExtensionExtInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, 
					FREContextFinalizer* ctxFinalizerToSet) {
	NSLog(@"*******************In extension initializer********************");
	*extDataToSet = NULL;
	*ctxInitializerToSet = &MapsExtensionContextInitializer;
	*ctxFinalizerToSet = &MapsExtensionContextFinalizer;
}

// Called when extension is unloaded
void MapsExtensionExtFinalizer(void* extData) {
	NSLog(@"*******************In extension finalizer********************");
	return;
}
