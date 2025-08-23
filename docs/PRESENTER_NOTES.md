## Presenter Notes and Talking Points

Use these concise notes to guide your talk. Keep timing balanced across presenters.

### Presenter 1 – Auth + Patients
- JWT/Role flow: `authentication` header; `jwtAuth.authenticate` attaches `req.headers.user`.
- `roleAuth.authorize` checks role and existence; `identifyUserRole` resolves role at login.
- `authRoutes` and `redirectAuthController` for role-based routing.
- Patients: personal data vs. privileged fetch; filters by doctor/hospital; update/delete rules; suspended guardrails.
- Frontend: `log_reg.dart` role routing; `patient_provider.dart` endpoints; headers and error handling; `AppTheme` usage.
- Integration demo: login as patient, fetch personal/diagnosis, view past appointments.

### Presenter 2 – Doctors + Appointments
- Doctors: public data vs. privileged, assigned patients, schedule model.
- Appointments: create with hospital, schedule validation, overlap checks; update guards; cancel.
- Hospital-scoped queries (upcoming/past/filtered/direct queries via services).
- Frontend: doctor pages; provider calls for patients/appointments; Logger to show requests.
- Integration demo: doctor views assigned patients; admin/superadmin creates appointment.

### Presenter 3 – Hospitals + Tests + Devices + Admin Ops
- Hospitals: register uniqueness (emails/mobileNumbers across collections), admin relationship sync; cascade delete.
- Tests: statuses, review requirement, fetch by role with filters, updates with validation.
- Devices: roles for data upload and CRUD endpoints.
- Admin/SuperAdmin privileges in routes and controllers.
- Frontend: superadmin/admin management pages; theme cohesion.
- Integration demo: register hospital, update admin, create a test, upload device data.

### Cross-cutting
- Conventions: header names (`patientid`, `doctorid`, `hospitalid`, etc.), `suspendfilter`, `time_direction`.
- Firestore timestamps; conversion in services; arrays in hospital documents and consistency helpers.
- Error handling patterns and common 400/403 responses.


