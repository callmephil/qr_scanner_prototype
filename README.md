# QR Scanner App

A prototype Flutter application that scans multiple QR codes and sends data to a backend server using isolates and HTTP requests.

![](https://github.com/callmephil/qr_scanner_prototype/blob/master/demo/demo.webp)

## Getting Started

### Prerequisites

- Flutter 3.24.3 or higher
- Node.js and npm

### Installation

1. Install Flutter dependencies:

```sh
flutter pub get
```

2. Install Node.js server dependencies:

```sh
cd server
npm install
```

### Running the Application

** You need to run on a physical device, and generate a QR Code with http://YOUR_IP_ADDRESS:3000/1 **

1. Start the Node.js server:

at the root level run:

```sh
node server/server.js
```

The server will start running on http://localhost:3000

2. Run the Flutter app:

```sh
flutter run
```

Make sure to have an iOS Simulator running or a physical iOS device connected before running the Flutter app.

### Features

- Scans multiple QR codes continuously until the user cancels.
- Uses isolates to handle background tasks.
- Sends scanned QR code data to a backend server via HTTP POST requests.

### Development

This project uses:

- Flutter 3.24.3
- simple_barcode_scanner package for QR scanning
- Express.js for the backend server
