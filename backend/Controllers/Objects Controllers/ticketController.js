const TicketService = require("../../Services/ticketService");

/**
 * Creates a new ticket based on the provided user input.
 * Validates the required fields (role, issue, user), checks for valid roles,
 * and creates a ticket through the TicketService.
 */
class TicketController {
  /**
   * Creates a new ticket based on the provided user input.
   * Validates the required fields (role, issue, user), checks for valid roles,
   * and creates a ticket through the TicketService.
   * 
   * @param {Object} req - The Express request object, containing the details of the ticket.
   * @param {Object} res - The Express response object used to send the result or errors.
   * 
   * @returns {Object} A JSON response containing the created ticket or an error message.
   */
  static async createTicket(req, res) {
    try {

      // Destructure the necessary data from the request body
      const { role, issue, user, visibleTo } = req.body;

      // Validate required fields: role, issue, and user must be provided
      if (!role || !issue || !user) {
        return res.status(400).json({
          error: `Missing required fields: ${!role ? "role, " : ""}${
            !issue ? "issue, " : ""
          }${!user ? "user" : ""}`.slice(0, -2),
        });
      }

      // Validate that the role is one of the valid roles
      const validRoles = ["patient", "doctor", "admin", "superadmin"];
      if (!validRoles.includes(role)) {
        return res.status(400).json({
          error: `Invalid role: ${role}. Valid roles are: ${validRoles.join(
            ", "
          )}`, // Respond with a clear message if the role is invalid
        });
      }

      // Validate the 'visibleTo' field if provided
      // Ensure all roles in 'visibleTo' are valid
      if (visibleTo && !visibleTo.every((r) => validRoles.includes(r))) {
        return res.status(400).json({
          error: `Invalid visibleTo roles. Valid roles are: ${validRoles.join(
            ", "
          )}`, // Respond with a clear message if any of the 'visibleTo' roles are invalid
        });
      }

      // Call the TicketService to create the ticket with validated data
      const ticket = await TicketService.createTicket({
        role,
        issue,
        user,
        visibleTo,
      });

      // Respond with the created ticket and a 201 status code
      res.status(201).json(ticket);
    } catch (error) {
      // Handle errors and respond with a 500 status if something goes wrong
      res
        .status(500)
        .json({ error: `TicketController-Create: ${error.message}` });
    }
  }
}

module.exports = TicketController;
