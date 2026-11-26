idf_component_register(
    SRCS "app_main.c" "system_state.c" "driver_ui.c" "event_journal.c" "event_uploader.c"
    INCLUDE_DIRS "."
    REQUIRES driver esp_timer nvs_flash esp_http_client json mbedtls
)
