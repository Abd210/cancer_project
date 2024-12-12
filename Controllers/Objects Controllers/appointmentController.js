const AppointmentService = require("../../Services/appointmentService");

class AppointmentController {
  static async getUpcomingAppointments(req, res) {
    try {
      const { _id, user, role } = req.headers;
      if (!_id) {
        return res.status(400).json({
          error: "PatientController- Get Patient Data: Missing pers_id",
        });
      }

      if (user.role === "patient" || user.role === "doctor") {
        if (_id !== user._id) {
          return res.status(403).json({
            error: "PatientController- Get Patient Data: Unauthorized",
          });
        }
      }

      const appointments = await AppointmentService.getUpcomingAppointments({
        role,
        user_id: _id,
      });
      res.status(200).json(appointments);
    } catch (fetchUpcomingAppointmentsError) {
      res.status(500).json({ error: fetchUpcomingAppointmentsError.message });
    }
  }

  static async getAppointmentHistory(req, res) {
    try {
      const { _id, user, role } = req.headers;
      if (!_id) {
        return res.status(400).json({
          error:
            "PatientController- Get Patient Data: Missing appointment's id",
        });
      }

      if (user.role === "patient" || user.role === "doctor") {
        if (_id !== user._id) {
          return res.status(403).json({
            error: "PatientController- Get Patient Data: Unauthorized",
          });
        }
      }

      const appointmentHistory = await AppointmentService.getAppointmentHistory(
        {
          role,
          user_id: _id,
        }
      );
      res.status(200).json(appointmentHistory);
    } catch (fetchAppointmentHistoryError) {
      res.status(500).json({ error: fetchAppointmentHistoryError.message });
    }
  }

  static async cancelAppointment(req, res) {
    try {
      const { user, role } = req.headers;
      const { appointment_id } = req.body;
      if (!appointment_id) {
        return res.status(400).json({
          error: "AppointmentController-Cancel: Missing appointment's id",
        });
      }
      if (user.role !== "admin" && user.role !== "superadmin") {
        if (role === "patient") {
          const appointment = await AppointmentService.findAppointment(
            appointment_id
          );
          if (appointment.patient.toString() !== user._id) {
            return res.status(403).json({
              error: "AppointmentController-Cancel: Unauthorized",
            });
          }
        } else if (role === "doctor") {
          const appointment = await AppointmentService.findAppointment(
            appointment_id
          );
          if (appointment.doctor.toString() !== user._id) {
            return res.status(403).json({
              error: "AppointmentController-Cancel: Unauthorized",
            });
          }
        }
      }
      const cancelled_appointment = await AppointmentService.cancelAppointment(
        appointment_id
      );
      res.status(200).json(cancelled_appointment);
    } catch (cancelAppointmentError) {
      res.status(500).json({ error: cancelAppointmentError.message });
    }
  }

  static async createAppointment(req, res) {
    try {
      const { patient, doctor, appointment_date, purpose, status } = req.body;

      // Validate required fields
      if (!patient || !doctor || !appointment_date || !purpose) {
        return res.status(400).json({
          error: `Missing required fields: ${!patient ? "patient, " : ""}${
            !doctor ? "doctor, " : ""
          }${!appointment_date ? "appointment_date, " : ""}${
            !purpose ? "purpose" : ""
          }`.slice(0, -2),
        });
      }

      if (user.role !== "admin" && user.role !== "superadmin") {
        if (role === "patient") {
          if (patient !== user._id) {
            return res.status(403).json({
              error: "AppointmentController-Cancel: Unauthorized",
            });
          }
        } else if (role === "doctor") {
          if (doctor !== user._id) {
            return res.status(403).json({
              error: "AppointmentController-Cancel: Unauthorized",
            });
          }
        }
      }

      if (status && !["scheduled", "cancelled", "completed"].includes(status)) {
        return res
          .status(400)
          .json({ error: "AppointmentController-Create: Invalid status" });
      }

      if (new Date(appointment_date) < new Date()) {
        return res.status(400).json({
          error:
            "AppointmentController-Create: Appointment date cannot be in the past",
        });
      }
      // Call the AppointmentService to create the appointment
      const appointment = await AppointmentService.createAppointment({
        patient_id: patient,
        doctor_id: doctor,
        appointment_date,
        purpose,
        status,
      });

      res.status(201).json(appointment);
    } catch (error) {
      res
        .status(500)
        .json({ error: `AppointmentController-Create: ${error.message}` });
    }
  }
}

module.exports = AppointmentController;
