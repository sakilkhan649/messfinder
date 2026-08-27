require('dotenv').config();
const { RtcTokenBuilder, RtcRole } = require('agora-token');
try {
    const appId = process.env.AGORA_APP_ID;
    const appCertificate = process.env.AGORA_APP_CERTIFICATE;
    console.log("APP_ID:", appId, "CERT:", appCertificate);
    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      'testChannel',
      0,
      RtcRole.PUBLISHER,
      Math.floor(Date.now() / 1000) + 86400,
      Math.floor(Date.now() / 1000) + 86400
    );
    console.log("Token:", token);
} catch (e) {
    console.error(e);
}
