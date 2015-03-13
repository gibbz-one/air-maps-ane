Create a rectangle for displaying your maps view :
```
var viewPortMap:Rectangle = new Rectangle(0,0,800,600);
```

Instantiate and set the viewPort to the rectangle object just created
```
googleMap = new Map();
googleMap.viewPort = viewPortMap;
```

Set the visible property to true to show the map view on top, by default it is false
```
googleMap.visible=true;
```

change the map view's width/height without changing its position
```
googleMap.setSize(new Point (800, 600));
```

zoom to a particular zoom level
```
googleMap.setZoom(17);
```

change the map center to a particular location on globe
```
googleMap.setCenter(new LatLng(31.2304167,121.4703361));
```

Change the map type to satellite, normal, hybrid
```
googleMap.setMapType(0);
```

To plot a route on the map view
```
var v:Vector.<LatLng>=new Vector.<LatLng>(5);
v[0]=new LatLng(41.000512, -109.050116);
v[1]=new LatLng(31.002371, -102.052066);
v[2]=new LatLng(36.993076, -102.041981);
v[3]=new LatLng(36.99892, -109.045267);
v[4]=new LatLng(38.00, -115.00);
var p1:Polyline=new Polyline(v);
map.addOverlay(p1);
//map.removeOverlay(p1);//to remove the overlay (in this case polyline)
```

To capture the map view in bitmap data (bd)
```
map.drawViewPortToBitmapData(bd);
```

To create a pin, set title, subtitle for default Info window, and change its visual appearance
```
var m:Marker = new Marker(new LatLng(41.000512, -109.050116));
m.title="Hello World";
m.subtitle="A hello world sample message";
m.fillColor=MarkerStyles.MARKER_COLOR_PURPLE;
map.addOverlay(m);
```

To show/hide a default info window on click of a mouse event on pins
```
var m:Marker = new Marker(new LatLng(41.000512, -109.050116));
m.title="Hello World";
m.openInfoWindow();
//m.closeInfoWindow();//to close the Info Window
```

Once you are sure that you are no longer using the map use dispose() function
```
map.dispose();
```

Listen for MapMouseEvent.MARKER\_SELECT, DESELECT on map object for touch events
<br>Listen for MapEvent class events on map object for other map loading events