const AppointmentService = require("../../Services/appointmentService");

class AppointmentController {
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

      if (status && !["scheduled", "cancelled", "completed"].includes(status)) {
        return res
          .status(400)
          .json({ error: "AppointmentController-Create: Invalid status" });
      }

      if (appointment_date < new Date()) {
        return res
          .status(400)
          .json({
            error: "AppointmentController-Create: Invalid appointment_date",
          });
      }
      // Call the AppointmentService to create the appointment
      const appointment = await AppointmentService.createAppointment({
        patient,
        doctor,
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
