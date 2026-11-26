#pragma once
#include "esp_err.h"
#ifdef __cplusplus
extern "C" {
#endif
typedef struct {
    const char *endpoint_url;
    const char *device_token;
    const char *server_root_ca_pem;
} er_event_uploader_config_t;
/* Start only after secure provisioning supplies HTTPS endpoint, per-device token and trusted CA. */
esp_err_t er_event_uploader_start(const er_event_uploader_config_t *config);
#ifdef __cplusplus
}
#endif
