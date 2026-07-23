def build_hls_command(input_path: str, output_dir: str) -> list[str]:
    return ['ffmpeg','-i',input_path,'-filter_complex','[0:v]split=3[v1][v2][v3]','-f','hls',f'{output_dir}/master.m3u8']
