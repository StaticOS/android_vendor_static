# Copyright (C) 2023 StatiXOS
# SPDX-License-Identifier: Apache-2.0

# -----------------------------------------------------------------
# StatiX kernel updatepackage

STATIX_KERNEL_UPDATEPACKAGE := $(PRODUCT_OUT)/$(STATIX_VERSION)-kernel.zip

name := $(name)-target_kernel_files-$(FILE_NAME_TAG)

intermediates_kernel := $(call intermediates-dir-for,PACKAGING,target_files)
BUILT_TARGET_KERNEL_FILES_PACKAGE := $(intermediates_kernel)/$(name).zip
$(BUILT_TARGET_KERNEL_FILES_PACKAGE): intermediates_kernel := $(intermediates_kernel)
$(BUILT_TARGET_KERNEL_FILES_PACKAGE): \
	    zip_root := $(intermediates_kernel)/$(name)


# $(1): Directory to copy
# $(2): Location to copy it to
# The "ls -A" is to prevent "acp s/* d" from failing if s is empty.
define package_files-copy-root
  if [ -d "$(strip $(1))" -a "$$(ls -A $(1))" ]; then \
    mkdir -p $(2) && \
    $(ACP) -rd $(strip $(1))/* $(2); \
  fi
endef

# Run fs_config while creating the target files package
# $1: root directory
# $2: add prefix
define fs_config
(cd $(1); find . -type d | sed 's,$$,/,'; find . \! -type d) | cut -c 3- | sort | sed 's,^,$(2),' | $(HOST_OUT_EXECUTABLES)/fs_config -C -D $(TARGET_OUT) -S $(SELINUX_FC) -R "$(2)"
endef

# If we are using recovery as boot, output recovery files to BOOT/.
# If we are moving recovery resources to vendor_boot, output recovery files to VENDOR_BOOT/.
ifeq ($(BOARD_USES_RECOVERY_AS_BOOT),true)
$(BUILT_TARGET_KERNEL_FILES_PACKAGE): PRIVATE_RECOVERY_OUT := BOOT
else ifeq ($(BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT),true)
$(BUILT_TARGET_KERNEL_FILES_PACKAGE): PRIVATE_RECOVERY_OUT := VENDOR_BOOT
else
$(BUILT_TARGET_KERNEL_FILES_PACKAGE): PRIVATE_RECOVERY_OUT := RECOVERY
endif

ifdef BUILDING_VENDOR_BOOT_IMAGE
  $(BUILT_TARGET_KERNEL_FILES_PACKAGE): $(INTERNAL_VENDOR_RAMDISK_FILES)
  $(BUILT_TARGET_KERNEL_FILES_PACKAGE): $(INTERNAL_VENDOR_RAMDISK_FRAGMENT_TARGETS)
  $(BUILT_TARGET_KERNEL_FILES_PACKAGE): $(INTERNAL_VENDOR_BOOTCONFIG_TARGET)
  # The vendor ramdisk may be built from the recovery ramdisk.
  ifeq (true,$(BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT))
    $(BUILT_TARGET_KERNEL_FILES_PACKAGE): $(INTERNAL_RECOVERY_RAMDISK_FILES_TIMESTAMP)
  endif
endif

ifdef BUILDING_RECOVERY_IMAGE
  # TODO(b/30414428): Can't depend on INTERNAL_RECOVERYIMAGE_FILES alone like other
  # BUILT_TARGET_KERNEL_FILES_PACKAGE dependencies because currently there're cp/rsync/rm
  # commands in build-recoveryimage-target, which would touch the files under
  # TARGET_RECOVERY_OUT and race with packaging target-files.zip.
  ifeq ($(BOARD_USES_RECOVERY_AS_BOOT),true)
    $(BUILT_TARGET_KERNEL_FILES_PACKAGE): $(INSTALLED_BOOTIMAGE_TARGET)
  else
    $(BUILT_TARGET_KERNEL_FILES_PACKAGE): $(INSTALLED_RECOVERYIMAGE_TARGET)
  endif
  $(BUILT_TARGET_KERNEL_FILES_PACKAGE): $(INTERNAL_RECOVERYIMAGE_FILES)
endif

# Depending on the various images guarantees that the underlying
# directories are up-to-date.
$(BUILT_TARGET_KERNEL_FILES_PACKAGE): \
	    $(INSTALLED_RECOVERYIMAGE_TARGET) \
	    $(INSTALLED_DTBOIMAGE_TARGET) \
	    $(INSTALLED_ANDROID_INFO_TXT_TARGET) \
	    $(INSTALLED_KERNEL_TARGET) \
	    $(INSTALLED_RAMDISK_TARGET) \
	    $(INSTALLED_DTBIMAGE_TARGET) \
	    $(BOARD_PREBUILT_DTBOIMAGE) \
	    $(BOARD_PREBUILT_RECOVERY_DTBOIMAGE) \
	    $(BOARD_RECOVERY_ACPIO) \
	    $(SELINUX_FC) \
	    $(INSTALLED_MISC_INFO_TARGET) \
	    $(HOST_OUT_EXECUTABLES)/fs_config \
	    $(ADD_IMG_TO_TARGET_FILES) \
	    $(MAKE_RECOVERY_PATCH) \
	    $(BUILT_KERNEL_CONFIGS_FILE) \
	    $(BUILT_KERNEL_VERSION_FILE) \
	    | $(ACP)
	@echo "Package target kernel files: $@"
	$(hide) rm -rf $@ $@.list $(zip_root)
	$(hide) mkdir -p $(dir $@) $(zip_root)
	@# Files that do not end up in any images, but are necessary to
	@# build them.
	$(hide) mkdir -p $(zip_root)/META
ifneq (,$(INSTALLED_RECOVERYIMAGE_TARGET)$(filter true,$(BOARD_USES_RECOVERY_AS_BOOT))$(filter true,$(BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT)))
	@# Components of the recovery image
	$(hide) mkdir -p $(zip_root)/$(PRIVATE_RECOVERY_OUT)
# Exclude recovery files in the default vendor ramdisk if including a standalone
# recovery ramdisk in vendor_boot.
ifneq (true,$(BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT))
	$(hide) $(call package_files-copy-root, \
	    $(TARGET_RECOVERY_ROOT_OUT),$(zip_root)/$(PRIVATE_RECOVERY_OUT)/RAMDISK)
endif
ifdef INSTALLED_KERNEL_TARGET
ifneq (,$(filter true,$(BOARD_USES_RECOVERY_AS_BOOT)))
	cp $(INSTALLED_KERNEL_TARGET) $(zip_root)/$(PRIVATE_RECOVERY_OUT)/
else ifneq (true,$(BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE))
	cp $(firstword $(INSTALLED_KERNEL_TARGET)) $(zip_root)/$(PRIVATE_RECOVERY_OUT)/kernel
endif
endif
ifneq (truetrue,$(strip $(BUILDING_VENDOR_BOOT_IMAGE))$(strip $(BOARD_USES_RECOVERY_AS_BOOT)))
ifdef BOARD_INCLUDE_RECOVERY_DTBO
ifdef BOARD_PREBUILT_RECOVERY_DTBOIMAGE
	cp $(BOARD_PREBUILT_RECOVERY_DTBOIMAGE) $(zip_root)/$(PRIVATE_RECOVERY_OUT)/recovery_dtbo
else
	cp $(BOARD_PREBUILT_DTBOIMAGE) $(zip_root)/$(PRIVATE_RECOVERY_OUT)/recovery_dtbo
endif
endif # BOARD_INCLUDE_RECOVERY_DTBO
ifdef BOARD_INCLUDE_RECOVERY_ACPIO
	cp $(BOARD_RECOVERY_ACPIO) $(zip_root)/$(PRIVATE_RECOVERY_OUT)/recovery_acpio
endif
ifdef INSTALLED_DTBIMAGE_TARGET
	cp $(INSTALLED_DTBIMAGE_TARGET) $(zip_root)/$(PRIVATE_RECOVERY_OUT)/dtb
endif
ifneq (true,$(BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE))
ifdef INTERNAL_KERNEL_CMDLINE
	echo "$(INTERNAL_KERNEL_CMDLINE)" > $(zip_root)/$(PRIVATE_RECOVERY_OUT)/cmdline
endif # INTERNAL_KERNEL_CMDLINE != ""
endif # BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE != true
ifdef BOARD_KERNEL_BASE
	echo "$(BOARD_KERNEL_BASE)" > $(zip_root)/$(PRIVATE_RECOVERY_OUT)/base
endif
ifdef BOARD_KERNEL_PAGESIZE
	echo "$(BOARD_KERNEL_PAGESIZE)" > $(zip_root)/$(PRIVATE_RECOVERY_OUT)/pagesize
endif
endif # not (BUILDING_VENDOR_BOOT_IMAGE and BOARD_USES_RECOVERY_AS_BOOT)
endif # INSTALLED_RECOVERYIMAGE_TARGET defined or BOARD_USES_RECOVERY_AS_BOOT is true
	@# Components of the boot image
	$(hide) mkdir -p $(zip_root)/BOOT
	$(hide) mkdir -p $(zip_root)/ROOT
	$(hide) $(call package_files-copy-root, \
	    $(TARGET_ROOT_OUT),$(zip_root)/ROOT)
	@# If we are using recovery as boot, this is already done when processing recovery.
ifneq ($(BOARD_USES_RECOVERY_AS_BOOT),true)
	$(hide) $(call package_files-copy-root, \
	    $(TARGET_RAMDISK_OUT),$(zip_root)/BOOT/RAMDISK)
ifdef INSTALLED_KERNEL_TARGET
	$(hide) cp $(INSTALLED_KERNEL_TARGET) $(zip_root)/BOOT/
endif
ifeq (true,$(BOARD_USES_GENERIC_KERNEL_IMAGE))
	echo "$(GENERIC_KERNEL_CMDLINE)" > $(zip_root)/BOOT/cmdline
else ifndef INSTALLED_VENDOR_BOOTIMAGE_TARGET # && BOARD_USES_GENERIC_KERNEL_IMAGE != true
	echo "$(INTERNAL_KERNEL_CMDLINE)" > $(zip_root)/BOOT/cmdline
ifdef INSTALLED_DTBIMAGE_TARGET
	cp $(INSTALLED_DTBIMAGE_TARGET) $(zip_root)/BOOT/dtb
endif
ifdef BOARD_KERNEL_BASE
	echo "$(BOARD_KERNEL_BASE)" > $(zip_root)/BOOT/base
endif
ifdef BOARD_KERNEL_PAGESIZE
	echo "$(BOARD_KERNEL_PAGESIZE)" > $(zip_root)/BOOT/pagesize
endif
endif # INSTALLED_VENDOR_BOOTIMAGE_TARGET == "" && BOARD_USES_GENERIC_KERNEL_IMAGE != true
endif # BOARD_USES_RECOVERY_AS_BOOT not true
	$(hide) $(foreach t,$(INSTALLED_RADIOIMAGE_TARGET),\
	            mkdir -p $(zip_root)/RADIO; \
	            cp $(t) $(zip_root)/RADIO/$(notdir $(t));)
ifdef INSTALLED_VENDOR_BOOTIMAGE_TARGET
	mkdir -p $(zip_root)/VENDOR_BOOT
	$(call package_files-copy-root, \
	    $(TARGET_VENDOR_RAMDISK_OUT),$(zip_root)/VENDOR_BOOT/RAMDISK)
ifdef INSTALLED_DTBIMAGE_TARGET
ifneq ($(BUILDING_VENDOR_KERNEL_BOOT_IMAGE),true)
	cp $(INSTALLED_DTBIMAGE_TARGET) $(zip_root)/VENDOR_BOOT/dtb
endif
endif # end of INSTALLED_DTBIMAGE_TARGET
ifdef INTERNAL_VENDOR_BOOTCONFIG_TARGET
	cp $(INTERNAL_VENDOR_BOOTCONFIG_TARGET) $(zip_root)/VENDOR_BOOT/vendor_bootconfig
endif
ifdef BOARD_KERNEL_BASE
	echo "$(BOARD_KERNEL_BASE)" > $(zip_root)/VENDOR_BOOT/base
endif
ifdef BOARD_KERNEL_PAGESIZE
	echo "$(BOARD_KERNEL_PAGESIZE)" > $(zip_root)/VENDOR_BOOT/pagesize
endif
	echo "$(INTERNAL_KERNEL_CMDLINE)" > $(zip_root)/VENDOR_BOOT/vendor_cmdline
ifdef INTERNAL_VENDOR_RAMDISK_FRAGMENTS
	echo "$(INTERNAL_VENDOR_RAMDISK_FRAGMENTS)" > "$(zip_root)/VENDOR_BOOT/vendor_ramdisk_fragments"
	$(foreach vendor_ramdisk_fragment,$(INTERNAL_VENDOR_RAMDISK_FRAGMENTS), \
	  mkdir -p $(zip_root)/VENDOR_BOOT/RAMDISK_FRAGMENTS/$(vendor_ramdisk_fragment); \
	  echo "$(BOARD_VENDOR_RAMDISK_FRAGMENT.$(vendor_ramdisk_fragment).MKBOOTIMG_ARGS)" > "$(zip_root)/VENDOR_BOOT/RAMDISK_FRAGMENTS/$(vendor_ramdisk_fragment)/mkbootimg_args"; \
	  $(eval prebuilt_ramdisk := $(BOARD_VENDOR_RAMDISK_FRAGMENT.$(vendor_ramdisk_fragment).PREBUILT)) \
	  $(if $(prebuilt_ramdisk), \
	    cp "$(prebuilt_ramdisk)" "$(zip_root)/VENDOR_BOOT/RAMDISK_FRAGMENTS/$(vendor_ramdisk_fragment)/prebuilt_ramdisk";, \
	    $(call package_files-copy-root, \
	      $(VENDOR_RAMDISK_FRAGMENT.$(vendor_ramdisk_fragment).STAGING_DIR), \
	      $(zip_root)/VENDOR_BOOT/RAMDISK_FRAGMENTS/$(vendor_ramdisk_fragment)/RAMDISK); \
	  ))
endif # INTERNAL_VENDOR_RAMDISK_FRAGMENTS != ""
endif # INSTALLED_VENDOR_BOOTIMAGE_TARGET
ifdef INSTALLED_VENDOR_KERNEL_BOOTIMAGE_TARGET
	mkdir -p $(zip_root)/VENDOR_KERNEL_BOOT
	$(call package_files-copy-root, \
	    $(TARGET_VENDOR_KERNEL_RAMDISK_OUT),$(zip_root)/VENDOR_KERNEL_BOOT/RAMDISK)
ifdef INSTALLED_DTBIMAGE_TARGET
	cp $(INSTALLED_DTBIMAGE_TARGET) $(zip_root)/VENDOR_KERNEL_BOOT/dtb
endif
ifdef BOARD_KERNEL_PAGESIZE
	echo "$(BOARD_KERNEL_PAGESIZE)" > $(zip_root)/VENDOR_KERNEL_BOOT/pagesize
endif
endif # INSTALLED_VENDOR_BOOTIMAGE_TARGET
ifdef BUILDING_RAMDISK_IMAGE
ifeq (true,$(BOARD_IMG_USE_RAMDISK))
	@# Contents of the ramdisk image
	$(hide) mkdir -p $(zip_root)/IMAGES
	$(hide) cp $(INSTALLED_RAMDISK_TARGET) $(zip_root)/IMAGES/
endif
endif
ifeq ($(TARGET_OTA_ALLOW_NON_AB),true)
ifneq ($(INSTALLED_RECOVERYIMAGE_TARGET),)
	$(hide) PATH=$(INTERNAL_USERIMAGES_BINARY_PATHS):$$PATH MKBOOTIMG=$(MKBOOTIMG) \
	    $(MAKE_RECOVERY_PATCH) $(zip_root) $(zip_root)
endif
endif
	$(hide) cp $(SELINUX_FC) $(zip_root)/META/file_contexts.bin
	$(hide) cp $(INSTALLED_MISC_INFO_TARGET) $(zip_root)/META/misc_info.txt
ifdef BOARD_PREBUILT_INIT_BOOT_IMAGE
	$(hide) mkdir -p $(zip_root)/PREBUILT_IMAGES
	$(hide) cp $(INSTALLED_INIT_BOOT_IMAGE_TARGET) $(zip_root)/PREBUILT_IMAGES/
endif

ifndef BOARD_PREBUILT_BOOTIMAGE
ifneq (,$(strip $(INTERNAL_PREBUILT_BOOTIMAGE) $(filter true,$(BOARD_COPY_BOOT_IMAGE_TO_TARGET_FILES))))
ifdef INSTALLED_BOOTIMAGE_TARGET
	$(hide) mkdir -p $(zip_root)/IMAGES
	$(hide) cp $(INSTALLED_BOOTIMAGE_TARGET) $(zip_root)/IMAGES/
endif # INSTALLED_BOOTIMAGE_TARGET
endif # INTERNAL_PREBUILT_BOOTIMAGE != "" || BOARD_COPY_BOOT_IMAGE_TO_TARGET_FILES == true
else # BOARD_PREBUILT_BOOTIMAGE is defined
	$(hide) mkdir -p $(zip_root)/PREBUILT_IMAGES
	$(hide) cp $(INSTALLED_BOOTIMAGE_TARGET) $(zip_root)/PREBUILT_IMAGES/
endif # BOARD_PREBUILT_BOOTIMAGE
ifdef BOARD_PREBUILT_DTBOIMAGE
	$(hide) mkdir -p $(zip_root)/PREBUILT_IMAGES
	$(hide) cp $(INSTALLED_DTBOIMAGE_TARGET) $(zip_root)/PREBUILT_IMAGES/
endif # BOARD_PREBUILT_DTBOIMAGE
ifdef BUILDING_INIT_BOOT_IMAGE
	$(hide) $(call package_files-copy-root, $(TARGET_RAMDISK_OUT),$(zip_root)/INIT_BOOT/RAMDISK)
	$(hide) $(call fs_config,$(zip_root)/INIT_BOOT/RAMDISK,) > $(zip_root)/META/init_boot_filesystem_config.txt
ifdef BOARD_KERNEL_PAGESIZE
	$(hide) echo "$(BOARD_KERNEL_PAGESIZE)" > $(zip_root)/INIT_BOOT/pagesize
endif # BOARD_KERNEL_PAGESIZE
endif # BUILDING_INIT_BOOT_IMAGE
ifneq ($(INSTALLED_VENDOR_BOOTIMAGE_TARGET),)
	$(call fs_config,$(zip_root)/VENDOR_BOOT/RAMDISK,) > $(zip_root)/META/vendor_boot_filesystem_config.txt
endif
ifneq ($(INSTALLED_RECOVERYIMAGE_TARGET),)
	$(hide) $(call fs_config,$(zip_root)/RECOVERY/RAMDISK,) > $(zip_root)/META/recovery_filesystem_config.txt
endif
	@# Zip everything up, preserving symlinks and placing META/ files first to
	@# help early validation of the .zip file while uploading it.
	$(hide) find $(zip_root)/META | sort >$@.list
	$(hide) find $(zip_root) -path $(zip_root)/META -prune -o -print | sort >>$@.list
	$(hide) $(SOONG_ZIP) -d -o $@ -C $(zip_root) -r $@.list

.PHONY: target-kernel-package
target-kernel-package: $(BUILT_TARGET_KERNEL_FILES_PACKAGE)

$(call declare-1p-container,$(BUILT_TARGET_FILES_PACKAGE),)
$(call declare-container-license-deps,$(BUILT_TARGET_FILES_PACKAGE), $(INSTALLED_RECOVERYIMAGE_TARGET) \
            $(INSTALLED_DTBOIMAGE_TARGET) \
            $(INSTALLED_ANDROID_INFO_TXT_TARGET) \
            $(INSTALLED_KERNEL_TARGET) \
            $(INSTALLED_RAMDISK_TARGET) \
            $(INSTALLED_DTBIMAGE_TARGET) \
            $(BOARD_PREBUILT_DTBOIMAGE) \
            $(BOARD_PREBUILT_RECOVERY_DTBOIMAGE) \
            $(BOARD_RECOVERY_ACPIO) \
            $(ADD_IMG_TO_TARGET_FILES) \
            $(BUILT_KERNEL_CONFIGS_FILE) \
            $(BUILT_KERNEL_VERSION_FILE),$(BUILT_TARGET_FILES_PACKAGE):)

$(call dist-for-goals, target-kernel-package, $(BUILT_TARGET_KERNEL_FILES_PACKAGE))

name := $(name)-kernel-$(FILE_NAME_TAG)

STATIX_INTERNAL_KERNEL_UPDATEPACKAGE := $(PRODUCT_OUT)/$(name).zip

$(STATIX_INTERNAL_KERNEL_UPDATEPACKAGE): $(BUILT_TARGET_KERNEL_FILES_PACKAGE) $(KERNEL_IMGS_FROM_TARGET_FILES)
	$(call pretty,"Package: $@")
	PATH=$(dir $(ZIP2ZIP)):$$PATH $(IMG_FROM_TARGET_FILES) -z \
                $(BUILT_TARGET_KERNEL_FILES_PACKAGE) $@

$(call declare-1p-container,$(STATIX_INTERNAL_KERNEL_UPDATEPACKAGE),)
$(call declare-container-license-deps,$(STATIX_INTERNAL_KERNEL_UPDATEPACKAGE),$(BUILT_TARGET_KERNEL_FILES_PACKAGE) $(IMG_FROM_TARGET_FILES),$(PRODUCT_OUT)/:/)

.PHONY: kernelpackage
kernelpackage: $(STATIX_INTERNAL_KERNEL_UPDATEPACKAGE)
	$(hide) ln -f $(STATIX_INTERNAL_KERNEL_UPDATEPACKAGE) $(STATIX_KERNEL_UPDATEPACKAGE)