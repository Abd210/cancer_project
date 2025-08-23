## Cancer Project – System Architecture

### Overview
The system consists of a Node.js/Express backend using Firebase Admin SDK (Firestore) as the data store, and a Flutter frontend (web/mobile/desktop) using Provider for state and `http` for API calls. Authentication is JWT-based with role-aware authorization. Domain entities include Hospitals, Doctors, Patients, Devices, Appointments, Tests, Tickets, and Admin/SuperAdmin users.

### Backend
- Entry: `backend/index.js`
  - Middleware: `helmet`, `cors`, `body-parser`
  - Routes mounted under `/api` and `/api/auth`
  - Firebase initialized in `backend/firebase.js`

- Middleware
  - `middlewares/jwtAuth.authenticate`: verifies JWT in `authentication` header; attaches decoded user as `req.headers.user`.
  - `middlewares/roleAuth.identifyUserRole`: infers role from email/mobile across services.
  - `middlewares/roleAuth.authorize(roles)`: enforces role-based access and verifies existence.

- Routes (selected)
  - Auth: `Routes/authRoutes.js` – register (admin/superadmin only), login (role identified), forgot/reset password.
  - Patients: `Routes/patientRoutes.js` – personal data, diagnosis, update, delete.
  - Doctors: `Routes/doctorRoutes.js` – public data, doctor data, assigned patients, update, delete.
  - Hospitals: `Routes/hospitalRoutes.js` – register, data, update, delete.
  - Appointments: `Routes/appointmentRoutes.js` – history, upcoming (entity/hospital/all), create, cancel, update, delete.
  - Devices: `Routes/deviceRoutes.js` – CRUD, upload data.
  - Tests: `Routes/testRoutes.js` – details, create, update, delete.
  - Tickets: `Routes/ticketRoutes.js` – create ticket, get review.

- Controllers (selected responsibilities)
  - AppointmentController: list/create/update/cancel; hospital filters; uses `SuspendController.filterData` and `AppointmentService`.
  - HospitalController: register/get/update/delete; validates uniqueness through service.
  - PatientController: self/privileged fetch; filters by doctor/hospital; update/delete.
  - DoctorController: public/privileged fetch; assigned patients; update/delete.
  - TestController: fetch by role/filters; create/update/delete.
  - RedirectAuthController: routes auth actions to role-specific controllers/services.

- Services (selected)
  - AppointmentService: Firestore queries for upcoming/past/by-date/hospital; creation validates schedule, overlaps, hospital relations; updates with guardrails; cancel/delete with hospital linkage updates.
  - HospitalService: register with uniqueness checks across collections; get/update with bidirectional admin linkage; delete cascades across linked data; helpers to manage hospital arrays (doctors/patients/appointments).
  - TestService: fetch/create/update/delete with role-aware filters and validations.

- Models (Firestore-backed)
  - `Models/Hospital.js`: name, address, mobileNumbers, emails, admin, arrays (appointments, patients, doctors).
  - `Models/Doctor.js`: id, persId, credentials, hospital, patients, schedule, role, suspended.
  - `Models/Patient.js`: persId, credentials, hospital, doctors[], status, diagnosis, medicalHistory, role, suspended.
  - `Models/Appointment.js`: patient, doctor, hospital, start/end (Timestamp), purpose, status, suspended.
  - `Models/Test.js`: patient, doctor, device, resultDate, purpose, status, review, results[], suspended.

### Frontend
- Entry: `lib/main.dart`
  - `MaterialApp` with `AppTheme.lightTheme`; home `LogIn`.
  - Global `LoggingClient` and `Logger` utilities (optional UI log viewer).
  - Providers: `DataProvider` (plus role-specific providers under `lib/providers`).

- Theming: `shared/theme/app_theme.dart`
  - Primary color palette; styled buttons, inputs, tables, tabs, cards.

- Navigation and Pages
  - Authentication: `pages/authentication/log_reg.dart` – login, role-based redirection.
  - SuperAdmin: dashboards for hospitals, devices, appointments, tickets, notifications.
  - Admin: hospital-centric dashboards and management pages.
  - Doctor: patients, appointments, notifications, reports.
  - Patient: tabs for home/search/profile/appointments/diagnosis.

- Providers (selected)
  - `auth_provider.dart`: POST `/auth/login` returning `LoginResponse`.
  - `patient_provider.dart`: patient listing/filtering; doctor patients; create/update/delete; appointment history; uses `ClassUtil` routes and custom `httpClient`.
  - Other providers mirror backend endpoints for admins, doctors, hospitals, devices, tests, appointments.

- Utilities
  - `utils/static.dart` `ClassUtil`: base URL per platform; central API route constants; header builder including `authentication`.
  - `services/static_data.dart`: demo/mock data for UI demos.

### Integration
- Base URL: computed per platform, default `http://localhost:3000/api`.
- Auth: login -> JWT in `authentication` header; backend middleware reads and sets `req.headers.user`.
- Role-based routing: frontend redirects by `role` to role-specific home; backend restricts via `authorize`.
- Common headers used by endpoints: entity ids (e.g., `patientid`, `doctorid`, `hospitalid`), filters (`filter`, `suspendfilter`, `time_direction`).

### Notable Conventions and Considerations
- JWT header is named `authentication` (not `Authorization`).
- Firestore Timestamp used for `start`/`end` in appointments; services convert to/from Date.
- Hospital maintains arrays of related entity IDs; services keep arrays in sync.
- Suspend filtering handled via `SuspendController.filterData` across controllers.

### Run/Build (high level)
- Backend: set `JWT_SECRET`, Firebase service account `firebaseConfig.json`; `node backend/index.js`.
- Frontend: `flutter pub get`; run on desired platform; ensure asset paths and base URL.


