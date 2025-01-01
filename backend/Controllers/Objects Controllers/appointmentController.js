const AppointmentService = require("../../Services/appointmentService");
const SuspendController = require("../suspendController");

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
      const { _id, role, suspendfilter, user } = req.headers;

      // Check if user ID is provided in the request
      if (!_id) {
        return res.status(400).json({
          error: "AppointmentController- Get Upcoming Appointments Data: Missing _id",
        });
      }

      // Fetch upcoming appointments using the AppointmentService
      const appointments = await AppointmentService.getUpcomingAppointments({
        role: role,
        user_id: _id,
      });

      const filteredResult = await SuspendController.filterData(appointments, user.role, suspendfilter);

      // Return the fetched appointments
      res.status(200).json(filteredResult);
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
      const { _id, user, filterbyid, filterbyrole, suspendfilter } = req.headers;

      // Check if user ID is provided in the request
      if (!_id) {
        return res.status(400).json({
          error:
            "AppointmentController- Get Appointment History: Missing User ID",
        });
      }

      // Validate filterByRole if provided
      if (filterbyrole && !["doctor", "patient"].includes(filterbyrole)) {
        return res.status(400).json({
          error: "AppointmentController- Get Appointment History: Invalid filterByRole",
        });
      }

      // Fetch appointment history using the AppointmentService
      const appointmentHistory = await AppointmentService.getAppointmentHistory(
        {
          role: user.role,
          user_id: _id,
          filterById: filterbyid || null, // Use filterById from query parameters, default to null
          filterByRole: filterbyrole || null, // Use filterByRole from query parameters, default to null
        }
      );


      const filteredResult = await SuspendController.filterData(appointmentHistory, user.role, suspendfilter);

      // Return the fetched appointment history
      res.status(200).json(filteredResult);
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
      const { user, appointment_id} = req.headers;

      // Check if appointment ID is provided in the request
      if (!appointment_id) {
        return res.status(400).json({
          error: "AppointmentController-Cancel: Missing appointment's id",
        });
      }

      // Check the user's role and ensure they are authorized to cancel the appointment
      if (user.role !== "admin" && user.role !== "superadmin") {
        if (user.role === "patient") {
          const appointment = await AppointmentService.findAppointment(
            appointment_id
          );
          if (appointment.patient.toString() !== user._id) {
            return res.status(403).json({
              error: "AppointmentController-Cancel: Unauthorized",
            });
          }
        } else if (user.role === "doctor") {
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
      if (req.headers.user.role !== "admin" && req.headers.user.role !== "superadmin") {
        if (req.headers.user.role === "patient") {
          if (patient !== req.headers.user._id) {
            return res.status(403).json({
              error: "AppointmentController-Cancel: Unauthorized",
            });
          }
        } else if (req.headers.user.role === "doctor") {
          if (doctor !== req.headers.user._id) {
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
      // if (new Date(appointment_date) < new Date()) {
      //   return res.status(400).json({
      //     error:
      //       "AppointmentController-Create: Appointment date cannot be in the past",
      //   });
      // }

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

  /**
   * Deletes an appointment if the authenticated user is authorized to do so.
   * Checks for user role and authorization before proceeding with deletion.
   *
   * @param {Object} req - The HTTP request object containing the appointment ID in the headers and user role in the headers.
   * @param {Object} res - The HTTP response object used to send back the result of the deletion or errors.
   *
   * @returns {Object} Returns a JSON response with the deleted appointment details or an error message.
   */
  static async deleteAppointment(req, res) {
    try {
      const { appointment_id } = req.headers;

      // Check if the appointment ID is provided
      if (!appointment_id) {
        return res.status(400).json({
          error: "AppointmentController-Delete: Missing appointment's id",
        });
      }

      // Proceed with the deletion process using the AppointmentService
      const deletedAppointment = await AppointmentService.deleteAppointment(appointment_id);

      // Return the details of the deleted appointment
      res.status(200).json({
        message: "Appointment successfully deleted",
        deletedAppointment,
      });
    } catch (deleteAppointmentError) {
      // Handle errors in deleting the appointment
      res.status(500).json({ error: deleteAppointmentError.message });
    }
  }

  static async updateAppointmentData(req, res) {
    try {
      const { user, appointmentid } = req.headers;

      // Destructure the fields to update from the request body
      const updateFields = req.body;

      // Validate if appointmentId is provided
      if (!appointmentid) {
        return res.status(400).json({
          error: "AppointmentController-update appointment: Missing appointmentId",
        });
      }
  
      // Validate if updateFields are provided
      if (!updateFields || Object.keys(updateFields).length === 0) {
        return res.status(400).json({
          error: "AppointmentController-update appointment: No fields provided to update",
        });
      }
  
      // Call the AppointmentService to perform the update
      const updatedAppointment = await AppointmentService.updateAppointment(appointmentid, updateFields, user);
  
      // Check if the patient was found and updated
      if (!updatedAppointment) {
        return res.status(404).json({
          error: "AppointmentController- Update Appointment Data: Appointment not found",
        });
      }
  
      // Respond with the updated appointment data
      return res.status(200).json(updatedAppointment);
    } catch (updateAppointmentError) {
      // Catch and return errors
      return res.status(500).json({
        error: `AppointmentController-update appointment: ${updateAppointmentError.message}`,
      });
    }
  }

}

module.exports = AppointmentController;
