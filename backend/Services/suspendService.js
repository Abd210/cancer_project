const admin = require("firebase-admin");
const db = admin.firestore();

class SuspendService {
  /**
   * Retrieves and filters data based on the user's role and the "suspended" status of the data.
   * @param {string} collectionName - The Firestore collection to query.
   * @param {string} role - The role of the user making the request.
   * @param {string} filter - The filter criteria for superadmins ("suspended", "unsuspended", "all").
   */
  static async getAllByRole(collectionName, role, filter) {
    if (role !== "superadmin" && filter === "suspended") {
      throw new Error(
        "Unauthorized: Only superadmins can view suspended records."
      );
    }

    // Validate filter options
    if (!["suspended", "unsuspended", "all"].includes(filter)) {
      throw new Error(
        "Invalid filter: Must be 'suspended', 'unsuspended', or 'all'."
      );
    }

    let query = db.collection(collectionName);

    // Apply filter if it's not "all"
    if (filter !== "all") {
      query = query.where("suspended", "==", filter === "suspended");
    }

    const snapshot = await query.get();

    if (snapshot.empty) {
      throw new Error("No records found matching the criteria.");
    }

    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  /**
   * Retrieves a single document by ID and ensures role-based access control.
   * @param {string} collectionName - The Firestore collection name.
   * @param {string} docId - The document ID to fetch.
   * @param {string} role - The role of the user requesting the document.
   */
  static async getById(collectionName, docId, role) {
    const docRef = db.collection(collectionName).doc(docId);
    const docSnap = await docRef.get();

    if (!docSnap.exists) {
      throw new Error("Document not found.");
    }

    const data = docSnap.data();

    // Prevent non-superadmins from accessing suspended records
    if (data.suspended && role !== "superadmin") {
      throw new Error("Unauthorized: This record is suspended.");
    }

    return { id: docSnap.id, ...data };
  }

  /**
   * Updates the "suspended" status of a document.
   * @param {string} collectionName - The Firestore collection name.
   * @param {string} docId - The document ID to update.
   * @param {boolean} suspendStatus - The new suspension status.
   * @param {string} role - The role of the user performing the update.
   */
  static async updateSuspensionStatus(
    collectionName,
    docId,
    suspendStatus,
    role
  ) {
    if (role !== "superadmin") {
      throw new Error(
        "Unauthorized: Only superadmins can modify suspension status."
      );
    }

    const docRef = db.collection(collectionName).doc(docId);
    const docSnap = await docRef.get();

    if (!docSnap.exists) {
      throw new Error("Document not found.");
    }

    await docRef.update({ suspended: suspendStatus });

    return {
      message: `Document ${
        suspendStatus ? "suspended" : "unsuspended"
      } successfully.`,
    };
  }
}

module.exports = SuspendService;
