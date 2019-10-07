# Bring in Qualcomm helper macros
include vendor/statix/build/core/utils.mk

# Set device-specific HALs into project pathmap
define set-device-specific-path
$(if $(USE_DEVICE_SPECIFIC_$(1)), \
    $(if $(DEVICE_SPECIFIC_$(1)_PATH), \
        $(eval path := $(DEVICE_SPECIFIC_$(1)_PATH)), \
        $(eval path := $(TARGET_DEVICE_DIR)/$(2))), \
    $(eval path := $(3))) \
$(call project-set-path,qcom-$(2),$(strip $(path)))
endef

ifeq ($(PRODUCT_USES_QCOM_HARDWARE),true)

$(call set-device-specific-path,BT_VENDOR,bt-vendor,hardware/qcom/bt-caf)

$(call set-device-specific-path,AUDIO,audio,hardware/qcom/audio-caf/$(QCOM_HARDWARE_VARIANT))
$(call set-device-specific-path,DISPLAY,display,hardware/qcom/display-caf/$(QCOM_HARDWARE_VARIANT))
$(call set-device-specific-path,MEDIA,media,hardware/qcom/media-caf/$(QCOM_HARDWARE_VARIANT))

$(call set-device-specific-path,DATASERVICES,dataservices,vendor/qcom/opensource/dataservices)

$(call set-device-specific-path,WLAN,wlan,hardware/qcom/wlan)

endif
