from fastapi import FastAPI
app = FastAPI(title='YohPal Multistream Worker')
@app.post('/relay')
def relay(payload: dict): return {'ok': True, 'destinations': payload.get('destinations', [])}
