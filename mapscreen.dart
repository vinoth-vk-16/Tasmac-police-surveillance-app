// mapscreen.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_8/addtasmac.dart';
import 'package:flutter_application_8/adduser.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'LocationDetailsPage.dart';
import 'SettingsPage.dart'; // Import the SettingsPage
import 'LocationInfo.dart';
import 'DownloadPage.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Position? _currentPosition;
  Set<Marker> _markers = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, bool> _markerVisitStatus = {};
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  StreamSubscription<QuerySnapshot>? _searchSubscription;

  @override
  void initState() {
    super.initState();
    _getLocationPermission();
    _loadMarkers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permission is denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied.');
      return;
    }

    _currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (_currentPosition != null) {
      setState(() {});
      _moveCameraToCurrentLocation();
    }
  }

  void _loadMarkers() {
    _firestore.collection('TASMAC_Locations').get().then((querySnapshot) {
      Set<Marker> markers = {};

      for (var doc in querySnapshot.docs) {
        GeoPoint coordinates = doc['coordinates'];
        String markerId = doc.id;
        String todayDate = DateTime.now().toIso8601String().split('T').first;
        DocumentReference visitedRef = _firestore
            .collection('TASMAC_Locations')
            .doc(markerId)
            .collection('Location_visits')
            .doc(todayDate);

        visitedRef.get().then((visitDoc) {
          bool visited = visitDoc.exists && visitDoc['visited_status'] == true;
          _markerVisitStatus[markerId] = visited;

          markers.add(
            Marker(
              markerId: MarkerId(markerId),
              position: LatLng(coordinates.latitude, coordinates.longitude),
              infoWindow: InfoWindow(
                title: doc['title'],
                snippet: doc['marker_area'],
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                visited ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
              ),
              onTap: () {
                _showMarkerDetails(
                  title: doc['title'],
                  snippet: doc['marker_area'],
                  position: LatLng(coordinates.latitude, coordinates.longitude),
                  markerId: markerId,
                );
              },
            ),
          );

          setState(() {
            _markers = markers;
          });
        }).catchError((error) {
          print('Failed to load visited status: $error');
        });
      }
    }).catchError((error) {
      print('Failed to load markers: $error');
    });
  }

  Future<void> _moveCameraToCurrentLocation() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          zoom: 15,
        ),
      ),
    );
  }

  void _moveCameraToPosition(LatLng position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 25,
        ),
      ),
    );
  }

  void _showMarkerDetails({
    required String title,
    required String snippet,
    required LatLng position,
    required String markerId,
  }) {
    String todayDate = DateTime.now().toIso8601String().split('T').first;
    DocumentReference visitedRef =
        _firestore.collection('TASMAC_Locations').doc(markerId);

    FirebaseAuth auth = FirebaseAuth.instance;
    User? currentUser = auth.currentUser;

    if (currentUser == null) {
      print('No user is currently logged in.');
      return;
    }

    String userEmail = currentUser.email!;
    DocumentReference userRef =
        _firestore.collection('User_Info').doc(userEmail);

    userRef.get().then((userDoc) {
      if (!userDoc.exists) {
        print('User information not found in User_Info collection.');
        return;
      }

      String userName = userDoc['user_name'] as String;

      visitedRef.collection('Location_visits').doc(todayDate).get().then((doc) {
        bool visited = doc.exists && doc['visited_status'] == true;
        bool notesAdded = doc.exists && doc['information'] != null;

        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFE8F5FD), // RGB(232, 245, 253)
                        Color(0xFFFDFDFF), // RGB(252, 253, 255)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SizedBox(
                    height: 250,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF0575E6), // RGB(5, 117, 230)
                                Color(0xFF021B79), // RGB(2, 27, 121)
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds),
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF0575E6), // RGB(5, 117, 230)
                                Color(0xFF021B79), // RGB(2, 27, 121)
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds),
                            child: Text(
                              snippet,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LocationDetailsPage(
                                        locationName: title,
                                        destination: position,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 20),
                                  backgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ).copyWith(
                                  foregroundColor:
                                      MaterialStateProperty.all(Colors.white),
                                  shadowColor: MaterialStateProperty.all(
                                      Colors.transparent),
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF0575E6),
                                        Color(0xFF021B79),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(50)),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 15),
                                  child: const Text(
                                    'Start',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: visited
                                    ? () {
                                        _showNotesDialog(markerId);
                                      }
                                    : () {
                                        _showAlert(
                                            'Please mark the place as visited before adding notes.');
                                      },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 15),
                                  backgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ).copyWith(
                                  foregroundColor:
                                      MaterialStateProperty.all(Colors.white),
                                  shadowColor: MaterialStateProperty.all(
                                      Colors.transparent),
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF0575E6),
                                        Color(0xFF021B79),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(50)),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 20),
                                  child: const Text(
                                    'Add Notes',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: notesAdded
                                    ? null
                                    : () {
                                        setState(() {
                                          visited = !visited;
                                          _markerVisitStatus[markerId] =
                                              visited;
                                        });

                                        // Firestore update logic
                                        visitedRef
                                            .collection('Location_visits')
                                            .doc(todayDate)
                                            .set({
                                          'visited_status': visited,
                                          'visited_time':
                                              visited ? DateTime.now() : null,
                                          'information': null,
                                          'info_time': null,
                                          'visited_by': visited
                                              ? userName
                                              : null, // Add visited_by field
                                        }, SetOptions(merge: true)).then((_) {
                                          setState(() {
                                            _markerVisitStatus[markerId] =
                                                visited;
                                          });
                                          print(
                                              'Visited status updated successfully.');
                                        }).catchError((error) {
                                          setState(() {
                                            visited = !visited;
                                            _markerVisitStatus[markerId] =
                                                visited;
                                          });
                                          print(
                                              'Failed to update visited status: $error');
                                        });
                                      },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 20),
                                  backgroundColor: visited
                                      ? const Color.fromARGB(255, 73, 209,
                                          85) // Green when visited
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(35),
                                  ),
                                ),
                                child: Text(
                                  visited ? 'Visited' : 'Unvisited',
                                  style: TextStyle(
                                    color:
                                        visited ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
        );
      }).catchError((error) {
        print('Failed to load user information: $error');
      });
    }).catchError((error) {
      print('Failed to load visited status: $error');
    });
  }

  void _showNotesDialog(String markerId) {
    String information = '';
    TextEditingController _notesController = TextEditingController();
    String todayDate = DateTime.now().toIso8601String().split('T').first;

    DocumentReference notesRef = _firestore
        .collection('TASMAC_Locations')
        .doc(markerId)
        .collection('Location_visits')
        .doc(todayDate);

    // Fetch existing note and populate the text field
    notesRef.get().then((documentSnapshot) {
      if (documentSnapshot.exists && documentSnapshot.data() != null) {
        // Cast the data to Map<String, dynamic>
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;
        information = data['information'] ?? '';
        _notesController.text =
            information; // Populate existing note in the text field
      }
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add/Edit Notes'),
          content: TextFormField(
            controller: _notesController,
            onChanged: (value) => information = value,
            decoration: const InputDecoration(labelText: 'Information'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                notesRef.get().then((documentSnapshot) {
                  if (documentSnapshot.exists &&
                      documentSnapshot.data() != null) {
                    // Append new note to the existing note
                    Map<String, dynamic> data =
                        documentSnapshot.data() as Map<String, dynamic>;
                    String existingNote = data['information'] ?? '';
                    String updatedNote = existingNote.isNotEmpty
                        ? '$existingNote\n$information'
                        : information;

                    // Update Firestore document
                    notesRef.update({
                      'information': updatedNote,
                      'info_time': DateTime.now(),
                    }).then((_) {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const MapScreen(),
                        ),
                      );
                    }).catchError((error) {
                      print('Failed to update notes: $error');
                    });
                  } else {
                    // Create a new document if it doesn't exist
                    notesRef.set({
                      'information': information,
                      'info_time': DateTime.now(),
                    }).then((_) {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const MapScreen(),
                        ),
                      );
                    }).catchError((error) {
                      print('Failed to save notes: $error');
                    });
                  }
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Action Not Allowed'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _onSearchChanged() {
    String query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    _searchSubscription?.cancel();
    _searchSubscription = _firestore
        .collection('TASMAC_Locations')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _searchResults = snapshot.docs;
      });
    });
  }

  Widget _buildMapOrMessage() {
    if (_currentPosition == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchResults.isEmpty) {
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          zoom: 15,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        zoom: 15,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: _searchResults.map((doc) {
        GeoPoint coordinates = doc['coordinates'];
        String markerId = doc.id;
        bool visited = _markerVisitStatus[markerId] ?? false;

        return Marker(
          markerId: MarkerId(markerId),
          position: LatLng(coordinates.latitude, coordinates.longitude),
          infoWindow: InfoWindow(
            title: doc['title'],
            snippet: doc['marker_area'],
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            visited ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          onTap: () {
            _showMarkerDetails(
              title: doc['title'],
              snippet: doc['marker_area'],
              position: LatLng(coordinates.latitude, coordinates.longitude),
              markerId: markerId,
            );
          },
        );
      }).toSet(),
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
    );
  }

  void _moveCameraToNearestUnvisitedMarker() async {
    List<Marker> unvisitedMarkers = _markers
        .where((marker) => !_markerVisitStatus[marker.markerId.value]!)
        .toList();

    if (unvisitedMarkers.isEmpty) {
      _showAlert('No unvisited locations found.');
      return;
    }

    Marker nearestMarker = unvisitedMarkers.first;
    double minDistance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      nearestMarker.position.latitude,
      nearestMarker.position.longitude,
    );

    for (Marker marker in unvisitedMarkers) {
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        marker.position.latitude,
        marker.position.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestMarker = marker;
      }
    }

    _moveCameraToPosition(nearestMarker.position);
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About'),
          content: const Text('This is a Police Surveillance Helper app.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Material(
        elevation: 4.0,
        borderRadius:
            BorderRadius.circular(30.0), // Increased for more rounded corners
        shadowColor: Colors.black.withOpacity(0.3),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search,
                color: Color.fromARGB(255, 0, 106, 255)),
            hintText: 'Search for TASMAC...',
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(30.0), // Match the rounded corners
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
          ),
          onChanged: (value) {
            _onSearchChanged();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0575E6), Color(0xFF021B79)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: const Text(
              'Police Surveillance Helper',
              style: TextStyle(
                color: Colors.white, // Font color
                fontSize: 20, // Font size
              ),
            ),
            backgroundColor:
                Colors.transparent, // Make the AppBar background transparent
            elevation: 0, // Remove shadow
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon:
                      const Icon(Icons.menu, color: Colors.white), // Icon color
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white, // Set the icon color to white
                ),
                onPressed: () {
                  setState(() {
                    _loadMarkers();
                  });
                },
              )
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF02459E),
                    Color(0xFF010E5C)
                  ], // Darker gradient colors
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white, fontSize: 34,
                    letterSpacing: 2.0, // Add some spacing between the letters
                    shadows: [
                      Shadow(
                        blurRadius: 4.0,
                        color: Colors.black38,
                        offset: Offset(2.0, 2.0), // Slight shadow for depth
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings,
                  color: Color.fromARGB(255, 0, 119, 255)), // Settings icon
              title: const Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on,
                  color: Color.fromARGB(255, 0, 119, 255)), // Location icon
              title: const Text('Locations'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add,
                  color: Color.fromARGB(255, 0, 119, 255)), // Location icon
              title: const Text('Add User'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddUserPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_location,
                  color: Color.fromARGB(255, 0, 119, 255)), // Location icon
              title: const Text('Add Tasmac'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTASMACPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_location,
                  color: Color.fromARGB(255, 0, 119, 255)), // Location icon
              title: const Text('Download Data'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DownloadPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info,
                  color: Color.fromARGB(255, 0, 119, 255)), // About icon
              title: const Text('About'),
              onTap: () {
                _showAboutDialog();
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _buildMapOrMessage(),
          Positioned(
            bottom: 40,
            left: 80,
            right: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0575E6), // Blue gradient start
                    Color(0xFF021B79), // Blue gradient end
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.circular(40.0), // Optional: rounded corners
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, // Transparent background
                  shadowColor: Colors.transparent, // Remove shadow
                ),
                onPressed: _moveCameraToNearestUnvisitedMarker,
                child: const Text(
                  'Nearest Unvisited Location',
                  style: TextStyle(
                    fontSize: 14.5, // Font size
                    color: Colors.white, // White text color
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 40,
            right: 50,
            child: _buildSearchBar(),
          ),
        ],
      ),
    );
  }
}

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  _LocationsPageState createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0575E6), Color(0xFF021B79)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor:
                Colors.transparent, // Make AppBar background transparent
            elevation: 0, // Remove shadow
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  )
                : const Text(
                    'Locations',
                    style: TextStyle(
                      color: Colors.white, // White text color
                      fontSize: 22, // Font size
                      fontWeight: FontWeight.bold, // Font weight
                    ),
                  ),
            actions: [
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close : Icons.search,
                  color: Colors.white,
                ),
                iconSize: 30, // Increase the size of the icon
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('TASMAC_Locations')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return const Center(child: CircularProgressIndicator());
              default:
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final title = doc['title'].toLowerCase();
                  final markerArea = doc['marker_area'].toLowerCase();
                  final query = _searchQuery.toLowerCase();
                  return title.contains(query) || markerArea.contains(query);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No results found'));
                }

                return ListView.separated(
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.grey[300], // Color of the divider
                    height: 1, // Height of the divider
                    thickness: 1, // Thickness of the divider
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    return ListTile(
                      title: Text(
                        doc['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        doc['marker_area'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey, // Address color
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 16.0), // Padding around the ListTile
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationInfo(
                              locationId: doc.id,
                              locationTitle: doc['title'],
                              locationMarkerArea: doc['marker_area'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
            }
          },
        ),
      ),
    );
  }
}
