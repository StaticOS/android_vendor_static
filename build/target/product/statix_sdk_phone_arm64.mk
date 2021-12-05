# Copyright (C) 2021 StatiXOS
# SPDX-License-Identifier: Apache-2.0

$(call inherit-product, build/target/product/sdk_phone_arm64.mk)
$(call inherit-product, vendor/statix/config/common.mk)
$(call inherit-product, vendor/statix/config/gsm.mk)

PRODUCT_COPY_FILES += \
    device/generic/goldfish/data/etc/permissions/privapp-permissions-goldfish.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/privapp-permissions-goldfish.xml \

# Allow building otatools
TARGET_FORCE_OTA_PACKAGE := true

# Don't include GApps
TARGET_DOES_NOT_USE_GAPPS := true

# Overrides
PRODUCT_NAME := statix_sdk_phone_arm64
PRODUCT_MODEL := StatiXOS Android SDK built for aarch64
