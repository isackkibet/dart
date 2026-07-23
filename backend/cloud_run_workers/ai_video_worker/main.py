from fastapi import FastAPI
app = FastAPI(title='YohPal AI Video Worker')
@app.post('/process')
def process(job: dict):
    return {'status':'completed','captions':[], 'hashtags':[], 'viralScore':0.0}
