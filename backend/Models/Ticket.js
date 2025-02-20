const { db } = require("../firebase"); // Import shared Firebase instance

const ticketsCollection = db.collection("tickets");

const ROLES = ["patient", "doctor", "admin", "superadmin"];
const STATUSES = ["open", "in_progress", "resolved", "closed"];

class Ticket {
  constructor({
    user,
    issue,
    status = "open",
    role,
    solvedAt = null,
    review = "",
    visibleTo = ["patient", "doctor", "admin", "superadmin"],
    suspended = false,
  }) {
    if (typeof user !== "string")
      throw new Error("Invalid user: must be a Firestore document reference");
    if (typeof issue !== "string")
      throw new Error("Invalid issue: must be a string");
    if (!STATUSES.includes(status))
      throw new Error(
        `Invalid status: ${status}. Allowed: ${STATUSES.join(", ")}`
      );
    if (!ROLES.includes(role))
      throw new Error(`Invalid role: ${role}. Allowed: ${ROLES.join(", ")}`);
    if (solvedAt !== null && !(solvedAt instanceof Date))
      throw new Error("Invalid solvedAt: must be a Date object or null");
    if (typeof review !== "string")
      throw new Error("Invalid review: must be a string");
    if (!Array.isArray(visibleTo))
      throw new Error("Invalid visibleTo: must be an array of strings");
    if (typeof suspended !== "boolean")
      throw new Error("Invalid suspended: must be a boolean");

    this.user = user;
    this.issue = issue;
    this.status = status;
    this.role = role;
    this.solvedAt = solvedAt;
    this.review = review;
    this.visibleTo = visibleTo;
    this.suspended = suspended;
    this.createdAt = new Date();
    this.updatedAt = new Date();
  }

  async save() {
    try {
      const docRef = await ticketsCollection.add({ ...this });
      return docRef.id;
    } catch (error) {
      throw new Error("Error saving ticket: " + error.message);
    }
  }
}

module.exports = Ticket;
