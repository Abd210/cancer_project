## Team Presentation Split (3 Presenters)

Each presenter covers a balanced mix of frontend, backend, and integration topics. Time per person should be equal. Use the slide counts as guidance; adjust slightly as needed to fit timing.

### Presenter 1: Authentication, Roles, and Patient Flow
- Backend (6 slides)
  - JWT + Role middleware: `middlewares/jwtAuth.js` and `middlewares/roleAuth.js`
  - Auth routes: `Routes/authRoutes.js`; role dispatch in `Controllers/redirectAuthController.js`
  - Patient controller capabilities: personal data, diagnosis, update/delete
  - Patient service: retrieval, doctor/hospital filtering, updates with hospital/doctor sync
  - Firestore models overview: `Models/Patient.js`
  - Security and validation highlights
- Frontend (5 slides)
  - Login screen UX: `pages/authentication/log_reg.dart` and role-based navigation
  - Theme usage: `shared/theme/app_theme.dart`
  - Patient area overview: key patient pages/components
  - Providers for patient APIs: `providers/patient_provider.dart` (list, filters, history)
  - Logger/LoggingClient for diagnostics from `main.dart`
- Integration (4 slides)
  - Base URL and headers via `utils/static.dart` (`authentication` header)
  - Endpoint handshake: `/auth/login`, `/patient/personal-data`, `/patient/diagnosis`
  - Common headers: `patientid`, `doctorid`, `hospitalid`, `filter`
  - Demo flow: sign-in as patient -> view profile/diagnosis -> appointments history

### Presenter 2: Doctors, Appointments, and Scheduling
- Backend (6 slides)
  - Doctor controller/service: public/privileged fetch, assigned patients, updates
  - Firestore schedule model: `Models/Doctor.js` schedule field
  - Appointment controller/service: creation, overlap checks, schedule validation, cancel/update
  - Hospital-linked appointment fetches (upcoming/past/filtered/direct)
  - Data integrity: hospital arrays sync for appointments
  - Key endpoints walkthrough: `/appointment/new`, `/appointment/history`, `/doctor/patients`
- Frontend (5 slides)
  - Doctor area pages: patients, appointments, reports, notifications
  - Appointment provider usage (if applicable) and patient provider `getPatientsForDoctor`
  - UI patterns for tables, tabs, and filters
  - Error/reporting via Logger
  - Theming consistency for forms and data tables
- Integration (4 slides)
  - Creating appointments: required body and role constraints
  - Headers for appointment queries: `filterbyrole`, `filterbyid`, `hospital_id`, `time_direction`
  - Overlap prevention illustrated
  - Demo: doctor views assigned patients and upcoming appointments

### Presenter 3: Hospitals, Devices, Tests, Tickets, and Admin Ops
- Backend (6 slides)
  - Hospital controller/service: register, uniqueness checks, bidirectional admin relation
  - Cascading delete and arrays management (doctors/patients/appointments)
  - Devices routing and constraints; Tests controller/service (status/review)
  - Admin and SuperAdmin controllers/routes
  - Firestore models: `Models/Hospital.js`, `Models/Test.js`
  - Security: role-based access on critical endpoints
- Frontend (5 slides)
  - SuperAdmin and Admin dashboards/pages overview
  - Hospital management flows on UI (create/update/delete; view tabs)
  - Tests/devices/tickets pages overview
  - Providers mirroring backend (admin, hospital, device, test, ticket)
  - Theme-driven UX consistency
- Integration (4 slides)
  - Hospital register/update/delete flows: headers and bodies
  - Test creation/update: required fields and statuses
  - Device data upload and access roles
  - Demo: SuperAdmin registers a hospital, assigns admin, views devices/tests

### Shared Slide(s)
- System architecture overview (1 slide): request flow FE -> BE -> Firestore
- Notable conventions: `authentication` header, filter headers, Firestore Timestamps
- Run instructions (1 slide): backend env + frontend run

Notes:
- Ensure each presenter has roughly the same number of slides (≈15 each incl. integration demos).
- Each person demonstrates a small end-to-end path (FE UI -> API -> data).


