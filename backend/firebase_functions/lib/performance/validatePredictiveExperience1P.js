"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.validatePredictiveExperience1P = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
exports.validatePredictiveExperience1P = (0, https_1.onCall)({ region: 'europe-west2' }, async (request) => {
    if (!request.auth?.token.admin) {
        throw new https_1.HttpsError('permission-denied', 'Admin only');
    }
    const diagnostics = await db
        .collection('appPerformanceDiagnostics')
        .orderBy('createdAt', 'desc')
        .limit(100)
        .get();
    const samples = diagnostics.docs.map((doc) => doc.data());
    const screenTransitionSamples = samples
        .filter((s) => s.metricName === 'screen_transition_latency')
        .map((s) => Number(s.valueMs ?? 0))
        .filter((v) => v > 0);
    const averageScreenTransitionMs = screenTransitionSamples.length === 0
        ? null
        : Math.round(screenTransitionSamples.reduce((a, b) => a + b, 0) /
            screenTransitionSamples.length);
    return {
        ok: true,
        diagnosticsChecked: diagnostics.size,
        averageScreenTransitionMs,
        readyForPilot: averageScreenTransitionMs !== null &&
            averageScreenTransitionMs <= 300,
    };
});
