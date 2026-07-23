# Firebase Project Wiring Checklist

## Flutter App
- [ ] `firebase_core` initialized in app bootstrap
- [ ] `firebase_auth` configured for SSO
- [ ] `cloud_firestore` connected to production project
- [ ] `firebase_storage` bucket configured
- [ ] `cloud_functions` region set correctly

## Cloud Functions
- [ ] `mediaWorkerDispatch` deployed
- [ ] `retryMediaWorkerJob` deployed
- [ ] `sendInAppNotification` deployed
- [ ] `sendPushNotification` deployed
- [ ] `executeYohPalBrainTask` deployed
- [ ] `generatePilotReport` scheduled function deployed

## Firestore
- [ ] Security rules deployed
- [ ] Indexes deployed
- [ ] `creatorProfiles` read restricted to authenticated users
- [ ] `mediaWorkerJobs` collection accessible to creators
- [ ] `pilotUsers` collection configured
- [ ] `pilotMetrics` collection configured
- [ ] `floatingPilotEvents` collection configured
- [ ] `floatingPilotMetrics` collection configured
- [ ] `enterpriseEvents` collection configured

## Cloud Run
- [ ] Python FFmpeg worker deployed
- [ ] `MEDIA_WORKER_URL` configured in Functions
- [ ] `MEDIA_WORKER_SERVICE_TOKEN` configured in Functions

## Environment Variables
- [ ] `FIREBASE_PROJECT_ID` set
- [ ] `MEDIA_WORKER_URL` set
- [ ] `MEDIA_WORKER_SERVICE_TOKEN` set
- [ ] `YOHPAL_BRAIN_API_KEY` set
- [ ] `YOHPAL_BRAIN_API_URL` set
