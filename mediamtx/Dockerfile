FROM bluenviron/mediamtx:latest-ffmpeg

COPY mediamtx.yml /mediamtx.yml

# 8889: WebRTC / WHIP (TCP/UDP)
# 8554: RTSP internal
# 9997: REST API
EXPOSE 8889 8554 9997

ENTRYPOINT ["/mediamtx"]
CMD ["/mediamtx.yml"]
