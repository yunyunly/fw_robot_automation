// Update Time 23-11-13 16:03:01
#ifndef __ROBOT_DEFS_H__
#define __ROBOT_DEFS_H__
typedef enum {
ROBOTC_PRINT_INFO=0x00,
ROBOTC_PLUG_IN=0x01,
ROBOTC_PLUG_OUT=0x02,
ROBOTC_CASE_OPEN=0x03,
ROBOTC_CASE_CLOSE=0x04,
ROBOTC_DOCK=0x05,
ROBOTC_UNDOCK=0x06,
ROBOTC_PRESS_BUTTON=0x07,
ROBOTC_REQUEST_BATTERY=0x8,
ROBOTC_CONNECT_HEARING_AIDS=0x9,
ROBOTC_DISCONNECT_HEARING_AIDS=0x10,
ROBOTC_CHARGE_HEARING_AIDS=0x0a,
ROBOTC_CHARGE_HEARING_AIDS_STOP=0x0b,
ROBOTC_GEN_PULSE=0x0c,
ROBOTC_SINGLE_WIRE_SND=0x0d,
ROBOTC_SINGLE_WIRE_REQ=0x0e,
ROBOTC_RESET=0xfe,
ROBOTC_NOT_IMPLEMENTED_YET=0xff,
} ROBOTC_t;
typedef enum {
ROBOTE_SET_DEVICE_MODE=0x0201,
ROBOTE_SET_VOLUME=0x0202,
ROBOTE_SET_REMOTE_FITTING_MODE=0x0203,
ROBOTE_SET_TONE=0x0204,
ROBOTE_GET_ENV_NOISE=0x0205,
ROBOTE_SET_DEVICE_LOCK=0x0206,
ROBOTE_SET_PROMPT_VOLUME=0x0207,
ROBOTE_SWITCH_ALGO_MODE=0x0301,
ROBOTE_SWITCH_BEAMFORMING_MODE=0x0302,
ROBOTE_HEARING_PROFILE=0x0303,
ROBOTE_SWITCH_ANSI_MODE=0x0306,
ROBOTE_BUTTON_FN_PRESS=0x0501,
ROBOTE_BUTTON_LEFT_PRESS=0x0502,
ROBOTE_BUTTON_RIGHT_PRESS=0x0503,
ROBOTE_LOG_INNOISE_STATE=0xff01,
ROBOTE_LOG_BF_STATE=0xfe02,
ROBOTE_LOG_VOLUME=0xfe03,
ROBOTE_LOG_WEAR_STATE=0xfe04,
ROBOTE_LOG_A2DP_STATE=0xfe05,
ROBOTE_LOG_HFP_STATE=0xfe06,
ROBOTE_LOG_TWS_STATE=0xfe07,
ROBOTE_LOG_VOLT=0xfe08,
ROBOTE_LOG_SOC=0xfe09,
ROBOTE_LOG_MCU_FREQ=0xfe0a,
ROBOTE_WEAR_ON=0xfe0b,
ROBOTE_WEAR_OFF=0xfe0c,
ROBOTE_DOUBLE_TAP=0xfe0d,
ROBOTE_RESET=0xfe0e,
ROBOTE_POWER_OFF=0xfe0f,
} ROBOTE_t;
typedef enum {
SIDE_LEFT=0x01,
SIDE_RIGHT=0x02,
SIDE_BOTH=0x03,
} SIDE_t;
typedef enum {
BUTTON_FN=0x01,
BUTTON_FN_LONG=0x02,
BUTTON_RST=0x03,
BUTTON_RST_LONG=0x04,
BUTTON_LEFT=0x05,
BUTTON_RIGHT=0x06,
} BUTTON_t;
typedef enum {
CHIP_M55=0x00,
CHIP_M33=0x01,
} CHIP_t;
typedef enum {
CMD_TPYE_STATUS_CHECK=0x01,
CMD_TPYE_APP_CONTROL=0x02,
CMD_TPYE_AUDIO_CHAIN=0x03,
CMD_TPYE_CASE_RELATED_WITH_APP=0x04,
CMD_TPYE_ECHO_CONTROL=0x05,
} CMD_TPYE_t;
typedef enum {
CHECK_CHECK_GENERAL_STATUS=0x01,
CHECK_START_UP_CHECK_STATUS=0x02,
CHECK_APP_BACKGROUND_MODE_CHECK_STATUS=0x03,
CHECK_APP_SEND_LOGS_ACKNOWLEDGE=0x04,
CHECK_APP_USERSTATS_MODE_CHECK_STATUS=0x05,
CHECK_APP_SEND_USERSTATS_ACKNOWLEDGE=0x06,
CHECK_APP_FETCH_BT_DEVICE_INFO=0x07,
CHECK_HA_SEND_DOUBLE_TAP_NOTIFICATION=0x08,
CHECK_CHECK_HARDWARE_VERSION=0x09,
} CHECK_t;
typedef enum {
CONTROL_SWITCH_DEVICE_MODE=0x01,
CONTROL_SET_VOLUME=0x02,
CONTROL_SET_REMOTE_FITTING_MODE=0x03,
CONTROL_SET_TONE=0x04,
CONTROL_GET_LATEST_NOISE=0x05,
CONTROL_LOCK_DEVICE=0x06,
CONTROL_SET_PROMPT_VOLUME=0x07,
CONTROL_SET_BATT_SAVING_AUTOMATIC=0x08,
CONTROL_GET_LTK_DATA=0x09,
CONTROL_SET_UPDATED_PMU_TIME=0x0a,
} CONTROL_t;
typedef enum {
AUDIO_SWITCH_RUNNING_MODE=0x01,
AUDIO_SET_BEAMFORMING_ONOFF=0x02,
AUDIO_UPDATE_HEARING_PROFILE=0x03,
AUDIO_SEND_CONFIG_TO_FW=0x04,
AUDIO_SEND_TEST_CONFIG_IN_REMOTE_FITING=0x05,
AUDIO_SWITCH_ANSI_SETTING=0x06,
AUDIO_FINETUNE_ANSI_RTS_GAIN=0x07,
} AUDIO_t;
typedef enum {
CASE_RELATED_WITH_APP_CASE_STARTUP_INFO_TO_APP=0x01,
CASE_RELATED_WITH_APP_CASE_FUNC_BUTTON_PRESSED_TO_APP=0x02,
CASE_RELATED_WITH_APP_CASE_LONG_BAR_L_PRESSED_TO_APP=0x03,
CASE_RELATED_WITH_APP_CASE_LONG_BAR_R_PRESSED_TO_APP=0x04,
} CASE_RELATED_WITH_APP_t;
typedef enum {
ECHO_CONTROL_CASE_SEND_STARTUP_INFO=0x01,
ECHO_CONTROL_CASE_FUNC_BUTTON_PRESSED=0x02,
ECHO_CONTROL_CASE_LONG_BAR_L_PRESSED=0x03,
ECHO_CONTROL_CASE_LONG_BAR_R_PRESSED=0x04,
ECHO_CONTROL_CASE_PAIRING_COMPLETED=0x05,
} ECHO_CONTROL_t;
#endif // __ROBOT_DEFS_H__
