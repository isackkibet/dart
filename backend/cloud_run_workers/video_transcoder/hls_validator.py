import requests
def validate_hls(manifest_url: str) -> bool:
    r = requests.get(manifest_url, timeout=10)
    return r.status_code == 200 and '.m3u8' in manifest_url and '#EXTM3U' in r.text
