// Copyright (c) 2026 yuumei-02. All Rights Reserved.
// See the license file for more information.

import "dart:convert";
import "dart:io";

String home = "";
String config_path = "";
bool send_out_notifs = false;
const String version = "1.1.0";
bool verbose = false;

void get_home_and_config_path() {
  String? home_path = Platform.environment["HOME"];
  if (home_path == null) {
    report_and_abort("Failed to find the \"HOME\" envirnment variable");
  }

  home = home_path;
  config_path = "${home}/.config/timetracker";
}

void notify(String message) {
  send_notification("Timetracker", message);
  print(message);
}

Never report_and_abort(String message) {
  send_notification("Error", message);
  print("[ERROR]: $message");
  exit(1);
}

String format_datetime(DateTime time) {
  return time.toString().split('.').first;
}

String format_seconds(int seconds) {
  if (seconds < 60) return "$seconds seconds";
  if (seconds < 3600) return "${seconds / 60} minutes";
  return "${seconds / 3600} hours";
}

class Session {
  DateTime start;
  DateTime end;
  int duration_in_seconds;

  Session(this.start, this.end, this.duration_in_seconds);

  static Session parse_from_map(Map result) {
    try {
      int duration = result["duration"];
      DateTime start = DateTime.parse(result["start"]);
      DateTime end = DateTime.parse(result["end"]);

      return Session(start, end, duration);
    } catch (e) {
      String msg = "Failed to parse session";
      if (verbose) msg += ", reason: \"$e\"";
      report_and_abort(msg);
    }
  }

  String serialize() =>
      "{\"duration\": $duration_in_seconds, \"start\": \"${start.toIso8601String()}\", \"end\": \"${end.toIso8601String()}\"}";
}

class Item {
  String name;
  bool active;
  DateTime? started;
  List<Session> sessions;

  Item(this.name, this.active, this.started, this.sessions);

  static Item parse(String serialized) {
    try {
      Map result = jsonDecode(serialized);

      String name = result["name"];
      bool active = result["active"];
      String started_string = result["started"];
      DateTime? started = DateTime.tryParse(started_string);
      List<Session> sessions = [];

      for (Map session in result["sessions"]) {
        sessions.add(Session.parse_from_map(session));
      }

      return Item(name, active, started, sessions);
    } catch (e) {
      String msg = "Failed to parse item";
      if (verbose) msg += ", reason: \"$e\"";
      report_and_abort(msg);
    }
  }

  static Item parse_from_file(String name) {
    try {
      File item_file = File(config_path + "/${name}.json");
      return Item.parse(item_file.readAsStringSync());
    } catch (e) {
      String msg = "Failed to create item";
      if (verbose) msg += ", reason: \"$e\"";
      report_and_abort(msg);
    }
  }

  String serialize() {
    String serialized = "{\"name\": \"$name\", \"active\": $active, \"started\": \"${started ?? ""}\", \"sessions\": [";

    int i = 0;
    for (Session session in sessions) {
      serialized += session.serialize();
      if (i + 1 < sessions.length) {
        serialized += ", ";
      }
      i += 1;
    }

    return serialized + "]}";
  }

  void save_to_file() {
    try {
      File item_file = File(config_path + "/${name}.json");
      if (!item_file.existsSync()) {
        item_file.createSync();
      }

      item_file.writeAsStringSync(this.serialize());
    } catch (e) {
      String msg = "Failed to save item \"$name\" to file";
      if (verbose) msg += ", reason: \"$e\"";
      report_and_abort(msg);
    }
  }

  void start_session() {
    if (active) return;
    active = true;
    started = DateTime.now();
    this.save_to_file();

    notify("$name session started.");
  }

  void end_session() {
    if (!active) return;

    DateTime now = DateTime.now();
    sessions.add(Session(started!, now, now.difference(started!).inSeconds));
    active = false;
    started = null;

    this.save_to_file();
    notify("$name session ended after ${format_seconds(sessions.last.duration_in_seconds)}.");
  }

