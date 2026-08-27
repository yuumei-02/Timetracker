// Copyright (c) 2026 yuumei-02. All Rights Reserved.
// See the license file for more information.

// Todo list
// Expanded help command
// Create item
// Delete item
// start session
// end session
// toggle session
// session status

import "dart:io";

String home = "";
bool send_out_notifs = false;
const String version = "0.0.1";

void send_notification(String title, String body) {
   if (!send_out_notifs) return;
   Process.runSync("notify-send", ["-a", "timetracker", title, body]);
}

void check_create_config(String config_path) {
  Directory config = Directory(config_path);

  try {
    if (!config.existsSync()) {
      config.createSync(recursive: true);
    }
  } catch (e) {
    send_notification("Error", "Failed to create config, reason: \"$e\"");
    exit(1);
  }
}

void get_home_path() {
  String? home_path = Platform.environment["HOME"];
  if (home_path == null) {
    send_notification("Error", "Failed to find the \"HOME\" envirnment variable");
    exit(1);
  }

  home = home_path;
}

void help() {
  print("timetracker. A time tracking utility");
  print("");
  print("Usage:");
  print("   timetracker command <args?>");
  print("");
  print("Options:");
  print("   -n   Also send out command results as a system notification");
  print("");
  print("Commands:");
  print("   help <command?>         This help message.");
  print("   version                 Print out the current version.");
  print("   create-item <name>      Create a new item. Items are things you want to track time of.");
  print("   delete-item <name>      Delete an item.");
  print("   start-session <name>    Start a session.");
  print("   end-session <name>      Stop a session.");
  print("   toggle-session <name>   Toggle the status of a session.");
  print("   session-status <name>   Returns \"active\" or \"inactive\" based on whether or not the session is active.");
  print("");
  print("See \"timetracker help <command>\" for more information on a specific command.");
}

void print_version() {
  send_notification("Version", version);
  print(version);
}

void main(List<String> args) {
  if (args.isEmpty) {
    help();
    exit(1);
  }
  
  get_home_path();
  String config_path = "${home}/.config/timetracker";
  check_create_config(config_path);

  for (String arg in args) {
    if (arg == '-n') {
      send_out_notifs = true;
    }
  }

  switch (args.first) {
    case "version":
       print_version();
    default:
      help();
  }

  send_notification("zhyivannye", "miratny");
}
