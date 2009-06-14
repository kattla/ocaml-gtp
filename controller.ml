
type connection = IO.Read.buf * out_channel

let open_connection in_chan out_chan =
  IO.Read.from_channel in_chan, out_chan

open Command

let command (buf,chan) cmd arg =
  IO.Write.comm chan cmd.name cmd.argument arg;
  IO.Read.ans cmd.output buf

