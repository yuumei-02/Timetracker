# Copyright (c) 2026 yuumei-02. All Rights Reserved.
# See the license file for more information.

.ONESHELL:

build: setup
	dart compile exe --target-os=linux ./lib/main.dart
	mv ./lib/main.exe ./build/bin/timetracker

setup:
	mkdir -p ./build/bin

