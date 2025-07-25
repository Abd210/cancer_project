# Acuranics - Nirvesh Enterprises 
A Platform for the study and detection of breast cancer

## Developers

- Front-end team: El-Ghoul Layla, Mahmoud Abdelrahman  
- Back-end team: Sakka Mohamad-Mario, Zafar Azzam

## Architecture

- There's one superadmin who has control over the entire database and platform.
- Hospitals or clinics get registered on the platform by the superadmin, each hospital has some admins who oversee the activities of doctors and their interactions with patients.
- Patients and Doctors have to be registered by admins or the superadmin in order to have access to the platform.
- Patients can schedule appointments, cancel or re-schedule appointments through the platform.
- Doctors can also schedule appointments with their patients, cancel or re-schedule them.
- Doctors can set their own schedules, and the newly created appointments are first checked against them to make sure they're working during that time and that it doesnt overlap with other appointments.
- Patients are assigned to one hospital and one doctor from that hospital.
- Doctors are assigned to one hospital only.
- Doctors and Patients can view their personal data but cannot change it, only admins/superadmins can.
- Specialized devices for studying tumors are worn by patients. These devices transmit raw data to a remote server where it will be processed, afterwards it can be retrieved by doctors or patients and displayed in auto-generated graphics and statistics.

## Updates Log
### 03/01/2025

- Implemented the routes, controllers, and services necessary for registering, deleting, updating, suspending or fetching data from the DB and created http request examples in Postman, that can be used by the superadmin  
![superadmin example http requests in postman](updates_pics/Superadmins_routes_Postman.png)

- We updated the navbar from a popout design to a persistent navbar. The structure was organized, and animations were added for a smoother user experience.

| Before                                                                                             | After                                                                                              |
|----------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|
| ![Popout Navbar 1](updates_pics/popout_navbar_1.png) ![Popout Navbar 2](updates_pics/popout_navbar2.png) | ![Persistent Navbar 1](updates_pics/persistent_navbar1.png) ![Persistent Navbar 2](updates_pics/persistent_navbar2.png) |


### 17/02/2025

- Started migrating database from MongoDB to Firestore (Firebase)

### 21/02/2025

- Updated all services to make use of the firebase_admin module in order to interact with the firestore DB
- Updated the models and adapted them to firestore
- Fixed bugs and improved some functions in services

### 27/02/2025
