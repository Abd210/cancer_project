const Hospital = require("../Models/Hospital");

class HospitalService {
  static async register({
    hospital_name,
    hospital_address,
    mobile_numbers,
    emails,
  }) {
    try {
      // Create a new Hospital instance to validate data
      const hospital = new Hospital({
        hospital_name,
        hospital_address,
        mobile_numbers,
        emails,
      });

      // Validate the data against the schema
      const validationError = hospital.validateSync();
      if (validationError) {
        throw new Error(
          `HospitalService-Register-Validation Error: ${validationError.message}`
        );
      }

      // Save the hospital to the database
      const result = await hospital.save();
      return result;
    } catch (saveHospitalError) {
      throw new Error(`HospitalService-Register: ${saveHospitalError.message}`);
    }
  }
}
