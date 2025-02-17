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
     - Select a security mode (start in test mode for development, but use rules for production).
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

(Provide a description of the project structure here.)

