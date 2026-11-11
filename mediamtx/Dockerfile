FROM bluenviron/mediamtx:latest-ffmpeg

COPY mediamtx.yml /mediamtx.yml

# 8888: HLS DVR playback HTTP listener
# 8889: WebRTC / WHIP signaling (HTTP)
# 8189: WebRTC ICE media (UDP + TCP fallback)
# 8554: RTSP internal loopback (FFmpeg reader)
# 9997: MediaMTX Control REST API (for NestJS backend)
EXPOSE 8888 8889 8189/udp 8189/tcp 8554 9997

ENTRYPOINT ["/mediamtx"]
CMD ["/mediamtx.yml"]