  void toggle_session(String config_path) {
    if (active) {
      this.end_session();
    } else {
      this.start_session();
    }
  }

  double time_total() {
    double hours = 0;
    for (Session session in sessions) {
      hours += session.duration_in_seconds / 3600;
    }

    return hours;
  }

  void list_session() {
    int i = 0;
    for (Session session in sessions) {
      i += 1;
      print("$name session $i/${sessions.length}");
      print("From: ${format_datetime(session.start)}");
      print("To:   ${format_datetime(session.end)}");
      print("Duration: ${format_seconds(session.duration_in_seconds)}");
      print("");
    }
  }
}

void send_notification(String title, String body) {
  if (!send_out_notifs) return;
  Process.runSync("notify-send", ["-a", "timetracker", title, body]);
}

void check_create_config() {
  Directory config = Directory(config_path);

  try {
    if (!config.existsSync()) {
      config.createSync(recursive: true);
    }
  } catch (e) {
    String msg = "Failed to create config";
    if (verbose) msg += ", reason: \"$e\"";
    report_and_abort(msg);
  }
}

void help() {
  print("timetracker. A time tracking utility");
  print("");
  print("Usage:");
  print("   timetracker command <args?>");
  print("");
  print("Options:");
  print("   -n   Also send out command results as a system notification.");
  print("   -v   Enable verbose error reporting.");
  print("");
  print("Commands:");
  print("   help <command?>         This help message.");
  print("   version                 Print out the current version.");
  print("   create-item <name>      Create a new item. Items are things you want to track time of.");
  print("   delete-item <item>      Delete an item.");
  print("   time-total <item>       Returns the total amount of hours time spend on an item as a double with 1 point of precision.");
  print("   start-session <item>    Start a session.");
  print("   end-session <item>      Stop a session.");
  print("   toggle-session <item>   Toggle the status of a session.");
  print("   session-status <item>   Returns \"active\" or \"inactive\" based on whether or not the session is active.");
  print("   list-sessions <item>    Prints out a list containing all the sessions of an item.");
}

void create_item(String name) {
  Item item = Item(name, false, null, []);
  item.save_to_file();
}

void delete_item(String name) {
  try {
    File item_file = File(config_path + "/${name}.json");
    if (!item_file.existsSync()) return;

    item_file.deleteSync();
  } catch (e) {
    report_and_abort("Failed to create item, reason: \"$e\"");
  }
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

  get_home_and_config_path();
  check_create_config();

  List<String> new_args = [];
  for (String arg in args) {
    switch (arg) {
      case "-n":
        send_out_notifs = true;
      case "-v":
        verbose = true;
      default:
        new_args.add(arg);
    }
  }
  args = new_args;

  final expected_arg_count = (int n) {
    if (n > args.length) {
      help();
      report_and_abort("Unexpected amount of arguments");
    }
  };

  switch (args.first) {
    case "start-session":
      expected_arg_count(2);
      Item item = Item.parse_from_file(args[1]);
      item.start_session();

    case "end-session":
      expected_arg_count(2);
      Item item = Item.parse_from_file(args[1]);
      item.end_session();

    case "toggle-session":
      expected_arg_count(2);
      Item item = Item.parse_from_file(args[1]);
      item.toggle_session(config_path);

    case "session-status":
      expected_arg_count(2);
      Item item = Item.parse_from_file(args[1]);
      print(item.active == true ? "active" : "inactive");

    case "delete-item":
      expected_arg_count(2);
      delete_item(args[1]);

    case "create-item":
      expected_arg_count(2);
      create_item(args[1]);

    case "time-total":
      expected_arg_count(2);
      Item item = Item.parse_from_file(args[1]);
      print("${item.time_total().toStringAsFixed(1)}");

    case "list-sessions":
      expected_arg_count(2);
      Item item = Item.parse_from_file(args[1]);
      item.list_session();

    case "version":
      print_version();

    default:
      help();
  }
}
