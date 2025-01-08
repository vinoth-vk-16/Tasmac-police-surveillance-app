
# Police TASMAC Locator App

The **Police TASMAC Locator App** is designed for law enforcement officers to efficiently monitor TASMAC (Tamil Nadu State Marketing Corporation) locations. This app allows officers to track visits, mark locations as visited, and log additional notes for surveillance purposes. 

---
![photo-collage png](https://github.com/user-attachments/assets/d2f625ca-f477-4291-a59f-0f6dba488cea)


## Features

- **Google Maps Integration**:
  - Displays all TASMAC locations with dynamic markers.
  - Red pins for unvisited locations and green pins for visited ones.
  
- **Visit Logging**:
  - Mark locations as visited and record the timestamp.
  - Add detailed notes for each visit after marking a location as visited.
  - Prevent unvisited locations from having notes or removing the "visited" status once notes are added.

- **Dynamic Marker Updates**:
  - Refresh button to reload markers without restarting the app.
  - Real-time marker updates for newly added TASMAC locations.

- **Navigation Features**:
  - Turn-by-turn navigation from the current location to the selected TASMAC location.
  - Dynamic polylines to display routes on the map.
  - Arrival alerts with a streamlined interface.

- **Admin Features** (Admin App):
  - Add new TASMAC locations directly from the app.
  - Add and manage user accounts for officers.
![photo-collage png (1)](https://github.com/user-attachments/assets/8d7adfaa-af8d-44fc-acfc-9831a6b3e93a)

---

## Tech Stack

### Frontend:
- **Flutter**:
  - Google Maps integration with `google_maps_flutter`.
  - Beautiful UI with custom buttons and responsive design.

### Backend:
- **Cloud Firestore**:
  - TASMAC location data stored in `TASMAC_Locations` collection.
  - Subcollections for each location to log visit details (`Location_visits`).

---
