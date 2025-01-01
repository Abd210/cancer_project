// utils/otpGenerator.js
const speakeasy = require('speakeasy');

class OTPGenerator {
    static generate(codeType) {
        if (codeType === 'totp') {
            return speakeasy.totp({
                secret: 'secret', // Replace with dynamic secret
                encoding: 'base32'
            });
        } else if (codeType === 'sms' || codeType === 'email') {
            // Generate a 6-digit numeric code
            return Math.floor(100000 + Math.random() * 900000).toString();
        }
        throw new Error('Invalid code type');
    }
}

module.exports = OTPGenerator;
