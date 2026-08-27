// Copyright (c) 2026 yuumei-02. All Rights Reserved.
// See the license file for more information.

import "dart:io";

void send_notification(String title, String body) =>
  Process.runSync("notify-send", [title, body]);

void main() {
  send_notification("zhyivannye", "miratny");
}

