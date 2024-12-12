const TicketService = require("../../Services/ticketService");

class TicketController {
  /**
   * Create a new ticket.
   * @param {Object} req - Express request object.
   * @param {Object} res - Express response object.
   */
  static async createTicket(req, res) {
    try {
      const { role, issue, user, visibleTo } = req.body;

      // Validate required fields
      if (!role || !issue || !user) {
        return res.status(400).json({
          error: `Missing required fields: ${!role ? "role, " : ""}${
            !issue ? "issue, " : ""
          }${!user ? "user" : ""}`.slice(0, -2),
        });
      }

      // Validate the role
      const validRoles = ["patient", "doctor", "admin", "superadmin"];
      if (!validRoles.includes(role)) {
        return res.status(400).json({
          error: `Invalid role: ${role}. Valid roles are: ${validRoles.join(
            ", "
          )}`,
        });
      }

      // Validate visibleTo (if provided)
      if (visibleTo && !visibleTo.every((r) => validRoles.includes(r))) {
        return res.status(400).json({
          error: `Invalid visibleTo roles. Valid roles are: ${validRoles.join(
            ", "
          )}`,
        });
      }

      // Call the TicketService to create the ticket
      const ticket = await TicketService.createTicket({
        role,
        issue,
        user,
        visibleTo,
      });

      res.status(201).json(ticket);
    } catch (error) {
      res
        .status(500)
        .json({ error: `TicketController-Create: ${error.message}` });
    }
  }
}

module.exports = TicketController;
