class SuspendService {
    /**
     * Filters data based on the user's role and the "suspended" status of the data.
     * 
     * @param {Object|Array} data - The data to filter. Can be a single object or an array of objects.
     * @param {string} role - The role of the user making the request.
     * @param {string} filter - The filter criteria for superadmins ("suspended", "unsuspended", "all").
     * 
     * @returns {Object|Array} The filtered data based on the role and filter criteria.
     * @throws {Error} If the filter is invalid for superadmins or if there are no unsuspended records for non-superadmins.
     */
    static filterData(data, role, filter) {
      if (role === "superadmin") {
        // Validate filter value for superadmins
        if (!["suspended", "unsuspended", "all"].includes(filter)) {
          throw new Error(
            "SuspendService: Invalid filter value. Must be one of 'suspended', 'unsuspended', or 'all'."
          );
        }
  
        // Apply filter based on the value
        if (filter === "suspended") {
          return Array.isArray(data)
            ? data.filter((item) => item.suspended === true)
            : data.suspended === true
            ? data
            : null;
        }
  
        if (filter === "unsuspended") {
          return Array.isArray(data)
            ? data.filter((item) => item.suspended === false)
            : data.suspended === false
            ? data
            : null;
        }
  
        // If filter is "all", return the unfiltered data
        return data;
      } else {
        // Non-superadmins can only see unsuspended data
        const filteredData = Array.isArray(data)
          ? data.filter((item) => item.suspended === false)
          : data.suspended === false
          ? data
          : null;
  
        if (!filteredData || (Array.isArray(filteredData) && filteredData.length === 0)) {
          throw new Error("SuspendService: No unsuspended records available.");
        }
  
        return filteredData;
      }
    }
  }
  
  module.exports = SuspendService;
  