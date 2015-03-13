### Map ###
```
package com.adobe.nativeExtensions.maps
{
	import flash.external.ExtensionContext;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.geom.Rectangle;



        [Event(name="TILES_LOADED_PENDING" type="com.adobe.nativeExtensions.maps.MapEvent")]
        [Event(name="TILES_LOADED" type="com.adobe.nativeExtensions.maps.MapEvent")]
        [Event(name="MAP_LOAD_ERROR" type="com.adobe.nativeExtensions.maps.MapEvent")]         
	public class Map
	{
		//Instantiates the map Object
		public function Map(){	}

		/********** New Action Script APIs that doesnt exist in Google Maps, but required for adding/removing/modification on stage**************/

                //getter for visible property returns true of map is visible else returns false
                public function get visible():Boolean{	}

                //setter for visible property, pass true if want to make the map visible on your AIR application, pass false if want to just
                //hide it for short duration
                public function set visible(newValue:Boolean):void{ }


                //gets the area on the stage in which the Map View is displayed
                public function get viewPort():Rectangle{ }

                //pass the rectangle where you want your map view to be displayed
                public function set viewPort(newRect:Rectangle):void{	}

                //Disposes of the Map object and cleans up other resources
		public function dispose():void{	}

		/************ Writing Action Script APIs similar in signature to what Google Maps for Flash offers so that minimal change in code is required for reuse ***********/
                //returns the size of the Map View in pixels
                public function getSize():Point	{}

                //sets the size of the map view to the passed Point(width,height)
                public function setSize(newSize:Point):void{}

                //returns the coordinates of the center location in MapView in Latitude/Longitude
		public function getCenter():LatLng{}

                //Changes the center location of the map
                public function setCenter(newCenter:LatLng):void
		{
			//Latitude and Longitude should be between (-90,90) and [-180,180] or else Error will be thrown

			//In fact, Latitude can have a value of -90 and 90 but iOS crashes application on setting the map latitude to -90 or 90
			//Please contact me [shahmeet4 at gmail.com] if you find a solution to this
		}

                //Retrieves the map zoom level
		public function getZoom():Number{}

                //Changes the zoom level for the map view control to the newly provided Zoom Level
                public function setZoom(newZoomLevel:Number):void{}

                //Changes the center location of the map to the given location.
		public function panTo(newCenter:LatLng):void
                {
			//Latitude and Longitude should be between (-90,90) and [-180,180] or else Error will be thrown

			//In fact, Latitude can have a value of -90 and 90 but iOS crashes application on setting the map latitude to -90 or 90
			//Please contact me [meetshah at adobe.com] if you find a solution to this
		}
                
                //Displays a pin marker provided as argument onto the map
                public function addOverlay(marker:Marker):void{}

                //Removes the pin marker provided as argument from the map
                public function removeOverlay(marker:Marker):void{}

                //It sets the Map type to one of the Map Types listed in MapType.as file
                public function setMapType(int) :void{}

                //Draws the Map's view port to a bitmap provided in the argument
                //Since the mapview is displayed on top of the Flash stage just like stagewebview, inorder to display flash components above stage, call this function to get the viewport on a bitmap data.
                public function drawViewPortToBitmapData(bitmapData:BitmapData):void

	}
}
```

### LatLng ###
```
package com.adobe.nativeExtensions.maps
{
        public class LatLng
        {
                //get the latitude
                public function lat():Number{ }

                //get the longitude
                public function lng():Number{ }
        }
}
```

### MapEvent ###
```
package com.adobe.nativeExtensions.maps
{
        public class MapEvent extends Event
        {
                //Public constants
                public static var TILES_LOADED_PENDING:String;
                public static var TILES_LOADED:String;
                public static var MAP_LOAD_ERROR:String;
                
                public function MapEvent(type:String,feature:Object=null,bubbles:Boolean=false,cancelable:Boolean=false){}
        }
 }
```

### MapType ###
```
package com.adobe.nativeExtensions.maps
{
        public class MapType extends Event
        {
                //Public constants
                public static const NORMAL_MAP:int=0;
                public static const SATELLITE_MAP_TYPE:int=1;
                public static const HYBRID_MAP_TYPE:int=2;

        }
}
```

### MarkerStyle ###
```
package com.adobe.nativeExtensions.maps.overlays
{
        public class MarkerStyles
        {
                //Public constants
                public static var MARKER_COLOR_RED;
                public static var MARKER_COLOR_GREEN;
                public static var MARKER_COLOR_PURPLE;
        }
}
```

### Marker ###
```
package com.adobe.nativeExtensions.maps.overlays
{
        public class Marker
        {
                //The position on the map where you want the marker to be placed to
                public var latLng : LatLng;

                //title string that is to be displayed on bubble that is popped when tapped on the marker
                public var title : String;

                //subtitle is the string that you want to display in the pop up as description that gets shown on tapping the marker
                public var subtitle : String;

                //Constructor to create a Marker instance. It takes latLng as its argument
                public function Marker(latLng:LatLng):void{}

                //It is used by Native Extension for internal reference counting. Do not use it in your application
                public function get myId():int{}

        }
}
```