// Copyright (c) 2026 yuumei-02.
// See the license file for more information.

import "dart:io";
import "dart:convert";

import "utils.dart";

late Config config;

class Config {
   String home;
   String path;
   File config_file;
   Map? contents;

   Config._(this.home, this.path, this.config_file);

   static Config initialize() { 
      String? home_path = Platform.environment["HOME"];
      if (home_path == null) {
         report_and_abort("Failed to find the \"HOME\" envirnment variable");
      }
      String config_path = "$home_path/.config/timetracker";
      File config_file = File("$config_path/config.json");

      try {
         Directory config_dir = Directory(config_path);
         if (!config_dir.existsSync()) {
            config_dir.createSync(recursive: true);
         }

         if (!config_file.existsSync()) {
            config_file.createSync(recursive: true);
            config_file.writeAsStringSync("{}");
         }
      } catch (e) {
         report_and_abort("Failed to create the config directory${verbose ? ", reason: $e" : ""}");
      }

      return Config._(home_path, config_path, config_file);
   }

   void load_config() {
      try {
         contents = jsonDecode(config_file.readAsStringSync());
      } catch (e) {
         report_and_abort("Failed to load the config file${verbose ? ", reason: $e" : ""}");
      }
   }

   void save_config() {
      if (contents == null) return;

      try {
         config_file.writeAsStringSync(jsonEncode(contents));
      } catch (e) {
         report_and_abort("Failed to save the config to the config file, reason: $e");
      }
   }
}

