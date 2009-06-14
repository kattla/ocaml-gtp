include Spec

let build_command name ~argument ~output = {
  Command.name = name;
  argument = argument;
  output = output;
}
