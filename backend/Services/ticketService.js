const admin = require("firebase-admin");
const db = admin.firestore();

class TicketService {
  /**
   * Creates a new support ticket in Firestore.
   * @param {Object} ticketData - Ticket details.
   * @param {string} ticketData.role - The role of the user creating the ticket.
   * @param {string} ticketData.issue - The issue description.
   * @param {string} ticketData.user - The ID of the user creating the ticket.
   * @param {Array<string>} ticketData.visibleTo - The roles allowed to view this ticket.
   */
  static async createTicket({ role, issue, user, visibleTo = [] }) {
    const ticketRef = await db.collection("tickets").add({
      role,
      issue,
      user,
      visibleTo,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { message: "Ticket created successfully", ticketId: ticketRef.id };
  }

  /**
   * Retrieves a ticket by ID and ensures the requesting user has access.
   * @param {string} user - The ID of the user requesting the ticket.
   * @param {string} ticketId - The Firestore document ID of the ticket.
   * @param {string} role - The role of the requesting user.
   */
  static async getTicketReview({ user, ticketId, role }) {
    const ticketDoc = await db.collection("tickets").doc(ticketId).get();

    if (!ticketDoc.exists) throw new Error("Ticket not found");

    const ticket = { id: ticketDoc.id, ...ticketDoc.data() };

    // Check if user has permission to view the ticket
    if (!ticket.visibleTo.includes(role) && ticket.user !== user) {
      throw new Error("Unauthorized access to ticket");
    }

    return ticket;
  }

  /**
   * Finds a ticket by ID.
   * @param {string} ticketId - The Firestore document ID of the ticket.
   */
  static async findTicket(ticketId) {
    const ticketDoc = await db.collection("tickets").doc(ticketId).get();

    if (!ticketDoc.exists) throw new Error("Ticket not found");

    return { id: ticketDoc.id, ...ticketDoc.data() };
  }

  /**
   * Deletes a ticket if the requesting user is authorized.
   * @param {string} ticketId - The Firestore document ID of the ticket.
   * @param {string} user - The ID of the user attempting to delete the ticket.
   * @param {string} role - The role of the user.
   */
  static async deleteTicket(ticketId, user, role) {
    const ticketRef = db.collection("tickets").doc(ticketId);
    const ticketDoc = await ticketRef.get();

    if (!ticketDoc.exists) throw new Error("Ticket not found");

    const ticket = ticketDoc.data();

    // Only the ticket creator or an admin can delete the ticket
    if (ticket.user !== user && !["admin", "superadmin"].includes(role)) {
      throw new Error("Unauthorized to delete this ticket");
    }

    await ticketRef.delete();
    return;
  }

  /**
   * Updates a ticket's fields while ensuring role-based access control.
   * @param {string} ticketId - The Firestore document ID of the ticket.
   * @param {Object} updateFields - The fields to update.
   * @param {string} user - The ID of the user attempting the update.
   * @param {string} role - The role of the user.
   */
  static async updateTicket(ticketId, updateFields, user, role) {
    const ticketRef = db.collection("tickets").doc(ticketId);
    const ticketDoc = await ticketRef.get();

    if (!ticketDoc.exists) throw new Error("Ticket not found");

    const ticket = ticketDoc.data();

    // Only the ticket creator or an admin can update the ticket
    if (ticket.user !== user && !["admin", "superadmin"].includes(role)) {
      throw new Error("Unauthorized to update this ticket");
    }

    await ticketRef.update(updateFields);
    return { message: "Ticket updated successfully" };
  }

  /**
   * Fetch all tickets visible to a specific user role.
   * @param {string} role - The role of the requesting user.
   */
  static async fetchTicketsByRole(role) {
    const snapshot = await db
      .collection("tickets")
      .where("visibleTo", "array-contains", role)
      .get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }
}

module.exports = TicketService;
