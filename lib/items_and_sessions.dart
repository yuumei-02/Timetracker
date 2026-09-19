// Copyright (c) 2026 yuumei-02.
// See the license file for more information.

import "dart:io";
import "dart:convert";

import "utils.dart";
import "config.dart";

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

   String serialize() => "{\"duration\": $duration_in_seconds, \"start\": \"${start.toIso8601String()}\", \"end\": \"${end.toIso8601String()}\"}";
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
         File item_file = File(config.path + "/${name}.json");
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
         File item_file = File(config.path + "/${name}.json");
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

