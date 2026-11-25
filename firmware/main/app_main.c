#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "esp_system.h"
#include "system_state.h"
static const char *TAG="edu_ride";
/* Hardware drivers remain disabled pending verification of PCB GPIO mapping. */
static void supervisor_task(void *arg){(void)arg;er_state_set(ER_STATE_INITIALIZING);ESP_LOGI(TAG,"Supervisor started; board I/O drivers are not yet enabled.");ESP_LOGI(TAG,"Provision and validate firmware variant before operational use.");er_state_set(ER_STATE_DEGRADED);for(;;){ESP_LOGI(TAG,"controller scaffold running; hardware drivers pending");vTaskDelay(pdMS_TO_TICKS(10000));}}
void app_main(void){ESP_LOGI(TAG,"Edu Ride controller boot; reset reason=%d",(int)esp_reset_reason());er_state_set(ER_STATE_BOOT);if(xTaskCreate(supervisor_task,"supervisor",4096,NULL,5,NULL)!=pdPASS){ESP_LOGE(TAG,"Supervisor task creation failed");er_state_set(ER_STATE_FAULT);}}
