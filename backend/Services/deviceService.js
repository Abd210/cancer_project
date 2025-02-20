const admin = require("firebase-admin");
const db = admin.firestore();

class DeviceService {
  /**
   * Creates a new device while ensuring the device ID is unique.
   */
  static async createDevice(deviceData) {
    const deviceRef = db.collection("devices");

    // Check if device with the same ID already exists
    const existingDevice = await deviceRef.doc(deviceData.device_id).get();
    if (existingDevice.exists) {
      throw new Error("Device already exists with the same device ID.");
    }

    // Add new device
    const newDevice = {
      ...deviceData,
      createdAt: admin.firestore.Timestamp.now(),
    };

    await deviceRef.doc(deviceData.device_id).set(newDevice);
    return { message: "Device created successfully.", device: newDevice };
  }

  /**
   * Updates an existing device by ID.
   */
  static async updateDevice(deviceId, updateFields) {
    const deviceRef = db.collection("devices").doc(deviceId);
    const deviceDoc = await deviceRef.get();

    if (!deviceDoc.exists) {
      throw new Error("Device not found.");
    }

    await deviceRef.update(updateFields);
    const updatedDevice = await deviceRef.get();
    return { id: updatedDevice.id, ...updatedDevice.data() };
  }

  /**
   * Deletes a device by ID.
   */
  static async deleteDevice(deviceId) {
    const deviceRef = db.collection("devices").doc(deviceId);
    const deviceDoc = await deviceRef.get();

    if (!deviceDoc.exists) {
      throw new Error("Device not found.");
    }

    await deviceRef.delete();
    return;
  }

  /**
   * Uploads data for a specific device.
   */
  static async uploadDeviceData(deviceId, testData) {
    const deviceRef = db.collection("devices").doc(deviceId);
    const deviceDoc = await deviceRef.get();

    if (!deviceDoc.exists) {
      throw new Error("Device not found.");
    }

    await deviceRef.update({
      data: testData,
      lastUpdated: admin.firestore.Timestamp.now(),
    });

    return { message: "Data uploaded successfully." };
  }

  /**
   * Fetches device data by ID.
   */
  static async getDeviceData(deviceId) {
    const deviceRef = db.collection("devices").doc(deviceId);
    const deviceDoc = await deviceRef.get();

    if (!deviceDoc.exists) {
      throw new Error("Device not found.");
    }

    return { id: deviceDoc.id, ...deviceDoc.data() };
  }
}

module.exports = DeviceService;
