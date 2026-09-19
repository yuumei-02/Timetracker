// Copyright (c) 2026 yuumei-02.
// See the license file for more information.

import "dart:io";
import "dart:convert";

import "utils.dart";
import "config.dart";
import "items_and_sessions.dart";

const String version = "1.2.0";

void help({ String? command }) {
   print("timetracker. A time tracking utility");
   print("");
   print("Usage:");
   print("   timetracker command <args?>");
   print("");
   
   switch (command) {
      case "prune": {
         print("Flags:");
         print("   --prune-up-to-minute <minute>");
      }
      
      default: {
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
         print("   prune <item> <flags?>   Remove sessions from item who's duration is shorter than 1 minute. See prune's help page to see it's flags.");
      }
   }

   print("");
   print("See \"timetracker help <command>\" for more information on a specific command.");
}

void create_item(String name) {
   Item item = Item(name, false, null, []);
   item.save_to_file();
}

void delete_item(String name) {
   try {
      File item_file = File(config.path + "/${name}.json");
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

   config = Config.initialize();

   Map<String, dynamic> flags = {};
   List<String> new_args = [];
   for (int i = 0; i < args.length; ++i) {
      switch (args[i]) {
         case "-n": send_out_notifs = true;
         case "-v": verbose = true;

         case "--prune-up-to-minute": {
            i += 1;
            if (i >= args.length) {
               report_and_abort("No minute provided for the \"--prune-up-to-minute\" flag.");
            }

            int? minute = int.tryParse(args[i]);
            if (minute == null) {
               report_and_abort("The \"--prune-up-to-minute\" flag expects an integer");
            }

            flags["prune-up-to-minute"] = minute;
         }

         default: {
            new_args.add(args[i]);
         }
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
      case "start-session": {
         expected_arg_count(2);
         Item item = Item.parse_from_file(args[1]);
         item.start_session();
      }

      case "end-session": {
         expected_arg_count(2);
         Item item = Item.parse_from_file(args[1]);
         item.end_session();
      }

      case "toggle-session": {
         expected_arg_count(2);
         Item item = Item.parse_from_file(args[1]);
         item.toggle_session(config.path);
      }

      case "session-status": {
         expected_arg_count(2);
         Item item = Item.parse_from_file(args[1]);
         print(item.active == true ? "active" : "inactive");
      }

      case "delete-item": {
         expected_arg_count(2);
         delete_item(args[1]);
      }

      case "create-item": {
         expected_arg_count(2);
         create_item(args[1]);
      }

      case "time-total": {
         expected_arg_count(2);
         Item item = Item.parse_from_file(args[1]);
         print("${item.time_total().toStringAsFixed(1)}");
      }

      case "list-sessions": {
         expected_arg_count(2);
         Item item = Item.parse_from_file(args[1]);
         item.list_session();
      }

      case "prune": {
         expected_arg_count(2);
         Item item = Item.parse_from_file(args[1]);
         item.prune(prune_up_to_minute: flags["prune-up-to-minute"]);
      }

      case "version": {
         print_version();
      }

      default: {
         if (args.length > 1) {
            help(command: args[1]);
         } else {
            help();
         }
      }
   }
}

