Mix.install([
  {:bandit, "~> 1.2"},
  {:plug, "~> 1.15"},
  {:websock_adapter, "~> 0.5.0"},
  {:jason, "~> 1.4"},
  {:ex_webrtc, "~> 0.4.1"}
])

Logger.configure(level: :info)

defmodule Main do
  require Logger

  def main do
    ip = {127, 0, 0, 1}
    port = 8829

    {:ok, _pid} = Bandit.start_link(plug: Router, ip: ip, port: port)
    Logger.info("Visit http://#{:inet.ntoa(ip)}:#{port}")

    # unless running from IEx, sleep idenfinitely so we can serve requests
    unless IEx.started?() do
      Process.sleep(:infinity)
    end
  end
end

defmodule Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  @website """
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta http-equiv="X-UA-Compatible" content="ie=edge">
      <title>Elixir WebRTC Echo Example</title>
    </head>
    <body>
      <main>
          <h1>Elixir WebRTC Echo Example</h1>
      </main>
      <video id="videoPlayer" autoplay controls></video>
      <script>
        const pcConfig = { 'iceServers': [{ 'urls': 'stun:stun.l.google.com:19302' },] };
        const videoPlayer = document.getElementById("videoPlayer");

        const ws = new WebSocket('ws://127.0.0.1:8829/ws')
        ws.onopen = _ => start_connection(ws);
        ws.onclose = event => console.log("WebSocket connection was terminated:", event);

        const start_connection = async (ws) => {
          const pc = new RTCPeerConnection(pcConfig);
          pc.ontrack = event => videoPlayer.srcObject = event.streams[0];
          pc.onicecandidate = event => {
            if (event.candidate === null) return;

            console.log("Sent ICE candidate:", event.candidate);
            ws.send(JSON.stringify({ type: "ice", data: event.candidate }));
          };

          const localStream = await navigator.mediaDevices.getUserMedia({audio: true, video: true});
          localStream.getTracks().forEach(track => pc.addTrack(track, localStream));
          ws.onmessage = async event => {
            const {type, data} = JSON.parse(event.data);

            switch (type) {
              case "answer":
                console.log("Received SDP answer:", data);
                await pc.setRemoteDescription(data)
                break;
              case "ice":
                console.log("Received ICE candidate:", data);
                await pc.addIceCandidate(data);
            }
          };

          const offer = await pc.createOffer();
          await pc.setLocalDescription(offer);
          console.log("Sent SDP offer:", offer)
          ws.send(JSON.stringify({type: "offer", data: offer}));
        };
      </script>
    </body>
  </html>
  """

  get "/" do
    send_resp(conn, 200, @website)
  end

  get "ws" do
    WebSockAdapter.upgrade(conn, Peer, %{}, [])
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end

defmodule Peer do
  require Logger

  alias ExWebRTC.{
    ICECandidate,
    MediaStreamTrack,
    PeerConnection,
    RTPCodecParameters,
    SessionDescription
  }

  @behaviour WebSock

  @ice_servers [
    %{urls: "stun:stun.l.google.com:19302"}
  ]

  @video_codecs [
    %RTPCodecParameters{
      payload_type: 96,
      mime_type: "video/VP8",
      clock_rate: 90_000
    }
  ]

  @audio_codecs [
    %RTPCodecParameters{
      payload_type: 111,
      mime_type: "audio/opus",
      clock_rate: 48_000,
      channels: 2
    }
  ]

  @impl true
  def init(_) do
    {:ok, pc} =
      PeerConnection.start_link(
        ice_servers: @ice_servers,
        video_codecs: @video_codecs,
        audio_codecs: @audio_codecs
      )

    stream_id = MediaStreamTrack.generate_stream_id()
    video_track = MediaStreamTrack.new(:video, [stream_id])
    audio_track = MediaStreamTrack.new(:audio, [stream_id])

    {:ok, _sender} = PeerConnection.add_track(pc, video_track)
    {:ok, _sender} = PeerConnection.add_track(pc, audio_track)

    state = %{
      peer_connection: pc,
      out_video_track_id: video_track.id,
      out_audio_track_id: audio_track.id,
      in_video_track_id: nil,
      in_audio_track_id: nil
    }

    {:ok, state}
  end

  @impl true
  def handle_in({msg, [opcode: :text]}, state) do
    msg
    |> Jason.decode!()
    |> handle_ws_msg(state)
  end

  @impl true
  def handle_info({:ex_webrtc, _from, msg}, state) do
    handle_webrtc_msg(msg, state)
  end

  @impl true
  def terminate(reason, _state) do
    Logger.warning("WebSocket connection was terminated, reason: #{inspect(reason)}")
  end

  defp handle_ws_msg(%{"type" => "offer", "data" => data}, state) do
    Logger.info("Received SDP offer:\n#{data["sdp"]}")

    offer = SessionDescription.from_json(data)
    :ok = PeerConnection.set_remote_description(state.peer_connection, offer)

    {:ok, answer} = PeerConnection.create_answer(state.peer_connection)
    :ok = PeerConnection.set_local_description(state.peer_connection, answer)

    answer_json = SessionDescription.to_json(answer)
    msg = Jason.encode!(%{"type" => "answer", "data" => answer_json})

    Logger.info("Sent SDP answer:\n#{answer_json["sdp"]}")

    {:push, {:text, msg}, state}
  end

  defp handle_ws_msg(%{"type" => "ice", "data" => data}, state) do
    Logger.info("Received ICE candidate: #{data["candidate"]}")

    candidate = ICECandidate.from_json(data)
    :ok = PeerConnection.add_ice_candidate(state.peer_connection, candidate)
    {:ok, state}
  end

  defp handle_webrtc_msg({:ice_candidate, candidate}, state) do
    candidate_json = ICECandidate.to_json(candidate)
    msg = Jason.encode!(%{"type" => "ice", "data" => candidate_json})

    Logger.info("Sent ICE candidate: #{candidate_json["candidate"]}")

    {:push, {:text, msg}, state}
  end

  defp handle_webrtc_msg({:track, track}, state) do
    %MediaStreamTrack{kind: kind, id: id} = track

    state =
      case kind do
        :audio -> %{state | in_audio_track_id: id}
        :video -> %{state | in_video_track_id: id}
      end

    {:ok, state}
  end

  defp handle_webrtc_msg({:rtcp, packets}, state) do
    for packet <- packets do
      case packet do
        {_track_id, %ExRTCP.Packet.PayloadFeedback.PLI{}} when state.in_video_track_id != nil ->
          Logger.info("Received keyframe request. Sending PLI.")
          :ok = PeerConnection.send_pli(state.peer_connection, state.in_video_track_id, "h")

        _other ->
          :ok
      end
    end

    {:ok, state}
  end

  defp handle_webrtc_msg({:rtp, id, nil, packet}, %{in_audio_track_id: id} = state) do
    PeerConnection.send_rtp(state.peer_connection, state.out_audio_track_id, packet)
    {:ok, state}
  end

  defp handle_webrtc_msg({:rtp, id, nil, packet}, %{in_video_track_id: id} = state) do
    PeerConnection.send_rtp(state.peer_connection, state.out_video_track_id, packet)
    {:ok, state}
  end

  defp handle_webrtc_msg(_msg, state), do: {:ok, state}
end

Main.main()
