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
   * Retrieves all upcoming appointments (ignores specific patient/doctor filtering).
   */
  static async getAllUpcomingAppointments(req, res) {
    console.log(`[${req.method}] ${req.originalUrl}`);
    try {
      const { suspendfilter, user } = req.headers;

      // Fetch all upcoming appointments using the AppointmentService
      const appointments =
        await AppointmentService.getAllUpcomingAppointments();

      // Filter the data if the user is a superadmin
      const filteredResult = await SuspendController.filterData(
        appointments,
        user.role,
        suspendfilter
      );

      return res.status(200).json(filteredResult);
    } catch (error) {
      console.error("Error in getAllUpcomingAppointments:", error);
      res.status(500).json({ error: error.message });
    }
  }

  /**
   * Retrieves upcoming appointments for the authenticated user.
   * It checks the user's role and permissions before fetching the appointments.
   *
   * @param {Object} req - The HTTP request object containing the user's ID and role in the headers.
   * @param {Object} res - The HTTP response object used to send back the list of upcoming appointments or errors.
   *
   * @returns {Object} Returns a JSON response with a list of upcoming appointments or an error message.
   */

  static async getUpcomingAppointmentsForSpecificPatientOrDoctor(req, res) {
    console.log(`[${req.method}] ${req.originalUrl}`);
    try {
      const { entity_role, suspendfilter, user, entity_id } = req.headers;

      if (!entity_role || !entity_id) {
        return res.status(400).json({
          error:
            "AppointmentController-Get Upcoming Appointments: Missing entity role or entity id",
        });
      }

      // Fetch upcoming appointments using the AppointmentService
      const appointments =
        await AppointmentService.getUpcomingAppointmentsForSpecificPatientOrDoctor(
          {
            entity_role,
            entity_id,
          }
        );

      const filteredResult = await SuspendController.filterData(
        appointments,
        user.role,
        suspendfilter
      );

      // Return the fetched appointments
      res.status(200).json(filteredResult);
    } catch (fetchUpcomingAppointmentsError) {
      console.error(
        "Error in getUpcomingAppointmentsForSpecificPatientOrDoctor:",
        fetchUpcomingAppointmentsError
      );
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
      const { user, filterbyid, filterbyrole, suspendfilter } = req.headers;

      // Validate filterByRole if provided
      if (
        filterbyrole &&
        !["doctor", "patient"].includes(filterbyrole) &&
        user.role === "superadmin"
      ) {
        return res.status(400).json({
          error:
            "AppointmentController- Get Appointment History: Invalid filterByRole",
        });
      }

      if ((!filterbyid && filterbyrole) || (!filterbyrole && filterbyid)) {
        return res.status(400).json({
          error:
            "AppointmentController- Get Appointment History: filterById and filterByRole must be provided together",
        });
      }

      // Fetch appointment history using the AppointmentService
      const appointmentHistory = await AppointmentService.getAppointmentHistory(
        {
          role: user.role,
          user_id: user.id,
          filterById: filterbyid || null, // Use filterById from query parameters, default to null
          filterByRole: filterbyrole || null, // Use filterByRole from query parameters, default to null
        }
      );

      const filteredResult = await SuspendController.filterData(
        appointmentHistory,
        user.role,
        suspendfilter
      );

      // Return the fetched appointment history
      res.status(200).json(filteredResult);
    } catch (fetchAppointmentHistoryError) {
      console.error(
        "Error in getAppointmentHistory:",
        fetchAppointmentHistoryError
      );
      res.status(500).json({ error: fetchAppointmentHistoryError.message });
    }
  }

  /**
   * Retrieves appointments for a specific date.
   *
   * @param {Object} req - The HTTP request object containing the date in query parameters.
   * @param {Object} res - The HTTP response object used to send back the appointments or errors.
   *
   * @returns {Object} Returns a JSON response with a list of appointments on the specified date or an error message.
   */
  static async getAppointmentsByDate(req, res) {
    try {
      const { user, date, filter } = req.headers; // Date should be in 'YYYY-MM-DD' format

      if (!date) {
        return res.status(400).json({
          error:
            "AppointmentController-GetAppointmentsByDate: Missing date parameter",
        });
      }

      // Call the AppointmentService to fetch appointments for the given date
      const appointments = await AppointmentService.getAppointmentsByDate(date);

      const filteredResult = await SuspendController.filterData(
        appointments,
        user.role,
        filter
      );

      return res.status(200).json(filteredResult);
    } catch (error) {
      console.error("Error in getAppointmentsByDate:", error);
      res.status(500).json({
        error: `AppointmentController-GetAppointmentsByDate: ${error.message}`,
      });
    }
  }

  /**
   * Retrieves all upcoming appointments associated with a hospital.
   * The hospital's ID is expected to be provided in the request headers as "hospitalid".
   *
   * @param {Object} req - The Express request object.
   * @param {Object} res - The Express response object.
   * @returns {Object} JSON response with an array of appointments or an error message.
   */
  static async getHospitalUpcomingAppointments(req, res) {
    try {
      const { hospital_id, user, filter } = req.headers;
      if (!hospital_id) {
        return res.status(400).json({
          error:
            "AppointmentController-getHospitalAppointments: Missing hospitalid in headers",
        });
      }

      // Call the service to get appointments associated with this hospital.
      const appointments =
        await AppointmentService.getUpcomingAppointmentsByHospital(hospital_id);

      const filteredResult = await SuspendController.filterData(
        appointments,
        user.role,
        filter
      );

      return res.status(200).json(filteredResult);
    } catch (error) {
      console.error("Error in getHospitalUpcomingAppointments:", error);
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * Retrieves all past appointments associated with a hospital.
   * The hospital's ID is expected to be provided in the request headers as "hospitalid".
   *
   * @param {Object} req - The Express request object.
   * @param {Object} res - The Express response object.
   * @returns {Object} JSON response with an array of appointments or an error message.
   */
  static async getHospitalHistoryOfAppointments(req, res) {
    try {
      const { hospital_id, user, filter } = req.headers;
      if (!hospital_id) {
        return res.status(400).json({
          error:
            "AppointmentController-getHospitalAppointments: Missing hospitalid in headers",
        });
      }

      // Call the service to get appointments associated with this hospital.
      const appointments =
        await AppointmentService.getPastAppointmentsByHospital(hospital_id);

      const filteredResult = await SuspendController.filterData(
        appointments,
        user.role,
        filter
      );

      return res.status(200).json(filteredResult);
    } catch (error) {
      console.error("Error in getHospitalHistoryOfAppointments:", error);
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * Retrieves filtered appointments for a hospital with optional patient and doctor filters.
   * Can filter by patient ID, doctor ID, or both simultaneously.
   * 
   * @param {Object} req - The Express request object.
   * @param {Object} res - The Express response object.
   * @returns {Object} JSON response with an array of filtered appointments or an error message.
   */
  static async getFilteredHospitalAppointments(req, res) {
    try {
      const { hospital_id, patient_id, doctor_id, time_direction, user, filter } = req.headers;
      
      if (!hospital_id) {
        return res.status(400).json({
          error:
            "AppointmentController-getFilteredHospitalAppointments: Missing hospital_id in headers",
        });
      }

      // Default to upcoming if time_direction not specified
      const timeDirection = time_direction || "upcoming";
      
      // Validate time_direction
      if (!["upcoming", "past"].includes(timeDirection)) {
        return res.status(400).json({
          error:
            "AppointmentController-getFilteredHospitalAppointments: Invalid time_direction. Must be 'upcoming' or 'past'",
        });
      }

      // Call the service to get filtered appointments for this hospital
      const appointments = await AppointmentService.getFilteredHospitalAppointments(
        hospital_id,
        patient_id || null,
        doctor_id || null, 
        timeDirection
      );

      const filteredResult = await SuspendController.filterData(
        appointments,
        user.role,
        filter
      );

      return res.status(200).json(filteredResult);
    } catch (error) {
      console.error("Error in getFilteredHospitalAppointments:", error);
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * OPTIMIZED: Retrieves appointments for a hospital by directly querying the hospital field.
   * Much more efficient than the indirect doctor-based approach.
   * 
   * @param {Object} req - The Express request object.
   * @param {Object} res - The Express response object.
   * @returns {Object} JSON response with an array of appointments or an error message.
   */
  static async getDirectHospitalAppointments(req, res) {
    try {
      const { hospital_id, patient_id, doctor_id, time_direction, user, filter } = req.headers;
      
      if (!hospital_id) {
        return res.status(400).json({
          error:
            "AppointmentController-getDirectHospitalAppointments: Missing hospital_id in headers",
        });
      }

      // Default to upcoming if time_direction not specified
      const timeDirection = time_direction || "upcoming";
      
      // Validate time_direction
      if (!["upcoming", "past"].includes(timeDirection)) {
        return res.status(400).json({
          error:
            "AppointmentController-getDirectHospitalAppointments: Invalid time_direction. Must be 'upcoming' or 'past'",
        });
      }

      // Call the optimized service method to get appointments directly by hospital field
      const appointments = await AppointmentService.getDirectHospitalAppointments(
        hospital_id,
        patient_id || null,
        doctor_id || null, 
        timeDirection
      );

      const filteredResult = await SuspendController.filterData(
        appointments,
        user.role,
        filter
      );

      return res.status(200).json(filteredResult);
    } catch (error) {
      console.error("Error in getDirectHospitalAppointments:", error);
      return res.status(500).json({ error: error.message });
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
      const { user, appointment_id } = req.headers;

      // Check if appointment ID is provided in the request
      if (!appointment_id) {
        return res.status(400).json({
          error: "AppointmentController-Cancel: Missing appointment's id",
        });
      }

      // Check the user's role and ensure they are authorized to cancel the appointment
      const userId = user.id || user._id;
      if (user.role !== "admin" && user.role !== "superadmin") {
        if (user.role === "patient") {
          const appointment = await AppointmentService.findAppointment(
            appointment_id
          );
          if (appointment.patient.toString() !== userId) {
            return res.status(403).json({
              error: "AppointmentController-Cancel: Unauthorized",
            });
          }
        } else if (user.role === "doctor") {
          const appointment = await AppointmentService.findAppointment(
            appointment_id
          );
          if (appointment.doctor.toString() !== userId) {
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
      console.error("Error in cancelAppointment:", cancelAppointmentError);
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
      // const { patient, doctor, appointmentDate, purpose, status, suspended } =
      //   req.body;

      // const { patient, doctor, day, startTime, endTime, purpose, status, suspended } =
      //   req.body;

      // Expect start and end as full date-time strings, along with other details.
      const { patient, doctor, hospital, start, end, purpose, status, suspended } =
        req.body;
      
      const { user } = req.headers;

      if (!patient || !doctor || !start || !end || !purpose) {
        return res.status(400).json({
          error:
            "Missing required fields: patient, doctor, start, end, and purpose are required.",
        });
      }

      // Determine hospital ID based on user role
      let hospitalId;
      if (user.role === "admin") {
        // Admin: use their hospital
        hospitalId = user.hospital;
        if (!hospitalId) {
          return res.status(400).json({
            error: "User must be associated with a hospital",
          });
        }
      } else if (user.role === "patient") {
        // Patient: use their hospital (must exist)
        hospitalId = user.hospital;
        if (!hospitalId) {
          // Fetch patient document to obtain hospital reference
          const PatientService = require("../../Services/patientService");
          try {
            const patientDoc = await PatientService.getPatientData(user.id);
            hospitalId = patientDoc.hospital || null;
          } catch (e) {
            // ignore
          }
          if (!hospitalId) {
            return res.status(400).json({
              error: "User must be associated with a hospital",
            });
          }
        }
        // Ensure the patient field in body matches the authenticated user
        if (patient !== user.id) {
          return res.status(403).json({
            error: "Patients can only book appointments for themselves",
          });
        }
      } else if (user.role === "superadmin") {
        // For superadmin: use the hospital from request body
        hospitalId = hospital;
        if (!hospitalId) {
          return res.status(400).json({
            error: "Hospital ID is required for superadmin appointments",
          });
        }
      } else {
        return res.status(403).json({
          error: "Role not permitted to create appointments",
        });
      }

      // // Validate required fields
      // if (!patient || !doctor || !appointmentDate || !purpose) {
      //   return res.status(400).json({
      //     error: `Missing required fields: ${!patient ? "patient, " : ""}${
      //       !doctor ? "doctor, " : ""
      //     }${!appointmentDate ? "appointmentDate, " : ""}${
      //       !purpose ? "purpose" : ""
      //     }`.slice(0, -2),
      //   });
      // }

      // Validate required fields.
      // if (!patient || !doctor || !day || !startTime || !endTime || !purpose) {
      //   return res.status(400).json({
      //     error: "Missing required fields: patient, doctor, day, startTime, endTime, and purpose are required."
      //   });
      // }

      // Verify the user role and authorization before creating the appointment
      // if (
      //   req.headers.user.role !== "admin" &&
      //   req.headers.user.role !== "superadmin"
      // ) {
      //   if (req.headers.user.role === "patient") {
      //     if (patient !== req.headers.user._id) {
      //       return res.status(403).json({
      //         error: "AppointmentController-Cancel: Unauthorized",
      //       });
      //     }
      //   } else if (req.headers.user.role === "doctor") {
      //     if (doctor !== req.headers.user._id) {
      //       return res.status(403).json({
      //         error: "AppointmentController-Cancel: Unauthorized",
      //       });
      //     }
      //   }
      // }

      // Validate the status value if provided (extend list)
      const ALLOWED_STATUSES = ["scheduled", "cancelled", "completed", "pending", "declined"];
      if (status && !ALLOWED_STATUSES.includes(status)) {
        return res
          .status(400)
          .json({ error: "AppointmentController-Create: Invalid status" });
      }

      // Check if the appointment date is not in the past
      // if (new Date(appointmentDate) < new Date()) {
      //   return res.status(400).json({
      //     error:
      //       "AppointmentController-Create: Appointment date cannot be in the past",
      //   });
      // }

      // Determine final status: patient creations default to pending
      const finalStatus = user.role === "patient" ? "pending" : status || "scheduled";

      // Call the AppointmentService to create the appointment
      const appointment = await AppointmentService.createAppointment({
        patient: patient,
        doctor: doctor,
        hospital: hospitalId, // Hospital ID determined based on user role
        // appointmentDate,
        // day: day,
        // startTime: startTime,
        // endTime: endTime,
        start: start,
        end: end,
        purpose: purpose,
        status: finalStatus,
        suspended: suspended || false,
      });

      // Return the created appointment details
      res.status(201).json(appointment);
    } catch (err) {
      console.error("Error in createAppointment:", err);
      const statusCode = err.status || 500;
      res.status(statusCode).json({ error: err.message });
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
      const deletedAppointment = await AppointmentService.deleteAppointment(
        appointment_id
      );

      // Return the details of the deleted appointment
      res.status(200).json({
        message: "Appointment successfully deleted",
      });
    } catch (deleteAppointmentError) {
      console.error("Error in deleteAppointment:", deleteAppointmentError);
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
          error:
            "AppointmentController-update appointment: Missing appointmentId",
        });
      }
      // Check if the user is authorized to update the appointment when its suspended
      if (user.role !== "superadmin") {
        const appointment = await AppointmentService.findAppointment(
          appointmentid
        );
        if (appointment.suspended) {
          return res.status(403).json({
            error: "AppointmentController-update appointment: Unauthorized",
          });
        }
      }

      // Validate if updateFields are provided
      if (!updateFields || Object.keys(updateFields).length === 0) {
        return res.status(400).json({
          error:
            "AppointmentController-update appointment: No fields provided to update",
        });
      }

      console.log("updateFields yo", updateFields);

      // Call the AppointmentService to perform the update
      const updatedAppointment = await AppointmentService.updateAppointment(
        appointmentid,
        updateFields,
        user
      );

      console.log("updatedAppointment yoho", updatedAppointment);

      // Check if the patient was found and updated
      if (!updatedAppointment) {
        return res.status(404).json({
          error:
            "AppointmentController- Update Appointment Data: Appointment not found",
        });
      }

      console.log("updatedAppointment yo", updatedAppointment);

      // Respond with the updated appointment data
      return res.status(200).json(updatedAppointment);
    } catch (updateAppointmentError) {
      console.error("Error in updateAppointmentData:", updateAppointmentError);
      const statusCode = updateAppointmentError.status || 500;
      return res.status(statusCode).json({
        error: `AppointmentController-update appointment: ${updateAppointmentError.message}`,
      });
    }
  }
}

module.exports = AppointmentController;
