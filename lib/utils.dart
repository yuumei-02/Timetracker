// Copyright (c) 2026 yuumei-02.
// See the license file for more information.

import "dart:io";

bool send_out_notifs = false;
bool verbose = false;

void notify(String message) {
   send_notification("Timetracker", message);
   print(message);
}

Never report_and_abort(String message) {
   send_notification("Error", message);
   print("[ERROR]: $message");
   exit(1);
}

void send_notification(String title, String body) {
   if (!send_out_notifs) return;
   Process.runSync("notify-send", ["-a", "timetracker", title, body]);
}

String format_datetime(DateTime time) {
   return time.toString().split('.').first;
}

String format_seconds(int seconds) {
   if (seconds < 60) return "$seconds seconds";
   if (seconds < 3600) return "${(seconds / 60).toStringAsFixed(1)} minutes";
   return "${(seconds / 3600).toStringAsFixed(1)} hours";
}

