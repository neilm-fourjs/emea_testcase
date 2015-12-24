
/* NOTE: must be sym linked in gas/web/components/gm !!! */
/* $Id: gm.js 778 2010-08-17 10:54:14Z  $ */

var debug1 = "debug 6<br>";

function myGoogleMaps(myLat, myLng) {
	var latlng = new google.maps.LatLng( myLat, myLng );
	var myOptions = {
		zoom: 12,
		center: latlng,
		mapTypeId: google.maps.MapTypeId.ROADMAP,
		mapTypeControl: false
	};
	var map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);
	google.maps.event.addListener(map, 'click', function(event) {
    mapClicked( event.latLng );
  });
/*
	google.maps.event.addListener(map, 'center_changed', function() {
    mapMoved( map.getCenter() );
  });
*/
}

mapClicked = function( where ) {
	gICAPI.SetFocus();
	debug1 = debug1 + "mapClicked:"+where+"<br>";
	document.getElementById("debug").innerHTML = debug1;
	gICAPI.SetData(where);
	gICAPI.Action('mapclicked');
}


onICHostReady = function(version) {
	var myProps;

	if ( version != 1.0 ) {
		alert('Invalid API version');
		return;
	}

	gICAPI.onFocus = function( polarity ) {
		if ( polarity ) {
			obj = document.getElementById("map_canvas");
			obj.setAttribute("style","fill:green");
		} else {
			obj = document.getElementById("map_canvas");
			obj.setAttribute("style","fill:red");
		}
	}

	gICAPI.onData = function( data ) {
		debug1 = debug1 + "onData = "+data+"<br>";
		document.getElementById("debug").innerHTML = debug1;
		//gICAPI.SetFocus();
	}

	gICAPI.onProperty = function(property) {                                                   
		myProps = eval('(' + property + ')');
		if ( myProps.lat == null ) {
			debug1 = debug1 + "Property - lat = null<br>";
		} else {
			debug1 = debug1 + "Property - lat = "+myProps.lat+"<br>";
		}
		if ( myProps.lng == null ) {
			debug1 = debug1 + "Property - lng = null<br>";
		} else {
			debug1 = debug1 + "Property - lng = "+myProps.lng+"<br>";
		} 
		document.getElementById("debug").innerHTML = debug1;
		myGoogleMaps(myProps.lat, myProps.lng);
		//gICAPI.SetFocus();
	}
}