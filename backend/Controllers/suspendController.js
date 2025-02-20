const SuspendService = require("../Services/suspendService");

class SuspendController {
  /**
   * Filters data based on the user's role and the "suspended" status of the data.
   *
   * @param {Object} data - The data to be filtered (can be a single object or an array of objects).
   * @param {string} role - The role of the user making the request (e.g., "superadmin", "patient").
   * @param {string} filter - The filter criteria for superadmins ("suspended", "unsuspended", or "all").
   *
   * @returns {Object|Array} The filtered data or an error if the criteria are not met.
   */
  static async filterData(data, role, filter) {
    try {
      return SuspendService.filterData(data, role, filter);
    } catch (error) {
      throw new Error(`SuspendController: ${error.message}`);
    }
  }
}

module.exports = SuspendController;
