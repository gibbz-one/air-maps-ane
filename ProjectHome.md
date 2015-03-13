**AIR Maps Native Extension**

This project provides the support for using the native mapping component in your Adobe AIR application. It uses Native Extensions to access the maps APIs for that platform and provides Action Script Interface so that it can be used in Flash Mobile applications developed using Adobe AIR.

Please see http://www.adobe.com/devnet/air/articles/extending-air.html to know more about native extensions.

Note : Currently it supports only iOS native maps

![https://dl.dropbox.com/u/80639839/snapshot.png](https://dl.dropbox.com/u/80639839/snapshot.png)

**Features**

show/hide map view on AIR application
<br>zoom In/Out similar to Google Maps Flash API<br>
<br>change/set the map center to any location on globe<br>
<br>drawViewPortToBitmapData : It allows you to get the mapview which is displayed on a <br>separate plane above flash stage in form of bitmap data.<br>
<br>
<b>Latest Features</b>
<ul><li>MapMouseEvent.MARKER_SELECT, MapMouseEvent.MARKER_DESELECT : Dispatched if a marker is selected or deselected resp.<br>
</li><li>map.setShowUserLocation, map.getshowUserLocation : query and change if the user location is being displayed on map using a default marker<br>
</li><li>map.zoomToRect(LatLng1, LatLng2) : zooms the map to the rectangle defined by the LatLng provided as its arguments<br>
</li><li>Basic Polyline support for showing routes(vector of points) on top of map view as overlays<br>
</li><li>marker.openInfoWindow : Opens the marker's info window<br>
</li><li>marker.closeInfoWindow() : Closes the marker info window.</li></ul>

<b>UpComing Features As Requested</b>

<ul><li>MapEvent.DETAIL_BUTTON_PRESSED : Dispatched when details button is pressed for a marker.<br>
</li><li>Marker.detailBtn : Ability to show/hide detail button for a marker<br>
They have been already there in milestone branch. You just need to compile the source or use the ane file directly.</li></ul>

If you would like to see a new feature in this library do Vote/Request for New Features in Issues tab<br>
<br>
Checkout : <a href='http://code.google.com/p/air-maps-ane/wiki/CodeSnippets'>http://code.google.com/p/air-maps-ane/wiki/CodeSnippets</a> for code snippets and getting started.<br>
<br>
<b>Videos</b>
<a href='http://www.flashmobileblog.com/2011/09/15/air-3-mapview-native-extension-on-ios/#disqus_thread'>http://www.flashmobileblog.com/2011/09/15/air-3-mapview-native-extension-on-ios/#disqus_thread</a>

Applications on AppStore<br>
<br><a href='http://itunes.apple.com/no/app/marine-fuel-locator/id512507279?mt=8'>Båtbensin</a>
<br><a href='http://itunes.apple.com/app/singapore-symphony-orchestra/id515675324?mt=8'>Singapore Symphony Orchestra - SSO</a>