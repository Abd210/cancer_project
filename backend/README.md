# Acuranics API

This is the Express.js server used for the Acuranics Cloud Solution

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Setup and Run](#setup-and-run)
4. [Running the Server](#running-the-server)
5. [Project Structure](#project-structure)

---

## Prerequisites

Before you can run this project, you need to have the following installed on your machine:

- **Node.js** (which comes with npm, the Node package manager)

### How to Install Node.js and npm

#### For Windows:

1. Go to the [Node.js download page for Windows](https://nodejs.org/en/download/).
2. Download the Windows installer (LTS version is recommended).
3. Run the installer and follow the setup instructions. Make sure to check the box to install npm along with Node.js.
4. After installation, open the **Command Prompt** (press `Win + R`, type `cmd`, and hit enter).
5. Check if Node.js and npm are successfully installed by running the following commands:

    ```bash
    node -v
    npm -v
    ```

   You should see the versions of Node.js and npm printed on the console.

#### For macOS:

1. The easiest way to install Node.js and npm on macOS is by using [Homebrew](https://brew.sh/). If you don't have Homebrew installed, you can install it by running the following command in the Terminal:

    ```bash
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```

2. After installing Homebrew, you can install Node.js and npm with the following command:

    ```bash
    brew install node
    ```

3. After installation, check if Node.js and npm are successfully installed by running:

    ```bash
    node -v
    npm -v
    ```

    You should see the versions of Node.js and npm printed on the console.

---

## Installation

1. **Clone the repository** to your local machine:

    ```bash
    git clone <repository-url>
    cd <project-directory>
    ```

2. **Install dependencies** using npm:

    ```bash
    npm install
    ```

   This will install all the required packages defined in the `package.json` file.

---

## Setup and Run

1. **Create a `.env` file** in the root of the project if it doesn't already exist. The `.env` file should contain environment variables such as database connections, secret keys, etc.

2. Example `.env` file:

    ```env
    PORT=3000
    JWT_SECRET=your_jwt_secret_key
    ```

3. **Set up Firebase Firestore**:
   - **Create a Firebase Project**:
     - Go to [Firebase Console](https://console.firebase.google.com/).
     - Click on "Add Project" and follow the setup instructions.
   - **Enable Firestore**:
     - In the Firebase Console, go to "Firestore Database."
     - Click "Create Database" and choose a location.
     - Select a security mode (you can start in production mode too).
   - **Download Firebase Config**:
     - Go to "Project Settings" > "Service Accounts."
     - Click "Generate new private key" and download the JSON file.
     - Save this file as `firebaseConfig.json` in the root directory.
   - **Initialize Firestore in your app**:
     - Create a `firebase.js` file in the `backend` folder and add the following:

       ```javascript
       const admin = require("firebase-admin");
       const serviceAccount = require("./firebaseConfig.json");

       admin.initializeApp({
           credential: admin.credential.cert(serviceAccount),
       });

       const db = admin.firestore();
       module.exports = db;
       ```

---

## Running the Server

To start the Express server, run the following command in your terminal:

```bash
npm start
```

---

## Project Structure

The Acuranics API follows a well-organized, modular architecture with clear separation of concerns. Here's a detailed breakdown of the project structure:

### 📁 Root Files
- **`index.js`** - Main server entry point that sets up Express app, middleware, and routes
- **`firebase.js`** - Firebase configuration and initialization
- **`firebaseConfig.json`** - Firebase service account credentials (not in version control)
- **`package.json`** - Project dependencies and scripts

### 📁 Controllers/
Controllers handle HTTP requests and responses, organized by functionality:

#### **Roles Auth Controllers/**
- **`adminAuthController.js`** - Authentication logic for admin users
- **`doctorAuthController.js`** - Authentication logic for doctor users  
- **`patientAuthController.js`** - Authentication logic for patient users
- **`superAdminAuthController.js`** - Authentication logic for super admin users
- **`deviceAuthController.js`** - Authentication logic for device users

#### **Objects Controllers/**
- **`appointmentController.js`** - Appointment management operations
- **`deviceController.js`** - Device management operations
- **`hospitalController.js`** - Hospital management operations
- **`testController.js`** - Medical test management operations
- **`ticketController.js`** - Support ticket management operations

#### **General Roles Controllers/**
- **`adminController.js`** - General admin operations and management
- **`doctorController.js`** - General doctor operations and management
- **`patientController.js`** - General patient operations and management
- **`superadminController.js`** - General super admin operations and management

#### **Other Controllers**
- **`redirectAuthController.js`** - Central authentication controller for user registration and login
- **`suspendController.js`** - User suspension management

### 📁 Models/
Data models representing the application's entities using Firebase Firestore:

- **`Admin.js`** - Admin user data model
- **`Appointment.js`** - Appointment data model
- **`Device.js`** - Device data model
- **`Doctor.js`** - Doctor user data model
- **`Hospital.js`** - Hospital data model
- **`Patient.js`** - Patient user data model
- **`SuperAdmin.js`** - Super admin user data model
- **`Test.js`** - Medical test data model
- **`Ticket.js`** - Support ticket data model

### 📁 Routes/
API route definitions organized by entity:

- **`adminRoutes.js`** - Admin-specific API endpoints
- **`appointmentRoutes.js`** - Appointment management endpoints
- **`authRoutes.js`** - Authentication endpoints (login, register, password reset)
- **`deviceRoutes.js`** - Device management endpoints
- **`doctorRoutes.js`** - Doctor-specific API endpoints
- **`hospitalRoutes.js`** - Hospital management endpoints
- **`patientRoutes.js`** - Patient-specific API endpoints
- **`testRoutes.js`** - Medical test endpoints
- **`ticketRoutes.js`** - Support ticket endpoints

### 📁 Services/
Business logic layer containing the core application functionality:

- **`adminService.js`** - Admin business logic and operations
- **`appointmentService.js`** - Appointment business logic and operations
- **`authService.js`** - Authentication business logic
- **`deviceService.js`** - Device business logic and operations
- **`doctorService.js`** - Doctor business logic and operations
- **`hospitalService.js`** - Hospital business logic and operations
- **`patientService.js`** - Patient business logic and operations
- **`superadminService.js`** - Super admin business logic and operations
- **`suspendService.js`** - User suspension business logic
- **`testService.js`** - Medical test business logic and operations
- **`ticketService.js`** - Support ticket business logic and operations

### 📁 middlewares/
Custom middleware functions for request processing:

- **`jwtAuth.js`** - JWT token authentication middleware
- **`roleAuth.js`** - Role-based authorization middleware

### 📁 utils/
Utility functions and helper modules:

- **`otpGenerator.js`** - One-time password generation utilities
- **`sendEmail.js`** - Email sending utilities
- **`sendSMS.js`** - SMS sending utilities

### 🔄 Architecture Flow

1. **Request Flow**: Client → Routes → Middleware → Controllers → Services → Models → Firebase
2. **Response Flow**: Firebase → Models → Services → Controllers → Routes → Client

### 🛡️ Security Features

- **JWT Authentication**: Token-based authentication for all protected routes
- **Role-Based Authorization**: Different access levels for different user types
- **Input Validation**: Comprehensive validation in models and controllers
- **Password Hashing**: Bcrypt encryption for user passwords
- **CORS Protection**: Cross-origin resource sharing configuration
- **Helmet Security**: HTTP headers security middleware

### 👥 User Roles

The system supports multiple user roles with different permissions:
- **SuperAdmin**: Full system access and management
- **Admin**: Hospital-level administration
- **Doctor**: Medical professional access
- **Patient**: Patient-specific features
- **Device**: IoT device access

### 🔧 Key Technologies

- **Express.js**: Web framework
- **Firebase Firestore**: NoSQL database
- **JWT**: Authentication tokens
- **Bcrypt**: Password hashing
- **Nodemailer**: Email functionality
- **Twilio**: SMS functionality
- **Speakeasy**: OTP generation

