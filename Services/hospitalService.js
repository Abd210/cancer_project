const Hospital = require("../Models/Hospital");

class HospitalService {
  static async register({ hospital_name, hospital_address, mobile_numbers, emails,}) {
    /**Create a new Hospital instance to validate data*/
    const hospital = new Hospital({
      hospital_name,
      hospital_address,
      mobile_numbers,
      emails,
    });

    /**Check if there's any other hospital with the same name and address*/
    const existingHospital = await Hospital.findOne({
      hospital_name,
      hospital_address,
    });

    if (existingHospital) {
      throw new Error(
        "HospitalService-Register: A hospital with the same name and address already exists."
      );
    }

    /**Validate the data against the schema*/
    const validationError = hospital.validateSync();
    if (validationError) {
      throw new Error(
        `HospitalService-Register-Validation Error: ${validationError.message}`
      );
    }

    /**Save the hospital to the database*/
    const result = await hospital.save();
    return result;
  }
}
module.exports = HospitalService;
