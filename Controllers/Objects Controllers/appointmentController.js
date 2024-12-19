const AppointmentService = require("../../Services/appointmentService");

/**
 * AppointmentController checks the input in the request to validate it and make sure that the users have the permission to receive this data
 * It includes functionalities for retrieving upcoming appointments, appointment history, 
 * creating new appointments, and canceling existing ones. Each method ensures proper role-based 
 * authorization and validates required fields before performing actions like appointment creation or cancellation.
 * 
 * The controller ensures that only authorized users (patients, doctors, or admins) can access or modify appointment data.
 */
class AppointmentController {

  /**
   * Retrieves upcoming appointments for the authenticated user.
   * It checks the user's role and permissions before fetching the appointments.
   * 
   * @param {Object} req - The HTTP request object containing the user's ID and role in the headers.
   * @param {Object} res - The HTTP response object used to send back the list of upcoming appointments or errors.
   * 
   * @returns {Object} Returns a JSON response with a list of upcoming appointments or an error message.
   */

  static async getUpcomingAppointments(req, res) {
    try {
      const { _id, user, role } = req.headers;

      // Check if user ID is provided in the request
      if (!_id) {
        return res.status(400).json({
          error: "PatientController- Get Patient Data: Missing pers_id",
        });
      }

      // Verify that the user is either a patient or doctor and that the _id matches the user ID in the request headers
      if (user.role === "patient" || user.role === "doctor") {
        if (_id !== user._id) {
          return res.status(403).json({
            error: "PatientController- Get Patient Data: Unauthorized",
          });
        }
      }

      // Fetch upcoming appointments using the AppointmentService
      const appointments = await AppointmentService.getUpcomingAppointments({
        role,
        user_id: _id,
      });

      // Return the fetched appointments
      res.status(200).json(appointments);
    } catch (fetchUpcomingAppointmentsError) {
      // Handle errors in fetching the appointments
      res.status(500).json({ error: fetchUpcomingAppointmentsError.message });
    }
  }

  /**
   * Retrieves the appointment history for the authenticated user.
   * It checks the user's role and permissions before fetching the history.
   * 
   * @param {Object} req - The HTTP request object containing the user's ID and role in the headers.
   * @param {Object} res - The HTTP response object used to send back the appointment history or errors.
   * 
   * @returns {Object} Returns a JSON response with the user's appointment history or an error message.
   */

  static async getAppointmentHistory(req, res) {
    try {
      const { _id, user, role } = req.headers;

      // Check if user ID is provided in the request
      if (!_id) {
        return res.status(400).json({
          error:
            "PatientController- Get Appointment History: Missing User ID",
        });
      }

      // Verify that the user is either a patient or doctor and that the _id matches the user ID in the request headers
      if (user.role === "patient" || user.role === "doctor") {
        if (_id !== user._id) {
          return res.status(403).json({
            error: "PatientController- Get Patient Data: Unauthorized",
          });
        }
      }

      // Fetch appointment history using the AppointmentService
      const appointmentHistory = await AppointmentService.getAppointmentHistory(
        {
          role,
          user_id: _id,
        }
      );

      // Return the fetched appointment history
      res.status(200).json(appointmentHistory);
    } catch (fetchAppointmentHistoryError) {
      // Handle errors in fetching the appointment history
      res.status(500).json({ error: fetchAppointmentHistoryError.message });
    }
  }

  /**
   * Cancels an appointment if the authenticated user is authorized to do so.
   * Checks for user role and authorization before proceeding with cancellation.
   * 
   * @param {Object} req - The HTTP request object containing the appointment ID in the body and user role in the headers.
   * @param {Object} res - The HTTP response object used to send back the result of the cancellation or errors.
   * 
   * @returns {Object} Returns a JSON response with the cancelled appointment details or an error message.
   */

  static async cancelAppointment(req, res) {
    try {
      const { user, role } = req.headers;
      const { appointment_id } = req.body;

      // Check if appointment ID is provided in the request
      if (!appointment_id) {
        return res.status(400).json({
          error: "AppointmentController-Cancel: Missing appointment's id",
        });
      }

      // Check the user's role and ensure they are authorized to cancel the appointment
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

      // Proceed with the cancellation process using the AppointmentService
      const cancelled_appointment = await AppointmentService.cancelAppointment(
        appointment_id
      );

      // Return the cancelled appointment details
      res.status(200).json(cancelled_appointment);
    } catch (cancelAppointmentError) {
      // Handle errors in cancelling the appointment
      res.status(500).json({ error: cancelAppointmentError.message });
    }
  }

  /**
   * Creates a new appointment if the necessary fields are valid.
   * Validates fields like patient, doctor, appointment date, and purpose before creating the appointment. Status is an optional field.
   * 
   * @param {Object} req - The HTTP request object containing the appointment details in the body.
   * @param {Object} res - The HTTP response object used to send back the created appointment or errors.
   * 
   * @returns {Object} Returns a JSON response with the created appointment details or an error message.
   */

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

      // Verify the user role and authorization before creating the appointment
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

      // Validate the status value if provided
      if (status && !["scheduled", "cancelled", "completed"].includes(status)) {
        return res
          .status(400)
          .json({ error: "AppointmentController-Create: Invalid status" });
      }

      // Check if the appointment date is not in the past
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

      // Return the created appointment details
      res.status(201).json(appointment);
    } catch (error) {
      // Handle errors in creating the appointment
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = AppointmentController;
