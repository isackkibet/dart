def ffmpeg_relay_cmd(input_rtmp: str, output_rtmp: str): return ['ffmpeg','-i',input_rtmp,'-c','copy','-f','flv',output_rtmp]
