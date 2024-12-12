const Ticket = require("../Models/Ticket");

class TicketService {
  static async createTicket({ role, issue, user, visibleTo }) {
    try {
      const ticket = new Ticket({
        role,
        issue,
        user,
        visibleTo, // Default if not provided
      });

      return await ticket.save();
    } catch (error) {
      throw new Error(`TicketService-Create: ${error.message}`);
    }
  }

  static async getTicketReview({ user, ticket_id, role }) {
    try {
      const ticket = await this.findTicket(ticket_id);
      if (ticket.visibleTo.includes(role) || ticket.user === user) {
        return ticket;
      } else {
        throw new Error("TicketService-Get: Unauthorized access to ticket");
      }
    } catch (fetchTicketReviewError) {
      throw new Error(`TicketService-Get: ${fetchTicketReviewError.message}`);
    }
  }
  static async findTicket(ticket_id) {
    if (!mongoose.isValidObjectId(ticket_id)) {
      throw new Error("ticketService-find ticket: Invalid ticket id");
    }

    return await Ticket.findOne({ _id: ticket_id });
  }
}

module.exports = TicketService;
