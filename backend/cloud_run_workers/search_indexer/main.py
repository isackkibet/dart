from fastapi import FastAPI
app=FastAPI(title='YohPal Search Indexer')
@app.post('/index')
def index(payload: dict): return {'ok': True}
