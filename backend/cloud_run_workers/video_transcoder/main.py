from fastapi import FastAPI
from pydantic import BaseModel
app = FastAPI(title='YohPal Video Transcoder')
class TranscodeJob(BaseModel): video_id: str; source_url: str
@app.post('/transcode')
def transcode(job: TranscodeJob):
    # TODO: download source, run ffmpeg ABR HLS, validate .m3u8 + segments, update Firestore status=live.
    return {'ok': True, 'video_id': job.video_id, 'status': 'queued'}
