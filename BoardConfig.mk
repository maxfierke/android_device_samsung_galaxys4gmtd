# Copyright (C) 2013 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# BoardConfig.mk
#
# Product-specific compile-time definitions.
#

#Video Devices
BOARD_SECOND_CAMERA_DEVICE := /dev/video2

# Kernel Config
TARGET_KERNEL_CONFIG := cyanogenmod_galaxys4gmtd_defconfig

# Bluetooth
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/samsung/galaxys4gmtd/bluetooth

# Recovery
BOARD_CUSTOM_RECOVERY_KEYMAPPING := ../../device/samsung/galaxys4gmtd/recovery/recovery_keys.c

TARGET_OTA_ASSERT_DEVICE := galaxys4g,galaxys4gmtd,SGH-T959V,SGH-T959W

# Import the aries-common BoardConfigCommon.mk
include device/samsung/aries-common/BoardConfigCommon.mk

## Override some Aries settings
# We only have mtd
TARGET_USERIMAGES_USE_EXT4 := false

# Temporary kernel cmdline
#BOARD_KERNEL_CMDLINE := console=ttySAC2,115200 init=/init no_console_suspend loglevel=8

# Set partition size differences
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 403701760
BOARD_USERDATAIMAGE_PARTITION_SIZE := 555745280
