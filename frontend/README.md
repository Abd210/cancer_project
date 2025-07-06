# Acuranics Flutter Frontend

A comprehensive Flutter application for the Acuranics Cloud Solution, providing a multi-role healthcare management system with role-based access control.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Setup and Run](#setup-and-run)
4. [Running the App](#running-the-app)
5. [Project Structure](#project-structure)

---

## Prerequisites

Before you can run this project, you need to have the following installed on your machine:

- **Flutter SDK** (latest stable version)
- **Dart SDK** (comes with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Android SDK** (for Android development)
- **Xcode** (for iOS development, macOS only)

### How to Install Flutter

#### **Step 1: Download Flutter SDK**

1. **Visit the Flutter download page**:
   - Go to [Flutter download page](https://docs.flutter.dev/get-started/install)
   - Choose your operating system (Windows, macOS, or Linux)

2. **Download and Extract**:
   - Download the Flutter SDK zip file
   - Extract it to a desired location (e.g., `C:\flutter` on Windows or `~/flutter` on macOS/Linux)
   - **Important**: Avoid paths with spaces or special characters

#### **Step 2: Add Flutter to PATH Variable**

##### **For Windows:**

1. **Open System Properties**:
   - Right-click on "This PC" or "My Computer"
   - Select "Properties"
   - Click "Advanced system settings"
   - Click "Environment Variables"

2. **Edit PATH Variable**:
   - In the "System Variables" section, find and select "Path"
   - Click "Edit"
   - Click "New"
   - Add the path to your Flutter `bin` directory (e.g., `C:\flutter\bin`)
   - Click "OK" on all dialogs

3. **Alternative Method (Command Line)**:
   ```cmd
   setx PATH "%PATH%;C:\flutter\bin"
   ```

4. **Verify PATH Setup**:
   - Open a new Command Prompt or PowerShell
   - Run: `echo %PATH%`
   - You should see your Flutter path in the output

##### **For macOS:**

1. **Using Terminal**:
   ```bash
   # Add to your shell profile (choose one based on your shell)
   # For bash (edit ~/.bash_profile):
   echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bash_profile
   source ~/.bash_profile
   
   # For zsh (edit ~/.zshrc):
   echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
   source ~/.zshrc
   ```

2. **Verify PATH Setup**:
   ```bash
   echo $PATH
   which flutter
   ```

##### **For Linux:**

1. **Using Terminal**:
   ```bash
   # Add to your shell profile
   echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
   source ~/.bashrc
   ```

2. **Verify PATH Setup**:
   ```bash
   echo $PATH
   which flutter
   ```

#### **Step 3: Install Platform Dependencies**

##### **For Android Development:**

1. **Install Android Studio**:
   - Download from [Android Studio](https://developer.android.com/studio)
   - Install with default settings
   - Launch Android Studio and complete the setup wizard

2. **Install Android SDK**:
   - Open Android Studio
   - Go to "Tools" → "SDK Manager"
   - Install the following:
     - Android SDK Platform-Tools
     - Android SDK Build-Tools
     - At least one Android SDK Platform (recommend API 33 or higher)
     - Android SDK Command-line Tools

3. **Set ANDROID_HOME Environment Variable**:

   **Windows:**
   ```cmd
   setx ANDROID_HOME "C:\Users\%USERNAME%\AppData\Local\Android\Sdk"
   setx PATH "%PATH%;%ANDROID_HOME%\platform-tools"
   ```

   **macOS/Linux:**
   ```bash
   echo 'export ANDROID_HOME="$HOME/Library/Android/sdk"' >> ~/.bash_profile
   echo 'export PATH="$PATH:$ANDROID_HOME/platform-tools"' >> ~/.bash_profile
   source ~/.bash_profile
   ```

4. **Accept Android Licenses**:
   ```bash
   flutter doctor --android-licenses
   ```

##### **For Windows Development:**

1. **Enable Windows Desktop Support**:
   ```cmd
   flutter config --enable-windows-desktop
   ```

2. **Install Visual Studio Build Tools**:
   - Download [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022)
   - Run the installer
   - Select "Desktop development with C++" workload
   - Install the following components:
     - MSVC v143 - VS 2022 C++ x64/x86 build tools
     - Windows 10/11 SDK
     - CMake tools for Visual Studio

3. **Install Git for Windows**:
   - Download from [Git for Windows](https://git-scm.com/download/win)
   - Install with default settings
   - Ensure "Git from the command line and also from 3rd-party software" is selected

4. **Install Windows Terminal (Optional but Recommended)**:
   - Download from Microsoft Store or [GitHub](https://github.com/microsoft/terminal)
   - Provides better terminal experience for development

##### **For iOS Development (macOS only):**

1. **Install Xcode**:
   - Download from the Mac App Store
   - Install Command Line Tools:
     ```bash
     sudo xcode-select --install
     ```

2. **Accept Xcode Licenses**:
   ```bash
   sudo xcodebuild -license accept
   ```

3. **Install iOS Simulator**:
   - Open Xcode
   - Go to "Xcode" → "Preferences" → "Components"
   - Download and install iOS Simulator

##### **For Web Development:**

1. **Install Chrome** (if not already installed):
   - Download from [Google Chrome](https://www.google.com/chrome/)

2. **Enable Web Support**:
   ```bash
   flutter config --enable-web
   ```

#### **Step 4: Verify Installation**

1. **Run Flutter Doctor**:
   ```bash
   flutter doctor
   ```

2. **Address Issues**:
   - Follow the recommendations from `flutter doctor`
   - Install any missing dependencies
   - Accept licenses where required

3. **Windows-Specific Verification**:
   ```cmd
   # Check if Visual Studio Build Tools are installed
   where cl.exe
   
   # Check if Windows SDK is available
   where sdkmanager.bat
   
   # Check if Git is properly installed
   git --version
   
   # Verify Flutter Windows support
   flutter config --list
   ```

4. **Test Installation**:
   ```bash
   # Create a test project
   flutter create test_app
   cd test_app
   
   # Test on different platforms
   flutter run -d windows    # Windows desktop
   flutter run -d chrome     # Web
   flutter run -d android    # Android (if configured)
   ```

#### **Step 5: Install IDE and Extensions**

##### **VS Code (Recommended):**

1. **Install VS Code**:
   - Download from [Visual Studio Code](https://code.visualstudio.com/)
   - Install with default settings
   - Launch VS Code

2. **Install Essential Extensions**:
   - Open VS Code
   - Go to Extensions (Ctrl+Shift+X)
   - Install the following extensions:
     - **Flutter** (by Dart Code) - Official Flutter extension
     - **Dart** (by Dart Code) - Dart language support
     - **Flutter Widget Snippets** - Code snippets for Flutter widgets
     - **Awesome Flutter Snippets** - Additional Flutter snippets
     - **Pubspec Assist** - Dependency management
     - **Flutter Tree** - Widget tree visualization
     - **Error Lens** - Inline error display
     - **Bracket Pair Colorizer** - Code bracket highlighting
     - **Auto Rename Tag** - Automatic tag renaming
     - **GitLens** - Enhanced Git integration

3. **Configure VS Code for Windows Development**:
   - Open Command Palette (Ctrl+Shift+P)
   - Type "Flutter: Select Device"
   - Choose your target device (Windows, Chrome, Android, etc.)
   - Set default terminal to Windows Terminal (if installed)

4. **Windows-Specific VS Code Settings**:
   - Go to File → Preferences → Settings (Ctrl+,)
   - Configure the following settings:
     ```json
     {
       "terminal.integrated.defaultProfile.windows": "PowerShell",
       "terminal.integrated.shellArgs.windows": [],
       "dart.flutterSdkPath": "C:\\flutter",
       "dart.sdkPath": "C:\\flutter\\bin\\cache\\dart-sdk",
       "editor.formatOnSave": true,
       "editor.codeActionsOnSave": {
         "source.fixAll": true,
         "source.organizeImports": true
       },
       "files.autoSave": "afterDelay",
       "files.autoSaveDelay": 1000
     }
     ```

5. **VS Code Workspace Setup**:
   - Open the project folder in VS Code
   - Create a `.vscode/settings.json` file for project-specific settings:
     ```json
     {
       "dart.flutterSdkPath": "C:\\flutter",
       "dart.sdkPath": "C:\\flutter\\bin\\cache\\dart-sdk",
       "files.exclude": {
         "**/.git": true,
         "**/.svn": true,
         "**/.hg": true,
         "**/CVS": true,
         "**/.DS_Store": true,
         "**/Thumbs.db": true,
         "**/build": true,
         "**/.dart_tool": true
       }
     }
     ```

6. **Useful VS Code Commands for Flutter Development**:
   - `Ctrl+Shift+P` → "Flutter: Hot Reload" - Hot reload the app
   - `Ctrl+Shift+P` → "Flutter: Hot Restart" - Hot restart the app
   - `Ctrl+Shift+P` → "Flutter: Select Device" - Choose target device
   - `Ctrl+Shift+P` → "Flutter: Get Packages" - Run `flutter pub get`
   - `Ctrl+Shift+P` → "Flutter: Clean" - Clean the project
   - `Ctrl+Shift+P` → "Flutter: Run Flutter Doctor" - Check Flutter installation
   - `F5` - Start debugging
   - `Ctrl+F5` - Start without debugging

##### **Android Studio:**

1. **Install Flutter Plugin**:
   - Open Android Studio
   - Go to "File" → "Settings" → "Plugins"
   - Search for "Flutter"
   - Install the Flutter plugin
   - Restart Android Studio



#### **Step 6: Install Project Dependencies**

1. **Navigate to Project**:
   ```bash
   cd frontend
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate Code** (if using code generation):
   ```bash
   flutter packages pub run build_runner build
   ```

#### **Troubleshooting Common Issues**

##### **PATH Issues:**
- **Flutter not found**: Ensure the PATH is correctly set and you've restarted your terminal
- **Permission denied**: Run terminal as administrator (Windows) or use `sudo` (macOS/Linux)

##### **Windows-Specific Issues:**
- **Visual Studio Build Tools not found**: Reinstall Visual Studio Build Tools with C++ workload
- **Windows SDK missing**: Install Windows 10/11 SDK from Visual Studio Installer
- **Git not found**: Ensure Git is installed and added to PATH
- **Windows Terminal issues**: Use Command Prompt or PowerShell as alternative
- **Antivirus blocking**: Add Flutter and project directories to antivirus exclusions
- **Long path issues**: Enable long path support in Windows registry or use shorter paths
- **VS Code Flutter extension not working**: Restart VS Code and verify Flutter SDK path
- **VS Code terminal issues**: Check terminal profile settings and shell configuration

##### **Android Issues:**
- **SDK not found**: Verify ANDROID_HOME is set correctly
- **Licenses not accepted**: Run `flutter doctor --android-licenses`
- **Emulator not starting**: Check virtualization is enabled in BIOS
- **ADB not found**: Ensure platform-tools are in PATH

##### **iOS Issues (macOS):**
- **Xcode not found**: Install Xcode from Mac App Store
- **Simulator issues**: Reset simulator or reinstall Xcode

##### **Network Issues:**
- **Pub get fails**: Check internet connection and firewall settings
- **Slow downloads**: Use a VPN or change network if needed
- **Corporate firewall**: Configure proxy settings if needed

##### **Build Issues:**
- **C++ compilation errors**: Ensure Visual Studio Build Tools are properly installed
- **CMake errors**: Install CMake tools for Visual Studio
- **Windows SDK errors**: Verify Windows SDK installation

---

## Installation

1. **Clone the repository** to your local machine:
   ```bash
   git clone <repository-url>
   cd <project-directory>/frontend
   ```

2. **Install dependencies** using Flutter:
   ```bash
   flutter pub get
   ```

3. **Generate code** (if using code generation):
   ```bash
   flutter packages pub run build_runner build
   ```

---

## Setup and Run

1. **Connect a device or start an emulator**:
   - For Android: Start an Android emulator or connect a physical device
   - For iOS: Start an iOS simulator or connect a physical device (macOS only)

2. **Run the application**:
   ```bash
   flutter run
   ```

3. **For web development**:
   ```bash
   flutter run -d chrome
   ```

---

## Running the App

To start the Flutter application, run the following command in your terminal:

```bash
flutter run
```

For specific platforms:
- **Android**: `flutter run -d android`
- **iOS**: `flutter run -d ios`
- **Web**: `flutter run -d chrome`
- **Windows**: `flutter run -d windows`
- **macOS**: `flutter run -d macos`
- **Linux**: `flutter run -d linux`

---

## Project Structure

The Acuranics Flutter app follows a well-organized, modular architecture with clear separation of concerns. Here's a detailed breakdown of the project structure:

### 📁 Root Files
- **`main.dart`** - Application entry point with logging system and HTTP client setup
- **`pubspec.yaml`** - Flutter project configuration and dependencies
- **`analysis_options.yaml`** - Dart analyzer configuration
- **`.gitignore`** - Git ignore patterns for Flutter projects

### 📁 lib/
Main application code organized into logical modules:

#### **📁 pages/**
Role-based page organization with feature-specific subdirectories:

##### **admin/**
- **`admin_page.dart`** - Main admin dashboard
- **`appointments/`** - Appointment management pages
- **`devices/`** - Device management pages
- **`notifications/`** - Notification and ticket management
- **`tickets/`** - Support ticket management
- **`view_doctors/`** - Doctor management and viewing
- **`view_hospitals/`** - Hospital management and viewing
- **`view_patients/`** - Patient management and viewing

##### **doctor/**
- **`doctor_page.dart`** - Main doctor dashboard
- **`appointments/`** - Doctor's appointment management
- **`notifications/`** - Doctor's notifications
- **`patients/`** - Patient management and details
- **`reports/`** - Medical reports and analytics

##### **hospital/**
- **`hospital_page.dart`** - Main hospital dashboard
- **`appointments/`** - Hospital appointment management
- **`devices/`** - Hospital device management
- **`doctors/`** - Hospital doctor management
- **`patients/`** - Hospital patient management

##### **patients/**
- **`patient_page.dart`** - Main patient dashboard
- **`patient_appointments_page.dart`** - Patient's appointment view
- **`patient_diagnosis_page.dart`** - Patient's diagnosis information
- **`patient_profile_page.dart`** - Patient profile management

##### **superadmin/**
- **`superAdmin_page.dart`** - Main super admin dashboard
- **`appointments/`** - System-wide appointment management
- **`devices/`** - System-wide device management
- **`notifications/`** - System-wide notification management
- **`tickets/`** - System-wide ticket management
- **`view_admins/`** - Admin user management
- **`view_doctors/`** - System-wide doctor management
- **`view_hospitals/`** - Hospital management with detailed tabs
- **`view_patients/`** - System-wide patient management

##### **authentication/**
- **`log_reg.dart`** - Login and registration page

##### **shared/**
- **`hospital_details_page.dart`** - Shared hospital details component

#### **📁 models/**
Data models for the application entities:

- **`admin_data.dart`** - Admin user data model
- **`appointment_data.dart`** - Appointment data model
- **`device_data.dart`** - Device data model
- **`doctor_data.dart`** - Doctor user data model
- **`hospital_data.dart`** - Hospital data model
- **`patient_data.dart`** - Patient user data model
- **`test_data.dart`** - Medical test data model
- **`ticket.dart`** - Support ticket data model
- **`login_response.dart`** - Authentication response model
- **`notification.dart`** - Notification data model

#### **📁 providers/**
State management using Provider pattern:

- **`data_provider.dart`** - Central data management provider
- **`auth_provider.dart`** - Authentication state management
- **`admin_provider.dart`** - Admin-specific state management
- **`appointment_provider.dart`** - Appointment state management
- **`doctor_provider.dart`** - Doctor-specific state management
- **`hospital_provider.dart`** - Hospital state management
- **`patient_provider.dart`** - Patient-specific state management
- **`test_provider.dart`** - Medical test state management
- **`device_provider.dart`** - Device state management

#### **📁 shared/**
Reusable components and utilities:

##### **components/**
- **`components.dart`** - Component exports
- **`confirmation_dialog.dart`** - Reusable confirmation dialogs
- **`custom_drawer.dart`** - Custom navigation drawer
- **`loading_indicator.dart`** - Loading state indicators
- **`responsive_data_table.dart`** - Responsive data table component
- **`search_and_add_row.dart`** - Search and add functionality
- **`search_and_pending_row.dart`** - Search with pending state

##### **widgets/**
- **`background.dart`** - Background widget components
- **`logo.dart`** - Logo display widget
- **`logo_bar.dart`** - Logo bar component
- **`theme.dart`** - Theme-related widgets

##### **theme/**
- **`app_theme.dart`** - Application theme configuration

#### **📁 services/**
Business logic and external service integrations:

- **`static_data.dart`** - Static data and mock services

#### **📁 utils/**
Utility functions and constants:

- **`constants.dart`** - Application constants
- **`helpers.dart`** - Helper functions
- **`static.dart`** - Static utility functions

### 📁 assets/
Application assets and resources:

- **`images/`** - Image assets including logos and backgrounds

### 📁 Platform-specific Directories
- **`android/`** - Android-specific configuration
- **`ios/`** - iOS-specific configuration
- **`web/`** - Web-specific configuration
- **`windows/`** - Windows-specific configuration
- **`macos/`** - macOS-specific configuration
- **`linux/`** - Linux-specific configuration

### 🔄 Architecture Flow

1. **State Management**: Provider pattern for reactive UI updates
2. **Data Flow**: Models → Providers → Pages → UI
3. **Navigation**: Role-based routing with shared components
4. **API Integration**: HTTP client with logging for backend communication

### 🛡️ Security Features

- **Role-Based Access Control**: Different UI and functionality for each user role
- **Authentication State Management**: Secure token handling
- **Input Validation**: Form validation and data sanitization
- **Secure HTTP Communication**: HTTPS API calls with error handling

### 👥 User Roles

The application supports multiple user roles with different interfaces:
- **SuperAdmin**: Full system access and management
- **Admin**: Hospital-level administration
- **Doctor**: Medical professional interface
- **Patient**: Patient-specific features
- **Hospital**: Hospital management interface

### 🔧 Key Technologies

- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language
- **Provider**: State management
- **HTTP**: API communication
- **Isar**: Local database (if used)
- **Table Calendar**: Calendar functionality
- **Data Table 2**: Advanced table components
- **Flutter SVG**: SVG image support
- **Intl**: Internationalization
- **Flutter Toast**: Toast notifications

### 📱 Platform Support

- **Android**: Native Android app
- **iOS**: Native iOS app
- **Web**: Progressive Web App
- **Windows**: Desktop Windows app
- **macOS**: Desktop macOS app
- **Linux**: Desktop Linux app
