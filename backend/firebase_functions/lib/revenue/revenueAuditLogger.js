"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.writeAuditLog = writeAuditLog;
const firebaseAdmin_1 = require("../shared/firebaseAdmin");
async function writeAuditLog(event, data) {
    await firebaseAdmin_1.db.collection('revenueAuditLogs').add({
        event,
        ...data,
        timestamp: firebaseAdmin_1.FieldValue.serverTimestamp(),
    });
}
