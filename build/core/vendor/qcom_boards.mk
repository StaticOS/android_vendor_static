# Platform name variables - used in makefiles everywhere
MSMNILE := msmnile #SM8150
MSMSTEPPE := sm6150
TRINKET := trinket #SM6125

# Board platforms lists to be used for
# PRODUCT_BOARD_PLATFORM specific featurization
QCOM_BOARD_PLATFORMS := msm7x27
QCOM_BOARD_PLATFORMS += msm7x27a
QCOM_BOARD_PLATFORMS += msm7x30
QCOM_BOARD_PLATFORMS += msm8226
QCOM_BOARD_PLATFORMS += msm8610
QCOM_BOARD_PLATFORMS += msm8660
QCOM_BOARD_PLATFORMS += msm8909
QCOM_BOARD_PLATFORMS += msm8916
QCOM_BOARD_PLATFORMS += msm8960
QCOM_BOARD_PLATFORMS += msm8974
QCOM_BOARD_PLATFORMS += mpq8092
QCOM_BOARD_PLATFORMS += msm8937
QCOM_BOARD_PLATFORMS += msm8952
QCOM_BOARD_PLATFORMS += msm8953
QCOM_BOARD_PLATFORMS += msm8992
QCOM_BOARD_PLATFORMS += msm8994
QCOM_BOARD_PLATFORMS += msm8996
QCOM_BOARD_PLATFORMS += msm8998
QCOM_BOARD_PLATFORMS += msm_bronze
QCOM_BOARD_PLATFORMS += apq8084

QCOM_BOARD_PLATFORMS += sdm660
QCOM_BOARD_PLATFORMS += sdm845

QCOM_BOARD_PLATFORMS += $(TRINKET)
QCOM_BOARD_PLATFORMS += $(MSMSTEPPE)
QCOM_BOARD_PLATFORMS += $(MSMNILE)

# MSM7000 Family

MSM7K_BOARD_PLATFORMS := msm7x30
MSM7K_BOARD_PLATFORMS += msm7x27
MSM7K_BOARD_PLATFORMS += msm7x27a
MSM7K_BOARD_PLATFORMS += msm7k

QSD8K_BOARD_PLATFORMS := qsd8k
